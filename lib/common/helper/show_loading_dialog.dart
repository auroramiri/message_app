import 'package:flutter/material.dart';
import 'package:message_app/common/extension/custom_theme_extension.dart';
import 'package:message_app/common/utils/coloors.dart';

showLoadingDialog({
  required BuildContext context,
  required String message,
}) async {
  return showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                CircularProgressIndicator(color: Coloors.blueDark),
                SizedBox(width: 20),
                Expanded(
                  child: Text(
                    message,
                    style: TextStyle(
                      fontSize: 15,
                      color: context.theme.greyColor,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    },
  );
}
