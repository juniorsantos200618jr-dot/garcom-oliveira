import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'services/app_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppStore.instance.load();
  runApp(const GarcomFacilApp());
}

class GarcomFacilApp extends StatelessWidget {
  const GarcomFacilApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Garcom Facil',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.indigo,
        inputDecorationTheme: const InputDecorationTheme(filled: true),
      ),
      home: const LoginScreen(),
    );
  }
}
