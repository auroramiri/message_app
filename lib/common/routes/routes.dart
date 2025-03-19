import 'package:flutter/material.dart';
import 'package:message_app/common/models/user_model.dart';
import 'package:message_app/feature/auth/pages/login_page.dart';
import 'package:message_app/feature/auth/pages/user_info_page.dart';
import 'package:message_app/feature/auth/pages/verification_page.dart';
import 'package:message_app/feature/chat/pages/chat_page.dart';
import 'package:message_app/feature/chat/pages/profile_page.dart';
import 'package:message_app/feature/contact/pages/contact_page.dart';
import 'package:message_app/feature/home/pages/home_page.dart';
import 'package:message_app/feature/welcome/pages/welcome_page.dart';
import 'package:page_transition/page_transition.dart';

class Routes {
  static const String welcome = 'welcome';
  static const String login = 'login';
  static const String verification = 'verification';
  static const String userInfo = 'user-info';
  static const String home = 'home';
  static const String contact = 'contact';
  static const String chat = 'chat';
  static const String profile = 'profile';

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
      case chat:
        final UserModel user = settings.arguments as UserModel;
        return MaterialPageRoute(builder: (contex) => ChatPage(user: user));
      case profile:
        final UserModel user = settings.arguments as UserModel;
        return PageTransition(
          child: ProfilePage(user: user),
          type: PageTransitionType.fade,
          duration: Duration(milliseconds: 800),
        );
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
