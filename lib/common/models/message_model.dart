import 'package:message_app/common/enum/message_type.dart';

class MessageModel {
  final String senderId;
  final String receiverId;
  final String textMessage;
  final MessageType type;
  final DateTime timeSent;
  final String messageId;
  final bool isSeen;
  final bool notificationSent;
  final String? fileUrl;
  final int? fileSize;

  MessageModel({
    required this.senderId,
    required this.receiverId,
    required this.textMessage,
    required this.type,
    required this.timeSent,
    required this.messageId,
    required this.isSeen,
    required this.notificationSent,
    this.fileUrl,
    this.fileSize,
  });

  factory MessageModel.fromMap(Map<String, dynamic> map) {
    return MessageModel(
      senderId: map["senderId"],
      receiverId: map["receiverId"],
      textMessage: map["textMessage"],
      type: (map["type"] as String).toEnum(),
      timeSent: DateTime.fromMillisecondsSinceEpoch(map["timeSent"]),
      messageId: map["messageId"],
      isSeen: map["isSeen"] ?? false,
      notificationSent: false,
      fileUrl: map['fileUrl'],
      fileSize: map['fileSize'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      "senderId": senderId,
      "receiverId": receiverId,
      "textMessage": textMessage,
      "type": type.type,
      "timeSent": timeSent.millisecondsSinceEpoch,
      "messageId": messageId,
      "isSeen": isSeen,
      "notificationSent": notificationSent,
      'fileUrl': fileUrl,
      'fileSize': fileSize,
    };
  }
}
