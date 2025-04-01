// lib/repositories/notification/notification_repository.dart
import 'dart:developer';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationRepository {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  
  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'message_channel', // id
    'Сообщения', // title
    description: 'Канал для уведомлений о новых сообщениях', // description
    importance: Importance.high,
    enableVibration: true,
    playSound: true,
  );

  // Функция для инициализации уведомлений
  Future<void> initialize() async {
    // Запрос разрешений
    _messaging.getToken().then((token) {
      if (token != null) {
      } else {
      }
    });

    // Создание канала уведомлений для Android
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(_channel);

    // Инициализация локальных уведомлений
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );
    
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );
    
    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Обработка сообщений, когда приложение открыто
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    
    // Обработка нажатия на уведомление, когда приложение было закрыто
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationOpen);
  }

  // Обработка нажатия на уведомление
  void _onNotificationTapped(NotificationResponse response) {
    // Здесь можно добавить навигацию к конкретному чату
    log('Нажатие на уведомление: ${response.payload}');
    
    // Пример навигации (нужно реализовать в вашем приложении)
    // if (response.payload != null) {
    //   navigatorKey.currentState?.pushNamed(
    //     '/chat',
    //     arguments: {'chatId': response.payload},
    //   );
    // }
  }

  // Обработка открытия уведомления
  void _handleNotificationOpen(RemoteMessage message) {
    log('Уведомление открыто: ${message.data}');
    
    // Здесь также можно добавить навигацию к конкретному чату
    // final chatId = message.data['chatId'];
    // if (chatId != null) {
    //   navigatorKey.currentState?.pushNamed(
    //     '/chat',
    //     arguments: {'chatId': chatId},
    //   );
    // }
  }

  // Обработка сообщений в переднем плане
  void _handleForegroundMessage(RemoteMessage message) {
    log('Получено сообщение в переднем плане: ${message.notification?.title}');
    
    final notification = message.notification;
    // final android = message.notification?.android;
    
    // Извлечение данных о чате из сообщения
    final String? chatId = message.data['chatId'];
    // final String? senderId = message.data['senderId'];
    final String? senderName = message.data['senderName'];
    final String? messageText = message.data['messageText'];
    
    // Создание полезной нагрузки для использования при нажатии на уведомление
    final String payload = chatId ?? '';

    // Показ локального уведомления
    if (notification != null) {
      _localNotifications.show(
        notification.hashCode,
        notification.title ?? senderName ?? 'Новое сообщение',
        notification.body ?? messageText ?? 'Вы получили новое сообщение',
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channel.id,
            _channel.name,
            channelDescription: _channel.description,
            icon: 'ic_launcher',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: payload,
      );
    }
  }

  // Получение FCM токена
  Future<String?> getToken() async {
    return await _messaging.getToken();
  }

  // Подписка на тему чата
  Future<void> subscribeToChatTopic(String chatId) async {
    await _messaging.subscribeToTopic('chat_$chatId');
    log('Подписка на тему чата: chat_$chatId');
  }

  // Отписка от темы чата
  Future<void> unsubscribeFromChatTopic(String chatId) async {
    await _messaging.unsubscribeFromTopic('chat_$chatId');
    log('Отписка от темы чата: chat_$chatId');
  }
}
