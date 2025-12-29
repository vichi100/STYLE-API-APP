import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../theme/theme_provider.dart';

class ChatScreen extends ConsumerWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentMode = ref.watch(themeModeControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kai'),
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
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {},
          ),
        ],
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline, size: 64),
            SizedBox(height: 16),
            Text('Kai ChatBot Interface'),
          ],
        ),
      ),
    );
  }
}
