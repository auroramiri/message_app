import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:get/get.dart';
import 'package:message_app/common/localization/app_translations.dart';
import 'package:message_app/common/routes/routes.dart';
import 'package:message_app/common/theme/dark_theme.dart';
import 'package:message_app/common/theme/light_theme.dart';
import 'package:message_app/feature/auth/controller/auth_controller.dart';
import 'package:message_app/feature/home/pages/home_page.dart';
import 'package:message_app/feature/home/pages/settings_home_page.dart';
import 'package:message_app/feature/welcome/pages/welcome_page.dart';
import 'package:message_app/firebase_options.dart';
import 'package:message_app/repositories/notification/background_message_handler.dart';
import 'package:message_app/repositories/notification/notification_providers.dart';

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // Set up background message handler
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const ProviderScope(child: ChatApp()));
}

class ChatApp extends ConsumerStatefulWidget {
  const ChatApp({super.key});

  @override
  ConsumerState<ChatApp> createState() => _ChatAppState();
}

class _ChatAppState extends ConsumerState<ChatApp> {
  late FlutterLocalNotificationsPlugin _localNotifications;

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
  }

  Future<void> _initializeNotifications() async {
    final notificationRepository = ref.read(notificationRepositoryProvider);
    await notificationRepository.initialize();

    // Initialize local notifications
    _localNotifications = FlutterLocalNotificationsPlugin();

    // Initialize with the new callback
    const initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      ),
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (details) async {
        // Handle notification tap when app is running
        if (mounted && details.payload != null) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => HomePage()),
          );
        }
      },
    );

    // Handle notification tap when app is terminated
    final notificationAppLaunchDetails =
        await _localNotifications.getNotificationAppLaunchDetails();
    if (mounted &&
        notificationAppLaunchDetails != null &&
        notificationAppLaunchDetails.notificationResponse?.payload != null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => HomePage()),
      );
    }

    await FirebaseMessaging.instance.requestPermission();

    ref.read(userInfoAuthProvider.future).then((user) {
      if (user != null) {
        ref.read(messageNotificationServiceProvider).subscribeToUserChats();
      }
    });

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        _showNotification(message.notification!);
      }
    });

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  }

  void _showNotification(RemoteNotification notification) async {
    final androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'channel_id',
      'channel_name',
      channelDescription: 'channel_description',
      importance: Importance.max,
      priority: Priority.high,
    );

    final platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    await _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      platformChannelSpecifics,
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);

    // Убедитесь, что Splash Screen удаляется после загрузки
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FlutterNativeSplash.remove();
    });

    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'app_title'.tr,
      theme: lightTheme(),
      darkTheme: darkTheme(),
      themeMode: themeMode,
      translations: AppTranslations(),
      locale: const Locale('en', 'US'),
      fallbackLocale: const Locale('en', 'US'),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', 'US'),
        Locale('ru', 'RU'),
        Locale('de', 'DE'),
      ],
      home: ref
          .watch(userInfoAuthProvider)
          .when(
            data: (user) {
              if (user == null) {
                return const WelcomePage();
              } else {
                return const HomePage();
              }
            },
            error: (error, trace) {
              return const Scaffold(
                body: Center(child: Text('Something went wrong!')),
              );
            },
            loading: () {
              return const SizedBox();
            },
          ),
      onGenerateRoute: Routes.onGenerateRoute,
    );
  }
}
