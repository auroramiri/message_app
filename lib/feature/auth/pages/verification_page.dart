import 'package:flutter/material.dart';
import 'package:message_app/common/extension/custom_theme_extension.dart';
import 'package:message_app/common/widgets/custom_icon_button.dart';
import 'package:message_app/feature/auth/widgets/custom_text_field.dart';

class VerificationPage extends StatefulWidget {
  const VerificationPage({
    super.key,
    required this.verificationId,
    required this.phoneNumber,
  });
  final String verificationId;
  final String phoneNumber;

  @override
  State<VerificationPage> createState() => _VerificationPageState();
}

class _VerificationPageState extends State<VerificationPage> {
  late TextEditingController codeController;

  @override
  void initState() {
    codeController = TextEditingController();
    super.initState();
  }

  @override
  void dispose() {
    codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        title: Text(
          'Verify your phone\'s number',
          style: TextStyle(color: context.theme.authAppbarTextColor),
        ),
        centerTitle: true,
        actions: [CustomIconButton(onTap: () {}, icon: Icons.more_vert)],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 10),
              child: RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: TextStyle(color: context.theme.greyColor, height: 1.5),
                  children: [
                    TextSpan(
                      text:
                          "You've tried to register +7894123116. before requesting an SMS or call with your code. ",
                    ),
                    TextSpan(
                      text: 'Wrong number?',
                      style: TextStyle(color: context.theme.blueColor),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 80),
              child: CustomTextField(
                controller: codeController,
                hintText: '- - -  - - - ',
                fontSize: 30,
                autoFocus: true,
                keyboardType: TextInputType.number,
                onChanged: (value) {},
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Enter 6-digit code',
              style: TextStyle(color: context.theme.greyColor),
            ),
            const SizedBox(height: 30),
            Row(
              children: [
                Icon(Icons.message, color: context.theme.greyColor),
                const SizedBox(width: 20),
                Text(
                  'Resend code',
                  style: TextStyle(color: context.theme.greyColor),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Divider(color: context.theme.blueColor!.withValues(alpha: 0.2)),
          ],
        ),
      ),
    );
  }
}
