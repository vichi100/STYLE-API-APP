import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:style_advisor/src/features/wardrobe/domain/wardrobe_item.dart';

part 'style_repository.g.dart';

@riverpod
StyleRepository styleRepository(StyleRepositoryRef ref) {
  return StyleRepository();
}

class StyleRepository {
  final _dio = Dio();

  Future<String> scoreStyle({
    required String mood,
    required WardrobeItem top,
    required WardrobeItem bottom,
    WardrobeItem? layer,
    required String userId,
  }) async {
    final baseUrl = dotenv.env['API_BASE_URL'] ?? '';
    
    final Map<String, dynamic> body = {
      "mood": mood,
      "top": top.toStyleScoreJson(userId),
      "bottom": bottom.toStyleScoreJson(userId),
    };

    if (layer != null) {
      body["layer"] = layer.toStyleScoreJson(userId);
    }

    try {
      final response = await _dio.post(
        // '$baseUrl/style/score',
        // '$baseUrl/rule-style/rule-score',
        // '$baseUrl/semantic/vector-score',
        '$baseUrl/color/color-score',   
        data: body,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        // Assuming response contains a message or score.
        // Adjust based on actual response structure. User didn't specify response format.
        // Assuming { "data": "Score analysis..." } or similar.
        // Returning the stringified data for now or a specific field.
        return response.data.toString();
      } else {
        throw Exception('Failed to score style: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error scoring style: $e');
    }
  }
}
