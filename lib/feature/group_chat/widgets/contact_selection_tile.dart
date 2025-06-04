import 'package:flutter/material.dart';
import 'package:message_app/common/models/user_model.dart';

class ContactSelectionTile extends StatelessWidget {
  final UserModel user;
  final bool isSelected;
  final VoidCallback onTap;

  const ContactSelectionTile({
    super.key,
    required this.user,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundImage:
            // ignore: unnecessary_null_comparison
            user.profileImageUrl != null
                ? NetworkImage(user.profileImageUrl)
                : null,
        // ignore: unnecessary_null_comparison
        child: user.profileImageUrl == null ? const Icon(Icons.person) : null,
      ),
      title: Text(user.username),
      trailing:
          isSelected
              ? const Icon(Icons.check_circle, color: Colors.blue)
              : const Icon(Icons.radio_button_unchecked),
      onTap: onTap,
    );
  }
}
