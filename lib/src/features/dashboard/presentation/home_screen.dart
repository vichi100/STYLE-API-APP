import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../theme/theme_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentMode = ref.watch(themeModeControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Style Advisor'),
        actions: [
          PopupMenuButton<AppThemeMode>(
            initialValue: currentMode,
            icon: const Icon(Icons.color_lens),
            onSelected: (mode) {
              ref.read(themeModeControllerProvider.notifier).setMode(mode);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: AppThemeMode.light,
                child: Text('Light Mode'),
              ),
              const PopupMenuItem(
                value: AppThemeMode.dark,
                child: Text('Standard Dark'),
              ),
              const PopupMenuItem(
                value: AppThemeMode.vibrant,
                child: Text('Vibrant Dark'),
              ),
            ],
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Welcome back!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Navigate to details
              },
              child: const Text('View Recommendations'),
            ),
            const SizedBox(height: 20),
            Text(
              'Current Theme: ${currentMode.name.toUpperCase()}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
