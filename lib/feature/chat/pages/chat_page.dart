import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:message_app/common/models/user_model.dart';
import 'package:message_app/common/widgets/custom_icon_button.dart';
import 'package:message_app/feature/auth/controller/auth_controller.dart';

class ChatPage extends ConsumerWidget {
  const ChatPage({super.key, required this.user});

  final UserModel user;

  String lastSeenMessage(lastSeen) {
    DateTime now = DateTime.now();
    Duration differenceDuration = now.difference(
      DateTime.fromMillisecondsSinceEpoch(lastSeen),
    );

    String finalMessage =
        differenceDuration.inSeconds > 59
            ? differenceDuration.inMinutes > 59
                ? differenceDuration.inHours > 23
                    ? "${differenceDuration.inDays} ${differenceDuration.inDays == 1 ? 'day' : 'days'} "
                    : "${differenceDuration.inHours} ${differenceDuration.inHours == 1 ? 'hour' : 'hours'} "
                : "${differenceDuration.inMinutes} ${differenceDuration.inMinutes == 1 ? 'minute' : 'minutes'} "
            : 'few seconds ago';

    return finalMessage;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        leading: InkWell(
          onTap: () {
            Navigator.of(context).pop();
          },
          borderRadius: BorderRadius.circular(20),
          child: Row(
            children: [
              Icon(Icons.arrow_back),
              CircleAvatar(
                radius: 16,
                backgroundImage: NetworkImage(user.profileImageUrl),
              ),
            ],
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              user.username,
              style: TextStyle(fontSize: 18, color: Colors.white),
            ),
            SizedBox(height: 3),
            StreamBuilder(
              stream: ref
                  .read(authControllerProvider)
                  .getUserPrecenceStatus(uid: user.uid),
              builder: (_, snapshot) {
                if (snapshot.connectionState != ConnectionState.active) {
                  return Text(
                    'connecting...',
                    style: TextStyle(fontSize: 12, color: Colors.white),
                  );
                }
                final singleUserModel = snapshot.data!;

                final lastMessage = lastSeenMessage(singleUserModel.lastSeen);

                return Text(
                  singleUserModel.active ? "Online" : "$lastMessage ago",
                  style: TextStyle(fontSize: 12, color: Colors.white),
                );
              },
            ),
          ],
        ),
        actions: [
          CustomIconButton(
            onTap: () {},
            icon: Icons.call,
            iconColor: Colors.white,
          ),
          CustomIconButton(
            onTap: () {},
            icon: Icons.video_call,
            iconColor: Colors.white,
          ),
          CustomIconButton(
            onTap: () {},
            icon: Icons.more_vert,
            iconColor: Colors.white,
          ),
        ],
      ),
    );
  }
}
