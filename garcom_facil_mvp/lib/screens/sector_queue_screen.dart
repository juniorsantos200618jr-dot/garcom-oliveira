import 'package:flutter/material.dart';
import '../models/order.dart';
import '../models/product.dart';
import '../services/app_store.dart';

class SectorQueueScreen extends StatefulWidget {
  const SectorQueueScreen({super.key});

  @override
  State<SectorQueueScreen> createState() => _SectorQueueScreenState();
}

class _SectorQueueScreenState extends State<SectorQueueScreen> {
  Sector sector = Sector.churrasqueira;

  @override
  Widget build(BuildContext context) {
    final orders = AppStore.instance.orders
        .where((o) => o.items.any((i) => i.product.sector == sector))
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Fila de producao')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: SegmentedButton<Sector>(
              segments: Sector.values
                  .map((s) => ButtonSegment(value: s, label: Text(s.label)))
                  .toList(),
              selected: {sector},
              onSelectionChanged: (value) => setState(() => sector = value.first),
            ),
          ),
          Expanded(
            child: orders.isEmpty
                ? const Center(child: Text('Nenhum pedido neste setor.'))
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    itemCount: orders.length,
                    itemBuilder: (context, index) {
                      final order = orders[index];
                      final items = order.items.where((i) => i.product.sector == sector).toList();
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Mesa ${order.tableNumber}',
                                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  Chip(label: Text(order.status.label)),
                                ],
                              ),
                              Text('Garcom: ${order.waiter}'),
                              const Divider(),
                              ...items.map((item) => Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 3),
                                    child: Text(
                                      '${item.quantity}x ${item.product.name}${item.note.isEmpty ? '' : ' — ${item.note}'}',
                                    ),
                                  )),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                children: [
                                  OutlinedButton(
                                    onPressed: () async {
                                      await AppStore.instance.setOrderStatus(order, OrderStatus.preparando);
                                      setState(() {});
                                    },
                                    child: const Text('Preparando'),
                                  ),
                                  FilledButton(
                                    onPressed: () async {
                                      await AppStore.instance.setOrderStatus(order, OrderStatus.pronto);
                                      setState(() {});
                                    },
                                    child: const Text('Pronto'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
