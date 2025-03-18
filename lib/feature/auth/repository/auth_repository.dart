import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:message_app/common/helper/show_alert_dialog.dart';
import 'package:message_app/common/helper/show_loading_dialog.dart';
import 'package:message_app/common/models/user_model.dart';
import 'package:message_app/common/repository/firebase_storage_repository.dart';
import 'package:message_app/common/routes/routes.dart';

final authRepositoryProvider = Provider((ref) {
  return AuthRepository(
    auth: FirebaseAuth.instance,
    firestore: FirebaseFirestore.instance,
  );
});

class AuthRepository {
  final FirebaseAuth auth;
  final FirebaseFirestore firestore;

  Future<UserModel?> getCurrentUserInfo() async {
    UserModel? user;
    final userInfo =
        await firestore.collection('users').doc(auth.currentUser?.uid).get();
    if (userInfo.data() == null) return user;
    user = UserModel.fromMap(userInfo.data()!);
    return user;
  }

  AuthRepository({required this.auth, required this.firestore});

  void saveUserInfoToFirestore({
    required String username,
    required var profileImage,
    required Ref ref,
    required BuildContext context,
    required bool mounted,
  }) async {
    try {
      showLoadingDialog(context: context, message: 'Saving user info...');
      String uid = auth.currentUser!.uid;
      String profileImageUrl = '';
      if (profileImage != null) {
        profileImageUrl = await ref
            .read(firebaseStorageRepositoryProvider)
            .storeFileToFirebase('profileImage/$uid', profileImage);
      }

      UserModel user = UserModel(
        username: username,
        uid: uid,
        profileImageUrl: profileImageUrl,
        active: true,
        phoneNumber: auth.currentUser!.phoneNumber!,
        groupId: [],
      );

      await firestore.collection('users').doc(uid).set(user.toMap());

      if (!context.mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, Routes.home, (route) => false);
    } catch (e) {
      Navigator.pop(context);
      showAllertDialog(context: context, message: e.toString());
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
      if (!mounted) return;
      if (context.mounted) {
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil(Routes.userInfo, (route) => false);
      }
    } on FirebaseAuthException catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        showAllertDialog(context: context, message: e.toString());
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
          showAllertDialog(context: context, message: e.toString());
        },
        codeSent: (smsCodeId, resendSmsCodeId) {
          Navigator.of(context).pushNamedAndRemoveUntil(
            Routes.verification,
            (route) => false,
            arguments: {'phoneNumber': phoneNumber, 'smsCodeId': smsCodeId},
          );
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
        showAllertDialog(context: context, message: e.toString());
      }
    }
  }
}
