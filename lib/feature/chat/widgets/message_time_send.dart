import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:message_app/common/models/message_model.dart';

class MessageTimeSend extends StatelessWidget {
  const MessageTimeSend({
    super.key,
    required this.message,
  });

  final MessageModel message;

  @override
  Widget build(BuildContext context) {
    return Text(
      DateFormat.Hm().format(message.timeSent),
      style: const TextStyle(
        fontSize: 11,
        color: Colors.white,
      ),
    );
  }
}