import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';
import 'package:message_app/common/models/group_chat_model.dart';
import 'package:message_app/common/models/group_message_model.dart';
import 'package:message_app/common/widgets/custom_icon_button.dart';
import 'package:message_app/common/utils/show_date_card.dart';
import 'package:message_app/feature/group_chat/controllers/group_chat_controller.dart';
import 'package:message_app/feature/group_chat/pages/group_profile_page.dart';
import 'package:message_app/feature/group_chat/repositories/group_chat_repository.dart';
import 'package:message_app/feature/group_chat/widgets/group_chat_text_field.dart';
import 'package:message_app/feature/group_chat/widgets/group_message_card.dart';

class GroupChatPage extends ConsumerWidget {
  const GroupChatPage({super.key, required this.group});

  final GroupChatModel group;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage:
                  group.groupIconUrl != null && group.groupIconUrl!.isNotEmpty
                      ? NetworkImage(group.groupIconUrl!)
                      : null,
              child:
                  group.groupIconUrl == null || group.groupIconUrl!.isEmpty
                      ? const Icon(Icons.group)
                      : null,
            ),
            const SizedBox(width: 10),
            Text(group.groupName),
          ],
        ),
        actions: [
          CustomIconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => GroupProfilePage(group: group),
                ),
              );
            },
            icon: Icons.info,
            iconColor: Colors.white,
          ),
        ],
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 60),
            child: StreamBuilder<List<GroupMessageModel>>(
              stream: ref
                  .read(groupChatControllerProvider)
                  .getGroupMessages(group.groupId),
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.active) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text("no_messages_yet".tr));
                }

                final messages = snapshot.data!;

                return ListView.builder(
                  itemCount: messages.length,
                  controller: ScrollController(),
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isSender =
                        message.senderId ==
                        FirebaseAuth.instance.currentUser?.uid;
                    final isModerator = group.moderatorIds[0] == FirebaseAuth.instance.currentUser?.uid;

                    final haveNip =
                        index == 0 ||
                        (message.senderId != messages[index - 1].senderId);

                    final isShowDateCard =
                        index == 0 ||
                        (message.timeSent.day !=
                            messages[index - 1].timeSent.day);

                    return FutureBuilder<String>(
                      future: ref
                          .read(groupChatRepositoryProvider)
                          .getUserNameById(message.senderId),
                      builder: (context, userSnapshot) {
                        final senderName = userSnapshot.data ?? 'unknown'.tr;

                        return Column(
                          children: [
                            if (isShowDateCard)
                              ShowDateCard(date: message.timeSent),
                            GroupMessageCard(
                              isSender: isSender,
                              haveNip: haveNip,
                              message: message,
                              senderName: senderName,
                              isModerator: isModerator,
                            ),
                          ],
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
          Container(
            alignment: const Alignment(0, 1),
            child: GroupChatTextField(
              groupId: group.groupId,
              scrollController: ScrollController(),
            ),
          ),
        ],
      ),
    );
  }
}
