import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:message_app/common/extension/custom_theme_extension.dart';
import 'package:message_app/common/models/user_model.dart';
import 'package:message_app/common/utils/coloors.dart';

class ContactCard extends StatelessWidget {
  const ContactCard({
    super.key,
    required this.contactSource,
    required this.onTap,
  });

  final UserModel contactSource;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: EdgeInsets.only(left: 20, right: 10),
      leading: CircleAvatar(
        backgroundColor: context.theme.greyColor!.withValues(alpha: 0.3),
        radius: 20,
        backgroundImage:
            contactSource.profileImageUrl.isNotEmpty
                ? CachedNetworkImageProvider(contactSource.profileImageUrl)
                : null,
        child:
            contactSource.profileImageUrl.isEmpty
                ? Icon(Icons.person, size: 30, color: Colors.white)
                : null,
      ),
      title: Text(
        contactSource.username,
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      ),
      subtitle:
          contactSource.profileImageUrl.isEmpty
              ? null
              : Text(
                "Hey there! I'm using Бундъварка",
                style: TextStyle(
                  color: context.theme.greyColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
      trailing:
          contactSource.profileImageUrl.isEmpty
              ? TextButton(
                onPressed: onTap,
                style: TextButton.styleFrom(foregroundColor: Coloors.blueDark),
                child: Text('INVITE'),
              )
              : null,
    );
  }
}
