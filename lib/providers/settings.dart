import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hustle_stay/main.dart';

class _Settings {
  /// whether dark mode is on
  bool darkMode = false;

  /// the last visited page
  int currentPage = 0;

  /// Introduction screen visisted
  bool introductionScreenVisited = false;

  /// converts setting parameters into a string
  String encode() {
    return json.encode({
      "darkMode": darkMode,
      "currentPage": currentPage,
      "introductionScreenVisited": introductionScreenVisited,
    });
  }

  /// converts string into setting parameters
  void load(String str) {
    final settings = json.decode(str);
    darkMode = settings["darkMode"] ?? false;
    introductionScreenVisited = settings["introductionScreenVisited"] ?? false;
    currentPage = settings["currentPage"] ?? 0;
  }
}

class _SettingsProvider extends StateNotifier<_Settings> {
  /// loading settings on startup
  _SettingsProvider() : super(_Settings()) {
    loadSettings();
  }

  /// loads settings previously stored using shared preferences
  Future<bool> loadSettings() async {
    state.load(prefs!.getString('settings') ?? "{}");
    notifyListeners();
    return true;
  }

  /// saves settings onto the device using shared preferences
  Future<bool> saveSettings() async {
    prefs!.setString('settings', state.encode());
    return true;
  }

  /// deletes previously stored settings on the device
  /// and also reloads the setting parameters
  Future<void> clearSettings() async {
    await prefs!.clear();
    loadSettings();
  }

  /// If watch listeners do not react to changes automatically,
  /// then use this function to notify all watch listeners
  void notifyListeners() {
    saveSettings();
    final _Settings savedSettings = state;
    state = _Settings();
    state = savedSettings;
  }
}

/// use notifier on this object to access the settings class
final settingsProvider = StateNotifierProvider<_SettingsProvider, _Settings>(
    (ref) => _SettingsProvider());
