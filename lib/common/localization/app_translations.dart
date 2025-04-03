import 'package:get/get.dart';
import 'en.dart';
import 'ru.dart';
import 'de.dart';

class AppTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
    'en_US': enUS,
    'ru_RU': ruRU,
    'de_DE': deDE,
  };
}
