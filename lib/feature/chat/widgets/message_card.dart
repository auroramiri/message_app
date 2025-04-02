import 'package:cached_network_image/cached_network_image.dart';
import 'package:custom_clippers/custom_clippers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:message_app/common/enum/message_type.dart' as my_type;
import 'package:message_app/common/extension/custom_theme_extension.dart';
import 'package:message_app/common/models/message_model.dart';
import 'package:message_app/feature/chat/controller/chat_controller.dart';
import 'package:message_app/feature/chat/pages/chat_page.dart';
import 'dart:developer' as developer;

import 'package:message_app/feature/chat/pages/image_viewer_page.dart';

class MessageCard extends ConsumerWidget {
  const MessageCard({
    super.key,
    required this.isSender,
    required this.haveNip,
    required this.message,
  });

  final bool isSender;
  final bool haveNip;
  final MessageModel message;

  void _showContextMenu(
    BuildContext context,
    Offset tapPosition,
    WidgetRef ref,
  ) {
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;

    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromPoints(tapPosition, tapPosition),
      Offset.zero & overlay.size,
    );

    showMenu<String>(
      context: context,
      position: position,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 2,
      items: [
        if (message.type == my_type.MessageType.text)
          PopupMenuItem<String>(
            value: 'copy',
            child: Row(
              children: [
                Icon(Icons.copy, size: 20, color: context.theme.greyColor),
                const SizedBox(width: 10),
                const Text('Copy'),
              ],
            ),
          ),
        if (isSender)
          PopupMenuItem<String>(
            value: 'delete',
            child: Row(
              children: [
                Icon(Icons.delete_outline, size: 20, color: Colors.red),
                const SizedBox(width: 10),
                const Text('Delete'),
              ],
            ),
          ),
        PopupMenuItem<String>(
          value: 'forward',
          child: Row(
            children: [
              Icon(Icons.forward, size: 20, color: context.theme.greyColor),
              const SizedBox(width: 10),
              const Text('Forward'),
            ],
          ),
        ),
        if (message.type == my_type.MessageType.text)
          PopupMenuItem<String>(
            value: 'info',
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 20,
                  color: context.theme.greyColor,
                ),
                const SizedBox(width: 10),
                const Text('Info'),
              ],
            ),
          ),
      ],
    ).then((value) {
      if (context.mounted) {
        _handleMenuSelection(context, value, ref);
      }
    });
  }

  void _handleMenuSelection(
    BuildContext context,
    String? value,
    WidgetRef ref,
  ) async {
    if (value == null) return;

    switch (value) {
      case 'copy':
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
        break;

      case 'delete':
        if (isSender) {
          _showDeleteConfirmation(context, ref);
        }
        break;

      case 'forward':
        _handleForwardMessage(context);
        break;

      case 'info':
        _showMessageInfo(context);
        break;
    }
  }

  void _showDeleteConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: const Text('Delete Message'),
            content: const Text(
              'Are you sure you want to delete this message?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('CANCEL'),
              ),
              TextButton(
                onPressed: () async {
                  // Close the confirmation dialog
                  Navigator.pop(dialogContext);

                  // Store the BuildContext for the loading dialog
                  BuildContext? loadingDialogContext;

                  // Show loading indicator
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (ctx) {
                      loadingDialogContext = ctx;
                      return const Center(child: CircularProgressIndicator());
                    },
                  );

                  try {
                    // Call the delete message method from your controller
                    await ref
                        .read(chatControllerProvider)
                        .deleteMessage(
                          messageId: message.messageId,
                          context: context,
                        );

                    // Close loading indicator if it's still showing
                    if (loadingDialogContext != null && context.mounted) {
                      Navigator.of(loadingDialogContext!).pop();
                      loadingDialogContext = null;
                    }

                    // Show success message
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Message deleted')),
                      );
                    }
                  } catch (e) {
                    developer.log('Error deleting message: $e');

                    // Close loading indicator if it's still showing
                    if (loadingDialogContext != null && context.mounted) {
                      Navigator.of(loadingDialogContext!).pop();
                      loadingDialogContext = null;
                    }

                    // Show error message
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to delete message: $e')),
                      );
                    }
                  }
                },
                child: const Text(
                  'DELETE',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );
  }

  void _handleForwardMessage(BuildContext context) {
    // Navigate to contact selection page for forwarding
    // You'll need to implement this navigation and selection logic
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Forward feature coming soon')),
    );
  }

  void _showMessageInfo(BuildContext context) {
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Check if this message is currently uploading
    final uploadingImages = ref.watch(uploadingImagesProvider);
    final isUploading = uploadingImages.containsKey(message.messageId);

    return GestureDetector(
      onLongPress: () {
        final RenderBox renderBox = context.findRenderObject() as RenderBox;
        final position = renderBox.localToGlobal(Offset.zero);
        _showContextMenu(context, position, ref);
      },
      child: Container(
        alignment: isSender ? Alignment.centerRight : Alignment.centerLeft,
        margin: EdgeInsets.only(
          top: 4,
          bottom: 4,
          left:
              isSender
                  ? 80
                  : haveNip
                  ? 10
                  : 15,
          right: isSender ? (haveNip ? 10 : 15) : 80,
        ),
        child: ClipPath(
          clipper:
              haveNip
                  ? UpperNipMessageClipperTwo(
                    isSender ? MessageType.send : MessageType.receive,
                    nipWidth: 8,
                    nipHeight: 10,
                    bubbleRadius: haveNip ? 12 : 0,
                  )
                  : null,
          child: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  color:
                      isSender
                          ? context.theme.senderChatCardBg
                          : context.theme.receiverChatCardBg,
                  borderRadius: haveNip ? null : BorderRadius.circular(12),
                  boxShadow: const [BoxShadow(color: Colors.black38)],
                ),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 5),
                  child:
                      message.type == my_type.MessageType.image
                          ? GestureDetector(
                            onTap:
                                isUploading
                                    ? null
                                    : () => _openImageViewer(context, ref),
                            child: Padding(
                              padding: const EdgeInsets.only(
                                right: 3,
                                top: 3,
                                left: 3,
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    // Image
                                    Hero(
                                      tag: 'image_${message.messageId}',
                                      child: CachedNetworkImage(
                                        imageUrl: message.textMessage,
                                        placeholder:
                                            (context, url) => Container(
                                              width: 200,
                                              height: 200,
                                              color: Colors.grey[800],
                                              child: const Center(
                                                child: CircularProgressIndicator(
                                                  valueColor:
                                                      AlwaysStoppedAnimation<
                                                        Color
                                                      >(Colors.white),
                                                ),
                                              ),
                                            ),
                                        errorWidget:
                                            (context, url, error) => Container(
                                              width: 200,
                                              height: 200,
                                              color: Colors.grey[800],
                                              child: const Icon(
                                                Icons.error,
                                                color: Colors.white,
                                              ),
                                            ),
                                      ),
                                    ),

                                    // Loading overlay
                                    if (isUploading)
                                      Container(
                                        width: 200,
                                        height: 200,
                                        color: Colors.black.withValues(
                                          alpha: 0.5,
                                        ),
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            const CircularProgressIndicator(
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                    Colors.white,
                                                  ),
                                            ),
                                            const SizedBox(height: 10),
                                            const Text(
                                              'Uploading...',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          )
                          : Column(
                            // Existing text message code...
                          ),
                ),
              ),
              if (message.type == my_type.MessageType.image && !isUploading)
                Positioned(
                  bottom: 4,
                  right: 4,
                  child: Container(
                    padding: const EdgeInsets.only(
                      left: 90,
                      right: 10,
                      bottom: 10,
                      top: 14,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: const Alignment(0, -1),
                        end: const Alignment(1, 1),
                        colors: [
                          context.theme.greyColor!.withValues(alpha: 0),
                          context.theme.greyColor!.withValues(alpha: 0.5),
                        ],
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(300),
                        bottomRight: Radius.circular(100),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          DateFormat.Hm().format(message.timeSent),
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.white,
                          ),
                        ),
                        if (isSender) const SizedBox(width: 3),
                        if (isSender)
                          _buildReadStatusIndicator(
                            context,
                            isImageMessage: true,
                          ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _openImageViewer(BuildContext context, WidgetRef ref) {
    final imageMessages = ref.read(chatImagesProvider(message.receiverId));
    final index = imageMessages.indexWhere(
      (msg) => msg.messageId == message.messageId,
    );

    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (context) => ImageViewerPage(
              imageUrl: message.textMessage,
              allImages: imageMessages.map((m) => m.textMessage).toList(),
              initialIndex: index >= 0 ? index : 0,
            ),
      ),
    );
  }

  Widget _buildReadStatusIndicator(
    BuildContext context, {
    bool isImageMessage = false,
  }) {
    final Color baseColor =
        isImageMessage ? Colors.white : context.theme.greyColor!;
    final Color seenColor = Colors.blue;

    return Icon(
      message.isSeen ? Icons.done_all : Icons.done,
      size: 14,
      color: message.isSeen ? seenColor : baseColor,
    );
  }
}
