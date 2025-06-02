import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class TokenService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  // Сохранение FCM токена пользователя в Firestore
  Future<void> saveToken() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final token = await _messaging.getToken();
      if (token == null) return;

      // Обновление документа пользователя с одним FCM токеном
      await _firestore.collection('users').doc(user.uid).set({
        'fcmToken': token,
        'lastTokenUpdate': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      log('FCM токен успешно сохранен для пользователя: ${user.uid}');
    } catch (e) {
      log('Ошибка при сохранении FCM токена: $e');
    }
  }

  // Удаление токена при выходе пользователя
  Future<void> removeToken() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Удаляем токен, устанавливая его в пустую строку или null
      await _firestore.collection('users').doc(user.uid).update({
        'fcmToken': FieldValue.delete(),
      });

      log('FCM токен удален для пользователя: ${user.uid}');
    } catch (e) {
      log('Ошибка при удалении FCM токена: $e');
    }
  }
}
