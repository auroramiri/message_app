import 'package:flutter/material.dart';
import 'package:message_app/common/models/message_model.dart';
import 'package:message_app/feature/home/pages/video_player_screen.dart';

class ChatVideoGalleryPage extends StatelessWidget {
  final List<MessageModel> videoMessages;
  final String chatName;

  const ChatVideoGalleryPage({
    super.key,
    required this.videoMessages,
    required this.chatName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('$chatName\'s Videos')),
      body:
          videoMessages.isEmpty
              ? Center(
                child: Text(
                  'No videos in this chat',
                  style: TextStyle(fontSize: 16),
                ),
              )
              : GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 2,
                  mainAxisSpacing: 2,
                ),
                itemCount: videoMessages.length,
                itemBuilder: (context, index) {
                  final message = videoMessages[index];
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) =>
                                  VideoPlayerScreen(videoUrl: message.fileUrl!),
                        ),
                      );
                    },
                    child: Container(
                      color: Colors.black,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Здесь можно добавить превью видео, если оно доступно
                          Icon(
                            Icons.play_circle_outline,
                            color: Colors.white,
                            size: 40,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
    );
  }
}
