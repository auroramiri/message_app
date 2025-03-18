import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:message_app/common/routes/routes.dart';
import 'package:message_app/common/theme/dark_theme.dart';
import 'package:message_app/common/theme/light_theme.dart';
import 'package:message_app/feature/auth/controller/auth_controller.dart';
import 'package:message_app/feature/home/pages/home_page.dart';
import 'package:message_app/feature/welcome/pages/welcome_page.dart';
import 'package:message_app/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const ProviderScope(child: ChatApp()));
}

class ChatApp extends ConsumerWidget {
  const ChatApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'БундъВарка',
      theme: lightTheme(),
      darkTheme: darkTheme(),
      themeMode: ThemeMode.system,
      home: ref
          .watch(userInfoAuthProvider)
          .when(
            data: (user) {
              if (user == null) return const WelcomePage();
              return HomePage();
            },
            error: (error, trace) {
              return Scaffold(
                body: Center(child: Text('Something went wrong!')),
              );
            },
            loading: () {
              return Scaffold(
                body: Center(
                  child: Image.asset('assets/images/playstore.png', width: 50),
                ),
              );
            },
          ),
      onGenerateRoute: Routes.onGenerateRoute,
    );
  }
}
