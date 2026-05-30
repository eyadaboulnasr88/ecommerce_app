class ProductModel {
  final String id;
  final String title;
  final String description;
  final String image;
  final double price;
  final String category;

  ProductModel({
    required this.id,
    required this.title,
    required this.description,
    required this.image,
    required this.price,
    required this.category,
  });

  factory ProductModel.fromJson(
    Map<String, dynamic> json,
    String id,
  ) {
    return ProductModel(
      id: id,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      image: json['image'] ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      category: json['category'] ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'description': description,
        'image': image,
        'price': price,
        'category': category,
      };
}