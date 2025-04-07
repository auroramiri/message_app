import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:message_app/common/extension/custom_theme_extension.dart';

class VideoThumbnailWidget extends StatefulWidget {
  final String videoUrl;
  final bool isSender;
  final VoidCallback onTap;

  const VideoThumbnailWidget({
    super.key,
    required this.videoUrl,
    required this.isSender,
    required this.onTap,
  });

  @override
  State<VideoThumbnailWidget> createState() => _VideoThumbnailWidgetState();
}

class _VideoThumbnailWidgetState extends State<VideoThumbnailWidget> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initializeController();
  }

  Future<void> _initializeController() async {
    try {
      debugPrint(
        'Initializing video controller for thumbnail: ${widget.videoUrl}',
      );
      _controller = VideoPlayerController.networkUrl(
        Uri.parse(widget.videoUrl),
      );

      await _controller!.initialize();

      // Seek to the first frame
      await _controller!.seekTo(Duration.zero);
      await _controller!.setVolume(0.0);

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('Error initializing video controller: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 250, maxHeight: 250),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Video thumbnail or placeholder
            ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child:
                  _isInitialized && _controller != null && !_hasError
                      ? SizedBox(
                        width: 250,
                        height: 200,
                        child: FittedBox(
                          fit: BoxFit.cover,
                          child: SizedBox(
                            width: _controller!.value.size.width,
                            height: _controller!.value.size.height,
                            child: VideoPlayer(_controller!),
                          ),
                        ),
                      )
                      : Container(
                        width: 250,
                        height: 200,
                        color:
                            widget.isSender
                                ? context.theme.senderChatCardBg
                                : context.theme.receiverChatCardBg,
                        child: const Icon(
                          Icons.video_file,
                          size: 70,
                          color: Colors.white54,
                        ),
                      ),
            ),

            // Play button overlay
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.play_arrow,
                color: Colors.white,
                size: 30,
              ),
            ),

            // Video indicator
            Positioned(
              bottom: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.videocam, color: Colors.white, size: 16),
                    SizedBox(width: 4),
                    Text(
                      'Video',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
