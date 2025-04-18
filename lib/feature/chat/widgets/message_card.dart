import 'dart:io';
import 'package:custom_clippers/custom_clippers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:message_app/common/extension/custom_theme_extension.dart';
import 'package:message_app/common/utils/context_menu.dart';
import 'package:message_app/common/utils/file_utils.dart';
import 'package:message_app/feature/chat/pages/chat_page.dart';
import 'package:message_app/feature/chat/pages/video_player_screen.dart';
import 'package:message_app/common/models/message_model.dart';
import 'package:message_app/feature/chat/widgets/audio_message_player.dart';
import 'package:message_app/feature/chat/widgets/build_image_message.dart';
import 'package:message_app/feature/chat/widgets/message_time_send.dart';
import 'package:message_app/common/enum/message_type.dart' as my_type;

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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uploadingImages = ref.watch(uploadingImagesProvider);
    final isUploading = uploadingImages.containsKey(message.messageId);

    return GestureDetector(
      onLongPress: () {
        final renderBox = context.findRenderObject() as RenderBox;
        final position = renderBox.localToGlobal(Offset.zero);
        showContextMenu(context, position, ref, message, isSender);
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
              _buildMessageContent(context, isUploading, ref),
              if (message.type == my_type.MessageType.image && !isUploading)
                _buildImageOverlay(context),
              if (isUploading && message.type == my_type.MessageType.video)
                Positioned.fill(
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.5),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessageContent(
    BuildContext context,
    bool isUploading,
    WidgetRef ref,
  ) {
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
        child: _getMessageWidget(context, isUploading, ref),
      ),
    );
  }

  Widget _getMessageWidget(
    BuildContext context,
    bool isUploading,
    WidgetRef ref,
  ) {
    switch (message.type) {
      case my_type.MessageType.image:
        return buildImageMessage(context, isUploading, ref, message);
      case my_type.MessageType.file:
        return _buildFileMessage(context);
      case my_type.MessageType.video:
        return _buildVideoMessage(context, isUploading);
      case my_type.MessageType.audio:
        return _buildAudioMessage(context);
      default:
        return _buildTextMessage(context);
    }
  }

  Widget _buildAudioMessage(BuildContext context) {
    return Column(
      children: [
        AudioMessagePlayer(message: message),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            MessageTimeSend(message: message),
            if (isSender) const SizedBox(width: 3),
            if (isSender) _buildReadStatusIndicator(context),
          ],
        ),
      ],
    );
  }

  Widget _buildTextMessage(BuildContext context) {
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
              if (isSender) _buildReadStatusIndicator(context),
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
          children: [
            MessageTimeSend(message: message),
            if (isSender) const SizedBox(width: 3),
            if (isSender)
              _buildReadStatusIndicator(context, isImageMessage: true),
          ],
        ),
      ),
    );
  }

  Widget _buildReadStatusIndicator(
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

  Widget _buildFileMessage(BuildContext context) {
    final fileName = message.textMessage;
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

  Widget _buildVideoMessage(BuildContext context, bool isUploading) {
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

  String formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));

    return hours == '00' ? '$minutes:$seconds' : '$hours:$minutes:$seconds';
  }
}
