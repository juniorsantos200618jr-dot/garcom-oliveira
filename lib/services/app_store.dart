import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/order.dart';
import '../models/product.dart';

class AppStore {
  static final AppStore instance = AppStore._();
  AppStore._();

  final List<Product> products = [];
  final List<RestaurantOrder> orders = [];

  static const List<Product> _defaultProducts = [
    Product(id: 'p1', name: 'Picanha', price: 42.90, category: 'Churrascos', sector: Sector.churrasqueira),
    Product(id: 'p2', name: 'Espetinho de carne', price: 12.00, category: 'Churrascos', sector: Sector.churrasqueira),
    Product(id: 'p3', name: 'Frango grelhado', price: 27.90, category: 'Churrascos', sector: Sector.churrasqueira),
    Product(id: 'p4', name: 'Batata frita', price: 18.00, category: 'Porcoes', sector: Sector.cozinha),
    Product(id: 'p5', name: 'Arroz', price: 9.00, category: 'Acompanhamentos', sector: Sector.cozinha),
    Product(id: 'p6', name: 'Feijao', price: 9.00, category: 'Acompanhamentos', sector: Sector.cozinha),
    Product(id: 'p7', name: 'Refrigerante lata', price: 7.00, category: 'Bebidas', sector: Sector.bar),
    Product(id: 'p8', name: 'Suco', price: 8.00, category: 'Bebidas', sector: Sector.bar),
    Product(id: 'p9', name: 'Agua', price: 4.00, category: 'Bebidas', sector: Sector.bar),
  ];

  List<String> get categories {
    final values = products.map((p) => p.category.trim()).where((e) => e.isNotEmpty).toSet().toList();
    values.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return values;
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _loadProducts(prefs);
    _loadOrders(prefs);
  }

  void _loadProducts(SharedPreferences prefs) {
    final raw = prefs.getString('products_v2');
    if (raw == null || raw.isEmpty) {
      products
        ..clear()
        ..addAll(_defaultProducts);
      return;
    }
    try {
      final data = jsonDecode(raw) as List<dynamic>;
      products
        ..clear()
        ..addAll(data.map((e) => Product.fromJson(e as Map<String, dynamic>)));
    } catch (_) {
      products
        ..clear()
        ..addAll(_defaultProducts);
    }
  }

  void _loadOrders(SharedPreferences prefs) {
    final raw = prefs.getString('orders');
    if (raw == null || raw.isEmpty) return;
    try {
      final data = jsonDecode(raw) as List<dynamic>;
      orders
        ..clear()
        ..addAll(data.map((entry) {
          final map = entry as Map<String, dynamic>;
          final items = (map['items'] as List<dynamic>).map((i) {
            final im = i as Map<String, dynamic>;
            final productId = (im['productId'] ?? '') as String;
            Product? product;
            for (final p in products) {
              if (p.id == productId) {
                product = p;
                break;
              }
            }
            product ??= Product(
              id: productId.isEmpty ? 'removido' : productId,
              name: (im['productName'] ?? 'Produto removido') as String,
              price: (im['productPrice'] as num?)?.toDouble() ?? 0,
              category: (im['productCategory'] ?? 'Outros') as String,
              sector: Sector.values[(im['productSector'] as int?) ?? 1],
              active: false,
            );
            return OrderItem(
              product: product,
              quantity: (im['quantity'] as int?) ?? 1,
              note: (im['note'] ?? '') as String,
            );
          }).toList();
          return RestaurantOrder(
            id: map['id'] as String,
            tableNumber: map['tableNumber'] as int,
            waiter: map['waiter'] as String,
            createdAt: DateTime.parse(map['createdAt'] as String),
            items: items,
            status: OrderStatus.values[(map['status'] as int?) ?? 0],
          );
        }));
    } catch (_) {
      // Mantem o app utilizavel mesmo se houver dado antigo/corrompido.
    }
  }

  Future<void> saveProducts() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('products_v2', jsonEncode(products.map((p) => p.toJson()).toList()));
  }

  Future<void> addProduct(Product product) async {
    products.add(product);
    await saveProducts();
  }

  Future<void> updateProduct(Product product) async {
    final index = products.indexWhere((p) => p.id == product.id);
    if (index < 0) return;
    products[index] = product;
    await saveProducts();
  }

  Future<void> deleteProduct(String id) async {
    products.removeWhere((p) => p.id == id);
    await saveProducts();
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    final data = orders.map((order) => {
      'id': order.id,
      'tableNumber': order.tableNumber,
      'waiter': order.waiter,
      'createdAt': order.createdAt.toIso8601String(),
      'status': order.status.index,
      'items': order.items.map((item) => {
        'productId': item.product.id,
        'productName': item.product.name,
        'productPrice': item.product.price,
        'productCategory': item.product.category,
        'productSector': item.product.sector.index,
        'quantity': item.quantity,
        'note': item.note,
      }).toList(),
    }).toList();
    await prefs.setString('orders', jsonEncode(data));
  }

  Future<void> addOrder(RestaurantOrder order) async {
    orders.insert(0, order);
    await save();
  }

  Future<void> setOrderStatus(RestaurantOrder order, OrderStatus status) async {
    order.status = status;
    await save();
  }
}
