import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:message_app/common/extension/custom_theme_extension.dart';
import 'package:message_app/common/helper/show_alert_dialog.dart';
import 'package:message_app/common/models/user_model.dart';
import 'package:message_app/common/routes/routes.dart';
import 'package:message_app/common/services/encryption/key_generation_service.dart';
import 'package:message_app/common/utils/coloors.dart';
import 'package:message_app/common/widgets/custom_icon_button.dart';
import 'package:message_app/common/widgets/short_h_bar.dart';
import 'package:message_app/feature/auth/controller/auth_controller.dart';
import 'package:message_app/feature/auth/pages/image_picker_page.dart';
import 'package:message_app/feature/auth/repository/auth_repository.dart';
import 'package:message_app/feature/auth/widgets/custom_text_field.dart';
import 'package:message_app/feature/chat/widgets/custom_list_tile.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserProfilePage extends ConsumerStatefulWidget {
  const UserProfilePage({super.key});

  @override
  ConsumerState<UserProfilePage> createState() => _UserInfoPageState();
}

class _UserInfoPageState extends ConsumerState<UserProfilePage> {
  final storage = FlutterSecureStorage();
  late AuthRepository _authRepository;
  File? imageCamera;
  Uint8List? imageGallery;
  UserModel? currentUser;

  late TextEditingController usernameController;
  bool isEditing = false;
  late FocusNode usernameFocusNode;

  @override
  void initState() {
    super.initState();

    final keyGenerationService = KeyGenerationService(secureStorage: storage);

    _authRepository = AuthRepository(
      auth: FirebaseAuth.instance,
      firestore: FirebaseFirestore.instance,
      keyGenerationService: keyGenerationService,
      realtime: FirebaseDatabase.instance,
    );

    usernameController = TextEditingController();
    usernameFocusNode = FocusNode();
    _fetchCurrentUser();
  }

  @override
  void dispose() {
    usernameController.dispose();
    usernameFocusNode.dispose();
    super.dispose();
  }

