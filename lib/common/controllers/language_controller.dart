// lib/core/controllers/language_controller.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageController extends GetxController {
  static LanguageController get to => Get.find();

  final RxString currentLanguage = 'en_US'.obs;

  final List<Map<String, dynamic>> languages = [
    {'name': 'English', 'locale': const Locale('en', 'US'), 'code': 'en_US'},
    {'name': 'Русский', 'locale': const Locale('ru', 'RU'), 'code': 'ru_RU'},
    {'name': 'Deutsch', 'locale': const Locale('de', 'DE'), 'code': 'de_DE'},
  ];

  @override
  void onInit() {
    super.onInit();
    loadSavedLanguage();
  }

  Future<void> loadSavedLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLanguage = prefs.getString('language') ?? 'en_US';
    changeLanguage(savedLanguage);
  }

  // Change language
  void changeLanguage(String languageCode) {
    final locale =
        languages.firstWhere(
              (element) => element['code'] == languageCode,
              orElse: () => languages.first,
            )['locale']
            as Locale;

    Get.updateLocale(locale);
    currentLanguage.value = languageCode;
    saveLanguage(languageCode);
  }

  Future<void> saveLanguage(String languageCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', languageCode);
  }
}
