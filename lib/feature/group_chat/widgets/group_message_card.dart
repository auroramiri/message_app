import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:custom_clippers/custom_clippers.dart';
import 'package:message_app/common/models/group_message_model.dart';
import 'package:message_app/common/extension/custom_theme_extension.dart';
import 'package:message_app/common/models/message_model.dart';
import 'package:message_app/common/utils/context_menu.dart';
import 'package:message_app/common/utils/file_utils.dart';
import 'package:message_app/feature/chat/pages/video_player_screen.dart';
import 'package:message_app/feature/chat/widgets/audio_message_player.dart';
import 'package:message_app/feature/chat/widgets/build_image_message.dart';
import 'package:message_app/common/utils/message_time_send.dart';
import 'package:message_app/common/enum/message_type.dart' as my_type;

class GroupMessageCard extends ConsumerWidget {
  const GroupMessageCard({
    super.key,
    required this.isSender,
    required this.haveNip,
    required this.message,
    required this.senderName,
    required this.isModerator,
  });

  final bool isSender;
  final bool haveNip;
  final GroupMessageModel message;
  final String senderName;
  final bool isModerator;

  MessageModel convertToMessageModel(GroupMessageModel groupMessage) {
    return MessageModel(
      senderId: groupMessage.senderId,
      receiverId:
          groupMessage.groupId, // Assuming groupId can act as receiverId
      textMessage: groupMessage.message,
      type: groupMessage.type,
      timeSent: groupMessage.timeSent,
      messageId: groupMessage.messageId,
      isSeen: false, // Assuming a default value
      notificationSent: false, // Assuming a default value
      fileUrl: groupMessage.fileUrl,
      fileSize: groupMessage.fileSize,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onLongPress: () {
        final renderBox = context.findRenderObject() as RenderBox;
        final position = renderBox.localToGlobal(Offset.zero);
        showContextMenu(context, position, ref, message, isSender, isModerator);
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
        child: Column(
          crossAxisAlignment:
              isSender ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (!isSender)
              Padding(
                padding: const EdgeInsets.only(left: 15),
                child: Text(
                  senderName,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: context.theme.greyColor,
                  ),
                ),
              ),
            ClipPath(
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
                  _buildMessageContent(context, ref),
                  if (message.type == my_type.MessageType.image)
                    _buildImageOverlay(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageContent(BuildContext context, WidgetRef ref) {
    return Container(
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
        child: _getMessageWidget(context, ref),
      ),
    );
  }

  Widget _getMessageWidget(BuildContext context, WidgetRef ref) {
    switch (message.type) {
      case my_type.MessageType.image:
        return buildImageMessage(
          context,
          false,
          ref,
          convertToMessageModel(message),
        );
      case my_type.MessageType.file:
        return _buildFileMessage(context);
      case my_type.MessageType.video:
        return _buildVideoMessage(context);
      case my_type.MessageType.audio:
        return _buildAudioMessage(context);
      default:
        return _buildTextMessage(context, ref);
    }
  }

  Widget _buildAudioMessage(BuildContext context) {
    return Column(
      children: [
        AudioMessagePlayer(message: convertToMessageModel(message)),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [MessageTimeSend(message: convertToMessageModel(message))],
        ),
      ],
    );
  }

  Widget _buildTextMessage(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment:
          isSender ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: EdgeInsets.only(
            top: 8,
            left: isSender ? 10 : 15,
            right: isSender ? 15 : 10,
          ),
          child: Text(message.message, style: const TextStyle(fontSize: 16)),
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
              MessageTimeSend(message: convertToMessageModel(message)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildImageOverlay(BuildContext context) {
    return Positioned(
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
          children: [MessageTimeSend(message: convertToMessageModel(message))],
        ),
      ),
    );
  }

  Widget _buildFileMessage(BuildContext context) {
    final fileName = message.message;
    final fileExtension = getFileExtension(fileName);
    final fileNameWithoutExtension = getFileNameWithoutExtension(fileName);
    final fileSizeInBytes = message.fileSize ?? 0;
    final formattedFileSize = formatFileSize(fileSizeInBytes.toDouble());
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
                        ? () => saveFile(context, fileUrl, fileName)
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
                    MessageTimeSend(message: convertToMessageModel(message)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVideoMessage(BuildContext context) {
    return FutureBuilder<String?>(
      future: generateThumbnailFileFromUrl(message.fileUrl!),
      builder: (context, snapshot) {
        return Container(
          height: 250,
          width: 250,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (snapshot.connectionState == ConnectionState.waiting)
                const Center(child: CircularProgressIndicator())
              else if (snapshot.hasError ||
                  !snapshot.hasData ||
                  snapshot.data == null)
                const Center(child: Icon(Icons.error_outline))
              else
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
                      borderRadius: BorderRadius.circular(15),
                      image: DecorationImage(
                        image: FileImage(File(snapshot.data!)),
                        fit: BoxFit.cover,
                      ),
                    ),
                    child: const Icon(
                      Icons.play_circle_fill,
                      color: Colors.white,
                      size: 60,
                    ),
                  ),
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
                      const Icon(Icons.videocam, color: Colors.white, size: 16),
                      const SizedBox(width: 4),
                      const Text(
                        'Video',
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        formatFileSize(message.fileSize!.toDouble()),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String formatFileSize(double bytes) {
    const suffixes = ["B", "KB", "MB", "GB", "TB"];
    if (bytes == 0) return "0 B";
    int i = (log(bytes) / log(1024)).floor();
    return '${(bytes / pow(1024, i)).toStringAsFixed(2)} ${suffixes[i]}';
  }
}
