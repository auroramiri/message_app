import 'package:flutter/material.dart';
import 'package:message_app/common/models/user_model.dart';
import 'package:message_app/common/widgets/custom_icon_button.dart';

class ChatPage extends StatelessWidget {
  const ChatPage({super.key, required this.user});

  final UserModel user;

  @override
  Widget build(BuildContext context) {
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
            Text('last seen 2 min ago', style: TextStyle(fontSize: 12)),
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
