import 'package:flutter/material.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';
import 'package:message_app/common/models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminUserProfilePage extends StatefulWidget {
  final UserModel user;

  const AdminUserProfilePage({super.key, required this.user});

  @override
  State<AdminUserProfilePage> createState() => _AdminUserProfilePageState();
}

class _AdminUserProfilePageState extends State<AdminUserProfilePage> {
  late TextEditingController usernameController;
  bool isEditing = false;
  String? profileImageUrl;

  @override
  void initState() {
    super.initState();
    usernameController = TextEditingController(text: widget.user.username);
    profileImageUrl = widget.user.profileImageUrl;
  }

  @override
  void dispose() {
    usernameController.dispose();
    super.dispose();
  }

  void toggleEditing() {
    setState(() {
      isEditing = !isEditing;
    });
  }

  Future<void> removeProfileImage() async {
    setState(() {
      profileImageUrl = null;
    });

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.user.uid)
          .update({'profileImageUrl': ''});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${'failed_to_remove_profile_image'.tr}$e')),
        );
      }
    }
  }

  Future<void> saveUserChanges() async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.user.uid)
          .update({'username': usernameController.text});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('user_information_updated_successfully'.tr)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${'failed_to_update_user_information'.tr}$e'),
          ),
        );
      }
    }
  }

  Future<void> deleteUserAccount() async {
    try {
      String userId = widget.user.uid;

      await FirebaseFirestore.instance.collection('users').doc(userId).delete();

      QuerySnapshot userChatsSnapshot =
          await FirebaseFirestore.instance
              .collectionGroup('chats')
              .where('participants', arrayContains: userId)
              .get();

      for (var chatDoc in userChatsSnapshot.docs) {
        List<dynamic> participants = chatDoc['participants'];
        for (var participantId in participants) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(participantId)
              .collection('chats')
              .doc(chatDoc.id)
              .delete();
        }
      }

      await FirebaseAuth.instance.currentUser?.delete();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('user_account_deleted_successfully'.tr)),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('${'failed_to_delete_user_account'.tr}$e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('user_profile'.tr),
        actions: [
          IconButton(
            icon: Icon(isEditing ? Icons.done : Icons.edit),
            onPressed: toggleEditing,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundImage:
                      profileImageUrl != null && profileImageUrl!.isNotEmpty
                          ? NetworkImage(profileImageUrl!)
                          : null,
                  child:
                      profileImageUrl == null || profileImageUrl!.isEmpty
                          ? const Icon(Icons.person, size: 50)
                          : null,
                ),
                if (profileImageUrl != null && profileImageUrl!.isNotEmpty)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: GestureDetector(
                      onTap: removeProfileImage,
                      child: const CircleAvatar(
                        radius: 15,
                        backgroundColor: Colors.red,
                        child: Icon(Icons.close, size: 15, color: Colors.white),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            Text(widget.user.phoneNumber, style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 20),
            TextField(
              controller: usernameController,
              enabled: isEditing,
              decoration: InputDecoration(
                labelText: 'username'.tr,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            if (isEditing)
              ElevatedButton(
                onPressed: saveUserChanges,
                child: Text('save_changes'.tr),
              ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: Text('delete_account'.tr),
                      content: Text(
                        'are_you_sure_you_want_to_delete_this_account'.tr,
                      ),
                      actions: <Widget>[
                        TextButton(
                          child: Text('cancel'.tr),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        ),
                        TextButton(
                          child: Text('delete'.tr),
                          onPressed: () {
                            Navigator.of(context).pop();
                            deleteUserAccount();
                          },
                        ),
                      ],
                    );
                  },
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: Text('delete_account'.tr),
            ),
          ],
        ),
      ),
    );
  }
}
