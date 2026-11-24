class ProductModel {
  final int? productId;
  final String name;
  final int? categoryId;
  final double price;
  final int stock;
  final bool active;

  ProductModel({
    this.productId,
    required this.name,
    this.categoryId,
    required this.price,
    required this.stock,
    required this.active,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      productId: json['productId'] as int?,
      name: json['name'] as String? ?? 'Sin nombre',
      categoryId: json['categoryId'] as int?,
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      stock: json['stock'] as int? ?? 0,
      active: json['active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'name': name,
      'categoryId': categoryId,
      'price': price,
      'stock': stock,
      'active': active,
    };
  }
}
