
class WardrobeItem {
  final String id;
  final String imageUrl;
  final String customCategory;
  final String generalCategory;
  final String? subCategory;
  final String? specificCategory;
  final String? userId;
  final String? tags;
  final List<String>? colors;
  final String? caption;

  const WardrobeItem({
    required this.id,
    required this.imageUrl,
    required this.customCategory,
    required this.generalCategory,
    this.subCategory,
    this.specificCategory,
    this.userId,
    this.tags,
    this.colors,
    this.caption,
  });

  factory WardrobeItem.fromJson(Map<String, dynamic> json, String imageBaseUrl) {
    final relativeUrl = json['image_url'] as String? ?? '';
    final fullUrl = "$imageBaseUrl$relativeUrl";
    
    return WardrobeItem(
      id: json['image_id']?.toString() ?? json['\$id']?.toString() ?? '',
      imageUrl: fullUrl,
      customCategory: json['custom_category'] ?? 'Uncategorized',
      generalCategory: json['general_category'] ?? 'Uncategorized',
      subCategory: json['sub_category'],
      specificCategory: json['specific_category'] ?? json['sub_category'],
      userId: json['user_id'],
      tags: json['tags'],
      colors: (json['colors'] as List<dynamic>?)?.map((e) => e.toString()).toList(),
      caption: json['caption'],
    );
  }

  Map<String, dynamic> toStyleScoreJson(String currentUserId) {
    return {
      "user_id": userId ?? currentUserId,
      "general_category": generalCategory,
      "specific_category": specificCategory ?? subCategory ?? customCategory,
      "custom_category": customCategory,
      "image_id": id,
      "image_url": imageUrl, 
      "tags": tags ?? "",
      "colors": colors ?? [],
      "caption": caption ?? "",
    };
  }
}
