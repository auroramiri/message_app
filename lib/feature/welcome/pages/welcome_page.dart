import 'package:flutter/material.dart';
import 'package:message_app/common/extension/custom_theme_extension.dart';
import 'package:message_app/common/routes/routes.dart';
import 'package:message_app/feature/welcome/pages/widgets/language_button.dart';
import 'package:message_app/feature/welcome/pages/widgets/privacy_and_terms.dart';

import '../../../common/widgets/custom_elevated_button.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  navigateToLoginPage(context) {
    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(Routes.login, (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 50,
                  vertical: 10,
                ),
                child: Image.asset(
                  'assets/images/circle.png',
                  color: context.theme.circleImageColor,
                ),
              ),
            ),
          ),
          const SizedBox(height: 40),
          Expanded(
            child: Column(
              children: [
                const Text(
                  'Добро пожаловать в БундъВарку',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const PrivacyAndTerms(),
                CustomElevatedButton(
                  onPressed: () => navigateToLoginPage(context),
                  text: 'Agree and Continue',
                ),
                const SizedBox(height: 50),
                LanguageButton(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
