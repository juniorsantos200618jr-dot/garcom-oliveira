import 'dart:convert';
import 'dart:io';
import '../models/order.dart';
import '../models/product.dart';

class PrinterTarget {
  final String ip;
  final int port;
  const PrinterTarget(this.ip, {this.port = 9100});
}

class PrinterService {
  static final PrinterService instance = PrinterService._();
  PrinterService._();

  // Troque os IPs pelos IPs reais das impressoras do cliente.
  final Map<Sector, PrinterTarget?> targets = {
    Sector.churrasqueira: null,
    Sector.cozinha: null,
    Sector.bar: null,
  };

  Future<Map<Sector, String>> printOrder(RestaurantOrder order) async {
    final result = <Sector, String>{};

    for (final sector in Sector.values) {
      final items = order.items.where((i) => i.product.sector == sector).toList();
      if (items.isEmpty) continue;

      final target = targets[sector];
      if (target == null) {
        result[sector] = 'Simulado (impressora nao configurada)';
        continue;
      }

      try {
        final socket = await Socket.connect(
          target.ip,
          target.port,
          timeout: const Duration(seconds: 4),
        );
        socket.add(_ticketBytes(order, sector, items));
        await socket.flush();
        await socket.close();
        result[sector] = 'Enviado para ${target.ip}:${target.port}';
      } catch (e) {
        result[sector] = 'Falha: $e';
      }
    }

    return result;
  }

  List<int> _ticketBytes(
    RestaurantOrder order,
    Sector sector,
    List<OrderItem> items,
  ) {
    final buffer = StringBuffer();
    buffer.writeln('*** ${sector.label.toUpperCase()} ***');
    buffer.writeln('MESA ${order.tableNumber}');
    buffer.writeln('Garcom: ${order.waiter}');
    buffer.writeln('Pedido: ${order.id}');
    buffer.writeln('------------------------------');
    for (final item in items) {
      buffer.writeln('${item.quantity}x ${item.product.name}');
      if (item.note.trim().isNotEmpty) {
        buffer.writeln('OBS: ${item.note.trim()}');
      }
    }
    buffer.writeln('------------------------------');
    buffer.writeln();
    buffer.writeln();
    buffer.writeln();

    // ESC/POS basico: inicializa + texto + corte parcial.
    return <int>[
      0x1B, 0x40,
      ...latin1.encode(buffer.toString()),
      0x1D, 0x56, 0x01,
    ];
  }
}
