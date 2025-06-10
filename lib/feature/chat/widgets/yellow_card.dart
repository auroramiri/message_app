import 'package:flutter/material.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';
import 'package:message_app/common/extension/custom_theme_extension.dart';

class YellowCard extends StatelessWidget {
  const YellowCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 30),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: context.theme.yellowCardBgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        'end_to_end_encrypted'.tr,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 13,
          color: context.theme.yellowCardTextColor,
        ),
      ),
    );
  }
}
