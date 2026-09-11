import 'package:flutter/material.dart';
import '../models/order.dart';
import '../models/product.dart';
import '../services/app_store.dart';
import '../services/printer_service.dart';

class OrderScreen extends StatefulWidget {
  final int tableNumber;
  final String waiterName;
  const OrderScreen({
    super.key,
    required this.tableNumber,
    required this.waiterName,
  });

  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  String? selectedCategory;
  final List<OrderItem> cart = [];

  List<Product> get visibleProducts {
    final all = AppStore.instance.products.where((p) => p.active).toList();
    if (selectedCategory == null) return all;
    return all.where((p) => p.category == selectedCategory).toList();
  }

  List<String> get visibleCategories {
    final values = AppStore.instance.products
        .where((p) => p.active)
        .map((p) => p.category)
        .toSet()
        .toList();
    values.sort();
    return values;
  }

  double get total => cart.fold(0, (sum, item) => sum + item.total);

  void _add(Product product) {
    setState(() {
      final existing = cart.where((i) => i.product.id == product.id).firstOrNull;
      if (existing == null) {
        cart.add(OrderItem(product: product));
      } else {
        existing.quantity++;
      }
    });
  }

  Future<void> _editItem(OrderItem item) async {
    final ctrl = TextEditingController(text: item.note);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(item.product.name),
        content: TextField(
          controller: ctrl,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Observacao',
            hintText: 'Ex.: sem cebola, carne bem passada',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(context, ctrl.text), child: const Text('Salvar')),
        ],
      ),
    );
    if (result != null) setState(() => item.note = result);
  }

  Future<void> _send() async {
    if (cart.isEmpty) return;
    final order = RestaurantOrder(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      tableNumber: widget.tableNumber,
      waiter: widget.waiterName,
      createdAt: DateTime.now(),
      items: cart.map((i) => OrderItem(
        product: i.product,
        quantity: i.quantity,
        note: i.note,
      )).toList(),
    );

    await AppStore.instance.addOrder(order);
    final printResult = await PrinterService.instance.printOrder(order);
    if (!mounted) return;

    final text = printResult.entries
        .map((e) => '${e.key.label}: ${e.value}')
        .join('\n');
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pedido enviado'),
        content: Text(text.isEmpty ? 'Pedido salvo.' : text),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Mesa ${widget.tableNumber}')),
      body: Column(
        children: [
          SizedBox(
            height: 56,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              scrollDirection: Axis.horizontal,
              children: [
                ChoiceChip(
                  label: const Text('Todos'),
                  selected: selectedCategory == null,
                  onSelected: (_) => setState(() => selectedCategory = null),
                ),
                const SizedBox(width: 8),
                ...visibleCategories.map((category) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(category),
                    selected: selectedCategory == category,
                    onSelected: (_) => setState(() => selectedCategory = category),
                  ),
                )),
              ],
            ),
          ),
          Expanded(
            child: visibleProducts.isEmpty
                ? const Center(child: Text('Nenhum produto ativo.'))
                : ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: visibleProducts.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final product = visibleProducts[index];
                      return Card(
                        child: ListTile(
                          title: Text(product.name),
                          subtitle: Text('${product.category} • R\$ ${product.price.toStringAsFixed(2)}'),
                          trailing: FilledButton(
                            onPressed: () => _add(product),
                            child: const Text('Adicionar'),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          if (cart.isNotEmpty)
            SafeArea(
              top: false,
              child: Material(
                elevation: 10,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        height: 100,
                        child: ListView.builder(
                          itemCount: cart.length,
                          itemBuilder: (context, index) {
                            final item = cart[index];
                            return ListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              title: Text('${item.quantity}x ${item.product.name}'),
                              subtitle: item.note.isEmpty ? null : Text('Obs: ${item.note}'),
                              onTap: () => _editItem(item),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    onPressed: () => setState(() {
                                      if (item.quantity > 1) {
                                        item.quantity--;
                                      } else {
                                        cart.remove(item);
                                      }
                                    }),
                                    icon: const Icon(Icons.remove_circle_outline),
                                  ),
                                  IconButton(
                                    onPressed: () => setState(() => item.quantity++),
                                    icon: const Icon(Icons.add_circle_outline),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: _send,
                          icon: const Icon(Icons.send),
                          label: Text('Enviar pedido • R\$ ${total.toStringAsFixed(2)}'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

extension FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
