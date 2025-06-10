import 'dart:async';
import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Импортируем FirebaseAuth

class DisappearingMessagesService {
  final FirebaseFirestore firestore;

  DisappearingMessagesService({required this.firestore});

  void setDisappearingMessagesTimer(String time, String chatId) {
    Duration duration;
    switch (time) {
      case '1 minute':
        duration = Duration(minutes: 1);
      case '1 hour':
        duration = Duration(hours: 1);
        break;
      case '1 day':
        duration = Duration(days: 1);
        break;
      case '1 week':
        duration = Duration(days: 7);
        break;
      default:
        return; // If 'Off' is selected, do nothing
    }

    Timer(duration, () {
      // При срабатывании таймера вызываем удаление для обоих пользователей
      deleteMessages(chatId);
    });
  }

  Future<void> deleteMessages(String otherUserId) async {
    try {
      final currentUserId =
          FirebaseAuth
              .instance
              .currentUser!
              .uid; // Получаем ID текущего пользователя

      log(
        'Attempting to delete messages for chat between $currentUserId and $otherUserId',
      );

      // Удаляем сообщения для текущего пользователя
      final currentUserMessagesCollection = firestore
          .collection('users')
          .doc(currentUserId)
          .collection('chats')
          .doc(otherUserId) // chatId в этом контексте - это otherUserId
          .collection('messages');

      final currentUserMessages = await currentUserMessagesCollection.get();

      final batch1 = firestore.batch();
      for (var message in currentUserMessages.docs) {
        batch1.delete(message.reference);
      }
      await batch1.commit();
      log('Messages deleted for user $currentUserId successfully');

      // Удаляем сообщения для другого пользователя
      final otherUserMessagesCollection = firestore
          .collection('users')
          .doc(otherUserId) // Теперь otherUserId - это документ пользователя
          .collection('chats')
          .doc(
            currentUserId,
          ) // А currentUserId - это документ чата в его коллекции
          .collection('messages');

      final otherUserMessages = await otherUserMessagesCollection.get();

      final batch2 = firestore.batch();
      for (var message in otherUserMessages.docs) {
        batch2.delete(message.reference);
      }
      await batch2.commit();
      log('Messages deleted for user $otherUserId successfully');

      log(
        'Messages deleted successfully for both users in chat with $otherUserId',
      );
    } catch (e) {
      log('Error deleting messages for chat with $otherUserId: $e');
    }
  }
}
