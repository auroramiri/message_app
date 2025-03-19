import 'package:flutter/material.dart';
import 'package:message_app/feature/auth/pages/login_page.dart';
import 'package:message_app/feature/auth/pages/user_info_page.dart';
import 'package:message_app/feature/auth/pages/verification_page.dart';
import 'package:message_app/feature/contact/pages/contact_page.dart';
import 'package:message_app/feature/home/pages/home_page.dart';
import 'package:message_app/feature/welcome/pages/welcome_page.dart';

class Routes {
  static const String welcome = 'welcome';
  static const String login = 'login';
  static const String verification = 'verification';
  static const String userInfo = 'user-info';
  static const String home = 'home';
  static const String contact = 'contact';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case welcome:
        return MaterialPageRoute(builder: (contex) => const WelcomePage());
      case login:
        return MaterialPageRoute(builder: (contex) => const LoginPage());
      case verification:
        final Map args = settings.arguments as Map;
        return MaterialPageRoute(
          builder:
              (contex) => VerificationPage(
                smsCodeId: args['smsCodeId'],
                phoneNumber: args['phoneNumber'],
              ),
        );
      case userInfo:
        final String? profileImageUrl = settings.arguments as String?;
        return MaterialPageRoute(
          builder: (contex) => UserInfoPage(profileImageUrl: profileImageUrl),
        );
      case home:
        return MaterialPageRoute(builder: (contex) => const HomePage());
      case contact:
        return MaterialPageRoute(builder: (contex) => const ContactPage());
      default:
        return MaterialPageRoute(
          builder:
              (contex) => const Scaffold(
                body: Center(child: Text('No Page Route Provided')),
              ),
        );
    }
  }
}
