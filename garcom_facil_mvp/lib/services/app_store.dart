import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/order.dart';
import '../models/product.dart';

class AppStore {
  static final AppStore instance = AppStore._();
  AppStore._();

  final List<Product> products = const [
    Product(id: 'p1', name: 'Picanha', price: 42.90, sector: Sector.churrasqueira),
    Product(id: 'p2', name: 'Espetinho de carne', price: 12.00, sector: Sector.churrasqueira),
    Product(id: 'p3', name: 'Frango grelhado', price: 27.90, sector: Sector.churrasqueira),
    Product(id: 'p4', name: 'Batata frita', price: 18.00, sector: Sector.cozinha),
    Product(id: 'p5', name: 'Arroz', price: 9.00, sector: Sector.cozinha),
    Product(id: 'p6', name: 'Feijao', price: 9.00, sector: Sector.cozinha),
    Product(id: 'p7', name: 'Refrigerante lata', price: 7.00, sector: Sector.bar),
    Product(id: 'p8', name: 'Suco', price: 8.00, sector: Sector.bar),
    Product(id: 'p9', name: 'Agua', price: 4.00, sector: Sector.bar),
  ];

  final List<RestaurantOrder> orders = [];

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
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
            final product = products.firstWhere((p) => p.id == im['productId']);
            return OrderItem(
              product: product,
              quantity: im['quantity'] as int,
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
