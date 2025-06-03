import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:message_app/common/helper/show_alert_dialog.dart';
import 'package:message_app/common/helper/show_loading_dialog.dart';
import 'package:message_app/common/models/user_model.dart';
import 'package:message_app/common/repository/firebase_storage_repository.dart';
import 'package:message_app/common/routes/routes.dart';
import 'package:message_app/common/services/encryption/key_generation_service.dart';

final authRepositoryProvider = Provider((ref) {
  final storage = FlutterSecureStorage();
  final keyGenerationService = KeyGenerationService(secureStorage: storage);
  return AuthRepository(
    auth: FirebaseAuth.instance,
    firestore: FirebaseFirestore.instance,
    keyGenerationService: keyGenerationService,
    realtime: FirebaseDatabase.instance,
  );
});

class AuthRepository {
  final FirebaseAuth auth;
  final FirebaseFirestore firestore;
  final KeyGenerationService keyGenerationService;
  final FirebaseDatabase realtime;

  AuthRepository({
    required this.auth,
    required this.firestore,
    required this.keyGenerationService,
    required this.realtime,
  });

  Future<UserModel?> getCurrentUserInfo() async {
    final userInfo = await firestore.collection('users').doc(auth.currentUser?.uid).get();
    if (userInfo.data() == null) return null;
    return UserModel.fromMap(userInfo.data()!);
  }

  Stream<UserModel> getUserPresenceStatus({required String uid}) {
    return firestore
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((event) => UserModel.fromMap(event.data()!));
  }

  void updateUserPresence() async {
    Map<String, dynamic> online = {
      'active': true,
      'lastSeen': DateTime.now().millisecondsSinceEpoch,
    };
    Map<String, dynamic> offline = {
      'active': false,
      'lastSeen': DateTime.now().millisecondsSinceEpoch,
    };
    final connectedRef = realtime.ref('.info/connected');

    connectedRef.onValue.listen((event) async {
      final isConnected = event.snapshot.value as bool? ?? false;
      if (isConnected) {
        await realtime.ref().child(auth.currentUser!.uid).update(online);
      } else {
        realtime
            .ref()
            .child(auth.currentUser!.uid)
            .onDisconnect()
            .update(offline);
      }
    });
  }

  Future<void> saveUserInfoToFirestore({
    required String username,
    required dynamic profileImage,
    required Ref ref,
    required BuildContext context,
    required bool mounted,
  }) async {
    try {
      showLoadingDialog(context: context, message: 'Saving user info...');
      final uid = auth.currentUser!.uid;
      var profileImageUrl = profileImage is String ? profileImage : '';

      final userDoc = await firestore.collection('users').doc(uid).get();

      bool isAdmin = false;
      String fcmToken = '';

      if (userDoc.exists) {
        final currentUser = UserModel.fromMap(
          userDoc.data() as Map<String, dynamic>,
        );
        isAdmin = currentUser.isAdmin;
        fcmToken = currentUser.fcmToken;
      }

      if (profileImage != null && profileImage is! String) {
        profileImageUrl = await ref
            .read(firebaseStorageRepositoryProvider)
            .storeFileToFirebase('profileImage/$uid', profileImage);
      }

      final keyPair = keyGenerationService.generateRSAKeyPair();
      final publicKeyPEM = keyGenerationService.encodePublicKeyToPEM(keyPair.publicKey);
      await keyGenerationService.savePrivateKey(keyPair.privateKey);

      final user = UserModel(
        username: username,
        uid: uid,
        lastSeen: DateTime.now().millisecondsSinceEpoch,
        profileImageUrl: profileImageUrl,
        active: true,
        phoneNumber: auth.currentUser!.phoneNumber!,
        groupId: [],
        isAdmin: isAdmin,
        fcmToken: fcmToken,
        rsaPublicKey: publicKeyPEM,
      );

      await firestore.collection('users').doc(uid).set(user.toMap());

      if (context.mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          Routes.home,
          (route) => false,
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        showAllertDialog(context: context, message: e.toString());
      }
    }
  }

  void verifySmsCode({
    required BuildContext context,
    required String smsCodeId,
    required String smsCode,
    required bool mounted,
  }) async {
    try {
      showLoadingDialog(context: context, message: 'Verifying code...');
      final credential = PhoneAuthProvider.credential(
        verificationId: smsCodeId,
        smsCode: smsCode,
      );
      await auth.signInWithCredential(credential);
      final user = await getCurrentUserInfo();
      if (context.mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          Routes.userInfo,
          (route) => false,
          arguments: user?.profileImageUrl,
        );
      }
    } on FirebaseAuthException {
      if (context.mounted) {
        Navigator.pop(context);
        showAllertDialog(
          context: context,
          message:
              'Verification code is invalid. Check and enter the correct verification code',
        );
      }
    }
  }

  void sendSmsCode({
    required BuildContext context,
    required String phoneNumber,
  }) async {
    try {
      showLoadingDialog(
        context: context,
        message: 'Sending a verification code to $phoneNumber',
      );
      await auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          await auth.signInWithCredential(credential);
        },
        verificationFailed: (e) {
          if (context.mounted) {
            Navigator.pop(context);
            showAllertDialog(context: context, message: e.toString());
          }
        },
        codeSent: (smsCodeId, resendSmsCodeId) {
          if (context.mounted) {
            Navigator.of(context).pushNamedAndRemoveUntil(
              Routes.verification,
              (route) => false,
              arguments: {'phoneNumber': phoneNumber, 'smsCodeId': smsCodeId},
            );
          }
        },
        codeAutoRetrievalTimeout: (String smsCodeId) {},
      );
    } on FirebaseAuthException catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        showAllertDialog(context: context, message: e.toString());
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        showAllertDialog(context: context, message: e.toString());
      }
    }
  }

  Future<void> deleteUser() async {
    try {
      await firestore.collection('users').doc(auth.currentUser?.uid).delete();
      await auth.currentUser?.delete();
    } catch (e) {
      throw Exception('Failed to delete user: $e');
    }
  }
}
