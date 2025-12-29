import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'app_theme.dart';

part 'theme_provider.g.dart';

enum AppThemeMode {
  light,
  dark,
  vibrant,
}

// Controls the current enum state
@riverpod
class ThemeModeController extends _$ThemeModeController {
  @override
  AppThemeMode build() => AppThemeMode.dark; // Default to Standard Dark

  void setMode(AppThemeMode mode) {
    state = mode;
  }
}

// Returns the actual ThemeData based on the selected mode
@riverpod
ThemeData appTheme(AppThemeRef ref) {
  final mode = ref.watch(themeModeControllerProvider);
  switch (mode) {
    case AppThemeMode.light:
      return AppTheme.lightTheme;
    case AppThemeMode.dark:
      return AppTheme.darkTheme;
    case AppThemeMode.vibrant:
      return AppTheme.vibrantTheme;
  }
}
