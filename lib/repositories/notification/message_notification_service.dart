// lib/repositories/notification/message_notification_service.dart
import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:message_app/repositories/notification/notification_repository.dart';

class MessageNotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final NotificationRepository _notificationRepository;

  MessageNotificationService(this._notificationRepository);

  // Подписка на все чаты пользователя
  Future<void> subscribeToUserChats() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Получение всех чатов, в которых участвует пользователь
      final chatsSnapshot = await _firestore
          .collection('chats')
          .where('participants', arrayContains: user.uid)
          .get();

      // Подписка на каждый чат
      for (var chat in chatsSnapshot.docs) {
        await _notificationRepository.subscribeToChatTopic(chat.id);
      }

      log('Подписка на все чаты пользователя выполнена');
    } catch (e) {
      log('Ошибка при подписке на чаты пользователя: $e');
    }
  }

  // Подписка на новый чат
  Future<void> subscribeToChat(String chatId) async {
    await _notificationRepository.subscribeToChatTopic(chatId);
  }

  // Отписка от чата
  Future<void> unsubscribeFromChat(String chatId) async {
    await _notificationRepository.unsubscribeFromChatTopic(chatId);
  }

  // Настройка слушателя для новых сообщений в чате
  void setupMessageListener(String chatId, Function(Map<String, dynamic>) onNewMessage) {
    final user = _auth.currentUser;
    if (user == null) return;

    _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(1)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        final message = snapshot.docs.first.data();
        final senderId = message['senderId'];
        
        // Проверяем, что сообщение не от текущего пользователя
        if (senderId != user.uid) {
          onNewMessage(message);
        }
      }
    });
  }
}
