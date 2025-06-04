import 'dart:developer' as developer;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:message_app/common/enum/message_type.dart';
import 'package:message_app/common/models/group_chat_model.dart';
import 'package:message_app/common/models/group_message_model.dart';
import 'package:uuid/uuid.dart';

final groupChatRepositoryProvider = Provider((ref) {
  return GroupChatRepository(
    firestore: FirebaseFirestore.instance,
    auth: FirebaseAuth.instance,
  );
});

class GroupChatRepository {
  final FirebaseFirestore firestore;
  final FirebaseAuth auth;

  GroupChatRepository({required this.firestore, required this.auth});

  Future<void> createGroup({
    required String groupName,
    required List<String> participantIds,
    required String? groupIconUrl,
  }) async {
    try {
      final groupId = const Uuid().v1();
      final currentUserId = auth.currentUser!.uid;

      final uniqueParticipantIds = participantIds.toSet().toList();

      final group = GroupChatModel(
        groupId: groupId,
        groupName: groupName,
        groupIconUrl: groupIconUrl,
        createdBy: currentUserId,
        participantIds: [...uniqueParticipantIds, currentUserId],
        moderatorIds: [currentUserId],
        createdAt: DateTime.now(),
        lastMessage: '',
      );

      await firestore.collection('groups').doc(groupId).set(group.toMap());

      for (var participantId in uniqueParticipantIds) {
        await firestore
            .collection('users')
            .doc(participantId)
            .collection('groups')
            .doc(groupId)
            .set({'groupId': groupId});
      }

      await firestore
          .collection('users')
          .doc(currentUserId)
          .collection('groups')
          .doc(groupId)
          .set({'groupId': groupId});
    } catch (e) {
      developer.log('Error creating group: $e');
      throw Exception('Failed to create group: $e');
    }
  }

  Future<void> sendGroupMessage({
    required String groupId,
    required String message,
    required MessageType messageType,
    String? fileUrl,
    int? fileSize,
  }) async {
    try {
      final messageId = const Uuid().v1();
      final currentUserId = auth.currentUser!.uid;

      final groupMessage = GroupMessageModel(
        messageId: messageId,
        groupId: groupId,
        senderId: currentUserId,
        message: message,
        type: messageType,
        fileUrl: fileUrl,
        fileSize: fileSize,
        timeSent: DateTime.now(),
      );

      await firestore
          .collection('groups')
          .doc(groupId)
          .collection('messages')
          .doc(messageId)
          .set(groupMessage.toMap());

      await firestore.collection('groups').doc(groupId).update({
        'lastMessage': message,
        'lastMessageTime': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      developer.log('Error sending group message: $e');
      throw Exception('Failed to send group message: $e');
    }
  }

  Stream<List<GroupMessageModel>> getGroupMessages(String groupId) {
    return firestore
        .collection('groups')
        .doc(groupId)
        .collection('messages')
        .orderBy('timeSent')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => GroupMessageModel.fromMap(doc.data()))
              .toList();
        });
  }

  Stream<List<GroupChatModel>> getUserGroups() {
    final currentUserId = auth.currentUser!.uid;
    return firestore
        .collection('users')
        .doc(currentUserId)
        .collection('groups')
        .snapshots()
        .asyncMap((snapshot) async {
          final groupIds =
              snapshot.docs.map((doc) => doc['groupId'] as String).toList();
          final groups = <GroupChatModel>[];

          for (var groupId in groupIds) {
            final groupDoc =
                await firestore.collection('groups').doc(groupId).get();
            if (groupDoc.exists) {
              groups.add(GroupChatModel.fromMap(groupDoc.data()!));
            }
          }

          return groups;
        });
  }

  Future<String> getUserNameById(String userId) async {
    try {
      final userDoc = await firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        return userDoc.data()?['username'] ?? 'Unknown';
      } else {
        return 'Unknown';
      }
    } catch (e) {
      return 'Unknown';
    }
  }

  Future<void> deleteGroupMessage({
    required String groupId,
    required String messageId,
  }) async {
    try {
      developer.log(
        'Attempting to delete message $messageId from group $groupId',
      );

      await firestore
          .collection('groups')
          .doc(groupId)
          .collection('messages')
          .doc(messageId)
          .delete();

      developer.log('Message $messageId deleted successfully.');
    } catch (e) {
      developer.log('Error deleting group message $messageId: $e');
      throw Exception('Failed to delete message: $e');
    }
  }

  Future<void> addParticipant({
    required String groupId,
    required String participantId,
  }) async {
    try {
      // Add participant to the group
      await firestore.collection('groups').doc(groupId).update({
        'participantIds': FieldValue.arrayUnion([participantId]),
      });

      // Add group to the participant's list of groups
      await firestore
          .collection('users')
          .doc(participantId)
          .collection('groups')
          .doc(groupId)
          .set({'groupId': groupId});
    } catch (e) {
      developer.log('Error adding participant: $e');
      throw Exception('Failed to add participant: $e');
    }
  }

  Future<void> removeParticipant({
    required String groupId,
    required String participantId,
  }) async {
    try {
      // Remove participant from the group
      await firestore.collection('groups').doc(groupId).update({
        'participantIds': FieldValue.arrayRemove([participantId]),
      });

      // Remove group from the participant's list of groups
      await firestore
          .collection('users')
          .doc(participantId)
          .collection('groups')
          .doc(groupId)
          .delete();
    } catch (e) {
      developer.log('Error removing participant: $e');
      throw Exception('Failed to remove participant: $e');
    }
  }
}
