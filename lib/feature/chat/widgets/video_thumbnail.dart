import 'package:flutter/material.dart';
import 'package:message_app/feature/home/pages/video_player_screen.dart';
import 'package:message_app/feature/chat/widgets/video_thumbnail_widget.dart';

class VideoThumbnail extends StatelessWidget {
  final String videoUrl;
  final String? thumbnailUrl;
  final bool isSender;

  const VideoThumbnail({
    super.key,
    required this.videoUrl,
    this.thumbnailUrl,
    required this.isSender,
  });

  @override
  Widget build(BuildContext context) {
    return VideoThumbnailWidget(
      videoUrl: videoUrl,
      isSender: isSender,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => VideoPlayerScreen(videoUrl: videoUrl),
          ),
        );
      },
    );
  }
}
