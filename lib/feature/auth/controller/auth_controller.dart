import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:message_app/common/models/user_model.dart';
import 'package:message_app/feature/auth/repository/auth_repository.dart';

final authControllerProvider = Provider((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return AuthController(authRepository: authRepository, ref: ref);
});

final userInfoAuthProvider = FutureProvider((ref) {
  final authController = ref.watch(authControllerProvider);
  return authController.getCurrentUserInfo();
});

class AuthController {
  final AuthRepository authRepository;
  final Ref ref;

  AuthController({required this.ref, required this.authRepository});

  Stream<UserModel> getUserPrecenceStatus({required String uid}) {
    return authRepository.getUserPrecenceStatus(uid: uid);
  }

  void updateUserPrecence() {
    return authRepository.updateUserPrecence();
  }

  Future<UserModel?> getCurrentUserInfo() async {
    UserModel? user = await authRepository.getCurrentUserInfo();
    return user;
  }

  void saveUserInfoToFirestore({
    required String username,
    required var profileImage,
    required BuildContext context,
    required bool mounted,
  }) {
    authRepository.saveUserInfoToFirestore(
      username: username,
      profileImage: profileImage,
      ref: ref,
      context: context,
      mounted: mounted,
    );
  }

  void verifySmsCode({
    required BuildContext context,
    required String smsCodeId,
    required String smsCode,
    required bool mounted,
  }) {
    authRepository.verifySmsCode(
      context: context,
      smsCodeId: smsCodeId,
      smsCode: smsCode,
      mounted: mounted,
    );
  }

  void sendSmsCode({
    required BuildContext context,
    required String phoneNumber,
  }) {
    authRepository.sendSmsCode(context: context, phoneNumber: phoneNumber);
  }
}
