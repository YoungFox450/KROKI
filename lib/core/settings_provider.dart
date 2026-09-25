import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final settingsProvider = StateNotifierProvider<SettingsNotifier, AppSettings>((ref) {
  return SettingsNotifier();
});

class AppSettings {
  final bool soundEnabled;
  final bool notificationsEnabled;
  final bool darkMode;
  final bool colorblindMode;
  final bool hapticEnabled;

  AppSettings({
    this.soundEnabled = true,
    this.notificationsEnabled = true,
    this.darkMode = true,
    this.colorblindMode = false,
    this.hapticEnabled = true,
  });

  AppSettings copyWith({
    bool? soundEnabled,
    bool? notificationsEnabled,
    bool? darkMode,
    bool? colorblindMode,
    bool? hapticEnabled,
  }) {
    return AppSettings(
      soundEnabled: soundEnabled ?? this.soundEnabled,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      darkMode: darkMode ?? this.darkMode,
      colorblindMode: colorblindMode ?? this.colorblindMode,
      hapticEnabled: hapticEnabled ?? this.hapticEnabled,
    );
  }
}

class SettingsNotifier extends StateNotifier<AppSettings> {
  SettingsNotifier() : super(AppSettings()) {
    _loadFromPrefs();
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    state = AppSettings(
      soundEnabled: prefs.getBool('sound_enabled') ?? true,
      notificationsEnabled: prefs.getBool('notifications_enabled') ?? true,
      darkMode: prefs.getBool('dark_mode') ?? true,
      colorblindMode: prefs.getBool('colorblind_mode') ?? false,
      hapticEnabled: prefs.getBool('haptic_enabled') ?? true,
    );
  }

  Future<void> toggleSound(bool value) async {
    state = state.copyWith(soundEnabled: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sound_enabled', value);
  }

  Future<void> toggleNotifications(bool value) async {
    state = state.copyWith(notificationsEnabled: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', value);
  }

  Future<void> toggleDarkMode(bool value) async {
    state = state.copyWith(darkMode: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dark_mode', value);
  }

  Future<void> toggleColorblindMode(bool value) async {
    state = state.copyWith(colorblindMode: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('colorblind_mode', value);
  }

  Future<void> toggleHaptic(bool value) async {
    state = state.copyWith(hapticEnabled: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('haptic_enabled', value);
  }
}
