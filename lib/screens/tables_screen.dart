import 'package:flutter/material.dart';
import '../services/app_store.dart';
import 'order_screen.dart';
import 'sector_queue_screen.dart';
import 'settings_screen.dart';

class TablesScreen extends StatefulWidget {
  final String waiterName;
  const TablesScreen({super.key, required this.waiterName});

  @override
  State<TablesScreen> createState() => _TablesScreenState();
}

class _TablesScreenState extends State<TablesScreen> {
  bool _tableOpen(int table) => AppStore.instance.orders.any(
        (o) => o.tableNumber == table && o.status != null,
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Mesas • ${widget.waiterName}'),
        actions: [
          IconButton(
            tooltip: 'Producao',
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SectorQueueScreen()),
              );
              setState(() {});
            },
            icon: const Icon(Icons.receipt_long),
          ),
          IconButton(
            tooltip: 'Configuracoes',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
            icon: const Icon(Icons.settings),
          ),
        ],
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 180,
          mainAxisExtent: 120,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: 20,
        itemBuilder: (context, index) {
          final table = index + 1;
          final open = _tableOpen(table);
          return Card(
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => OrderScreen(
                      tableNumber: table,
                      waiterName: widget.waiterName,
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
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    Row(
                      children: [
                        Icon(open ? Icons.circle : Icons.check_circle_outline, size: 16),
                        const SizedBox(width: 6),
                        Text(open ? 'Com pedido' : 'Livre'),
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
