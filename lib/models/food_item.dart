class FoodItem {
  final String id;
  final String name;
  final double price;
  final String description;
  final String imageUrl;
  final String category;
  final bool isAvailable;
  final int sortOrder;

  const FoodItem({
    required this.id,
    required this.name,
    required this.price,
    required this.description,
    required this.imageUrl,
    required this.category,
    this.isAvailable = true,
    this.sortOrder = 0,
  });

  String get heroTag => 'food_$id';

  FoodItem copyWith({
    String? id,
    String? name,
    double? price,
    String? description,
    String? imageUrl,
    String? category,
    bool? isAvailable,
    int? sortOrder,
  }) {
    return FoodItem(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      category: category ?? this.category,
      isAvailable: isAvailable ?? this.isAvailable,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  factory FoodItem.fromJson(Map<String, dynamic> json) {
    return FoodItem(
      id: json['id'] as String,
      name: json['name'] as String,
      price: (json['price'] as num).toDouble(),
      description: json['description'] as String,
      imageUrl: (json['image_url'] as String?) ?? (json['imageUrl'] as String? ?? ''),
      category: json['category'] as String,
      isAvailable: (json['is_available'] as bool?) ?? (json['isAvailable'] as bool?) ?? true,
      sortOrder: (json['sort_order'] as int?) ?? (json['sortOrder'] as int?) ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'description': description,
      'image_url': imageUrl,
      'category': category,
      'is_available': isAvailable,
      'sort_order': sortOrder,
    };
  }
}
