import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:message_app/common/enum/message_type.dart';
import 'package:message_app/common/helper/show_alert_dialog.dart';
import 'package:message_app/common/models/last_message_model.dart';
import 'package:message_app/common/models/message_model.dart';
import 'package:message_app/feature/auth/controller/auth_controller.dart';
import 'package:message_app/feature/chat/repositories/chat_repository.dart';

final chatControllerProvider = Provider((ref) {
  final chatRepository = ref.watch(chatRepositoryProvider);
  return ChatController(chatRepository: chatRepository, ref: ref);
});

class ChatController {
  final ChatRepository _chatRepository;
  final Ref ref;

  ChatController({
    required ChatRepository chatRepository,
    required this.ref,
  }) : _chatRepository = chatRepository;

  void sendFileMessage(
    BuildContext context,
    var file,
    String receiverId,
    MessageType messageType,
  ) {
    ref.read(userInfoAuthProvider).whenData((senderData) {
      return _chatRepository.sendFileMessage(
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
    return _chatRepository.getAllOneToOneMessage(receiverId);
  }

  Stream<List<LastMessageModel>> getAllLastMessageList() {
    return _chatRepository.getAllLastMessageList();
  }

  void sendTextMessage({
    required BuildContext context,
    required String textMessage,
    required String receiverId,
  }) {
    ref
        .read(userInfoAuthProvider)
        .whenData(
          (value) => _chatRepository.sendTextMessage(
            context: context,
            textMessage: textMessage,
            receiverId: receiverId,
            senderData: value!,
          ),
        );
  }

  Future<String?> getChatBackgroundImage(String receiverId) {
    return _chatRepository.getChatBackgroundImage(receiverId);
  }

  Future<void> setChatBackgroundImage({
    required var imageFile,
    required String receiverId,
    required BuildContext context,
  }) async {
    if (imageFile == null) {
      if (context.mounted) {
        showAllertDialog(context: context, message: "No image selected.");
      }
      return;
    }

    return _chatRepository.setChatBackgroundImage(
      imageFile: imageFile,
      receiverId: receiverId,
      context: context,
      ref: ref, // Pass the ref from the controller
    );
  }

  Future<void> deleteChat({
    required String receiverId,
    required BuildContext context,
  }) async {
    return _chatRepository.deleteChat(receiverId: receiverId, context: context);
  }

  // Delete a single message
  Future<void> deleteMessage({
    required String receiverId,
    required String messageId,
    required BuildContext context,
  }) async {
    return _chatRepository.deleteMessage(
      receiverId: receiverId,
      messageId: messageId,
      context: context,
    );
  }
}
