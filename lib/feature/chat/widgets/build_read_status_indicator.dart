import 'package:flutter/material.dart';
import 'package:message_app/common/extension/custom_theme_extension.dart';
import 'package:message_app/common/models/message_model.dart';

Widget buildReadStatusIndicator(
  MessageModel message,
  BuildContext context, {
  bool isImageMessage = false,
}) {
  final baseColor = isImageMessage ? Colors.white : context.theme.greyColor!;
  final seenColor = Colors.blue;

  return Icon(
    message.isSeen ? Icons.done_all : Icons.done,
    size: 14,
    color: message.isSeen ? seenColor : baseColor,
  );
}
