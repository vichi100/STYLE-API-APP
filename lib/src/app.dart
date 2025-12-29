import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'routing/app_router.dart';
import 'theme/app_theme.dart';
import 'theme/theme_provider.dart';

class StyleAdvisorApp extends ConsumerWidget {
  const StyleAdvisorApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goRouter = ref.watch(goRouterProvider);
    final theme = ref.watch(appThemeProvider);
    
    return MaterialApp.router(
      routerConfig: goRouter,
      title: 'Style Advisor',
      debugShowCheckedModeBanner: false,
      theme: theme,
      // We force 'light' mode here because we are manually feeding the detailed
      // ThemeData (which might be dark) into the 'theme' property.
      // This gives us full control without System/OS interference.
      themeMode: ThemeMode.light, 
    );
  }
}
