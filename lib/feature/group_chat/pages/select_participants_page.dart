import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:message_app/common/models/last_message_model.dart';
import 'package:message_app/common/models/user_model.dart';
import 'package:message_app/feature/chat/repositories/chat_repository.dart'; // Ensure this import is correct
import 'package:message_app/feature/group_chat/controllers/group_chat_controller.dart';

class SelectParticipantsPage extends ConsumerStatefulWidget {
  const SelectParticipantsPage({super.key, required this.groupId});

  final String groupId;

  @override
  ConsumerState<SelectParticipantsPage> createState() =>
      _SelectParticipantsPageState();
}

class _SelectParticipantsPageState
    extends ConsumerState<SelectParticipantsPage> {
  final Set<String> _selectedParticipantIds = {};
  late String _currentUserId;

  @override
  void initState() {
    super.initState();
    _currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
  }

  void _toggleParticipantSelection(String participantId) {
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

  Future<void> _addSelectedParticipants() async {
    try {
      for (var participantId in _selectedParticipantIds) {
        await ref
            .read(groupChatControllerProvider)
            .addParticipant(
              groupId: widget.groupId,
              participantId: participantId,
            );
      }
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to add participants: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Participants'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _addSelectedParticipants,
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Select Participants',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<LastMessageModel>>(
              stream: ref.read(chatRepositoryProvider).getAllLastMessageList(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final lastMessages = snapshot.data ?? [];
                final currentUserId =
                    FirebaseAuth.instance.currentUser?.uid ?? '';

                final filteredMessages =
                    lastMessages.where((message) {
                      return message.contactId != currentUserId;
                    }).toList();

                return ListView.builder(
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

                    return CheckboxListTile(
                      value: _selectedParticipantIds.contains(user.uid),
                      onChanged: (bool? selected) {
                        if (selected != null) {
                          _toggleParticipantSelection(user.uid);
                        }
                      },
                      title: Text(user.username),
                      secondary: CircleAvatar(
                        backgroundImage:
                            user.profileImageUrl.isNotEmpty
                                ? CachedNetworkImageProvider(
                                  user.profileImageUrl,
                                )
                                : null,
                        child:
                            user.profileImageUrl.isEmpty
                                ? const Icon(Icons.person)
                                : null,
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
