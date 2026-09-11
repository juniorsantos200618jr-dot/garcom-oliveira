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
  final Sector sector;

  const Product({
    required this.id,
    required this.name,
    required this.price,
    required this.sector,
  });
}
