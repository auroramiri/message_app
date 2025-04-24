import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:message_app/common/extension/custom_theme_extension.dart';
import 'package:message_app/common/helper/show_alert_dialog.dart';
import 'package:message_app/common/models/user_model.dart';
import 'package:message_app/common/utils/coloors.dart';
import 'package:message_app/common/widgets/custom_icon_button.dart';
import 'package:message_app/common/widgets/short_h_bar.dart';
import 'package:message_app/feature/auth/controller/auth_controller.dart';
import 'package:message_app/feature/auth/pages/image_picker_page.dart';
import 'package:message_app/feature/auth/repository/auth_repository.dart';
import 'package:message_app/feature/auth/widgets/custom_text_field.dart';
import 'package:message_app/feature/chat/widgets/custom_list_tile.dart';

class UserProfilePage extends ConsumerStatefulWidget {
  const UserProfilePage({super.key});

  @override
  ConsumerState<UserProfilePage> createState() => _UserInfoPageState();
}

class _UserInfoPageState extends ConsumerState<UserProfilePage> {
  final AuthRepository _authRepository = AuthRepository(
    auth: FirebaseAuth.instance,
    firestore: FirebaseFirestore.instance,
    realtime: FirebaseDatabase.instance,
  );
  File? imageCamera;
  Uint8List? imageGallery;
  UserModel? currentUser;

  late TextEditingController usernameController;
  bool isEditing = false;
  late FocusNode usernameFocusNode;

  @override
  void initState() {
    usernameController = TextEditingController();
    usernameFocusNode = FocusNode();
    _fetchCurrentUser().then((_) {
      if (mounted) {
        usernameController = TextEditingController(
          text: currentUser?.username ?? '',
        );
      }
    });
    super.initState();
  }

  Future<void> _fetchCurrentUser() async {
    final user = await _authRepository.getCurrentUserInfo();
    if (mounted) {
      setState(() {
        currentUser = user;
      });
    }
  }

  @override
  void dispose() {
    usernameController.dispose();
    usernameFocusNode.dispose();
    super.dispose();
  }

  Future<void> saveUserDataToFirebase() async {
    String username = usernameController.text;

    if (username.isEmpty) {
      return showAllertDialog(
        context: context,
        message: 'Please, provide a username',
      );
    } else if (username.length < 3 || username.length > 20) {
      return showAllertDialog(
        context: context,
        message: 'Username must be between 3 and 20 characters',
      );
    }

    ref
        .read(authControllerProvider)
        .saveUserInfoToFirestore(
          username: username,
          profileImage:
              imageCamera ?? imageGallery ?? currentUser?.profileImageUrl,
          context: context,
          mounted: mounted,
        );

    setState(() {
      isEditing = false;
    });
  }

  Future<void> imagePickerTypeBottomSheet() async {
    await showModalBottomSheet(
      context: context,
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ShortHBar(),
            Row(
              children: [
                SizedBox(width: 20),
                Text(
                  'Profile photo',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
                ),
                Spacer(),
                CustomIconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icons.close,
                ),
                SizedBox(width: 15),
              ],
            ),
            Divider(color: context.theme.greyColor!.withValues(alpha: 0.3)),
            SizedBox(height: 5),
            Row(
              children: [
                SizedBox(width: 20),
                imagePickerIcon(
                  onTap: pickImageFromCamera,
                  icon: Icons.camera_alt_rounded,
                  text: 'Camera',
                ),
                SizedBox(width: 15),
                imagePickerIcon(
                  onTap: () async {
                    Navigator.pop(context);
                    final image = await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => ImagePickerPage(),
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
            SizedBox(height: 15),
          ],
        );
      },
    );
  }

  Future<void> pickImageFromCamera() async {
    Navigator.of(context).pop();
    try {
      final image = await ImagePicker().pickImage(source: ImageSource.camera);
      setState(() {
        imageCamera = File(image!.path);
        imageGallery = null;
      });
    } catch (e) {
      if (!mounted) return;
      showAllertDialog(context: context, message: e.toString());
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
            color: context.theme.greyColor!.withValues(alpha: .2),
            width: 1,
          ),
        ),
        SizedBox(height: 5),
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
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            GestureDetector(
              onTap: imagePickerTypeBottomSheet,
              child: Container(
                width: 250,
                height: 250,
                padding: EdgeInsets.all(1),
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
                                        as ImageProvider
                                    : currentUser?.profileImageUrl != null
                                    ? NetworkImage(currentUser!.profileImageUrl)
                                        as ImageProvider
                                    : FileImage(imageCamera!) as ImageProvider,
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
            SizedBox(height: 20),
            Text(
              currentUser?.phoneNumber ?? 'Loading...',
              style: TextStyle(fontSize: 20, color: context.theme.greyColor),
            ),
            Row(
              children: [
                SizedBox(width: 20),
                Expanded(
                  child: CustomTextField(
                    controller: usernameController,
                    textAlign: TextAlign.left,
                    focusNode: usernameFocusNode,
                    enabled: isEditing,
                    autoFocus: false,
                  ),
                ),
                SizedBox(width: 10),
                CustomIconButton(
                  icon: isEditing ? Icons.done : Icons.edit,
                  iconColor: context.theme.blueColor,
                  onPressed: toggleEditing,
                ),
                SizedBox(width: 20),
              ],
            ),
            const CustomListTile(
              title: 'Encryption',
              subTitle:
                  'Messages and calls are end-to-end encrypted, Tap to verify.',
              leading: Icons.lock,
            ),
            const SizedBox(height: 20),
            CustomListTile(
              title: 'Save changes',
              leading: Icons.save,
              onTap: saveUserDataToFirebase,
            ),
            const SizedBox(height: 20),
            ListTile(
              contentPadding: const EdgeInsets.only(left: 25, right: 10),
              leading: const Icon(Icons.block, color: Color(0xFFF15C6D)),
              title: Text(
                'Delete account:  ${currentUser?.username ?? 'Loading'}',
                style: const TextStyle(color: Color(0xFFF15C6D)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
