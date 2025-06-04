import 'package:message_app/common/enum/message_type.dart';

class GroupMessageModel {
  final String messageId;
  final String groupId;
  final String senderId;
  final String message;
  final MessageType type;
  final String? fileUrl;
  final int? fileSize;
  final DateTime timeSent;

  GroupMessageModel({
    required this.messageId,
    required this.groupId,
    required this.senderId,
    required this.message,
    required this.type,
    this.fileUrl,
    this.fileSize,
    required this.timeSent,
  });

  Map<String, dynamic> toMap() {
    return {
      'messageId': messageId,
      'groupId': groupId,
      'senderId': senderId,
      'message': message,
      'type': type.name,
      'fileUrl': fileUrl,
      'fileSize': fileSize,
      'timeSent': timeSent.millisecondsSinceEpoch,
    };
  }

  factory GroupMessageModel.fromMap(Map<String, dynamic> map) {
    return GroupMessageModel(
      messageId: map['messageId'] ?? '',
      groupId: map['groupId'] ?? '',
      senderId: map['senderId'] ?? '',
      message: map['message'] ?? '',
      type: MessageType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => MessageType.text,
      ),
      fileUrl: map['fileUrl'],
      fileSize: map['fileSize'],
      timeSent: DateTime.fromMillisecondsSinceEpoch(map['timeSent'] ?? 0),
    );
  }
}
