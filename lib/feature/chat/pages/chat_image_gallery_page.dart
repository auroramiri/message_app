import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:message_app/common/models/message_model.dart';
import 'package:message_app/feature/chat/pages/image_viewer_page.dart';

class ChatImageGalleryPage extends ConsumerWidget {
  final List<MessageModel> imageMessages;
  final String chatName;

  const ChatImageGalleryPage({
    super.key,
    required this.imageMessages,
    required this.chatName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          '$chatName - Images (${imageMessages.length})',
          style: const TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body:
          imageMessages.isEmpty
              ? const Center(
                child: Text(
                  'No images in this chat',
                  style: TextStyle(color: Colors.white),
                ),
              )
              : GridView.builder(
                padding: const EdgeInsets.all(2),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 2,
                  mainAxisSpacing: 2,
                ),
                itemCount: imageMessages.length,
                itemBuilder: (context, index) {
                  final message = imageMessages[index];
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => ImageViewerPage(
                                imageUrl: message.textMessage,
                                // Pass the list of images and current index for navigation
                                allImages:
                                    imageMessages
                                        .map((m) => m.textMessage)
                                        .toList(),
                                initialIndex: index,
                              ),
                        ),
                      );
                    },
                    child: Hero(
                      tag: 'gallery_image_${message.messageId}',
                      child: CachedNetworkImage(
                        imageUrl: message.textMessage,
                        fit: BoxFit.cover,
                        placeholder:
                            (context, url) => Container(
                              color: Colors.grey[900],
                              child: const Center(
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              ),
                            ),
                        errorWidget:
                            (context, url, error) => Container(
                              color: Colors.grey[900],
                              child: const Icon(
                                Icons.error,
                                color: Colors.white,
                              ),
                            ),
                      ),
                    ),
                  );
                },
              ),
    );
  }
}
