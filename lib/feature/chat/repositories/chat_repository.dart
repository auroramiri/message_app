import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:message_app/common/enum/message_type.dart';
import 'package:message_app/common/helper/show_alert_dialog.dart';
import 'package:message_app/common/models/last_message_model.dart';
import 'package:message_app/common/models/message_model.dart';
import 'package:message_app/common/models/user_model.dart';
import 'package:message_app/common/repository/firebase_storage_repository.dart';
import 'package:message_app/common/services/encryption/key_generation_service.dart';
import 'package:pointycastle/api.dart';
import 'package:pointycastle/asymmetric/api.dart';
import 'package:pointycastle/asymmetric/oaep.dart';
import 'package:pointycastle/asymmetric/rsa.dart';
import 'package:uuid/uuid.dart';

final chatRepositoryProvider = Provider((ref) {
  final storage = FlutterSecureStorage();
  final keyGenerationService = KeyGenerationService(secureStorage: storage);
  return ChatRepository(
    secureStorage: storage,
    firestore: FirebaseFirestore.instance,
    auth: FirebaseAuth.instance,
    keyGenerationService: keyGenerationService,
  );
});

class ChatRepository {
  final FlutterSecureStorage secureStorage;
  final FirebaseFirestore firestore;
  final FirebaseAuth auth;
  final KeyGenerationService keyGenerationService;

  ChatRepository({
    required this.secureStorage,
    required this.firestore,
    required this.auth,
    required this.keyGenerationService,
  });

  Future<String> decryptMessage(String encryptedMessage) async {
    developer.log('Starting decryption process for message.');
    try {
      final decryptedMessage = await keyGenerationService.decryptMessage(
        encryptedMessage,
      );

      developer.log('Message decrypted successfully.: $decryptedMessage');
      return decryptedMessage;
    } catch (e) {
      developer.log('Error during decryption: $e');
      throw Exception('Failed to decrypt message: $e');
    }
  }

  Future<String?> getReceiverPublicKey(String userId) async {
    final userDoc = await firestore.collection('users').doc(userId).get();
    if (userDoc.exists) {
      return userDoc.data()!['rsaPublicKey'] as String?;
    }
    return null;
  }

  Future<String> encryptMessage(String message, String publicKeyPEM) async {
    final publicKey = keyGenerationService.decodePublicKeyFromPEM(publicKeyPEM);
    final encryptor = OAEPEncoding(RSAEngine())
      ..init(true, PublicKeyParameter<RSAPublicKey>(publicKey));

    final messageBytes = Uint8List.fromList(utf8.encode(message));
    final encrypted = encryptor.process(messageBytes);
    return base64.encode(encrypted);
  }

