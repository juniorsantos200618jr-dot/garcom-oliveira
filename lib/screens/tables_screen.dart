import 'package:flutter/material.dart';
import '../models/account.dart';
import '../services/app_store.dart';
import 'login_screen.dart';
import 'order_screen.dart';
import 'sector_queue_screen.dart';
import 'settings_screen.dart';

class TablesScreen extends StatefulWidget {
  final UserAccount account;
  const TablesScreen({super.key, required this.account});

  @override
  State<TablesScreen> createState() => _TablesScreenState();
}

class _TablesScreenState extends State<TablesScreen> {
  bool get isAdmin => widget.account.role == UserRole.admin;

  bool _tableOpen(int table) => AppStore.instance.orders.any(
        (o) => o.tableNumber == table && o.status != null,
      );

  String? _waiterForTable(int table) {
    for (final order in AppStore.instance.orders) {
      if (order.tableNumber == table && order.status != null) return order.waiter;
    }
    return null;
  }

  void _logout() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isAdmin ? 'Mesas • Administrador' : 'Mesas • ${widget.account.name}'),
        actions: [
          if (isAdmin)
            IconButton(
              tooltip: 'Pedidos / producao',
              onPressed: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SectorQueueScreen()),
                );
                setState(() {});
              },
              icon: const Icon(Icons.receipt_long),
            ),
          if (isAdmin)
            IconButton(
              tooltip: 'Painel administrativo',
              onPressed: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                );
                setState(() {});
              },
              icon: const Icon(Icons.admin_panel_settings),
            ),
          IconButton(
            tooltip: 'Sair',
            onPressed: _logout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 190,
          mainAxisExtent: 132,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: 20,
        itemBuilder: (context, index) {
          final table = index + 1;
          final open = _tableOpen(table);
          final waiter = _waiterForTable(table);
          return Card(
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => OrderScreen(
                      tableNumber: table,
                      waiterName: widget.account.name,
                    ),
                  ),
                );
                setState(() {});
              },
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Mesa $table',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(open ? Icons.circle : Icons.check_circle_outline, size: 16),
                            const SizedBox(width: 6),
                            Text(open ? 'Em atendimento' : 'Livre'),
                          ],
                        ),
                        if (open && waiter != null) ...[
                          const SizedBox(height: 4),
                          Text('Garcom: $waiter', maxLines: 1, overflow: TextOverflow.ellipsis),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
