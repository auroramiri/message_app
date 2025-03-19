import 'package:flutter/material.dart';
import 'package:message_app/common/widgets/custom_icon_button.dart';
import 'package:message_app/feature/home/pages/call_home_page.dart';
import 'package:message_app/feature/home/pages/chat_home_page.dart';
import 'package:message_app/feature/home/pages/status_home_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Бундъварка', style: TextStyle(letterSpacing: 1)),
          elevation: 1,
          actions: [
            CustomIconButton(onTap: () {}, icon: Icons.search),
            CustomIconButton(onTap: () {}, icon: Icons.more_vert),
          ],
          bottom: TabBar(
            indicatorWeight: 3,
            labelStyle: TextStyle(fontWeight: FontWeight.bold),
            splashFactory: NoSplash.splashFactory,
            tabs: [Tab(text: 'CHATS'), Tab(text: 'STATUS'), Tab(text: 'CALLS')],
          ),
        ),
        body: TabBarView(
          children: [ChatHomePage(), StatusHomePage(), CallHomePage()],
        ),
      ),
    );
  }
}
