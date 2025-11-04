// lib/models/service.dart
class Service {
  final String id;
  final String name;
  final String category;
  final double fixedPrice;
  final String? description;
  final String? imageUrl;

  Service({
    required this.id,
    required this.name,
    required this.category,
    required this.fixedPrice,
    this.description,
    this.imageUrl,
  });

  factory Service.fromMap(Map<String, dynamic> map) {
    return Service(
      id: map['id'],
      name: map['name'],
      category: map['category'],
      fixedPrice: map['fixed_price'].toDouble(),
      description: map['description'],
      imageUrl: map['image_url'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'category': category,
      'fixed_price': fixedPrice,
      'description': description,
      'image_url': imageUrl,
    };
  }
}