class Product {
  final int? id;
  final String name;
  final String? description;
  final double price;
  final String? imageUrl;

  Product({
    this.id,
    required this.name,
    this.description,
    required this.price,
    this.imageUrl,
  });

  factory Product.fromJson(Map<String, dynamic> j) => Product(
    id: j['id'],
    name: j['name'] ?? '',
    description: j['description'],
    price: (j['price'] is int)
        ? (j['price'] as int).toDouble()
        : (j['price'] ?? 0.0).toDouble(),
    imageUrl: j['image_url'],
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'price': price.toString(),
    'image_url': imageUrl,
  };
}
