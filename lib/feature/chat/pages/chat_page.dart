import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:custom_clippers/custom_clippers.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:message_app/common/enum/message_type.dart' as my_type;
import 'package:message_app/common/helper/last_seen_message.dart';
import 'package:message_app/common/models/message_model.dart';
import 'package:message_app/feature/auth/pages/image_picker_page.dart';
import 'package:message_app/feature/chat/pages/chat_image_gallery_page.dart';
import 'package:shimmer/shimmer.dart';
import 'package:message_app/common/extension/custom_theme_extension.dart';
import 'package:message_app/common/models/user_model.dart';
import 'package:message_app/common/routes/routes.dart';
import 'package:message_app/common/widgets/custom_icon_button.dart';
import 'package:message_app/feature/auth/controller/auth_controller.dart';
import 'package:message_app/feature/chat/controller/chat_controller.dart';
import 'package:message_app/feature/chat/widgets/chat_text_field.dart';
import 'package:message_app/feature/chat/widgets/message_card.dart';
import 'package:message_app/feature/chat/widgets/show_date_card.dart';
import 'package:message_app/feature/chat/widgets/yellow_card.dart';

final pageStorageBucket = PageStorageBucket();
final ScrollController _scrollController = ScrollController();

final chatBackgroundProvider = FutureProvider.family<String?, String>((
  ref,
  receiverId,
) {
  return ref.watch(chatControllerProvider).getChatBackgroundImage(receiverId);
});

final uploadingImagesProvider = StateProvider<Map<String, File>>((ref) => {});

final chatImagesProvider = StateProvider.family<List<MessageModel>, String>(
  (ref, chatId) => [],
);

final tempBackgroundImageProvider = StateProvider<Uint8List?>((ref) => null);

class ChatPage extends ConsumerWidget {
  ChatPage({super.key, required this.user});

  final UserModel user;
  final ScrollController scrollController = ScrollController();

  final AssetImage defaultBackgroudImage = AssetImage(
    'assets/images/doodle_bg.png',
  );

