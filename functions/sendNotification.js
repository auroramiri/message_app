import { onDocumentCreated } from 'firebase-functions/v2/firestore';
import { firestore, messaging } from './firebase.js';

export const sendNotification = onDocumentCreated('users/{receiverId}/chats/{senderId}/messages/{messageId}', async (snap) => {
    console.log('Snap:', snap); // Логирование snap

    const receiverId = snap.params.receiverId;
    const senderId = snap.params.senderId;
    const messageId = snap.params.messageId;

    console.log('Receiver ID:', receiverId);
    console.log('Sender ID:', senderId);
    console.log('Message ID:', messageId);

    // Получаем документ пользователя-получателя
    const userDoc = await firestore.collection('users').doc(receiverId).get();

    if (!userDoc.exists) {
        console.log('Пользователь с uid не найден:', receiverId);
        return null;
    }

    const userData = userDoc.data();
    const tokens = userData.fcmTokens;

    if (!tokens || tokens.length === 0) {
        console.log('FCM токен для пользователя не найден:', receiverId);
        return null;
    }

    const token = tokens[0]; // Выбираем первый FCM токен из массива

    console.log('FCM токен:', token);

    // Получаем имя отправителя
    const senderDoc = await firestore.collection('users').doc(senderId).get();
    const senderUsername = senderDoc.exists ? senderDoc.data().username : 'Unknown';
    // Получаем текст сообщения
    const messageDoc = await firestore.collection(`users/${receiverId}/chats/${senderId}/messages`).doc(messageId).get();
    console.log('Сообщение:', messageDoc.exists ? messageDoc.data().textMessage : 'Unknown message');

    // Получаем заголовок сообщения
    const messageTitle = messageDoc.exists ? messageDoc.data().textMessage : 'Unknown message';

    const message = {
        notification: {
            title: messageTitle,
            body: `Вы получили новое сообщение от ${senderUsername}!`,
        },
        token: token // Ensure that this token is correctly set with the FCM token
    };

    return messaging.send(message)
        .then(response => {
            console.log('Успешно отправлено сообщение:', response);
            return null;
        })
        .catch(error => {
            console.error('Ошибка отправки сообщения:', error);
            console.error('Ответ от сервера:', error.errorInfo.message);
            return null;
        });
});