import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:message_app/common/extension/custom_theme_extension.dart';
import 'package:message_app/common/helper/last_seen_message.dart';
import 'package:message_app/common/models/user_model.dart';
import 'package:message_app/common/utils/coloors.dart';
import 'package:message_app/common/utils/disappearing_message_servise.dart';
import 'package:message_app/common/widgets/custom_icon_button.dart';
import 'package:message_app/feature/auth/controller/auth_controller.dart';
import 'package:message_app/common/utils/custom_list_tile.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key, required this.user});

  final UserModel user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String chatId = user.uid;
    return Scaffold(
      backgroundColor: context.theme.profilePageBg,
      body: CustomScrollView(
        slivers: [
          SliverPersistentHeader(
            delegate: SliverPersistentDelegate(user),
            pinned: true,
          ),
          SliverToBoxAdapter(
            child: Column(
              children: [
                Container(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  child: Column(
                    children: [
                      Text(user.username, style: const TextStyle(fontSize: 24)),

                      const SizedBox(height: 10),
                      StreamBuilder(
                        stream: ref
                            .read(authControllerProvider)
                            .getUserPresenceStatus(uid: user.uid),
                        builder: (_, snapshot) {
                          if (snapshot.connectionState !=
                              ConnectionState.active) {
                            return const SizedBox();
                          }

                          final singleUserModel = snapshot.data!;
                          final lastMessage = lastSeenMessage(
                            singleUserModel.lastSeen,
                          );

                          return Column(
                            children: [
                              const SizedBox(height: 10),
                              Text(
                                singleUserModel.phoneNumber,
                                style: TextStyle(
                                  fontSize: 20,
                                  color: context.theme.greyColor,
                                ),
                              ),
                              Text(
                                singleUserModel.active
                                    ? 'online'
                                    : "last seen $lastMessage ago",
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                CustomListTile(
                  title: 'Disappearing messages',
                  leading: Icons.timer,
                  subTitle: 'Set a timer to delete messages',
                  onTimeSelected: (time) {
                    final disappearingMessagesService =
                        DisappearingMessagesService(
                          firestore: FirebaseFirestore.instance,
                        );
                    disappearingMessagesService.setDisappearingMessagesTimer(
                      time,
                      chatId,
                    );
                  },
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  iconWithText({required IconData icon, required String text}) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 30, color: Coloors.blueDark),
          const SizedBox(height: 10),
          Text(text, style: const TextStyle(color: Coloors.blueDark)),
        ],
      ),
    );
  }
}

class SliverPersistentDelegate extends SliverPersistentHeaderDelegate {
  final UserModel user;

  final double maxHeaderHeight = 180;
  final double minHeaderHeight = kToolbarHeight + 20;
  final double maxImageSize = 130;
  final double minImageSize = 40;

  SliverPersistentDelegate(this.user);

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final size = MediaQuery.of(context).size;
    final percent = shrinkOffset / (maxHeaderHeight - 35);
    final percent2 = shrinkOffset / (maxHeaderHeight);
    final currentImageSize = (maxImageSize * (1 - percent)).clamp(
      minImageSize,
      maxImageSize,
    );
    final currentImagePosition = ((size.width / 2 - 65) * (1 - percent)).clamp(
      minImageSize,
      maxImageSize,
    );
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Container(
        color: Theme.of(context).appBarTheme.backgroundColor!.withValues(
          alpha: percent2 * 2 < 1 ? percent2 * 2 : 1,
        ),
        child: Stack(
          children: [
            Positioned(
              top: MediaQuery.of(context).viewPadding.top + 15,
              left: currentImagePosition + 50,
              child: Text(
                user.username,
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.white.withValues(alpha: percent2),
                ),
              ),
            ),
            Positioned(
              left: 0,
              top: MediaQuery.of(context).viewPadding.top + 5,
              child: BackButton(
                color:
                    percent2 > .3
                        ? Colors.white.withValues(alpha: percent2)
                        : null,
              ),
            ),
            Positioned(
              right: 0,
              top: MediaQuery.of(context).viewPadding.top + 5,
              child: CustomIconButton(
                onPressed: () {},
                icon: Icons.more_vert,
                iconColor:
                    percent2 > .3
                        ? Colors.white.withValues(alpha: percent2)
                        : Theme.of(context).textTheme.bodyMedium!.color,
              ),
            ),
            Positioned(
              left: currentImagePosition,
              top: MediaQuery.of(context).viewPadding.top + 5,
              bottom: 0,
              child: Hero(
                tag: 'profile',
                child: Container(
                  width: currentImageSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    image: DecorationImage(
                      image: CachedNetworkImageProvider(user.profileImageUrl),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  double get maxExtent => maxHeaderHeight;

  @override
  double get minExtent => minHeaderHeight;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return false;
  }
}