  // Method to show confirmation dialog for deleting chat
  Future<void> _showDeleteChatConfirmation(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Clear Chat History'),
            content: const Text(
              'Are you sure you want to delete all messages in this chat? '
              'This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('CANCEL'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'DELETE',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );
    if (context.mounted) {
      if (result == true) {
        // Show loading indicator
        showDialog(
          context: context,
          barrierDismissible: false,
          builder:
              (context) => const Center(child: CircularProgressIndicator()),
        );

        try {
          // Delete the chat
          await ref
              .read(chatControllerProvider)
              .deleteChat(receiverId: user.uid, context: context);

          // Close loading indicator
          if (context.mounted) Navigator.pop(context);

          // Show success message
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Chat history cleared successfully'),
                duration: Duration(seconds: 2),
              ),
            );
          }
        } catch (e) {
          // Close loading indicator
          if (context.mounted) Navigator.pop(context);

          // Show error message
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to clear chat history: ${e.toString()}'),
                duration: const Duration(seconds: 3),
              ),
            );
          }
        }
      }
    }
  }

  void _scrollToBottom({bool animate = true}) {
    if (_scrollController.hasClients) {
      if (animate) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      } else {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(chatControllerProvider).markAllMessagesAsSeen(user.uid);
    });
    ref.listen(chatControllerProvider, (previous, next) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    });

    final chatBackgroundAsync = ref.watch(chatBackgroundProvider(user.uid));

    return Scaffold(
      backgroundColor: context.theme.chatPageBgColor,
      appBar: AppBar(
        leading: InkWell(
          onTap: () {
            Navigator.pop(context);
          },
          borderRadius: BorderRadius.circular(20),
          child: Row(
            children: [
              const Icon(Icons.arrow_back),
              Hero(
                tag: 'profile',
                child: Container(
                  width: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    image: DecorationImage(
                      image: CachedNetworkImageProvider(user.profileImageUrl),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        title: InkWell(
          onTap: () {
            Navigator.pushNamed(context, Routes.profile, arguments: user);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.username,
                  style: const TextStyle(fontSize: 18, color: Colors.white),
                ),
                const SizedBox(height: 3),
                StreamBuilder(
                  stream: ref
                      .read(authControllerProvider)
                      .getUserPrecenceStatus(uid: user.uid),
                  builder: (_, snapshot) {
                    if (snapshot.connectionState != ConnectionState.active) {
                      return const SizedBox();
                    }

                    final singleUserModel = snapshot.data!;
                    final lastMessage = lastSeenMessage(
                      singleUserModel.lastSeen,
                    );

                    return Text(
                      singleUserModel.active
                          ? 'online'
                          : "last seen $lastMessage ago",
                      style: const TextStyle(fontSize: 12, color: Colors.white),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          CustomIconButton(
            onPressed: () {},
            icon: Icons.video_call,
            iconColor: Colors.white,
          ),
          CustomIconButton(
            onPressed: () {},
            icon: Icons.call,
            iconColor: Colors.white,
          ),
          CustomIconButton(
            icon: Icons.photo_library,
            iconColor: Colors.white,
            onPressed: () {
              final imageMessages = ref.read(chatImagesProvider(user.uid));
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => ChatImageGalleryPage(
                        imageMessages: imageMessages,
                        chatName: user.username,
                      ),
                ),
              );
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (String value) async {
              if (value == 'set_background') {
                try {
                  final tempBackgroundImage = await Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => ImagePickerPage()),
                  );

                  if (tempBackgroundImage == null) {
                    return;
                  }

                  if (context.mounted) {
                    await ref
                        .read(chatControllerProvider)
                        .setChatBackgroundImage(
                          imageFile: tempBackgroundImage,
                          receiverId: user.uid,
                          context: context,
                        );
                    ref.refresh(chatBackgroundProvider(user.uid));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Chat background updated'),
                        ),
                      );
                    }
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error setting background: $e')),
                    );
                  }
                }
              } else if (value == 'clear_chat') {
                if (context.mounted) {
                  _showDeleteChatConfirmation(context, ref);
                }
              }
            },
            itemBuilder:
                (context) => [
                  const PopupMenuItem<String>(
                    value: 'set_background',
                    child: Text('Set Background Image'),
                  ),
                  const PopupMenuItem<String>(
                    value: 'clear_chat',
                    child: Text('Clear Chat History'),
                  ),
                ],
          ),
        ],
      ),
      body: Stack(
        children: [
          // chat background image
          chatBackgroundAsync.when(
            data: (backgroundImageUrl) {
              // If there's a custom background image, use it
              if (backgroundImageUrl != null && backgroundImageUrl.isNotEmpty) {
                return CachedNetworkImage(
                  imageUrl: backgroundImageUrl,
                  height: double.maxFinite,
                  width: double.maxFinite,
                  fit: BoxFit.cover,
                  placeholder:
                      (context, url) => Image(
                        height: double.maxFinite,
                        width: double.maxFinite,
                        image: defaultBackgroudImage,
                        fit: BoxFit.cover,
                        color: context.theme.chatPageDoodleColor,
                      ),
                  errorWidget:
                      (context, url, error) => Image(
                        height: double.maxFinite,
                        width: double.maxFinite,
                        image: defaultBackgroudImage,
                        fit: BoxFit.cover,
                        color: context.theme.chatPageDoodleColor,
                      ),
                );
              } else {
                // Use default background if no custom background is set
                return Image(
                  height: double.maxFinite,
                  width: double.maxFinite,
                  image: defaultBackgroudImage,
                  fit: BoxFit.cover,
                  color: context.theme.chatPageDoodleColor,
                );
              }
            },
            loading:
                () => Image(
                  height: double.maxFinite,
                  width: double.maxFinite,
                  image: defaultBackgroudImage,
                  fit: BoxFit.cover,
                  color: context.theme.chatPageDoodleColor,
                ),
            error:
                (_, __) => Image(
                  height: double.maxFinite,
                  width: double.maxFinite,
                  image: defaultBackgroudImage,
                  fit: BoxFit.cover,
                  color: context.theme.chatPageDoodleColor,
                ),
          ),
          // Stream of Chat
          Padding(
            padding: const EdgeInsets.only(bottom: 60),
            child: StreamBuilder(
              stream: ref
                  .watch(chatControllerProvider)
                  .getAllOneToOneMessage(user.uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.active) {
                  return ListView.builder(
                    itemCount: 15,
                    itemBuilder: (_, index) {
                      final random = Random().nextInt(14);
                      return Container(
                        alignment:
                            random.isEven
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                        margin: EdgeInsets.only(
                          top: 5,
                          bottom: 5,
                          left: random.isEven ? 150 : 15,
                          right: random.isEven ? 15 : 150,
                        ),
                        child: ClipPath(
                          clipper: UpperNipMessageClipperTwo(
                            random.isEven
                                ? MessageType.send
                                : MessageType.receive,
                            nipWidth: 8,
                            nipHeight: 10,
                            bubbleRadius: 12,
                          ),
                          child: Shimmer.fromColors(
                            baseColor:
                                random.isEven
                                    ? context.theme.greyColor!.withValues(
                                      alpha: 0.3,
                                    )
                                    : context.theme.greyColor!.withValues(
                                      alpha: 0.2,
                                    ),
                            highlightColor:
                                random.isEven
                                    ? context.theme.greyColor!.withValues(
                                      alpha: 0.4,
                                    )
                                    : context.theme.greyColor!.withValues(
                                      alpha: 0.3,
                                    ),
                            child: Container(
                              height: 40,
                              width:
                                  170 + double.parse((random * 2).toString()),
                              color: Colors.red,
                            ),
                          ),
                        ),
                      );
                    },
                  );
                }

                if (snapshot.hasData) {
                  final messages = snapshot.data!;
                  final imageMessages =
                      messages
                          .where((msg) => msg.type == my_type.MessageType.image)
                          .toList();

                  // Update the provider with image messages
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    ref.read(chatImagesProvider(user.uid).notifier).state =
                        imageMessages;
                  });
                }

                return PageStorage(
                  bucket: pageStorageBucket,
                  child: ListView.builder(
                    key: const PageStorageKey('chat_page_list'),
                    itemCount: snapshot.data!.length,
                    shrinkWrap: true,
                    controller: scrollController,
                    itemBuilder: (_, index) {
                      final message = snapshot.data![index];
                      final isSender =
                          message.senderId ==
                          FirebaseAuth.instance.currentUser!.uid;

                      final haveNip =
                          (index == 0) ||
                          (index == snapshot.data!.length - 1 &&
                              message.senderId !=
                                  snapshot.data![index - 1].senderId) ||
                          (message.senderId !=
                                  snapshot.data![index - 1].senderId &&
                              message.senderId ==
                                  snapshot.data![index + 1].senderId) ||
                          (message.senderId !=
                                  snapshot.data![index - 1].senderId &&
                              message.senderId !=
                                  snapshot.data![index + 1].senderId);
                      final isShowDateCard =
                          (index == 0) ||
                          ((index == snapshot.data!.length - 1) &&
                              (message.timeSent.day >
                                  snapshot.data![index - 1].timeSent.day)) ||
                          (message.timeSent.day >
                                  snapshot.data![index - 1].timeSent.day &&
                              message.timeSent.day <=
                                  snapshot.data![index + 1].timeSent.day);

                      return Column(
                        children: [
                          if (index == 0) const YellowCard(),
                          if (isShowDateCard)
                            ShowDateCard(date: message.timeSent),
                          MessageCard(
                            isSender: isSender,
                            haveNip: haveNip,
                            message: message,
                          ),
                        ],
                      );
                    },
                  ),
                );
              },
            ),
          ),
          Container(
            alignment: const Alignment(0, 1),
            child: ChatTextField(
              receiverId: user.uid,
              scrollController: scrollController,
            ),
          ),
        ],
      ),
    );
  }
}
