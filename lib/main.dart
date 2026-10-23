import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/config.dart';
import 'core/theme.dart';
import 'features/auth/auth_gate.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Config.ok)
    await Supabase.initialize(
        url: Config.supabaseUrl, anonKey: Config.supabaseAnonKey);
  runApp(const LuxuryApp());
}

class LuxuryApp extends StatelessWidget {
  const LuxuryApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
      title: 'Luxury',
      debugShowCheckedModeBanner: false,
      theme: luxuryTheme,
      home: const AuthGate());
}
