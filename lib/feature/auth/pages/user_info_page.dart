import 'package:flutter/material.dart';
import 'package:message_app/common/extension/custom_theme_extension.dart';
import 'package:message_app/common/widgets/custom_elevated_button.dart';
import 'package:message_app/feature/auth/widgets/custom_text_field.dart';

class UserInfoPage extends StatefulWidget {
  const UserInfoPage({super.key});

  @override
  State<UserInfoPage> createState() => _UserInfoPageState();
}

class _UserInfoPageState extends State<UserInfoPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        title: Text(
          'Profile info',
          style: TextStyle(color: context.theme.authAppbarTextColor),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            Text(
              'Please provide your name and an optional profile photo',
              textAlign: TextAlign.center,
              style: TextStyle(color: context.theme.greyColor),
            ),
            SizedBox(height: 40),
            Container(
              padding: EdgeInsets.all(26),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: context.theme.photoIconBgColor,
              ),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 3, right: 3),
                child: Icon(
                  Icons.add_a_photo,
                  size: 48,
                  color: context.theme.photoIconColor,
                ),
              ),
            ),
            SizedBox(height: 40),
            Row(
              children: [
                SizedBox(width: 20),
                Expanded(
                  child: CustomTextField(
                    hintText: 'Type your name here',
                    textAlign: TextAlign.left,
                    autoFocus: true,
                  ),
                ),
                SizedBox(width: 10),
                Icon(
                  Icons.emoji_emotions_outlined,
                  color: context.theme.photoIconColor,
                ),
                SizedBox(width: 20),
              ],
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: CustomElevatedButton(
        onPressed: () {},
        text: 'NEXT',
        buttonWidth: 90,
      ),
    );
  }
}
