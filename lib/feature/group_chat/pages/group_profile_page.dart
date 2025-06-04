import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:message_app/common/models/group_chat_model.dart';
import 'package:message_app/feature/group_chat/controllers/group_chat_controller.dart';
import 'package:message_app/feature/group_chat/pages/select_participants_page.dart';
import 'package:message_app/feature/group_chat/repositories/group_chat_repository.dart';

class GroupProfilePage extends ConsumerWidget {
  const GroupProfilePage({super.key, required this.group});

  final GroupChatModel group;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final isModerator = group.moderatorIds.contains(currentUserId);

    void removeParticipant(String participantId) async {
      try {
        await ref
            .read(groupChatControllerProvider)
            .removeParticipant(
              groupId: group.groupId,
              participantId: participantId,
            );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to remove participant: $e')),
        );
      }
    }

    void deleteGroup() async {
      // Implement logic to delete the group
    }

    void leaveGroup() async {
      try {
        await ref
            .read(groupChatControllerProvider)
            .removeParticipant(
              groupId: group.groupId,
              participantId: currentUserId!,
            );
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to leave group: $e')));
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Group Profile')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: CircleAvatar(
                radius: 50,
                backgroundImage:
                    group.groupIconUrl != null && group.groupIconUrl!.isNotEmpty
                        ? NetworkImage(group.groupIconUrl!)
                        : null,
                child:
                    group.groupIconUrl == null || group.groupIconUrl!.isEmpty
                        ? const Icon(Icons.group, size: 50)
                        : null,
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                group.groupName,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Participants',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: group.participantIds.length,
                itemBuilder: (context, index) {
                  final participantId = group.participantIds[index];
                  return FutureBuilder<String>(
                    future: ref
                        .read(groupChatRepositoryProvider)
                        .getUserNameById(participantId),
                    builder: (context, snapshot) {
                      final participantName = snapshot.data ?? 'Unknown';
                      return ListTile(
                        title: Text(participantName),
                        trailing:
                            isModerator && participantId != currentUserId
                                ? IconButton(
                                  icon: const Icon(Icons.remove_circle),
                                  onPressed:
                                      () => removeParticipant(participantId),
                                )
                                : null,
                      );
                    },
                  );
                },
              ),
            ),
            if (isModerator)
              Column(
                children: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => SelectParticipantsPage(
                                groupId: group.groupId,
                              ),
                        ),
                      );
                    },
                    child: const Text('Add Participants'),
                  ),
                  ElevatedButton(
                    onPressed: deleteGroup,
                    child: const Text('Delete Group'),
                  ),
                ],
              ),
            ElevatedButton(
              onPressed: leaveGroup,
              child: const Text('Leave Group'),
            ),
          ],
        ),
      ),
    );
  }
}
