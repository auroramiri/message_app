import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';
import 'package:message_app/common/widgets/custom_icon_button.dart';
import 'package:message_app/feature/auth/controller/auth_controller.dart';
import 'package:message_app/feature/home/pages/admin_home_page.dart';
import 'package:message_app/feature/home/pages/profile_home_page.dart';
import 'package:message_app/feature/home/pages/chat_home_page.dart';
import 'package:message_app/feature/home/pages/settings_home_page.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  late Timer timer;
  updateUserPrecence() {
    ref.read(authControllerProvider).updateUserPrecence();
  }

  @override
  void initState() {
    updateUserPrecence();
    timer = Timer.periodic(
      const Duration(minutes: 1),
      (timer) => setState(() {}),
    );
    super.initState();
  }

  @override
  void dispose() {
    timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ref
        .watch(userInfoAuthProvider)
        .when(
          loading:
              () => const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              ),
          error:
              (error, stack) =>
                  Scaffold(body: Center(child: Text('Ошибка: $error'))),
          data: (user) {
            if (user == null) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            int tabLength = user.isAdmin ? 4 : 3;
            return DefaultTabController(
              length: tabLength,
              child: Scaffold(
                appBar: AppBar(
                  title: Text(
                    'app_title'.tr,
                    style: TextStyle(letterSpacing: 1),
                  ),
                  elevation: 1,
                  actions: [
                    CustomIconButton(onPressed: () {}, icon: Icons.search),
                    CustomIconButton(onPressed: () {}, icon: Icons.more_vert),
                  ],
                  bottom: TabBar(
                    indicatorWeight: 3,
                    labelStyle: TextStyle(fontWeight: FontWeight.bold),
                    splashFactory: NoSplash.splashFactory,
                    tabs: [
                      Tab(text: 'chats'.tr),
                      Tab(text: 'profile'.tr),
                      if (user.isAdmin) const Tab(text: 'Users'),
                      Tab(text: 'settings'.tr),
                    ],
                  ),
                ),
                body: TabBarView(
                  children: [
                    ChatHomePage(),
                    ref
                        .watch(userInfoAuthProvider)
                        .when(
                          loading:
                              () => const Center(
                                child: CircularProgressIndicator(),
                              ),
                          error:
                              (error, stack) =>
                                  Center(child: Text('Ошибка: $error')),
                          data:
                              (user) =>
                                  user != null
                                      ? UserProfilePage()
                                      : const Center(
                                        child: CircularProgressIndicator(),
                                      ),
                        ),
                    if (user.isAdmin) const AdminPage(),
                    SettingsPage(),
                  ],
                ),
              ),
            );
          },
        );
  }
}
