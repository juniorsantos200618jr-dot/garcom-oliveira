enum Sector { churrasqueira, cozinha, bar }

extension SectorLabel on Sector {
  String get label {
    switch (this) {
      case Sector.churrasqueira:
        return 'Churrasqueira';
      case Sector.cozinha:
        return 'Cozinha';
      case Sector.bar:
        return 'Bar';
    }
  }
}

class Product {
  final String id;
  final String name;
  final double price;
  final String category;
  final Sector sector;
  final bool active;

  const Product({
    required this.id,
    required this.name,
    required this.price,
    required this.category,
    required this.sector,
    this.active = true,
  });

  Product copyWith({
    String? id,
    String? name,
    double? price,
    String? category,
    Sector? sector,
    bool? active,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      category: category ?? this.category,
      sector: sector ?? this.sector,
      active: active ?? this.active,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'price': price,
        'category': category,
        'sector': sector.index,
        'active': active,
      };

  factory Product.fromJson(Map<String, dynamic> map) {
    return Product(
      id: map['id'] as String,
      name: (map['name'] ?? 'Produto') as String,
      price: (map['price'] as num?)?.toDouble() ?? 0,
      category: (map['category'] ?? 'Outros') as String,
      sector: Sector.values[(map['sector'] as int?) ?? 1],
      active: (map['active'] as bool?) ?? true,
    );
  }
}
