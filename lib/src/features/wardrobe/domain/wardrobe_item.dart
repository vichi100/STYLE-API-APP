
class WardrobeItem {
  final String id;
  final String imageUrl;
  final String customCategory;
  final String generalCategory;
  final String? subCategory;

  const WardrobeItem({
    required this.id,
    required this.imageUrl,
    required this.customCategory,
    required this.generalCategory,
    this.subCategory,
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
    );
  }
}
