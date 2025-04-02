import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:message_app/common/enum/message_type.dart';
import 'package:message_app/common/helper/show_alert_dialog.dart';
import 'package:message_app/common/models/last_message_model.dart';
import 'package:message_app/common/models/message_model.dart';
import 'package:message_app/common/models/user_model.dart';
import 'package:message_app/common/repository/firebase_storage_repository.dart';

final chatRepositoryProvider = Provider((ref) {
  return ChatRepository(
    firestore: FirebaseFirestore.instance,
    auth: FirebaseAuth.instance,
  );
});

class ChatRepository {
  final FirebaseFirestore firestore;
  final FirebaseAuth auth;

  ChatRepository({required this.firestore, required this.auth});

  Future<void> deleteChat({
    required String receiverId,
    required BuildContext context,
  }) async {
    try {
      // Get reference to the messages collection
      final currentUserMessagesCollection = firestore
          .collection('users')
          .doc(auth.currentUser!.uid)
          .collection('chats')
          .doc(receiverId)
          .collection('messages');

      final receiverUserMessagesCollection = firestore
          .collection('users')
          .doc(receiverId)
          .collection('chats')
          .doc(auth.currentUser!.uid)
          .collection('messages');

      // Get all messages
      final currentUserMessages = await currentUserMessagesCollection.get();
      final receiverUserMessages = await receiverUserMessagesCollection.get();

      // Create a batch to delete all messages
      final batch = firestore.batch();

      // Add each message to the batch for deletion
      for (var message in currentUserMessages.docs) {
        batch.delete(message.reference);
      }
      for (var message in receiverUserMessages.docs) {
        batch.delete(message.reference);
      }

      // Commit the batch to delete all messages
      await batch.commit();

      // Delete the chat document itself
      await firestore
          .collection('users')
          .doc(auth.currentUser!.uid)
          .collection('chats')
          .doc(receiverId)
          .delete();

      await firestore
          .collection('users')
          .doc(receiverId)
          .collection('chats')
          .doc(auth.currentUser!.uid)
          .delete();

      // Create a new empty chat document with a "Chat cleared" message
      final currentUserData =
          await firestore.collection('users').doc(auth.currentUser!.uid).get();

      final receiverData =
          await firestore.collection('users').doc(receiverId).get();

      if (currentUserData.exists && receiverData.exists) {
        final receiverUserData = UserModel.fromMap(receiverData.data()!);

        // Create a new last message entry
        final newLastMessage = LastMessageModel(
          username: receiverUserData.username,
          profileImageUrl: receiverUserData.profileImageUrl,
          contactId: receiverUserData.uid,
          timeSent: DateTime.now(),
          lastMessage: "Chat cleared",
          backgroundImageUrl: '',
        );

        // Save the new chat entry
        await firestore
            .collection('users')
            .doc(auth.currentUser!.uid)
            .collection('chats')
            .doc(receiverId)
            .set(newLastMessage.toMap());
      }
    } catch (e) {
      if (context.mounted) {
        showAllertDialog(context: context, message: e.toString());
      }
    }
  }

