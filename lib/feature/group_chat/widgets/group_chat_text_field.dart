import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';
import 'package:image_picker/image_picker.dart';
import 'package:message_app/common/enum/message_type.dart';
import 'package:message_app/common/extension/custom_theme_extension.dart';
import 'package:message_app/common/helper/show_alert_dialog.dart';
import 'package:message_app/common/utils/coloors.dart';
import 'package:message_app/common/widgets/custom_icon_button.dart';
import 'package:message_app/feature/auth/pages/image_picker_page.dart';
import 'package:message_app/feature/group_chat/controllers/group_chat_controller.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

class GroupChatTextField extends ConsumerStatefulWidget {
  const GroupChatTextField({
    super.key,
    required this.groupId,
    required this.scrollController,
  });

  final String groupId;
  final ScrollController scrollController;

  @override
  ConsumerState<GroupChatTextField> createState() => _GroupChatTextFieldState();
}

class _GroupChatTextFieldState extends ConsumerState<GroupChatTextField> {
  late TextEditingController messageController;
  File? imageCamera;
  bool isMessageIconEnabled = false;
  double cardHeight = 0;

  final recorder = AudioRecorder();
  bool isRecording = false;

  void recordAudio() async {
    if (kIsWeb) {
      showAllertDialog(
        context: context,
        message: "audio_recording_not_supported".tr,
      );
      return;
    }
    try {
      if (isRecording) {
        final path = await recorder.stop();
        if (path != null) {
          final audioFile = File(path);
          sendFileMessage(audioFile, MessageType.audio);
        }
      } else {
        if (await recorder.hasPermission()) {
          final directory = await getApplicationDocumentsDirectory();
          final path =
              '${directory.path}/audio_${DateTime.now().millisecondsSinceEpoch}.mp3';
          await recorder.start(const RecordConfig(), path: path);
        } else {
          if (mounted) {
            showAllertDialog(
              context: context,
              message: "error_recording_audio".tr,
            );
          }
        }
      }
      setState(() {
        isRecording = !isRecording;
      });
    } catch (e) {
      if (mounted) {
        showAllertDialog(
          context: context,
          message: '${'error_recording_audio'.tr}$e',
        );
      }
    }
  }

  void sendImageMessageFromGallery() async {
    try {
      final image = await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ImagePickerPage()),
      );

      if (image != null) {
        sendFileMessage(image, MessageType.image);
        setState(() => cardHeight = 0);
      }
    } catch (e) {
      if (!mounted) return;
      showAllertDialog(
        context: context,
        message: '${'error_selecting_image'.tr}$e',
      );
    }
  }

  void sendVideoMessageFromGallery() async {
    try {
      final picker = ImagePicker();
      final pickedVideo = await picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 10),
      );

      if (pickedVideo != null) {
        final videoFile = File(pickedVideo.path);
        final fileSize = await videoFile.length();
        final maxSize = 50 * 1024 * 1024;

        if (fileSize > maxSize) {
          if (mounted) {
            showAllertDialog(
              context: context,
              message: 'video_size_exceeds_limit'.tr,
            );
          }
          return;
        }

        sendFileMessage(videoFile, MessageType.video);
        setState(() => cardHeight = 0);
      }
    } catch (e) {
      if (!mounted) return;
      showAllertDialog(
        context: context,
        message: '${'error_selecting_video'.tr}$e',
      );
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
            message: 'error_image_not_found'.tr,
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      showAllertDialog(
        context: context,
        message: '${'error_capturing_image'.tr}$e',
      );
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

        final fileSize = await file.length();
        final maxSize = 30 * 1024 * 1024;

        if (fileSize > maxSize) {
          if (mounted) {
            showAllertDialog(
              context: context,
              message: 'file_size_exceeds_limit'.tr,
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
    File file,
    MessageType messageType, {
    String? fileName,
  }) async {
    try {
      await ref
          .read(groupChatControllerProvider)
          .sendGroupMessage(
            groupId: widget.groupId,
            message: fileName ?? file.path.split('/').last,
            messageType: messageType,
            file: file,
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
      await ref
          .read(groupChatControllerProvider)
          .sendGroupMessage(
            groupId: widget.groupId,
            message: messageController.text,
            messageType: MessageType.text,
          );
      messageController.clear();
    } else if (isRecording) {
      await recorder.stop();
      setState(() {
        isRecording = false;
      });
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

  Widget _buildRecordingIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.red,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.mic, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          Text('recording'.tr, style: TextStyle(color: Colors.white)),
        ],
      ),
    );
  }

  Widget iconWithText({
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
                        text: 'file'.tr,
                        background: const Color(0xFF7F66FE),
                      ),
                      iconWithText(
                        onPressed: pickImageFromCamera,
                        icon: Icons.camera_alt,
                        text: 'camera'.tr,
                        background: const Color(0xFFFE2E74),
                      ),
                      iconWithText(
                        onPressed: sendImageMessageFromGallery,
                        icon: Icons.photo,
                        text: 'gallery'.tr,
                        background: const Color(0xFFC861F9),
                      ),
                      iconWithText(
                        onPressed: sendVideoMessageFromGallery,
                        icon: Icons.movie,
                        text: 'video'.tr,
                        background: const Color(0xFFC861F9),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        if (isRecording) _buildRecordingIndicator(),
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
                    setState(() => isMessageIconEnabled = value.isNotEmpty);
                  },
                  decoration: InputDecoration(
                    hintText: 'message'.tr,
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
                onPressed: isMessageIconEnabled ? sendTextMessage : recordAudio,
                icon:
                    isMessageIconEnabled
                        ? Icons.send_outlined
                        : isRecording
                        ? Icons.stop
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
