import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:message_app/common/models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:message_app/feature/home/pages/admin_user_profile_page.dart';

final usersStreamProvider = StreamProvider<List<UserModel>>((ref) {
  return FirebaseFirestore.instance.collection('users').snapshots().map((
    snapshot,
  ) {
    return snapshot.docs.map((doc) => UserModel.fromMap(doc.data())).toList();
  });
});

class AdminPage extends ConsumerWidget {
  const AdminPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Users List')),
      body: ref
          .watch(usersStreamProvider)
          .when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(child: Text('Error: $error')),
            data: (users) {
              return ListView.builder(
                itemCount: users.length,
                itemBuilder: (context, index) {
                  final user = users[index];
                  return ListTile(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => AdminUserProfilePage(user: user),
                        ),
                      );
                    },
                    title: Text(user.username),
                    leading: CircleAvatar(
                      backgroundImage:
                          user.profileImageUrl.isNotEmpty
                              ? CachedNetworkImageProvider(user.profileImageUrl)
                              : null,
                      radius: 24,
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
    );
  }
}
