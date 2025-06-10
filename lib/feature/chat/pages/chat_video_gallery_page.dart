import 'dart:developer';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';
import 'package:message_app/common/models/message_model.dart';
import 'package:message_app/feature/chat/pages/video_player_screen.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

class ChatVideoGalleryPage extends StatefulWidget {
  final List<MessageModel> videoMessages;
  final String chatName;

  const ChatVideoGalleryPage({
    super.key,
    required this.videoMessages,
    required this.chatName,
  });

  @override
  State<ChatVideoGalleryPage> createState() => _ChatVideoGalleryPageState();
}

class _ChatVideoGalleryPageState extends State<ChatVideoGalleryPage> {
  final Map<String, String?> _thumbnails = {};

  @override
  void initState() {
    super.initState();
    _generateThumbnails();
  }

  Future<void> _generateThumbnails() async {
    for (var message in widget.videoMessages) {
      if (message.fileUrl != null) {
        try {
          final thumbnailPath = await _generateThumbnail(message.fileUrl!);
          if (mounted) {
            setState(() {
              _thumbnails[message.fileUrl!] = thumbnailPath;
            });
          }
        } catch (e) {
          log('Error generating thumbnail: $e');
        }
      }
    }
  }

  Future<String?> _generateThumbnail(String videoUrl) async {
    final directory = await getTemporaryDirectory();
    final thumbnailPath =
        '${directory.path}/${DateTime.now().millisecondsSinceEpoch}.jpg';
    await VideoThumbnail.thumbnailFile(
      video: videoUrl,
      thumbnailPath: thumbnailPath,
      imageFormat: ImageFormat.JPEG,
      maxHeight: 200,
      quality: 75,
    );
    return thumbnailPath;
  }

  Widget _buildVideoThumbnail(String videoUrl, String? thumbnailPath) {
    return Stack(
      alignment: Alignment.center,
      children: [
        if (thumbnailPath != null)
          Image.file(
            File(thumbnailPath),
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          )
        else
          Container(
            color: Colors.grey[900],
            width: double.infinity,
            height: double.infinity,
          ),
        Container(
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.3),
            shape: BoxShape.circle,
          ),
          padding: const EdgeInsets.all(8),
          child: const Icon(Icons.play_arrow, color: Colors.white, size: 30),
        ),
        if (thumbnailPath == null)
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${widget.chatName}${'s_video'.tr}')),
      body:
          widget.videoMessages.isEmpty
              ? Center(
                child: Text(
                  'no_videos_in_chat'.tr,
                  style: TextStyle(fontSize: 16),
                ),
              )
              : GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 2,
                  mainAxisSpacing: 2,
                ),
                itemCount: widget.videoMessages.length,
                itemBuilder: (context, index) {
                  final message = widget.videoMessages[index];
                  final videoUrl = message.fileUrl;
                  final thumbnailPath =
                      videoUrl != null ? _thumbnails[videoUrl] : null;

                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) =>
                                  VideoPlayerScreen(videoUrl: videoUrl),
                        ),
                      );
                    },
                    child: Container(
                      color: Colors.black,
                      child: _buildVideoThumbnail(videoUrl!, thumbnailPath),
                    ),
                  );
                },
              ),
    );
  }
}
