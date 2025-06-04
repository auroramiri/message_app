import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:message_app/common/extension/custom_theme_extension.dart';
import 'package:message_app/common/models/group_chat_model.dart';
import 'package:message_app/common/models/last_message_model.dart';
import 'package:message_app/common/models/user_model.dart';
import 'package:message_app/common/routes/routes.dart';
import 'package:message_app/common/utils/coloors.dart';
import 'package:message_app/feature/chat/controller/chat_controller.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:message_app/feature/group_chat/controllers/group_chat_controller.dart';
import 'package:rxdart/rxdart.dart';

class ChatHomePage extends ConsumerWidget {
  const ChatHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lastMessagesStream =
        ref.watch(chatControllerProvider).getAllLastMessageList();
    final groupChatsStream =
        ref.watch(groupChatControllerProvider).getUserGroups();

    return Scaffold(
      body: StreamBuilder<List<dynamic>>(
        stream: CombineLatestStream.list([
          lastMessagesStream,
          groupChatsStream,
        ]),
        builder: (_, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Coloors.blueDark),
            );
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final lastMessages =
              snapshot.data?[0] as List<LastMessageModel>? ?? [];
          final groupChats = snapshot.data?[1] as List<GroupChatModel>? ?? [];

          final combinedList = [
            ...lastMessages.map(
              (lastMessage) => {
                'type': 'personal',
                'data': lastMessage,
                'time': lastMessage.timeSent,
              },
            ),
            ...groupChats.map(
              (groupChat) => {
                'type': 'group',
                'data': groupChat,
                'time': groupChat.lastMessageTime ?? DateTime.now(),
              },
            ),
          ]..sort(
            (a, b) => (b['time'] as DateTime).compareTo(a['time'] as DateTime),
          );

          return ListView.builder(
            itemCount: combinedList.length,
            itemBuilder: (context, index) {
              final item = combinedList[index];
              final type = item['type'];
              final data = item['data'];

              if (type == 'personal') {
                final lastMessageData = data as LastMessageModel;
                return ListTile(
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      Routes.chat,
                      arguments: UserModel(
                        username: lastMessageData.username,
                        uid: lastMessageData.contactId,
                        profileImageUrl: lastMessageData.profileImageUrl,
                        active: true,
                        lastSeen: 0,
                        phoneNumber: '0',
                        groupId: [],
                        isAdmin: false,
                        fcmToken: '',
                      ),
                    );
                  },
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(lastMessageData.username),
                      Text(
                        DateFormat.Hm().format(lastMessageData.timeSent),
                        style: TextStyle(
                          fontSize: 13,
                          color: context.theme.greyColor,
                        ),
                      ),
                    ],
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Text(
                      lastMessageData.lastMessage,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: context.theme.greyColor),
                    ),
                  ),
                  leading: CircleAvatar(
                    backgroundImage:
                        lastMessageData.profileImageUrl.isNotEmpty
                            ? CachedNetworkImageProvider(
                              lastMessageData.profileImageUrl,
                            )
                            : null,
                    radius: 24,
                    child:
                        lastMessageData.profileImageUrl.isEmpty
                            ? const Icon(Icons.person)
                            : null,
                  ),
                );
              } else {
                final groupChatData = data as GroupChatModel;
                return ListTile(
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      Routes.groupChat,
                      arguments: groupChatData,
                    );
                  },
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(groupChatData.groupName),
                      Text(
                        groupChatData.lastMessageTime != null
                            ? DateFormat.Hm().format(
                              groupChatData.lastMessageTime!,
                            )
                            : 'No time',
                        style: TextStyle(
                          fontSize: 13,
                          color: context.theme.greyColor,
                        ),
                      ),
                    ],
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Text(
                      groupChatData.lastMessage ?? 'No messages',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: context.theme.greyColor),
                    ),
                  ),
                  leading: CircleAvatar(
                    backgroundImage:
                        groupChatData.groupIconUrl!.isNotEmpty
                            ? CachedNetworkImageProvider(
                              groupChatData.groupIconUrl!,
                            )
                            : null,
                    radius: 24,
                    child:
                        groupChatData.groupIconUrl!.isEmpty
                            ? const Icon(Icons.group)
                            : null,
                  ),
                );
              }
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, Routes.contact);
        },
        child: const Icon(Icons.chat),
      ),
    );
  }
}
