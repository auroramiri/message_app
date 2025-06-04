import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:message_app/common/enum/message_type.dart' as my_type;
import 'package:message_app/common/models/message_model.dart';
import 'package:message_app/feature/chat/controller/chat_controller.dart';

void showContextMenu(
  BuildContext context,
  Offset tapPosition,
  WidgetRef ref,
  MessageModel message,
  bool isSender,
) {
  final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
  final position = RelativeRect.fromRect(
    Rect.fromPoints(tapPosition, tapPosition),
    Offset.zero & overlay.size,
  );

  showMenu<String>(
    context: context,
    position: position,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    elevation: 2,
    items: buildContextMenuItems(message, isSender),
  ).then((value) {
    if (context.mounted) {
      handleMenuSelection(context, value, ref, message);
    }
  });
}

List<PopupMenuItem<String>> buildContextMenuItems(
  MessageModel message,
  bool isSender,
) {
  return [
    if (message.type == my_type.MessageType.text)
      PopupMenuItem<String>(
        value: 'copy',
        child: buildMenuItem(Icons.copy, 'Copy'),
      ),
    if (isSender)
      PopupMenuItem<String>(
        value: 'delete',
        child: buildMenuItem(
          Icons.delete_outline,
          'Delete',
          textColor: Colors.red,
        ),
      ),
    PopupMenuItem<String>(
      value: 'forward',
      child: buildMenuItem(Icons.forward, 'Forward'),
    ),
    if (message.type == my_type.MessageType.text)
      PopupMenuItem<String>(
        value: 'info',
        child: buildMenuItem(Icons.info_outline, 'Info'),
      ),
  ];
}

Widget buildMenuItem(
  IconData icon,
  String label, {
  Color textColor = Colors.black,
}) {
  return Row(
    children: [
      Icon(icon, size: 20, color: textColor),
      const SizedBox(width: 10),
      Text(label),
    ],
  );
}

void handleMenuSelection(
  BuildContext context,
  String? value,
  WidgetRef ref,
  MessageModel message,
) async {
  if (value == null) return;

  switch (value) {
    case 'copy':
      copyMessage(context, message);
      break;
    case 'delete':
      showDeleteConfirmation(context, ref, message);
      break;
    case 'forward':
      handleForwardMessage(context);
      break;
    case 'info':
      showMessageInfo(context, message);
      break;
  }
}

void copyMessage(BuildContext context, MessageModel message) async {
  if (message.type == my_type.MessageType.text) {
    await Clipboard.setData(ClipboardData(text: message.textMessage));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Message copied to clipboard'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }
}

void showDeleteConfirmation(
  BuildContext context,
  WidgetRef ref,
  MessageModel message,
) {
  showDialog(
    context: context,
    builder:
        (dialogContext) => AlertDialog(
          title: const Text('Delete Message'),
          content: const Text('Are you sure you want to delete this message?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('CANCEL'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                showLoadingDialog(context, () async {
                  await ref
                      .read(chatControllerProvider)
                      .deleteMessage(
                        messageId: message.messageId,
                        context: context,
                      );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Message deleted successfully'),
                      ),
                    );
                  }
                });
              },
              child: const Text('DELETE', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
  );
}

void showLoadingDialog(BuildContext context, Future<void> Function() action) {
  showDialog(
    context: context,
    barrierDismissible: false, // Пользователь не может закрыть его тапом вне
    builder:
        (context) => const Center(
          child: CircularProgressIndicator(), // Или любой другой индикатор
        ),
  );

  action()
      .then((_) {
        Navigator.of(context, rootNavigator: true).pop();
      })
      .catchError((error) {
        developer.log('Error performing action: $error');
        if (context.mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to perform action: $error')),
          );
        }
      });
}

void handleForwardMessage(BuildContext context) {
  ScaffoldMessenger.of(
    context,
  ).showSnackBar(const SnackBar(content: Text('Forward feature coming soon')));
}

void showMessageInfo(BuildContext context, MessageModel message) {
  showDialog(
    context: context,
    builder:
        (context) => AlertDialog(
          title: const Text('Message Info'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Sent: ${DateFormat('MMM d, yyyy • h:mm a').format(message.timeSent)}',
              ),
              const SizedBox(height: 8),
              Text('Status: ${message.isSeen ? "Seen" : "Delivered"}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CLOSE'),
            ),
          ],
        ),
  );
}
