// lib/repositories/notification/notification_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:message_app/repositories/notification/message_notification_service.dart';
import 'package:message_app/repositories/notification/notification_repository.dart';
import 'package:message_app/repositories/notification/token_service.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository();
});

final tokenServiceProvider = Provider<TokenService>((ref) {
  return TokenService();
});

final messageNotificationServiceProvider = Provider<MessageNotificationService>((ref) {
  final notificationRepository = ref.watch(notificationRepositoryProvider);
  return MessageNotificationService(notificationRepository);
});
