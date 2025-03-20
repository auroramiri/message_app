import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:message_app/common/enum/message_type.dart';
import 'package:message_app/common/models/last_message_model.dart';
import 'package:message_app/common/models/message_model.dart';
import 'package:message_app/feature/auth/controller/auth_controller.dart';
import 'package:message_app/feature/chat/repositories/chat_repository.dart';

final chatControllerProvider = Provider((ref) {
  final chatRepository = ref.watch(chatRepositoryProvider);
  return ChatController(
    chatRepository: chatRepository,
    ref: ref,
  );
});

class ChatController {
  final ChatRepository chatRepository;
  final Ref ref;

  ChatController({required this.chatRepository, required this.ref});

  void sendFileMessage(
    BuildContext context,
    var file,
    String receiverId,
    MessageType messageType,
  ) {
    ref.read(userInfoAuthProvider).whenData((senderData) {
      return chatRepository.sendFileMessage(
        file: file,
        context: context,
        receiverId: receiverId,
        senderData: senderData!,
        ref: ref,
        messageType: messageType,
      );
    });
  }

  Stream<List<MessageModel>> getAllOneToOneMessage(String receiverId) {
    return chatRepository.getAllOneToOneMessage(receiverId);
  }

  Stream<List<LastMessageModel>> getAllLastMessageList() {
    return chatRepository.getAllLastMessageList();
  }

  void sendTextMessage({
    required BuildContext context,
    required String textMessage,
    required String receiverId,
  }) {
    ref.read(userInfoAuthProvider).whenData(
          (value) => chatRepository.sendTextMessage(
            context: context,
            textMessage: textMessage,
            receiverId: receiverId,
            senderData: value!,
          ),
        );
  }
}