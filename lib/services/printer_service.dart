import 'dart:convert';
import 'dart:io';
import '../models/order.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PrinterTarget {
  final String ip;
  final int port;
  const PrinterTarget(this.ip, {this.port = 9100});
}

class PrinterService {
  static final PrinterService instance = PrinterService._();
  PrinterService._();

  PrinterTarget? target;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final ip = prefs.getString('printer_ip') ?? '';
    final port = prefs.getInt('printer_port') ?? 9100;
    target = ip.trim().isEmpty ? null : PrinterTarget(ip, port: port);
  }

  Future<void> saveTarget(PrinterTarget? value) async {
    target = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('printer_ip', value?.ip ?? '');
    await prefs.setInt('printer_port', value?.port ?? 9100);
  }

  Future<Map<String, String>> printOrder(RestaurantOrder order) async {
    final result = <String, String>{};
    final current = target;
    if (current == null) {
      result['Impressora'] = 'Simulado (impressora nao configurada)';
      return result;
    }

    try {
      final socket = await Socket.connect(
        current.ip,
        current.port,
        timeout: const Duration(seconds: 4),
      );
      socket.add(_ticketBytes(order));
      await socket.flush();
      await socket.close();
      result['Impressora'] = 'Enviado para ${current.ip}:${current.port}';
    } catch (e) {
      result['Impressora'] = 'Falha: $e';
    }
    return result;
  }

  Future<String> testPrint() async {
    final current = target;
    if (current == null) return 'Informe o IP da impressora primeiro.';
    try {
      final socket = await Socket.connect(current.ip, current.port, timeout: const Duration(seconds: 4));
      final text = '*** TESTE DE IMPRESSAO ***\nGarcom Oliveira\nImpressora configurada com sucesso.\n\n\n';
      socket.add(<int>[0x1B, 0x40, ...latin1.encode(text), 0x1D, 0x56, 0x01]);
      await socket.flush();
      await socket.close();
      return 'Teste enviado para ${current.ip}:${current.port}.';
    } catch (e) {
      return 'Falha no teste: $e';
    }
  }

  List<int> _ticketBytes(RestaurantOrder order) {
    final buffer = StringBuffer();
    buffer.writeln('*** NOVO PEDIDO ***');
    buffer.writeln('MESA ${order.tableNumber}');
    buffer.writeln('Garcom: ${order.waiter}');
    buffer.writeln('Pedido: ${order.id}');
    buffer.writeln('------------------------------');
    for (final item in order.items) {
      buffer.writeln('${item.quantity}x ${item.product.name}');
      if (item.note.trim().isNotEmpty) buffer.writeln('OBS: ${item.note.trim()}');
    }
    buffer.writeln('------------------------------');
    buffer.writeln();
    buffer.writeln();
    buffer.writeln();

    return <int>[0x1B, 0x40, ...latin1.encode(buffer.toString()), 0x1D, 0x56, 0x01];
  }
}