  Future<void> deleteMessage({
    String? receiverId,
    required String messageId,
    required BuildContext context,
  }) async {
    try {
      // First, we need to find the message to get the receiverId if not provided
      String actualReceiverId = receiverId ?? '';

      if (actualReceiverId.isEmpty) {
        // Search for the message in all chats to find the receiverId
        final userChats =
            await firestore
                .collection('users')
                .doc(auth.currentUser!.uid)
                .collection('chats')
                .get();

        bool messageFound = false;

        // Iterate through each chat
        for (var chatDoc in userChats.docs) {
          final chatId = chatDoc.id;

          // Check if this message exists in this chat
          final messageDoc =
              await firestore
                  .collection('users')
                  .doc(auth.currentUser!.uid)
                  .collection('chats')
                  .doc(chatId)
                  .collection('messages')
                  .doc(messageId)
                  .get();

          if (messageDoc.exists) {
            actualReceiverId = chatId;
            messageFound = true;
            break;
          }
        }

        if (!messageFound) {
          throw Exception('Message not found');
        }
      }

      // Now we have the receiverId, proceed with deletion

      // Delete message from sender's collection
      await firestore
          .collection('users')
          .doc(auth.currentUser!.uid)
          .collection('chats')
          .doc(actualReceiverId)
          .collection('messages')
          .doc(messageId)
          .delete();

      // Delete message from receiver's collection
      await firestore
          .collection('users')
          .doc(actualReceiverId)
          .collection('chats')
          .doc(auth.currentUser!.uid)
          .collection('messages')
          .doc(messageId)
          .delete();

      // Update last message if needed
      final messages =
          await firestore
              .collection('users')
              .doc(auth.currentUser!.uid)
              .collection('chats')
              .doc(actualReceiverId)
              .collection('messages')
              .orderBy('timeSent', descending: true)
              .limit(1)
              .get();

      if (messages.docs.isNotEmpty) {
        final lastMessage = MessageModel.fromMap(messages.docs.first.data());

        // Get user data
        final currentUserData =
            await firestore
                .collection('users')
                .doc(auth.currentUser!.uid)
                .get();

        final receiverData =
            await firestore.collection('users').doc(actualReceiverId).get();

        if (currentUserData.exists && receiverData.exists) {
          final senderData = UserModel.fromMap(currentUserData.data()!);
          final receiverUserData = UserModel.fromMap(receiverData.data()!);

          // Format last message text based on message type
          String lastMessageText;
          switch (lastMessage.type) {
            case MessageType.text:
              lastMessageText = lastMessage.textMessage;
              break;
            case MessageType.image:
              lastMessageText = '📸 Photo message';
              break;
            case MessageType.audio:
              lastMessageText = '🎵 Voice message';
              break;
            case MessageType.video:
              lastMessageText = '🎬 Video message';
              break;
            case MessageType.gif:
              lastMessageText = '🎭 GIF message';
              break;
          }

          // Update last message for both users
          saveAsLastMessage(
            senderUserData: senderData,
            receiverUserData: receiverUserData,
            lastMessage: lastMessageText,
            timeSent: lastMessage.timeSent,
            receiverId: actualReceiverId,
          );
        }
      } else {
        // If no messages left, update with "No messages"
        final currentUserData =
            await firestore
                .collection('users')
                .doc(auth.currentUser!.uid)
                .get();

        final receiverData =
            await firestore.collection('users').doc(actualReceiverId).get();

        if (currentUserData.exists && receiverData.exists) {
          final senderData = UserModel.fromMap(currentUserData.data()!);
          final receiverUserData = UserModel.fromMap(receiverData.data()!);

          saveAsLastMessage(
            senderUserData: senderData,
            receiverUserData: receiverUserData,
            lastMessage: "No messages",
            timeSent: DateTime.now(),
            receiverId: actualReceiverId,
          );
        }
      }
    } catch (e) {
      log('Error deleting message: $e');
      if (context.mounted) {
        showAllertDialog(context: context, message: e.toString());
      }
    }
  }

