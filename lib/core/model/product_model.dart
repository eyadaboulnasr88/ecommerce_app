class ProductModel {
  final String id;
  final String title;
  final dynamic price;
  final String image;
  final String description;

  ProductModel({
    required this.id,
    required this.title,
    required this.price,
    required this.image,
    required this.description,
  });

  factory ProductModel.fromJson(
    Map<String, dynamic> json,
    String id,
  ) {
    return ProductModel(
      id: id,
      title: json['title']?.toString() ?? '',
      price: json['price'],
      image: json['image']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'price': price,
      'image': image,
      'description': description,
    };
  }
}