import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:message_app/common/extension/custom_theme_extension.dart';

class ShowDateCard extends StatelessWidget {
  const ShowDateCard({super.key, required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 5,
      ),
      margin: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: context.theme.receiverChatCardBg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        DateFormat.yMMMd().format(date),
      ),
    );
  }
}