  Future<void> signOut() async {
    try {
      await _authRepository.auth.signOut();
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          Routes.welcome,
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text('Error'),
                content: Text('Failed to sign out: $e'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('OK'),
                  ),
                ],
              ),
        );
      }
    }
  }

  Future<void> _fetchCurrentUser() async {
    final user = await _authRepository.getCurrentUserInfo();
    if (mounted) {
      setState(() {
        currentUser = user;
        usernameController.text = currentUser?.username ?? '';
      });
    }
  }

  Future<void> saveUserDataToFirebase() async {
    String username = usernameController.text;

    if (username.isEmpty) {
      showAllertDialog(context: context, message: 'Please, provide a username');
      return;
    } else if (username.length < 3 || username.length > 20) {
      showAllertDialog(
        context: context,
        message: 'Username must be between 3 and 20 characters',
      );
      return;
    }

    await ref
        .read(authControllerProvider)
        .saveUserInfoToFirestore(
          username: username,
          profileImage:
              imageCamera ?? imageGallery ?? currentUser?.profileImageUrl,
          context: context,
          mounted: mounted,
        );

    if (mounted) {
      setState(() {
        isEditing = false;
      });
    }
  }

  Future<void> deleteUserAccount() async {
    try {
      await _authRepository.deleteUser();
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      if (mounted) {
        Navigator.pushNamed(context, Routes.welcome);
      }
    } catch (e) {
      if (mounted) {
        showAllertDialog(context: context, message: e.toString());
      }
    }
  }

  Future<void> imagePickerTypeBottomSheet() async {
    await showModalBottomSheet(
      context: context,
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ShortHBar(),
            Row(
              children: [
                const SizedBox(width: 20),
                Text(
                  'Profile photo',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
                ),
                const Spacer(),
                CustomIconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icons.close,
                ),
                const SizedBox(width: 15),
              ],
            ),
            Divider(color: context.theme.greyColor!.withValues(alpha: 0.3)),
            const SizedBox(height: 5),
            Row(
              children: [
                const SizedBox(width: 20),
                imagePickerIcon(
                  onTap: pickImageFromCamera,
                  icon: Icons.camera_alt_rounded,
                  text: 'Camera',
                ),
                const SizedBox(width: 15),
                imagePickerIcon(
                  onTap: () async {
                    Navigator.pop(context);
                    final image = await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const ImagePickerPage(),
                      ),
                    );
                    if (image == null) return;
                    setState(() {
                      imageGallery = image;
                      imageCamera = null;
                    });
                  },
                  icon: Icons.photo_camera_back_rounded,
                  text: 'Gallery',
                ),
              ],
            ),
            const SizedBox(height: 15),
          ],
        );
      },
    );
  }

  Future<void> pickImageFromCamera() async {
    Navigator.of(context).pop();
    try {
      final image = await ImagePicker().pickImage(source: ImageSource.camera);
      if (image != null && mounted) {
        setState(() {
          imageCamera = File(image.path);
          imageGallery = null;
        });
      }
    } catch (e) {
      if (mounted) {
        showAllertDialog(context: context, message: e.toString());
      }
    }
  }

  Widget imagePickerIcon({
    required VoidCallback onTap,
    required IconData icon,
    required String text,
  }) {
    return Column(
      children: [
        CustomIconButton(
          onPressed: onTap,
          icon: icon,
          iconColor: Coloors.blueDark,
          minWidth: 50,
          border: Border.all(
            color: context.theme.greyColor!.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        const SizedBox(height: 5),
        Text(text, style: TextStyle(color: context.theme.greyColor)),
      ],
    );
  }

  void toggleEditing() {
    setState(() {
      isEditing = !isEditing;
      if (isEditing) {
        usernameFocusNode.requestFocus();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            GestureDetector(
              onTap: imagePickerTypeBottomSheet,
              child: Container(
                width: 250,
                height: 250,
                padding: const EdgeInsets.all(1),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: context.theme.photoIconBgColor,
                  border: Border.all(
                    color:
                        imageCamera == null && imageGallery == null
                            ? Colors.transparent
                            : context.theme.greyColor!.withValues(alpha: 0.4),
                  ),
                  image:
                      (imageCamera != null ||
                              imageGallery != null ||
                              currentUser?.profileImageUrl != null)
                          ? DecorationImage(
                            fit: BoxFit.cover,
                            image:
                                imageGallery != null
                                    ? MemoryImage(imageGallery!)
                                    : currentUser?.profileImageUrl != null
                                    ? NetworkImage(currentUser!.profileImageUrl)
                                    : FileImage(imageCamera!),
                          )
                          : null,
                ),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 3, right: 3),
                  child: Icon(
                    Icons.add_a_photo,
                    size: 48,
                    color:
                        imageCamera == null &&
                                imageGallery == null &&
                                currentUser?.profileImageUrl == null
                            ? context.theme.photoIconColor
                            : Colors.transparent,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              currentUser?.phoneNumber ?? 'Loading...',
              style: TextStyle(fontSize: 20, color: context.theme.greyColor),
            ),
            Row(
              children: [
                const SizedBox(width: 20),
                Expanded(
                  child: CustomTextField(
                    controller: usernameController,
                    textAlign: TextAlign.left,
                    focusNode: usernameFocusNode,
                    enabled: isEditing,
                    autoFocus: false,
                  ),
                ),
                const SizedBox(width: 10),
                CustomIconButton(
                  icon: isEditing ? Icons.done : Icons.edit,
                  iconColor: context.theme.blueColor,
                  onPressed: toggleEditing,
                ),
                const SizedBox(width: 10),
              ],
            ),
            const CustomListTile(
              title: 'Encryption',
              subTitle:
                  'Messages and calls are end-to-end encrypted, Tap to verify.',
              leading: Icons.lock,
            ),
            const SizedBox(height: 10),
            CustomListTile(
              title: 'Save changes',
              leading: Icons.save,
              onTap: saveUserDataToFirebase,
            ),
            const SizedBox(height: 10),
            ListTile(
              contentPadding: const EdgeInsets.only(left: 25, right: 10),
              leading: const Icon(Icons.block, color: Color(0xFFF15C6D)),
              title: Text(
                'Delete account: ${currentUser?.username ?? 'Loading'}',
                style: const TextStyle(color: Color(0xFFF15C6D)),
              ),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: const Text('Delete Account'),
                      content: const Text(
                        'Are you sure you want to delete your account?',
                      ),
                      actions: <Widget>[
                        TextButton(
                          child: const Text('Cancel'),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        ),
                        TextButton(
                          child: const Text('Delete'),
                          onPressed: () {
                            Navigator.of(context).pop();
                            deleteUserAccount();
                          },
                        ),
                      ],
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 20),
            ListTile(
              contentPadding: const EdgeInsets.only(left: 25, right: 10),
              leading: const Icon(Icons.exit_to_app, color: Colors.blue),
              title: const Text(
                'Sign Out',
                style: TextStyle(color: Colors.blue),
              ),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: const Text('Sign Out'),
                      content: const Text('Are you sure you want to sign out?'),
                      actions: <Widget>[
                        TextButton(
                          child: const Text('Cancel'),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        ),
                        TextButton(
                          child: const Text('Sign Out'),
                          onPressed: () {
                            Navigator.of(context).pop();
                            signOut();
                          },
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
