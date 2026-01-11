
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:style_advisor/src/features/auth/presentation/user_provider.dart';
import 'package:style_advisor/src/features/wardrobe/domain/wardrobe_item.dart';

part 'wardrobe_api_provider.g.dart';

@riverpod
Future<List<WardrobeItem>> wardrobeApi(WardrobeApiRef ref) async {
  final user = ref.watch(userProvider);
  if (user == null) {
    return [];
  }

  final baseUrl = dotenv.env['API_BASE_URL'] ?? '';
  final imageBaseUrl = dotenv.env['IMAGE_BASE_URL']?.trim() ?? '';
  final dio = Dio();

  try {
    final response = await dio.post(
      '$baseUrl/wardrobe/items',
      data: {
        'user_id': user.id,
        'mobile': user.mobile,
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = response.data['data'] ?? [];
      return data.map((json) => WardrobeItem.fromJson(json, imageBaseUrl)).toList();
    } else {
      throw Exception('Failed to load wardrobe items: ${response.statusCode}');
    }
  } catch (e) {
    throw Exception('Error fetching wardrobe items: $e');
  }
}
