import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/app_store.dart';

class ProductAdminScreen extends StatefulWidget {
  const ProductAdminScreen({super.key});

  @override
  State<ProductAdminScreen> createState() => _ProductAdminScreenState();
}

class _ProductAdminScreenState extends State<ProductAdminScreen> {
  String? selectedCategory;

  List<Product> get visibleProducts {
    final all = [...AppStore.instance.products];
    all.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    if (selectedCategory == null) return all;
    return all.where((p) => p.category == selectedCategory).toList();
  }

  Future<void> _openEditor([Product? product]) async {
    final nameCtrl = TextEditingController(text: product?.name ?? '');
    final priceCtrl = TextEditingController(
      text: product == null ? '' : product.price.toStringAsFixed(2).replaceAll('.', ','),
    );
    final categoryCtrl = TextEditingController(text: product?.category ?? '');
    var sector = product?.sector ?? Sector.cozinha;
    var active = product?.active ?? true;

    final result = await showDialog<Product>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(product == null ? 'Adicionar produto' : 'Editar produto'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Nome',
                    hintText: 'Ex.: Coca-Cola 2L',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: priceCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Preco',
                    prefixText: 'R\$ ',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: categoryCtrl,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Categoria',
                    hintText: 'Ex.: Bebidas, Churrascos, Porcoes',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<Sector>(
                  value: sector,
                  decoration: const InputDecoration(
                    labelText: 'Vai imprimir em',
                    border: OutlineInputBorder(),
                  ),
                  items: Sector.values
                      .map((s) => DropdownMenuItem(value: s, child: Text(s.label)))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) setDialogState(() => sector = value);
                  },
                ),
                const SizedBox(height: 6),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Produto ativo'),
                  subtitle: const Text('Desative para esconder sem apagar.'),
                  value: active,
                  onChanged: (value) => setDialogState(() => active = value),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
            FilledButton(
              onPressed: () {
                final name = nameCtrl.text.trim();
                final category = categoryCtrl.text.trim();
                final price = double.tryParse(priceCtrl.text.trim().replaceAll(',', '.'));
                if (name.isEmpty || category.isEmpty || price == null || price < 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Preencha nome, preco e categoria corretamente.')),
                  );
                  return;
                }
                Navigator.pop(
                  context,
                  Product(
                    id: product?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
                    name: name,
                    price: price,
                    category: category,
                    sector: sector,
                    active: active,
                  ),
                );
              },
              child: const Text('Salvar'),
            ),
          ],
        ),
      ),
    );

    if (result == null) return;
    if (product == null) {
      await AppStore.instance.addProduct(result);
    } else {
      await AppStore.instance.updateProduct(result);
    }
    if (mounted) setState(() {});
  }

  Future<void> _delete(Product product) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Apagar produto?'),
        content: Text('Deseja apagar "${product.name}" do cardapio?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Apagar')),
        ],
      ),
    );
    if (confirm != true) return;
    await AppStore.instance.deleteProduct(product.id);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final categories = AppStore.instance.categories;
    if (selectedCategory != null && !categories.contains(selectedCategory)) {
      selectedCategory = null;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Editar cardapio')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(),
        icon: const Icon(Icons.add),
        label: const Text('Adicionar'),
      ),
      body: Column(
        children: [
          SizedBox(
            height: 58,
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
                ...categories.map((category) => Padding(
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
                ? const Center(child: Text('Nenhum produto nesta categoria.'))
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 90),
                    itemCount: visibleProducts.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 6),
                    itemBuilder: (context, index) {
                      final product = visibleProducts[index];
                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            child: Icon(product.active ? Icons.restaurant_menu : Icons.visibility_off),
                          ),
                          title: Text(
                            product.name,
                            style: TextStyle(
                              decoration: product.active ? null : TextDecoration.lineThrough,
                            ),
                          ),
                          subtitle: Text(
                            '${product.category} • R\$ ${product.price.toStringAsFixed(2)}\nImprime: ${product.sector.label}',
                          ),
                          isThreeLine: true,
                          onTap: () => _openEditor(product),
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) async {
                              if (value == 'edit') await _openEditor(product);
                              if (value == 'toggle') {
                                await AppStore.instance.updateProduct(product.copyWith(active: !product.active));
                                if (mounted) setState(() {});
                              }
                              if (value == 'delete') await _delete(product);
                            },
                            itemBuilder: (_) => [
                              const PopupMenuItem(value: 'edit', child: Text('Editar')),
                              PopupMenuItem(
                                value: 'toggle',
                                child: Text(product.active ? 'Desativar' : 'Ativar'),
                              ),
                              const PopupMenuItem(value: 'delete', child: Text('Apagar')),
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
