import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:message_app/common/enum/message_type.dart';
import 'package:message_app/common/extension/custom_theme_extension.dart';
import 'package:message_app/common/helper/show_alert_dialog.dart';
import 'package:message_app/common/utils/coloors.dart';
import 'package:message_app/common/widgets/custom_icon_button.dart';
import 'package:message_app/feature/auth/pages/image_picker_page.dart';
import 'package:message_app/feature/chat/controller/chat_controller.dart';

class ChatTextField extends ConsumerStatefulWidget {
  const ChatTextField({
    super.key,
    required this.receiverId,
    required this.scrollController,
  });

  final String receiverId;
  final ScrollController scrollController;

  @override
  ConsumerState<ChatTextField> createState() => _ChatTextFieldState();
}

class _ChatTextFieldState extends ConsumerState<ChatTextField> {
  late TextEditingController messageController;
  File? imageCamera;

  bool isMessageIconEnabled = false;
  double cardHeight = 0;

  void sendImageMessageFromGallery() async {
    final image = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ImagePickerPage()),
    );

    if (image != null) {
      sendFileMessage(image, MessageType.image);
      setState(() => cardHeight = 0);
    }
  }

  void pickImageFromCamera() async {
    if (cardHeight > 0) {
      setState(() => cardHeight = 0);
    }
    try {
      final pickedImage = await ImagePicker().pickImage(
        source: ImageSource.camera,
      );
      if (pickedImage != null) {
        final imageFile = File(pickedImage.path);
        if (await imageFile.exists()) {
          sendFileMessage(imageFile, MessageType.image);
        } else {
          if (!mounted) return;
          showAllertDialog(
            context: context,
            message: 'Error: Image file not found',
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      showAllertDialog(context: context, message: 'Error capturing image: $e');
    }
  }

  void pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        final filePath = result.files.single.path!;
        final file = File(filePath);
        final fileName = result.files.single.name;

        // Check file size - 30MB limit (30 * 1024 * 1024 bytes)
        final fileSize = await file.length();
        final maxSize = 30 * 1024 * 1024; // 30MB in bytes

        if (fileSize > maxSize) {
          if (mounted) {
            showAllertDialog(
              context: context,
              message:
                  'File size exceeds 30MB limit. Please select a smaller file.',
            );
          }
          return;
        }

        sendFileMessage(file, MessageType.file, fileName: fileName);
        setState(() => cardHeight = 0);
      }
    } catch (e) {
      if (!mounted) return;
      showAllertDialog(context: context, message: e.toString());
    }
  }

  void sendFileMessage(
    var file,
    MessageType messageType, {
    String? fileName,
  }) async {
    try {
      if (file == null) {
        if (context.mounted) {
          showAllertDialog(context: context, message: 'Error: File is null');
        }
        return;
      }

      ref
          .read(chatControllerProvider)
          .sendFileMessage(
            context,
            file,
            widget.receiverId,
            messageType,
            fileName: fileName,
          );

      await Future.delayed(const Duration(milliseconds: 500));
      SchedulerBinding.instance.addPostFrameCallback((timeStamp) {
        widget.scrollController.animateTo(
          widget.scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    } catch (e) {
      if (!mounted) return;
      showAllertDialog(context: context, message: e.toString());
    }
  }

  void sendTextMessage() async {
    if (isMessageIconEnabled) {
      ref
          .read(chatControllerProvider)
          .sendTextMessage(
            context: context,
            textMessage: messageController.text,
            receiverId: widget.receiverId,
          );
      messageController.clear();
    }

    await Future.delayed(const Duration(milliseconds: 100));
    SchedulerBinding.instance.addPostFrameCallback((timeStamp) {
      widget.scrollController.animateTo(
        widget.scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  iconWithText({
    required VoidCallback onPressed,
    required IconData icon,
    required String text,
    required Color background,
  }) {
    return Column(
      children: [
        CustomIconButton(
          onPressed: onPressed,
          icon: icon,
          background: background,
          minWidth: 50,
          iconColor: Colors.white,
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

  @override
  void initState() {
    messageController = TextEditingController();
    super.initState();
  }

  @override
  void dispose() {
    messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: cardHeight,
          width: double.maxFinite,
          margin: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: context.theme.receiverChatCardBg,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      iconWithText(
                        onPressed: pickFile,
                        icon: Icons.book,
                        text: 'File',
                        background: const Color(0xFF7F66FE),
                      ),
                      iconWithText(
                        onPressed: pickImageFromCamera,
                        icon: Icons.camera_alt,
                        text: 'Camera',
                        background: const Color(0xFFFE2E74),
                      ),
                      iconWithText(
                        onPressed: sendImageMessageFromGallery,
                        icon: Icons.photo,
                        text: 'Gallery',
                        background: const Color(0xFFC861F9),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(5.0),
          child: Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: messageController,
                  maxLines: 4,
                  minLines: 1,
                  onChanged: (value) {
                    value.isEmpty
                        ? setState(() => isMessageIconEnabled = false)
                        : setState(() => isMessageIconEnabled = true);
                  },
                  decoration: InputDecoration(
                    hintText: 'Message',
                    hintStyle: TextStyle(color: context.theme.greyColor),
                    filled: true,
                    fillColor: context.theme.chatTextFieldBg,
                    isDense: true,
                    border: OutlineInputBorder(
                      borderSide: const BorderSide(
                        style: BorderStyle.none,
                        width: 0,
                      ),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    prefixIcon: Material(
                      color: Colors.transparent,
                      child: CustomIconButton(
                        onPressed: () {},
                        icon: Icons.emoji_emotions_outlined,
                        iconColor: Theme.of(context).listTileTheme.iconColor,
                      ),
                    ),
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        RotatedBox(
                          quarterTurns: 45,
                          child: CustomIconButton(
                            onPressed:
                                () => setState(
                                  () =>
                                      cardHeight == 0
                                          ? cardHeight = 120
                                          : cardHeight = 0,
                                ),
                            icon:
                                cardHeight == 0
                                    ? Icons.attach_file
                                    : Icons.close,
                            iconColor:
                                Theme.of(context).listTileTheme.iconColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 5),
              CustomIconButton(
                onPressed: sendTextMessage,
                icon:
                    isMessageIconEnabled
                        ? Icons.send_outlined
                        : Icons.mic_none_outlined,
                background: Coloors.blueDark,
                iconColor: Colors.white,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