  Future<void> setChatBackgroundImage({
    required var imageFile,
    required String receiverId,
    required BuildContext context,
    required Ref ref,
  }) async {
    try {
      final chatId = const Uuid().v1();
      final storageRepo = ref.read(firebaseStorageRepositoryProvider);
      final backgroundImageUrl = await storageRepo.storeFileToFirebase(
        'chats/backgrounds/${auth.currentUser!.uid}/$receiverId/$chatId',
        imageFile,
      );

      if (backgroundImageUrl == null || backgroundImageUrl.isEmpty) {
        if (context.mounted) {
          showAllertDialog(
            context: context,
            message: "Failed to upload background image.",
          );
        }
        return;
      }
      // Get existing chat documents
      final senderChatDoc =
          await firestore
              .collection('users')
              .doc(auth.currentUser!.uid)
              .collection('chats')
              .doc(receiverId)
              .get();

      final receiverChatDoc =
          await firestore
              .collection('users')
              .doc(receiverId)
              .collection('chats')
              .doc(auth.currentUser!.uid)
              .get();

      // Update sender's chat document if it exists
      if (senderChatDoc.exists) {
        // Get the existing document data
        Map<String, dynamic> senderData = Map<String, dynamic>.from(
          senderChatDoc.data()!,
        );
        // Update the backgroundImageUrl field
        senderData['backgroundImageUrl'] = backgroundImageUrl;

        // Set the entire document with the updated data
        await firestore
            .collection('users')
            .doc(auth.currentUser!.uid)
            .collection('chats')
            .doc(receiverId)
            .set(senderData);
      } else {
        // Chat doesn't exist yet, show error
        if (context.mounted) {
          showAllertDialog(
            context: context,
            message: "Cannot set background image. Start a conversation first.",
          );
        }
        return;
      }

      // Update receiver's chat document if it exists
      if (receiverChatDoc.exists) {
        // Get the existing document data
        Map<String, dynamic> receiverData = Map<String, dynamic>.from(
          receiverChatDoc.data()!,
        );
        // Update the backgroundImageUrl field
        receiverData['backgroundImageUrl'] = backgroundImageUrl;

        // Set the entire document with the updated data
        await firestore
            .collection('users')
            .doc(receiverId)
            .collection('chats')
            .doc(auth.currentUser!.uid)
            .set(receiverData);
      }
    } catch (e) {
      if (context.mounted) {
        showAllertDialog(context: context, message: e.toString());
      }
    }
  }

  void sendFileMessage({
    required var file,
    required BuildContext context,
    required String receiverId,
    required UserModel senderData,
    required Ref ref,
    required MessageType messageType,
  }) async {
    try {
      final timeSent = DateTime.now();
      final messageId = const Uuid().v1();

      final imageUrl = await ref
          .read(firebaseStorageRepositoryProvider)
          .storeFileToFirebase(
            'chats/${messageType.type}/${senderData.uid}/$receiverId/$messageId',
            file,
          );
      final userMap = await firestore.collection('users').doc(receiverId).get();
      final receverUserData = UserModel.fromMap(userMap.data()!);

      String lastMessage;

      switch (messageType) {
        case MessageType.image:
          lastMessage = '📸 Photo message';
          break;
        case MessageType.audio:
          lastMessage = '📸 Voice message';
          break;
        case MessageType.video:
          lastMessage = '📸 Video message';
          break;
        case MessageType.gif:
          lastMessage = '📸 GIF message';
          break;
        default:
          lastMessage = '📦 GIF message';
          break;
      }

      saveToMessageCollection(
        receiverId: receiverId,
        textMessage: imageUrl,
        timeSent: timeSent,
        textMessageId: messageId,
        senderUsername: senderData.username,
        receiverUsername: receverUserData.username,
        messageType: messageType,
      );

      saveAsLastMessage(
        senderUserData: senderData,
        receiverUserData: receverUserData,
        lastMessage: lastMessage,
        timeSent: timeSent,
        receiverId: receiverId,
      );
    } catch (e) {
      if (context.mounted) {
        showAllertDialog(context: context, message: e.toString());
      }
    }
  }

  Stream<List<MessageModel>> getAllOneToOneMessage(String receiverId) {
    return firestore
        .collection('users')
        .doc(auth.currentUser!.uid)
        .collection('chats')
        .doc(receiverId)
        .collection('messages')
        .orderBy('timeSent')
        .snapshots()
        .map((event) {
          List<MessageModel> messages = [];
          for (var message in event.docs) {
            messages.add(MessageModel.fromMap(message.data()));
          }
          return messages;
        });
  }

