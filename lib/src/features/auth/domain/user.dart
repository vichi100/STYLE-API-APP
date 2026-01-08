class User {
  final String id;
  final String mobile;
  final bool isNewUser;
  final String? name;
  final String? email;
  final String? height;
  final String? weight;
  final String? fullLengthImageId;
  final String? closeUpImageId;
  final int dressCount;
  final int accessoryCount;

  User({
    required this.id,
    required this.mobile,
    this.isNewUser = false,
    this.name,
    this.email,
    this.height,
    this.weight,
    this.fullLengthImageId,
    this.closeUpImageId,
    this.dressCount = 0,
    this.accessoryCount = 0,
  });

  factory User.fromJson(Map<String, dynamic> json, {bool isNewUser = false}) {
    return User(
      id: (json['Id'] ?? json['\$id']) as String, // Handle both existing assumption and new key
      mobile: (json['Mobile'] ?? json['mobile']) as String,
      isNewUser: isNewUser,
      name: json['Name'] as String?,
      email: json['Email'] as String?,
      height: json['Height'] as String?,
      weight: json['Weight'] as String?,
      fullLengthImageId: json['full_lenght_Image_id'] as String?, // Note: user's typo in key
      closeUpImageId: json['close_up_image_id'] as String?,
      dressCount: (json['dress_id_list_count'] as num?)?.toInt() ?? 0,
      accessoryCount: (json['accessory_id_list_count'] as num?)?.toInt() ?? 0,
    );
  }

  bool get missingProfile => fullLengthImageId == null || closeUpImageId == null;
  bool get missingWardrobe => dressCount == 0 || accessoryCount == 0;

  @override
  String toString() {
    return 'User(id: $id, mobile: $mobile, new: $isNewUser, name: $name)';
  }
}
