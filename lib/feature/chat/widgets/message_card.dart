import 'package:cached_network_image/cached_network_image.dart';
import 'package:custom_clippers/custom_clippers.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:message_app/common/enum/message_type.dart' as my_type;
import 'package:message_app/common/extension/custom_theme_extension.dart';
import 'package:message_app/common/models/message_model.dart';

class MessageCard extends StatelessWidget {
  const MessageCard({
    super.key,
    required this.isSender,
    required this.haveNip,
    required this.message,
  });

  final bool isSender;
  final bool haveNip;
  final MessageModel message;

  void _showContextMenu(BuildContext context, Offset tapPosition) {
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final relativeRect = RelativeRect.fromLTRB(
      tapPosition.dx,
      tapPosition.dy,
      overlay.size.width - tapPosition.dx,
      overlay.size.height - tapPosition.dy,
    );

    showMenu(
      context: context,
      position: relativeRect,
      items: [
        PopupMenuItem(
          child: const Text('Copy'),
          onTap: () {
            // Handle copy action
          },
        ),
        PopupMenuItem(
          child: const Text('Delete'),
          onTap: () {
            // Handle delete action
          },
        ),
        PopupMenuItem(
          child: const Text('Forward'),
          onTap: () {
            // Handle forward action
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPressStart: (details) {
        _showContextMenu(context, details.globalPosition);
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
          right:
              isSender
                  ? haveNip
                      ? 10
                      : 15
                  : 80,
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
                          ? Padding(
                            padding: const EdgeInsets.only(
                              right: 3,
                              top: 3,
                              left: 3,
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image(
                                image: CachedNetworkImageProvider(
                                  message.textMessage,
                                ),
                              ),
                            ),
                          )
                          : Padding(
                            padding: EdgeInsets.only(
                              top: 8,
                              bottom: 8,
                              left: isSender ? 10 : 15,
                              right: isSender ? 15 : 10,
                            ),
                            child: Text(
                              "${message.textMessage}         ",
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                ),
              ),
              Positioned(
                bottom: message.type == my_type.MessageType.text ? 8 : 4,
                right:
                    message.type == my_type.MessageType.text
                        ? isSender
                            ? 15
                            : 10
                        : 4,
                child:
                    message.type == my_type.MessageType.text
                        ? Text(
                          DateFormat.Hm().format(message.timeSent),
                          style: TextStyle(
                            fontSize: 11,
                            color: context.theme.greyColor,
                          ),
                        )
                        : Container(
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
                          child: Text(
                            DateFormat.Hm().format(message.timeSent),
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.white,
                            ),
                          ),
                        ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
