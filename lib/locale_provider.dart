import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages the user's manual language override. `null` means "follow the
/// device's system language" (Flutter resolves this automatically via
/// MaterialApp's `supportedLocales` when `locale` is null).
class LocaleProvider extends ChangeNotifier {
  Locale? _locale;

  Locale? get locale => _locale;

  LocaleProvider({Locale? initialLocale}) : _locale = initialLocale;

  void setLocale(Locale? locale) async {
    _locale = locale;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    if (locale == null) {
      await prefs.remove('locale_language_code');
    } else {
      await prefs.setString('locale_language_code', locale.languageCode);
    }
  }
}
