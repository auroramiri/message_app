// github_update_checker.dart
import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class GitHubUpdateChecker {
  static Future<bool> checkForUpdates() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      final response = await http.get(
        Uri.parse(
          'https://api.github.com/repos/auroramiri/message_app/releases/latest',
        ),
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        final latestVersion = jsonData['tag_name'];

        if (await _isVersionOld(currentVersion, latestVersion)) {
          return true;
        }
      }
    } catch (e) {
      log('Ошибка при проверке обновлений: $e');
    }

    return false;
  }

  static Future<bool> _isVersionOld(
    String currentVersion,
    String latestVersion,
  ) async {
    final currentParts = currentVersion.split('.').map(int.parse).toList();
    final latestParts = latestVersion.split('.').map(int.parse).toList();

    for (var i = 0; i < currentParts.length; i++) {
      if (currentParts[i] < latestParts[i]) {
        return true;
      } else if (currentParts[i] > latestParts[i]) {
        return false;
      }
    }

    return false;
  }

  static void showUpdateDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Доступно обновление'),
          content: const Text('Доступна новая версия приложения. Хотите обновить?'),
          actions: [
            TextButton(
              child: const Text('Отмена'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Обновить'),
              onPressed: () async {
                final result = await canLaunchUrl(
                  Uri.parse('https://github.com/auroramiri/message_app/releases/latest'),
                );

                if (result) {
                  await launchUrl(
                    Uri.parse('https://github.com/auroramiri/message_app/releases/latest'),
                  );
                } else {
                  log('Невозможно открыть браузер');
                }
              },
            ),
          ],
        );
      },
    );
  }
}
