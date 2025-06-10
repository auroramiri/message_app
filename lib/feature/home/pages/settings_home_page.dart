import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:message_app/feature/welcome/pages/widgets/language_button.dart';

// Define a provider to manage the theme mode
final themeModeProvider = StateProvider<ThemeMode>((ref) {
  return ThemeMode.system; // Default to system theme
});

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    void toggleTheme() {
      final currentThemeMode = ref.read(themeModeProvider);
      final newThemeMode =
          currentThemeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
      ref.read(themeModeProvider.notifier).state = newThemeMode;
    }

    return Scaffold(
      appBar: AppBar(title: Text('app_title'.tr)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('settings'.tr, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 20),
            const LanguageButton(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: toggleTheme,
        child: Icon(
          ref.watch(themeModeProvider) == ThemeMode.dark
              ? Icons.wb_sunny
              : Icons.nightlight_round,
        ),
      ),
    );
  }
}
