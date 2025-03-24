import { onDocumentCreated } from 'firebase-functions/v2/firestore';
import { firestore, messaging } from './firebase.js';

export const sendNotification = onDocumentCreated('users/{receiverId}/chats/{senderId}/messages/{messageId}', async (snap) => {
    const messageId = snap.params.messageId;
    const receiverId = snap.params.receiverId;
    const senderId = snap.params.senderId;

    const messageDocReceiver = await firestore.collection(`users/${receiverId}/chats/${senderId}/messages`).doc(messageId).get();
    const messageDocSender = await firestore.collection(`users/${senderId}/chats/${receiverId}/messages`).doc(messageId).get();

    if (!messageDocReceiver.exists || !messageDocSender.exists) {
        console.log('Message document does not exist:', messageId);
        return null;
    }

    const messageDataReceiver = messageDocReceiver.data();
    const messageDataSender = messageDocSender.data();

    const messageTitle = messageDataReceiver.textMessage || 'Unknown message';
    const messageSender = messageDataReceiver.senderId;
    const messageReceiver = messageDataReceiver.receiverId;

    // Проверяем, отправлялось ли уже уведомление
    if (messageDataReceiver.notificationSent && messageDataSender.notificationSent) {
        console.log('Notification already sent for message:', messageId);
        return null;
    }

    // Получаем имя отправителя
    const senderDoc = await firestore.collection('users').doc(messageSender).get();
    const senderUsername = senderDoc.exists ? senderDoc.data().username : 'Unknown';

    // Получаем документ пользователя-получателя
    const userDoc = await firestore.collection('users').doc(messageReceiver).get();

    if (!userDoc.exists) {
        console.log('Пользователь с uid не найден:', messageReceiver);
        return null;
    }

    const userData = userDoc.data();
    const tokens = userData.fcmTokens;

    if (!tokens || tokens.length === 0) {
        console.log('FCM токен для пользователя не найден:', messageReceiver);
        return null;
    }

    const token = tokens[0]; // Выбираем первый FCM токен из массива

    const message = {
        notification: {
            title: `Вы получили новое сообщение от ${senderUsername}!`,
            body: messageTitle,
        },
        token: token
    };

    return messaging.send(message)
        .then(async (response) => {
            console.log('Успешно отправлено сообщение:', response);

            // Отмечаем, что уведомление было отправлено в обеих коллекциях
            await messageDocReceiver.ref.update({ notificationSent: true });
            await messageDocSender.ref.update({ notificationSent: true });

            return null;
        })
        .catch(error => {
            console.error('Ошибка отправки сообщения:', error);
            console.error('Ответ от сервера:', error.errorInfo.message);
            return null;
        });
});
