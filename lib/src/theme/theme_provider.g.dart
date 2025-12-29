// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'theme_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$appThemeHash() => r'7b279808972e0bb17c6b52d061b19cc1ed6e972a';

/// See also [appTheme].
@ProviderFor(appTheme)
final appThemeProvider = AutoDisposeProvider<ThemeData>.internal(
  appTheme,
  name: r'appThemeProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$appThemeHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AppThemeRef = AutoDisposeProviderRef<ThemeData>;
String _$themeModeControllerHash() =>
    r'03b83fb4ab314e60e6552804fd0b97478d5598a1';

/// See also [ThemeModeController].
@ProviderFor(ThemeModeController)
final themeModeControllerProvider =
    AutoDisposeNotifierProvider<ThemeModeController, AppThemeMode>.internal(
  ThemeModeController.new,
  name: r'themeModeControllerProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$themeModeControllerHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$ThemeModeController = AutoDisposeNotifier<AppThemeMode>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
