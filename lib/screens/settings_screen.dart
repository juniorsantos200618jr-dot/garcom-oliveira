import 'package:flutter/material.dart';
import '../services/printer_service.dart';
import 'product_admin_screen.dart';
import 'waiter_admin_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final ipCtrl = TextEditingController();
  final portCtrl = TextEditingController(text: '9100');

  @override
  void initState() {
    super.initState();
    ipCtrl.text = PrinterService.instance.target?.ip ?? '';
    portCtrl.text = (PrinterService.instance.target?.port ?? 9100).toString();
  }

  void _savePrinter() {
    final ip = ipCtrl.text.trim();
    final port = int.tryParse(portCtrl.text.trim()) ?? 9100;
    PrinterService.instance.saveTarget(ip.isEmpty ? null : PrinterTarget(ip, port: port));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Impressora aplicada.')),
    );
  }

  Future<void> _testPrinter() async {
    final message = await PrinterService.instance.testPrint();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Painel administrativo')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.people)),
              title: const Text('Garcons e acessos'),
              subtitle: const Text('Criar nome, usuario e senha de cada garcom.'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const WaiterAdminScreen()),
              ),
            ),
          ),
          Card(
            child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.restaurant_menu)),
              title: const Text('Cardapio'),
              subtitle: const Text('Adicionar, editar, desativar ou apagar itens e precos.'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ProductAdminScreen()),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('Impressora unica', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          const Text('Todos os pedidos saem juntos nesta impressora. Porta padrao: 9100.'),
          const SizedBox(height: 16),
          TextField(
            controller: ipCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'IP da impressora',
              hintText: 'Ex.: 192.168.1.50',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: portCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Porta',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: _savePrinter,
                  icon: const Icon(Icons.save),
                  label: const Text('Salvar'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    _savePrinter();
                    await _testPrinter();
                  },
                  icon: const Icon(Icons.print),
                  label: const Text('Testar'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text('Se o IP estiver vazio, os pedidos continuam salvos e a impressao fica em modo simulado.'),
        ],
      ),
    );
  }
}
