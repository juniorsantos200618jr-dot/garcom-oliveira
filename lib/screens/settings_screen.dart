import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/printer_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final Map<Sector, TextEditingController> ctrls = {
    for (final sector in Sector.values) sector: TextEditingController(),
  };

  @override
  void initState() {
    super.initState();
    for (final sector in Sector.values) {
      ctrls[sector]!.text = PrinterService.instance.targets[sector]?.ip ?? '';
    }
  }

  void _save() {
    for (final sector in Sector.values) {
      final ip = ctrls[sector]!.text.trim();
      PrinterService.instance.targets[sector] =
          ip.isEmpty ? null : PrinterTarget(ip);
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Configuracao aplicada nesta execucao.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Impressoras')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Informe o IP de cada impressora termica na rede do restaurante. Porta padrao: 9100.',
          ),
          const SizedBox(height: 16),
          ...Sector.values.map((sector) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: TextField(
                  controller: ctrls[sector],
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: '${sector.label} - IP da impressora',
                    hintText: 'Ex.: 192.168.1.50',
                    border: const OutlineInputBorder(),
                  ),
                ),
              )),
          FilledButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.save),
            label: const Text('Salvar'),
          ),
          const SizedBox(height: 16),
          const Text(
            'Enquanto o IP estiver vazio, o pedido e salvo normalmente e a impressao fica em modo simulado.',
          ),
        ],
      ),
    );
  }
}
