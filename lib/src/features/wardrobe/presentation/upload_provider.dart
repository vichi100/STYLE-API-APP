import 'package:flutter_riverpod/flutter_riverpod.dart';

final isUploadingProvider = StateProvider<bool>((ref) => false);
final uploadProgressProvider = StateProvider<String?>((ref) => null);
final currentTabProvider = StateProvider<int>((ref) => 0);
