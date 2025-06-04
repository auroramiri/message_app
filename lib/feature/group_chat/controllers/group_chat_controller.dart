import 'dart:developer';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:message_app/common/enum/message_type.dart';
import 'package:message_app/common/models/group_chat_model.dart';
import 'package:message_app/common/models/group_message_model.dart'
    as repository;
import 'package:message_app/common/repository/firebase_storage_repository.dart';
import 'package:message_app/feature/group_chat/repositories/group_chat_repository.dart'
    as repository;

final groupChatControllerProvider = Provider((ref) {
  final groupChatRepository = ref.watch(repository.groupChatRepositoryProvider);
  return GroupChatController(
    groupChatRepository: groupChatRepository,
    ref: ref,
  );
});

class GroupChatController {
  final repository.GroupChatRepository _groupChatRepository;
  final Ref ref;

  GroupChatController({
    required repository.GroupChatRepository groupChatRepository,
    required this.ref,
  }) : _groupChatRepository = groupChatRepository;

  Future<void> createGroup({
    required String groupName,
    required List<String> participantIds,
    required String? groupIconUrl,
  }) async {
    try {
      await _groupChatRepository.createGroup(
        groupName: groupName,
        participantIds: participantIds,
        groupIconUrl: groupIconUrl,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<void> sendGroupMessage({
    required String groupId,
    required String message,
    required MessageType messageType,
    File? file,
    String? fileName,
  }) async {
    try {
      String? fileUrl;
      int? fileSize;

      if (file != null) {
        fileUrl = await ref
            .read(firebaseStorageRepositoryProvider)
            .storeFileToFirebase(
              'groupMessages/${messageType.type}/$groupId/${DateTime.now().millisecondsSinceEpoch}',
              file,
            );
        fileSize = await file.length();
      }

      await _groupChatRepository.sendGroupMessage(
        groupId: groupId,
        message: message,
        messageType: messageType,
        fileUrl: fileUrl,
        fileSize: fileSize,
      );
    } catch (e) {
      rethrow;
    }
  }

  Stream<List<repository.GroupMessageModel>> getGroupMessages(String groupId) {
    return _groupChatRepository.getGroupMessages(groupId);
  }

  Stream<List<GroupChatModel>> getUserGroups() {
    return _groupChatRepository.getUserGroups();
  }

  Future<void> deleteGroupMessage({
    required String groupId,
    required String messageId,
  }) async {
    try {
      await _groupChatRepository.deleteGroupMessage(
        groupId: groupId,
        messageId: messageId,
      );
    } catch (e) {
      log(
        'Error from controller deleting message: $e',
      );
      rethrow; // Перебрасываем ошибку, чтобы UI мог ее обработать
    }
  }
}
