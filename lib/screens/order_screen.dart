import 'package:flutter/material.dart';
import '../models/order.dart';
import '../models/product.dart';
import '../services/app_store.dart';
import '../services/printer_service.dart';

class OrderScreen extends StatefulWidget {
  final int tableNumber;
  final String waiterName;
  final bool isAdmin;

  const OrderScreen({
    super.key,
    required this.tableNumber,
    required this.waiterName,
    required this.isAdmin,
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
      items: cart
          .map((i) => OrderItem(
                product: i.product,
                quantity: i.quantity,
                note: i.note,
              ))
          .toList(),
    );

    await AppStore.instance.addOrder(order);
    final printResult = await PrinterService.instance.printOrder(order);
    if (!mounted) return;

    setState(() => cart.clear());

    final text = printResult.entries.map((e) => '${e.key}: ${e.value}').join('\n');
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
    if (mounted) setState(() {});
  }

  Future<void> _showPreAccount() async {
    final orders = AppStore.instance.openOrdersForTable(widget.tableNumber);
    final totalBill = AppStore.instance.openTableTotal(widget.tableNumber);

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Pre-conta • Mesa ${widget.tableNumber}'),
        content: SizedBox(
          width: 480,
          child: orders.isEmpty
              ? const Text('Ainda nao ha pedidos lancados nesta mesa.')
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('Garcom: ${AppStore.instance.openTableWaiter(widget.tableNumber) ?? widget.waiterName}'),
                      const SizedBox(height: 12),
                      ...orders.expand((order) => order.items.map((item) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('${item.quantity}x ${item.product.name}'),
                                      if (item.note.isNotEmpty)
                                        Text('Obs: ${item.note}', style: Theme.of(context).textTheme.bodySmall),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text('R\$ ${item.total.toStringAsFixed(2)}'),
                              ],
                            ),
                          ))),
                      const Divider(height: 24),
                      Text(
                        'TOTAL: R\$ ${totalBill.toStringAsFixed(2)}',
                        textAlign: TextAlign.right,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Voltar')),
          if (widget.isAdmin && orders.isNotEmpty)
            FilledButton.icon(
              icon: const Icon(Icons.check_circle),
              label: const Text('Fechar conta'),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: dialogContext,
                  builder: (confirmContext) => AlertDialog(
                    title: const Text('Fechar conta?'),
                    content: Text(
                      'Mesa ${widget.tableNumber}\nTotal: R\$ ${totalBill.toStringAsFixed(2)}\n\nAo confirmar, a mesa sera liberada.',
                    ),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(confirmContext, false), child: const Text('Cancelar')),
                      FilledButton(onPressed: () => Navigator.pop(confirmContext, true), child: const Text('Confirmar')),
                    ],
                  ),
                );
                if (confirm != true) return;
                await AppStore.instance.closeTable(widget.tableNumber);
                if (!mounted) return;
                Navigator.pop(dialogContext);
                Navigator.pop(context);
              },
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final preAccountTotal = AppStore.instance.openTableTotal(widget.tableNumber);

    return Scaffold(
      appBar: AppBar(
        title: Text('Mesa ${widget.tableNumber}'),
        actions: [
          IconButton(
            tooltip: 'Pre-conta',
            onPressed: _showPreAccount,
            icon: const Icon(Icons.receipt),
          ),
        ],
      ),
      body: Column(
        children: [
          if (preAccountTotal > 0)
            Material(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: InkWell(
                onTap: _showPreAccount,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    children: [
                      const Icon(Icons.receipt_long),
                      const SizedBox(width: 8),
                      const Expanded(child: Text('Ver pre-conta')),
                      Text(
                        'R\$ ${preAccountTotal.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ),
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
