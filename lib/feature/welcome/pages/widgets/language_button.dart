// lib/feature/welcome/pages/widgets/language_button.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:message_app/common/controllers/language_controller.dart';

class LanguageButton extends StatelessWidget {
  const LanguageButton({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(LanguageController());

    return PopupMenuButton<String>(
      onSelected: (String value) {
        controller.changeLanguage(value);
      },
      itemBuilder: (BuildContext context) {
        return controller.languages.map((language) {
          return PopupMenuItem<String>(
            value: language['code'],
            child: Row(
              children: [
                Obx(
                  () =>
                      controller.currentLanguage.value == language['code']
                          ? const Icon(Icons.check, color: Colors.green)
                          : const SizedBox(width: 24),
                ),
                const SizedBox(width: 10),
                Text(language['name']),
              ],
            ),
          );
        }).toList();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('change_language'.tr),
            const SizedBox(width: 8),
            const Icon(Icons.language),
          ],
        ),
      ),
    );
  }
}
