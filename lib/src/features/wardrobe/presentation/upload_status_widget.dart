import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'upload_provider.dart';

class UploadStatusWidget extends ConsumerWidget {
  const UploadStatusWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progressText = ref.watch(uploadProgressProvider);
    
    // Default state if null
    if (progressText == null) return const SizedBox.shrink();

    return Row(
      children: [
        const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            progressText,
            style: const TextStyle(color: Colors.white, fontSize: 16),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
