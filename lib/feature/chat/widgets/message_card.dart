import 'dart:math';
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
import 'package:message_app/feature/chat/widgets/message_time_send.dart';
import 'package:dio/dio.dart';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';
import 'package:message_app/feature/home/pages/video_player_screen.dart';
import 'package:path_provider/path_provider.dart';

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
                  Navigator.pop(dialogContext);

                  BuildContext? loadingDialogContext;

                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (ctx) {
                      loadingDialogContext = ctx;
                      return const Center(child: CircularProgressIndicator());
                    },
                  );

                  try {
                    await ref
                        .read(chatControllerProvider)
                        .deleteMessage(
                          messageId: message.messageId,
                          context: context,
                        );

                    if (loadingDialogContext != null && context.mounted) {
                      Navigator.of(loadingDialogContext!).pop();
                      loadingDialogContext = null;
                    }

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Message deleted')),
                      );
                    }
                  } catch (e) {
                    developer.log('Error deleting message: $e');

                    if (loadingDialogContext != null && context.mounted) {
                      Navigator.of(loadingDialogContext!).pop();
                      loadingDialogContext = null;
                    }

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

  String _getFileExtension(String fileName) {
    try {
      return ".${fileName.split('.').last}";
    } catch (e) {
      return '';
    }
  }

  String _getFileNameWithoutExtension(String fileName) {
    try {
      return fileName.split('.').first;
    } catch (e) {
      return fileName;
    }
  }

  String _formatFileSize(double bytes) {
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB", "TB", "PB", "EB", "ZB", "YB"];
    var i = (log(bytes) / log(1024)).floor();
    return '${(bytes / pow(1024, i)).toStringAsFixed(2)} ${suffixes[i]}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                                    Hero(
                                      tag: 'image_${message.messageId}',
                                      child: CachedNetworkImage(
                                        imageUrl:
                                            message.fileUrl ??
                                            message.textMessage,
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
                          : message.type == my_type.MessageType.file
                          ? _buildFileMessage(context)
                          : Column(
                            crossAxisAlignment:
                                isSender
                                    ? CrossAxisAlignment.end
                                    : CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Padding(
                                padding: EdgeInsets.only(
                                  top: 8,
                                  left: isSender ? 10 : 15,
                                  right: isSender ? 15 : 10,
                                ),
                                child: Text(
                                  message.textMessage,
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.only(
                                  bottom: 5,
                                  left: isSender ? 10 : 15,
                                  right: isSender ? 15 : 10,
                                  top: 4,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    MessageTimeSend(message: message),
                                    if (isSender) const SizedBox(width: 3),
                                    if (isSender)
                                      _buildReadStatusIndicator(context),
                                  ],
                                ),
                              ),
                            ],
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
                        MessageTimeSend(message: message),
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
              if (message.type == my_type.MessageType.video)
                InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (_) =>
                                VideoPlayerScreen(videoUrl: message.fileUrl!),
                      ),
                    );
                  },
                  child: Container(
                    height: 250,
                    width: 250,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // You might want to add a thumbnail here if available
                        // For now, just showing a play button
                        const Icon(
                          Icons.play_circle_fill,
                          color: Colors.white,
                          size: 60,
                        ),
                        Positioned(
                          bottom: 10,
                          right: 10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.videocam,
                                  color: Colors.white,
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Video',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    MessageTimeSend(message: message),
                                    if (isSender) const SizedBox(width: 3),
                                    if (isSender)
                                      _buildReadStatusIndicator(
                                        context,
                                        isImageMessage: true,
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
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
              imageUrl: message.fileUrl ?? message.textMessage,
              allImages:
                  imageMessages.map((m) => m.fileUrl ?? m.textMessage).toList(),
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

  Widget _buildFileMessage(BuildContext context) {
    final fileName = message.textMessage;
    final fileExtension = _getFileExtension(fileName);
    final fileNameWithoutExtension = _getFileNameWithoutExtension(fileName);
    final fileSizeInBytes = message.fileSize ?? 0;
    final formattedFileSize = _formatFileSize(fileSizeInBytes.toDouble());

    final fileUrl = message.fileUrl;

    return Container(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.insert_drive_file,
                size: 32,
                color: context.theme.greyColor,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fileNameWithoutExtension,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      fileExtension,
                      style: TextStyle(
                        fontSize: 12,
                        color: context.theme.greyColor,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.download),
                onPressed:
                    fileUrl != null
                        ? () => _saveFile(context, fileUrl, fileName)
                        : null,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                formattedFileSize,
                style: TextStyle(fontSize: 10, color: context.theme.greyColor),
              ),
              Padding(
                padding: const EdgeInsets.only(
                  bottom: 5,
                  left: 10,
                  right: 0,
                  top: 4,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    MessageTimeSend(message: message),
                    if (isSender) const SizedBox(width: 3),
                    if (isSender) _buildReadStatusIndicator(context),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _saveFile(
    BuildContext context,
    String fileUrl,
    String fileName,
  ) async {
    String message;
    try {
      final dio = Dio();
      final dir = await getTemporaryDirectory();
      final filePath = '${dir.path}/$fileName';

      // Download the file
      await dio.download(fileUrl, filePath);

      final params = SaveFileDialogParams(sourceFilePath: filePath);
      final finalPath = await FlutterFileDialog.saveFile(params: params);

      if (finalPath != null) {
        message = 'File saved to disk';
      } else {
        message = 'Download cancelled';
      }
    } catch (e) {
      developer.log('Error saving file: $e');
      message = e.toString();
    }

    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  // Widget _buildMessageContent(BuildContext context) {
  //   switch (message.type) {
  //     case MessageType.text:
  //       return DisplayTextCard(message: message, isSender: isSender);
  //     case MessageType.image:
  //       return DisplayImageCard(message: message, isSender: isSender);
  //     case MessageType.video:
  //       return VideoThumbnail(
  //         videoUrl: message.fileUrl!,
  //         thumbnailUrl: message.thumbnailUrl,
  //         isSender: isSender,
  //       );
  //     case MessageType.file:
  //       return DisplayFileCard(message: message, isSender: isSender);
  //     default:
  //       return DisplayTextCard(message: message, isSender: isSender);
  //   }
  // }
}
