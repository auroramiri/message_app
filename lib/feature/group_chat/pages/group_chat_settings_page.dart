import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';
import 'package:image_picker/image_picker.dart';
import 'package:message_app/common/models/last_message_model.dart';
import 'package:message_app/common/models/user_model.dart';
import 'package:message_app/common/repository/firebase_storage_repository.dart';
import 'package:message_app/feature/chat/repositories/chat_repository.dart';
import 'package:message_app/feature/group_chat/controllers/group_chat_controller.dart';
import 'package:message_app/feature/group_chat/widgets/contact_selection_tile.dart';

class GroupSettingsPage extends ConsumerStatefulWidget {
  const GroupSettingsPage({super.key});

  @override
  ConsumerState<GroupSettingsPage> createState() => _GroupSettingsPageState();
}

class _GroupSettingsPageState extends ConsumerState<GroupSettingsPage> {
  final TextEditingController _groupNameController = TextEditingController();
  Uint8List? _imageGallery;
  final Set<String> _selectedParticipantIds = {};
  late String _currentUserId;

  @override
  void initState() {
    super.initState();
    _currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
  }

  Future<void> pickImageFromGallery() async {
    try {
      final image = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (image != null) {
        final imageBytes = await image.readAsBytes();
        setState(() {
          _imageGallery = imageBytes;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${'failed_to_pick_image'.tr}$e')),
        );
      }
    }
  }

  void _toggleParticipantSelection(String participantId) {
    // Prevent the current user from being added as a participant
    if (participantId == _currentUserId) {
      return;
    }

    setState(() {
      if (_selectedParticipantIds.contains(participantId)) {
        _selectedParticipantIds.remove(participantId);
      } else {
        _selectedParticipantIds.add(participantId);
      }
    });
  }

  Future<void> createGroup() async {
    final groupName = _groupNameController.text;
    final groupIconBytes = _imageGallery;
    final List<String> participantIds = _selectedParticipantIds.toList();

    try {
      String? groupIconUrl;
      if (groupIconBytes != null) {
        groupIconUrl = await ref
            .read(firebaseStorageRepositoryProvider)
            .storeFileToFirebase(
              'groupIcons/${DateTime.now().millisecondsSinceEpoch}',
              groupIconBytes,
            );
      }

      await ref
          .read(groupChatControllerProvider)
          .createGroup(
            groupName: groupName,
            participantIds: participantIds,
            groupIconUrl: groupIconUrl,
          );
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${'failed_to_create_group'.tr}$e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('create_group_chat'.tr),
        actions: [
          IconButton(icon: const Icon(Icons.check), onPressed: createGroup),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: GestureDetector(
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    builder: (BuildContext context) {
                      return SafeArea(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            ListTile(
                              leading: const Icon(Icons.photo_library),
                              title: Text('gallery'.tr),
                              onTap: () {
                                Navigator.pop(context);
                                pickImageFromGallery();
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
                child:
                    _imageGallery != null
                        ? CircleAvatar(
                          radius: 50,
                          backgroundImage: MemoryImage(_imageGallery!),
                        )
                        : const CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.grey,
                          child: Icon(Icons.group, size: 50),
                        ),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _groupNameController,
              decoration: InputDecoration(
                labelText: 'group_name'.tr,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'select_participants'.tr,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            StreamBuilder<List<LastMessageModel>>(
              stream: ref.read(chatRepositoryProvider).getAllLastMessageList(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text('${'error'.tr}: ${snapshot.error}'),
                  );
                }

                final lastMessages = snapshot.data ?? [];
                final currentUserId =
                    FirebaseAuth.instance.currentUser?.uid ?? '';

                // Filter out the current user from the list
                final filteredMessages =
                    lastMessages.where((message) {
                      return message.contactId != currentUserId;
                    }).toList();

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filteredMessages.length,
                  itemBuilder: (context, index) {
                    final lastMessage = filteredMessages[index];
                    final user = UserModel(
                      uid: lastMessage.contactId,
                      username: lastMessage.username,
                      profileImageUrl: lastMessage.profileImageUrl,
                      active: true,
                      lastSeen: 0,
                      phoneNumber: '',
                      groupId: [],
                      isAdmin: false,
                      fcmToken: '',
                      rsaPublicKey: '',
                    );

                    return ContactSelectionTile(
                      user: user,
                      isSelected: _selectedParticipantIds.contains(user.uid),
                      onTap: () => _toggleParticipantSelection(user.uid),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
