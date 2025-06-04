// File: functions/index.js (или новый файл, например, functions/groupChatNotifications.js)

import { onDocumentCreated } from 'firebase-functions/v2/firestore';
import { firestore, messaging } from './firebase.js'; // Убедитесь, что firebase.js правильно экспортирует firestore и messaging

export const sendGroupNotification = onDocumentCreated('groups/{groupId}/messages/{messageId}', async (snap) => {
    const messageId = snap.params.messageId;
    const groupId = snap.params.groupId;
    const messageDoc = await firestore.collection(`groups/${groupId}/messages`).doc(messageId).get();
    const messageData = messageDoc.data();
    const messageType = messageData.type;
    const senderId = messageData.senderId;
    const messageText = messageData.message;
    console.log(messageData);
    console.log(senderId);

    if (!messageData) {
        console.log('No data in group message document:', messageId);
        return null;
    }

    // Предполагаем, что текстовое сообщение хранится в поле 'text'

    // Проверяем, отправлялось ли уже уведомление (опционально, если хотите добавить такой флаг)
    // if (messageData.notificationSent) {
    //     console.log('Notification already sent for group message:', messageId);
    //     return null;
    // }

    console.log(`New message in group ${groupId} from sender ${senderId}. Type: ${messageType}`);

    try {
        // Получаем информацию об отправителе
        const senderDoc = await firestore.collection('users').doc(senderId).get();
        const senderUsername = senderDoc.exists ? senderDoc.data().username : 'Unknown';
        console.log(`Sender username: ${senderUsername}`);

        // Получаем информацию о группе
        const groupDoc = await firestore.collection('groups').doc(groupId).get();
        if (!groupDoc.exists) {
            console.log('Group document not found:', groupId);
            return null;
        }
        const groupData = groupDoc.data();
        const groupName = groupData.groupName || 'Групповой чат'; // Предполагаем, что имя группы хранится в поле 'name'
        const groupMembers = groupData.participantIds || []; // Предполагаем, что список участников хранится в поле 'members' (массив UID)
        console.log(`Group name: ${groupName}, Members count: ${groupMembers.length}`);

        // Собираем токены получателей (все участники, кроме отправителя)
        const recipientTokens = [];
        const tokenPromises = groupMembers
            .filter(memberId => memberId !== senderId) // Исключаем отправителя
            .map(async (memberId) => {
                const userDoc = await firestore.collection('users').doc(memberId).get();
                if (userDoc.exists) {
                    const userData = userDoc.data();
                    if (userData.fcmToken) {
                        recipientTokens.push(userData.fcmToken);
                        console.log(`Found token for recipient: ${memberId}`);
                    } else {
                        console.log(`FCM token not found for user: ${memberId}`);
                    }
                } else {
                    console.log(`User document not found for recipient: ${memberId}`);
                }
            });

        await Promise.all(tokenPromises);

        if (recipientTokens.length === 0) {
            console.log('No recipient tokens found for group notification.');
            return null;
        }

        // Определяем текст уведомления в зависимости от типа сообщения
        let notificationBody = 'Новое сообщение';
        if (messageType === 'text') {
            // Ограничиваем длину текста для уведомления
            notificationBody = messageText.length > 50 ? messageText.substring(0, 50) + '...' : messageText;
        } else if (messageType === 'image') {
            notificationBody = 'Отправил изображение';
        } else if (messageType === 'video') {
            notificationBody = 'Отправил видео';
        } else if (messageType === 'audio') {
            notificationBody = 'Отправил аудиосообщение';
        } else if (messageType === 'gif') {
            notificationBody = 'Отправил GIF';
        } else {
            notificationBody = 'Отправил вложение';
        }


        const message = {
            notification: {
                title: `${senderUsername} в ${groupName}`,
                body: notificationBody,
            },
            tokens: recipientTokens, // Используем 'tokens' для отправки нескольким устройствам
            data: { // Опционально: добавьте данные для обработки в приложении
                groupId: groupId,
                senderId: senderId,
                messageId: messageId,
                // Добавьте другие поля, если нужно
            }
        };

        // Отправляем уведомление нескольким устройствам
        const response = await messaging.sendEachForMulticast(message);

        console.log('Successfully sent group notification:', response);

        // Опционально: Отмечаем, что уведомление было отправлено в документе сообщения
        // await snap.ref.update({ notificationSent: true });

        return null;

    } catch (error) {
        return null;
    }
});
