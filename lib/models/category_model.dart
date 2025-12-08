class CategoryModel {
  final int id;
  final String nameEn;
  final String nameAr;
  final int? parentId;
  final String? imageUrl;

  const CategoryModel({
    required this.id,
    required this.nameEn,
    required this.nameAr,
    this.parentId,
    this.imageUrl,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] as int,
      nameEn: (json['name_en'] as String?) ?? (json['name'] as String? ?? ''),
      nameAr: json['name_ar'] as String,
      parentId: json['parent_id'] as int?,
      imageUrl: json['image_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name_en': nameEn,
      'name_ar': nameAr,
      'parent_id': parentId,
      'image_url': imageUrl,
    };
  }

  CategoryModel copyWith({
    int? id,
    String? nameEn,
    String? nameAr,
    int? parentId,
    String? imageUrl,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      nameEn: nameEn ?? this.nameEn,
      nameAr: nameAr ?? this.nameAr,
      parentId: parentId ?? this.parentId,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
}
