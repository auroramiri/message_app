  import 'dart:developer';

  import 'package:firebase_core/firebase_core.dart';
  import 'package:firebase_messaging/firebase_messaging.dart';
  import 'package:message_app/firebase_options.dart';

  @pragma('vm:entry-point')
  Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {

    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    
    log("Handling a background message: ${message.messageId}");
  }