  Stream<List<LastMessageModel>> getAllLastMessageList() {
    return firestore
        .collection('users')
        .doc(auth.currentUser!.uid)
        .collection('chats')
        .snapshots()
        .asyncMap((event) async {
          List<LastMessageModel> contacts = [];
          for (var document in event.docs) {
            final lastMessage = LastMessageModel.fromMap(document.data());
            final userData =
                await firestore
                    .collection('users')
                    .doc(lastMessage.contactId)
                    .get();
            final user = UserModel.fromMap(userData.data()!);
            contacts.add(
              LastMessageModel(
                username: user.username,
                profileImageUrl: user.profileImageUrl,
                contactId: lastMessage.contactId,
                timeSent: lastMessage.timeSent,
                lastMessage: lastMessage.lastMessage,
                backgroundImageUrl: lastMessage.backgroundImageUrl,
              ),
            );
          }
          return contacts;
        });
  }

  Future<String?> getChatBackgroundImage(String receiverId) async {
    try {
      final chatDoc =
          await firestore
              .collection('users')
              .doc(auth.currentUser!.uid)
              .collection('chats')
              .doc(receiverId)
              .get();

      if (chatDoc.exists && chatDoc.data()!.containsKey('backgroundImageUrl')) {
        return chatDoc.data()!['backgroundImageUrl'] as String?;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  void sendTextMessage({
    required BuildContext context,
    required String textMessage,
    required String receiverId,
    required UserModel senderData,
  }) async {
    try {
      final timeSent = DateTime.now();
      final receiverDataMap =
          await firestore.collection('users').doc(receiverId).get();
      final receiverData = UserModel.fromMap(receiverDataMap.data()!);
      final textMessageId = const Uuid().v1();

      saveToMessageCollection(
        receiverId: receiverId,
        textMessage: textMessage,
        timeSent: timeSent,
        textMessageId: textMessageId,
        senderUsername: senderData.username,
        receiverUsername: receiverData.username,
        messageType: MessageType.text,
      );

      saveAsLastMessage(
        senderUserData: senderData,
        receiverUserData: receiverData,
        lastMessage: textMessage,
        timeSent: timeSent,
        receiverId: receiverId,
      );
    } catch (e) {
      if (context.mounted) {
        showAllertDialog(context: context, message: e.toString());
      }
    }
  }

  void saveToMessageCollection({
    required String receiverId,
    required String textMessage,
    required DateTime timeSent,
    required String textMessageId,
    required String senderUsername,
    required String receiverUsername,
    required MessageType messageType,
  }) async {
    final message = MessageModel(
      senderId: auth.currentUser!.uid,
      receiverId: receiverId,
      textMessage: textMessage,
      type: messageType,
      timeSent: timeSent,
      messageId: textMessageId,
      isSeen: false,
      notificationSent: false,
    );

    // sender
    await firestore
        .collection('users')
        .doc(auth.currentUser!.uid)
        .collection('chats')
        .doc(receiverId)
        .collection('messages')
        .doc(textMessageId)
        .set(message.toMap());

    // receiver
    await firestore
        .collection('users')
        .doc(receiverId)
        .collection('chats')
        .doc(auth.currentUser!.uid)
        .collection('messages')
        .doc(textMessageId)
        .set(message.toMap());
  }

  void saveAsLastMessage({
    required UserModel senderUserData,
    required UserModel receiverUserData,
    required String lastMessage,
    required DateTime timeSent,
    required String receiverId,
  }) async {
    try {
      // Get existing chat documents to check if they exist and get background image URLs
      final senderChatDoc =
          await firestore
              .collection('users')
              .doc(auth.currentUser!.uid)
              .collection('chats')
              .doc(receiverId)
              .get();

      final receiverChatDoc =
          await firestore
              .collection('users')
              .doc(receiverId)
              .collection('chats')
              .doc(auth.currentUser!.uid)
              .get();

      // Create base message maps
      Map<String, dynamic> receiverLastMessageMap = {
        'username': senderUserData.username,
        'profileImageUrl': senderUserData.profileImageUrl,
        'contactId': senderUserData.uid,
        'timeSent': timeSent.millisecondsSinceEpoch,
        'lastMessage': lastMessage,
      };

      Map<String, dynamic> senderLastMessageMap = {
        'username': receiverUserData.username,
        'profileImageUrl': receiverUserData.profileImageUrl,
        'contactId': receiverUserData.uid,
        'timeSent': timeSent.millisecondsSinceEpoch,
        'lastMessage': lastMessage,
      };

      // Always include backgroundImageUrl field, even if it's null
      // This ensures the field exists in the document

      // For receiver's chat document
      if (receiverChatDoc.exists &&
          receiverChatDoc.data()!.containsKey('backgroundImageUrl')) {
        receiverLastMessageMap['backgroundImageUrl'] =
            receiverChatDoc.data()!['backgroundImageUrl'];
      } else {
        // If no background image exists, explicitly set to null
        receiverLastMessageMap['backgroundImageUrl'] = null;
      }

      // For sender's chat document
      if (senderChatDoc.exists &&
          senderChatDoc.data()!.containsKey('backgroundImageUrl')) {
        senderLastMessageMap['backgroundImageUrl'] =
            senderChatDoc.data()!['backgroundImageUrl'];
      } else {
        // If no background image exists, explicitly set to null
        senderLastMessageMap['backgroundImageUrl'] = null;
      }

      // Update receiver's chat document
      await firestore
          .collection('users')
          .doc(receiverId)
          .collection('chats')
          .doc(auth.currentUser!.uid)
          .set(receiverLastMessageMap);

      // Update sender's chat document
      await firestore
          .collection('users')
          .doc(auth.currentUser!.uid)
          .collection('chats')
          .doc(receiverId)
          .set(senderLastMessageMap);
    } catch (e) {
      log("Error saving last message: $e");
    }
  }

  Future<void> markMessageAsSeen(String senderId, String messageId) async {
    try {
      // Update in sender's collection
      await firestore
          .collection('users')
          .doc(senderId)
          .collection('chats')
          .doc(auth.currentUser!.uid)
          .collection('messages')
          .doc(messageId)
          .update({
            'isSeen': true,
            'seenTime': DateTime.now().millisecondsSinceEpoch,
          });

      // Update in receiver's (current user's) collection
      await firestore
          .collection('users')
          .doc(auth.currentUser!.uid)
          .collection('chats')
          .doc(senderId)
          .collection('messages')
          .doc(messageId)
          .update({
            'isSeen': true,
            'seenTime': DateTime.now().millisecondsSinceEpoch,
          });
    } catch (e) {
      log('Error marking message as seen: $e');
    }
  }

  Future<void> markAllMessagesAsSeen(String senderId) async {
    try {
      // Get all unseen messages from this sender
      final messages =
          await firestore
              .collection('users')
              .doc(auth.currentUser!.uid)
              .collection('chats')
              .doc(senderId)
              .collection('messages')
              .where('senderId', isEqualTo: senderId)
              .where('isSeen', isEqualTo: false)
              .get();

      // Create a batch to update all messages at once
      final batch = firestore.batch();
      final now = DateTime.now().millisecondsSinceEpoch;

      // Add each message to the batch for updating in receiver's collection
      for (var doc in messages.docs) {
        final messageRef = firestore
            .collection('users')
            .doc(auth.currentUser!.uid)
            .collection('chats')
            .doc(senderId)
            .collection('messages')
            .doc(doc.id);

        batch.update(messageRef, {'isSeen': true, 'seenTime': now});

        // Also update in sender's collection
        final senderMessageRef = firestore
            .collection('users')
            .doc(senderId)
            .collection('chats')
            .doc(auth.currentUser!.uid)
            .collection('messages')
            .doc(doc.id);

        batch.update(senderMessageRef, {'isSeen': true, 'seenTime': now});
      }

      // Commit the batch
      await batch.commit();
    } catch (e) {
      log('Error marking all messages as seen: $e');
    }
  }
}
