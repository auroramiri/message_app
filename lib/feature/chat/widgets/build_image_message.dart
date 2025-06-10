import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';
import 'package:message_app/common/models/message_model.dart';
import 'package:message_app/feature/chat/pages/chat_page.dart';
import 'package:message_app/feature/chat/pages/image_viewer_page.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Widget buildImageMessage(
  BuildContext context,
  bool isUploading,
  WidgetRef ref,
  MessageModel message,
) {
  return GestureDetector(
    onTap: isUploading ? null : () => openImageViewer(context, ref, message),
    child: Padding(
      padding: const EdgeInsets.only(right: 3, top: 3, left: 3),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Hero(
              tag: 'image_${message.messageId}',
              child: CachedNetworkImage(
                imageUrl: message.fileUrl ?? message.textMessage,
                placeholder:
                    (context, url) => Container(
                      width: 200,
                      height: 200,
                      color: Colors.grey[800],
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
                      width: 200,
                      height: 200,
                      color: Colors.grey[800],
                      child: const Icon(Icons.error, color: Colors.white),
                    ),
              ),
            ),
            if (isUploading)
              Container(
                width: 200,
                height: 200,
                color: Colors.black.withValues(alpha: 0.5),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'uploading'.tr,
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
  );
}

void openImageViewer(
  BuildContext context,
  WidgetRef ref,
  MessageModel message,
) {
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