  Future<void> deleteChat({
    required String receiverId,
    required BuildContext context,
  }) async {
    try {
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

      final currentUserMessages = await currentUserMessagesCollection.get();
      final receiverUserMessages = await receiverUserMessagesCollection.get();

      final batch = firestore.batch();

      for (var message in currentUserMessages.docs) {
        batch.delete(message.reference);
      }
      for (var message in receiverUserMessages.docs) {
        batch.delete(message.reference);
      }

      await batch.commit();

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

      final currentUserData =
          await firestore.collection('users').doc(auth.currentUser!.uid).get();
      final receiverData =
          await firestore.collection('users').doc(receiverId).get();

      if (currentUserData.exists && receiverData.exists) {
        final receiverUserData = UserModel.fromMap(receiverData.data()!);

        final newLastMessage = LastMessageModel(
          username: receiverUserData.username,
          profileImageUrl: receiverUserData.profileImageUrl,
          contactId: receiverUserData.uid,
          timeSent: DateTime.now(),
          lastMessage: "Chat cleared",
          backgroundImageUrl: '',
        );

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
      String actualReceiverId = receiverId ?? '';
      developer.log('Starting message deletion process.');

      if (actualReceiverId.isEmpty) {
        developer.log(
          'Receiver ID is empty. Searching for message in all chats.',
        );
        final userChats =
            await firestore
                .collection('users')
                .doc(auth.currentUser!.uid)
                .collection('chats')
                .get();

        bool messageFound = false;

        for (var chatDoc in userChats.docs) {
          final chatId = chatDoc.id;
          developer.log('Checking chat ID: $chatId');
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
            developer.log('Message found in chat ID: $chatId');
            break;
          }
        }

        if (!messageFound) {
          throw Exception('Message not found');
        }
      }

      final messageDoc =
          await firestore
              .collection('users')
              .doc(auth.currentUser!.uid)
              .collection('chats')
              .doc(actualReceiverId)
              .collection('messages')
              .doc(messageId)
              .get();

      if (messageDoc.exists) {
        final messageData = messageDoc.data();
        if (messageData != null) {
          final fileUrl = messageData['fileUrl'] as String?;

          if (fileUrl != null) {
            final storageReference = firebase_storage.FirebaseStorage.instance
                .refFromURL(fileUrl);
            await storageReference.delete();
            developer.log('File deleted from Firebase Storage.');
          }
        }
      }

      developer.log('Deleting message from sender\'s chat.');
      await firestore
          .collection('users')
          .doc(auth.currentUser!.uid)
          .collection('chats')
          .doc(actualReceiverId)
          .collection('messages')
          .doc(messageId)
          .delete();

      developer.log('Deleting message from receiver\'s chat.');
      await firestore
          .collection('users')
          .doc(actualReceiverId)
          .collection('chats')
          .doc(auth.currentUser!.uid)
          .collection('messages')
          .doc(messageId)
          .delete();

      developer.log('Fetching remaining messages.');
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

        developer.log('Fetching sender and receiver data.');
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
            case MessageType.file:
              lastMessageText = '📄 File message';
              break;
            case MessageType.gif:
              lastMessageText = '🎭 GIF message';
              break;
          }

          developer.log('Saving last message.');
          await saveAsLastMessage(
            senderUserData: senderData,
            receiverUserData: receiverUserData,
            lastMessage: lastMessageText,
            timeSent: lastMessage.timeSent,
            receiverId: actualReceiverId,
          );
        }
      } else {
        developer.log(
          'No messages left. Saving "No messages" as last message.',
        );
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

          await saveAsLastMessage(
            senderUserData: senderData,
            receiverUserData: receiverUserData,
            lastMessage: "No messages",
            timeSent: DateTime.now(),
            receiverId: actualReceiverId,
          );
        }
      }
    } catch (e) {
      developer.log('Error deleting message: $e');
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

      if (senderChatDoc.exists) {
        Map<String, dynamic> senderData = Map<String, dynamic>.from(
          senderChatDoc.data()!,
        );
        senderData['backgroundImageUrl'] = backgroundImageUrl;
        await firestore
            .collection('users')
            .doc(auth.currentUser!.uid)
            .collection('chats')
            .doc(receiverId)
            .set(senderData);
      } else {
        if (context.mounted) {
          showAllertDialog(
            context: context,
            message: "Cannot set background image. Start a conversation first.",
          );
        }
        return;
      }

      if (receiverChatDoc.exists) {
        Map<String, dynamic> receiverData = Map<String, dynamic>.from(
          receiverChatDoc.data()!,
        );
        receiverData['backgroundImageUrl'] = backgroundImageUrl;
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
    String? fileName,
  }) async {
    try {
      final timeSent = DateTime.now();
      final messageId = const Uuid().v1();
      developer.log(
        'Sending file message: file = ${messageType.type}, receiverId = $receiverId, messageType = $messageType, fileName = $fileName',
      );

      int? fileSize;
      if (file is File) {
        fileSize = await file.length();
      }

      final fileUrl = await ref
          .read(firebaseStorageRepositoryProvider)
          .storeFileToFirebase(
            'chats/${messageType.type}/${senderData.uid}/$receiverId/$messageId',
            file,
          );

      developer.log('File URL: $fileUrl');
      final userMap = await firestore.collection('users').doc(receiverId).get();
      final receiverUserData = UserModel.fromMap(userMap.data()!);

      String lastMessage;
      switch (messageType) {
        case MessageType.image:
          lastMessage = '📸 Photo message';
          break;
        case MessageType.audio:
          lastMessage = '🎵 Voice message';
          break;
        case MessageType.video:
          lastMessage = '🎬 Video message';
          break;
        case MessageType.gif:
          lastMessage = '🎭 GIF message';
          break;
        case MessageType.file:
          lastMessage = '📄 File: ${fileName ?? "File"}';
          break;
        default:
          lastMessage = '📦 Unknown message';
          break;
      }

      await saveToMessageCollection(
        receiverId: receiverId,
        textMessage: fileName ?? 'File',
        timeSent: timeSent,
        textMessageId: messageId,
        senderUsername: senderData.username,
        receiverUsername: receiverUserData.username,
        messageType: messageType,
        fileSize: fileSize,
        fileUrl: fileUrl,
      );

      developer.log('Message saved to message collection');

      await saveAsLastMessage(
        senderUserData: senderData,
        receiverUserData: receiverUserData,
        lastMessage: lastMessage,
        timeSent: timeSent,
        receiverId: receiverId,
      );

      developer.log('Last message saved');
    } catch (e) {
      developer.log(e.toString());
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

      await saveToMessageCollection(
        receiverId: receiverId,
        textMessage: textMessage,
        timeSent: timeSent,
        textMessageId: textMessageId,
        senderUsername: senderData.username,
        receiverUsername: receiverData.username,
        messageType: MessageType.text,
      );

      await saveAsLastMessage(
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

  Future<void> saveToMessageCollection({
    required String receiverId,
    required String textMessage,
    required DateTime timeSent,
    required String textMessageId,
    required String senderUsername,
    required String receiverUsername,
    required MessageType messageType,
    int? fileSize,
    String? fileUrl,
  }) async {
    try {
      developer.log('Retrieving public keys...');
      final senderPublicKeyPem = await getReceiverPublicKey(
        auth.currentUser!.uid,
      );
      final receiverPublicKeyPem = await getReceiverPublicKey(receiverId);

      if (senderPublicKeyPem == null || receiverPublicKeyPem == null) {
        throw Exception('Public keys not found');
      }

      developer.log('Public keys retrieved successfully.');

      // Ensure the text message is not empty
      if (textMessage.isEmpty) {
        throw Exception('Text message is empty');
      }

      developer.log('Encrypting message for sender...');
      developer.log('$textMessage PEMSender: $senderPublicKeyPem');
      final encryptedMessageForSender = await keyGenerationService
          .encryptMessage(textMessage, senderPublicKeyPem);
      developer.log('Encrypted message for sender: $encryptedMessageForSender');

      developer.log('Encrypting message for receiver...');
      final encryptedMessageForReceiver = await keyGenerationService
          .encryptMessage(textMessage, receiverPublicKeyPem);
      developer.log(
        'Encrypted message for receiver: $encryptedMessageForReceiver',
      );

      final messageForSender = MessageModel(
        senderId: auth.currentUser!.uid,
        receiverId: receiverId,
        textMessage: encryptedMessageForSender,
        type: messageType,
        timeSent: timeSent,
        messageId: textMessageId,
        isSeen: false,
        notificationSent: false,
        fileSize: fileSize,
        fileUrl: fileUrl,
      );

      final messageForReceiver = MessageModel(
        senderId: auth.currentUser!.uid,
        receiverId: receiverId,
        textMessage: encryptedMessageForReceiver,
        type: messageType,
        timeSent: timeSent,
        messageId: textMessageId,
        isSeen: false,
        notificationSent: false,
        fileSize: fileSize,
        fileUrl: fileUrl,
      );

      developer.log('Saving message for sender...');
      await firestore
          .collection('users')
          .doc(auth.currentUser!.uid)
          .collection('chats')
          .doc(receiverId)
          .collection('messages')
          .doc(textMessageId)
          .set(messageForSender.toMap());

      developer.log('Saving message for receiver...');
      await firestore
          .collection('users')
          .doc(receiverId)
          .collection('chats')
          .doc(auth.currentUser!.uid)
          .collection('messages')
          .doc(textMessageId)
          .set(messageForReceiver.toMap());

      developer.log('Messages saved successfully.');
    } catch (e) {
      developer.log('Error saving message: $e');
      throw Exception('Failed to save message: $e');
    }
  }

  Future<void> saveAsLastMessage({
    required UserModel senderUserData,
    required UserModel receiverUserData,
    required String lastMessage,
    required DateTime timeSent,
    required String receiverId,
  }) async {
    try {
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

      if (receiverChatDoc.exists &&
          receiverChatDoc.data()!.containsKey('backgroundImageUrl')) {
        receiverLastMessageMap['backgroundImageUrl'] =
            receiverChatDoc.data()!['backgroundImageUrl'];
      } else {
        receiverLastMessageMap['backgroundImageUrl'] = null;
      }

      if (senderChatDoc.exists &&
          senderChatDoc.data()!.containsKey('backgroundImageUrl')) {
        senderLastMessageMap['backgroundImageUrl'] =
            senderChatDoc.data()!['backgroundImageUrl'];
      } else {
        senderLastMessageMap['backgroundImageUrl'] = null;
      }

      await firestore
          .collection('users')
          .doc(receiverId)
          .collection('chats')
          .doc(auth.currentUser!.uid)
          .set(receiverLastMessageMap);

      await firestore
          .collection('users')
          .doc(auth.currentUser!.uid)
          .collection('chats')
          .doc(receiverId)
          .set(senderLastMessageMap);
    } catch (e) {
      developer.log("Error saving last message: $e");
    }
  }

  Future<void> markMessageAsSeen(String senderId, String messageId) async {
    try {
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
      developer.log('Error marking message as seen: $e');
    }
  }

  Future<void> markAllMessagesAsSeen(String senderId) async {
    try {
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

      final batch = firestore.batch();
      final now = DateTime.now().millisecondsSinceEpoch;

      for (var doc in messages.docs) {
        final messageRef = firestore
            .collection('users')
            .doc(auth.currentUser!.uid)
            .collection('chats')
            .doc(senderId)
            .collection('messages')
            .doc(doc.id);

        batch.update(messageRef, {'isSeen': true, 'seenTime': now});

        final senderMessageRef = firestore
            .collection('users')
            .doc(senderId)
            .collection('chats')
            .doc(auth.currentUser!.uid)
            .collection('messages')
            .doc(doc.id);

        batch.update(senderMessageRef, {'isSeen': true, 'seenTime': now});
      }

      await batch.commit();
    } catch (e) {
      developer.log('Error marking all messages as seen: $e');
    }
  }
}
