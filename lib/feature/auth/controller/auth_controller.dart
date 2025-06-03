import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:message_app/common/models/user_model.dart';
import 'package:message_app/feature/auth/repository/auth_repository.dart';
import 'package:message_app/repositories/notification/token_service.dart';
import 'package:message_app/repositories/notification/notification_providers.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Provider for the token-aware auth controller
final authStateProvider =
    StateNotifierProvider<AuthStateController, AsyncValue<User?>>((ref) {
      final auth = FirebaseAuth.instance;
      final tokenService = ref.watch(tokenServiceProvider);
      return AuthStateController(auth, tokenService);
    });

// Original auth controller provider
final authControllerProvider = Provider((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  final tokenService = ref.watch(tokenServiceProvider);
  return AuthController(
    authRepository: authRepository,
    tokenService: tokenService,
    ref: ref,
  );
});

final userInfoAuthProvider = FutureProvider<UserModel?>((ref) async {
  final authController = ref.watch(authControllerProvider);
  return authController.getCurrentUserInfo();
});

// New state notifier for auth state with token management
class AuthStateController extends StateNotifier<AsyncValue<User?>> {
  final FirebaseAuth _auth;
  final TokenService _tokenService;

  AuthStateController(this._auth, this._tokenService)
    : super(const AsyncValue.loading()) {
    _init();
  }

  void _init() {
    _auth.authStateChanges().listen((user) async {
      state = AsyncValue.data(user);

      if (user != null) {
        await _tokenService.saveToken();
      }
    });
  }

  Future<void> signOut() async {
    try {
      await _tokenService.removeToken();
      await _auth.signOut();
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
}

// Original AuthController with token management added
class AuthController {
  final AuthRepository authRepository;
  final TokenService tokenService;
  final Ref ref;

  AuthController({
    required this.ref,
    required this.authRepository,
    required this.tokenService,
  });

  Stream<UserModel> getUserPresenceStatus({required String uid}) {
    return authRepository.getUserPresenceStatus(uid: uid);
  }

  void updateUserPresence() {
    authRepository.updateUserPresence();
  }

  Future<UserModel?> getCurrentUserInfo() async {
    UserModel? user = await authRepository.getCurrentUserInfo();

    if (user != null) {
      await tokenService.saveToken();
    }

    return user;
  }

  Future<void> saveUserInfoToFirestore({
    required String username,
    required dynamic profileImage,
    required BuildContext context,
    required bool mounted,
  }) async {
    authRepository.saveUserInfoToFirestore(
      username: username,
      profileImage: profileImage,
      ref: ref,
      context: context,
      mounted: mounted,
    );

    await tokenService.saveToken();
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
