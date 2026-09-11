import 'product.dart';

enum OrderStatus { pendente, preparando, pronto }

extension OrderStatusLabel on OrderStatus {
  String get label {
    switch (this) {
      case OrderStatus.pendente:
        return 'Pendente';
      case OrderStatus.preparando:
        return 'Preparando';
      case OrderStatus.pronto:
        return 'Pronto';
    }
  }
}

class OrderItem {
  final Product product;
  int quantity;
  String note;

  OrderItem({required this.product, this.quantity = 1, this.note = ''});

  double get total => product.price * quantity;
}

class RestaurantOrder {
  final String id;
  final int tableNumber;
  final String waiter;
  final DateTime createdAt;
  final List<OrderItem> items;
  OrderStatus status;

  RestaurantOrder({
    required this.id,
    required this.tableNumber,
    required this.waiter,
    required this.createdAt,
    required this.items,
    this.status = OrderStatus.pendente,
  });

  double get total => items.fold(0, (sum, item) => sum + item.total);
}
