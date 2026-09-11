import 'package:flutter/material.dart';
import '../models/account.dart';
import '../services/app_store.dart';

class WaiterAdminScreen extends StatefulWidget {
  const WaiterAdminScreen({super.key});

  @override
  State<WaiterAdminScreen> createState() => _WaiterAdminScreenState();
}

class _WaiterAdminScreenState extends State<WaiterAdminScreen> {
  List<UserAccount> get waiters => AppStore.instance.accounts.where((a) => a.role == UserRole.garcom).toList();

  Future<void> _edit([UserAccount? account]) async {
    final name = TextEditingController(text: account?.name ?? '');
    final username = TextEditingController(text: account?.username ?? '');
    final password = TextEditingController(text: account?.password ?? '');
    bool active = account?.active ?? true;
    bool hidePassword = true;

    final result = await showDialog<UserAccount>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(account == null ? 'Criar acesso do garcom' : 'Editar garcom'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: name, decoration: const InputDecoration(labelText: 'Nome do garcom')),
                const SizedBox(height: 10),
                TextField(controller: username, autocorrect: false, decoration: const InputDecoration(labelText: 'Usuario para entrar')),
                const SizedBox(height: 10),
                TextField(
                  controller: password,
                  obscureText: hidePassword,
                  decoration: InputDecoration(
                    labelText: 'Senha',
                    suffixIcon: IconButton(
                      onPressed: () => setDialogState(() => hidePassword = !hidePassword),
                      icon: Icon(hidePassword ? Icons.visibility : Icons.visibility_off),
                    ),
                  ),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Acesso ativo'),
                  value: active,
                  onChanged: (v) => setDialogState(() => active = v),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
            FilledButton(
              onPressed: () {
                if (name.text.trim().isEmpty || username.text.trim().isEmpty || password.text.isEmpty) return;
                Navigator.pop(
                  context,
                  UserAccount(
                    id: account?.id ?? 'garcom-${DateTime.now().millisecondsSinceEpoch}',
                    name: name.text.trim(),
                    username: username.text.trim(),
                    password: password.text,
                    role: UserRole.garcom,
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
    final error = account == null
        ? await AppStore.instance.addWaiter(result)
        : await AppStore.instance.updateWaiter(result);
    if (!mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    } else {
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Acesso salvo.')));
    }
  }

  Future<void> _delete(UserAccount account) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir acesso?'),
        content: Text('O garcom ${account.name} nao conseguira mais entrar no app.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Excluir')),
        ],
      ),
    );
    if (ok != true) return;
    await AppStore.instance.deleteWaiter(account.id);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Garcons e acessos')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _edit(),
        icon: const Icon(Icons.person_add),
        label: const Text('Novo garcom'),
      ),
      body: waiters.isEmpty
          ? const Center(child: Text('Nenhum garcom cadastrado.\nToque em "Novo garcom" para criar o primeiro.', textAlign: TextAlign.center))
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 90),
              itemCount: waiters.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final a = waiters[index];
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(child: Icon(a.active ? Icons.person : Icons.person_off)),
                    title: Text(a.name),
                    subtitle: Text('Usuario: ${a.username} • ${a.active ? 'Ativo' : 'Desativado'}'),
                    onTap: () => _edit(a),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'edit') _edit(a);
                        if (value == 'delete') _delete(a);
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'edit', child: Text('Editar')),
                        PopupMenuItem(value: 'delete', child: Text('Excluir')),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
