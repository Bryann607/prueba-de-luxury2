import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/config.dart';
import '../../core/db.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../mesero/mesero_home.dart';
import '../cocina/cocina_home.dart';
import '../caja/caja_home.dart';
import '../admin/admin_home.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});
  @override
  Widget build(BuildContext context) {
    if (!Config.ok) return const Scaffold(body: Center(child: Padding(padding: EdgeInsets.all(24),
      child: Text('Falta SUPABASE_URL / SUPABASE_ANON_KEY. Ver README.'))));
    return StreamBuilder<AuthState>(stream: db.auth.onAuthStateChange,
      builder: (_, __) => db.auth.currentSession == null ? const LoginPage() : const RoleRouter());
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override State<LoginPage> createState() => _LoginState();
}
class _LoginState extends State<LoginPage> {
  final _e = TextEditingController(), _p = TextEditingController();
  bool _busy = false, _show = false;
  Future<void> _go() async {
    setState(() => _busy = true);
    await run(context, () => db.auth.signInWithPassword(email: _e.text.trim(), password: _p.text));
    if (mounted) setState(() => _busy = false);
  }
  @override
  Widget build(BuildContext context) {
    Widget brand(bool wide) => Container(width: double.infinity, color: lxBrand, padding: EdgeInsets.fromLTRB(24, wide ? 0 : 56, 24, wide ? 0 : 40),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, mainAxisSize: MainAxisSize.min, children: [
        logo(wide ? 140 : 104), const SizedBox(height: 14),
        const Text('Luxury', style: TextStyle(color: Color(0xFFFBF3EA), fontSize: 38, fontWeight: FontWeight.w800)),
        const Text('Restaurante Oriental · Chincha', style: TextStyle(color: Color(0xFFC9B3A8)))]));
    final form = ConstrainedBox(constraints: const BoxConstraints(maxWidth: 400), child: Padding(padding: const EdgeInsets.all(28),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Bienvenido', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
        const SizedBox(height: 6), const Text('Ingresa con tu cuenta de personal. Tu rol se detecta al ingresar.', style: TextStyle(color: lxMuted)),
        const SizedBox(height: 22),
        const Text('Usuario', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: lxMuted)), const SizedBox(height: 6),
        TextField(controller: _e, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(hintText: 'correo@luxury.pe')),
        const SizedBox(height: 16),
        const Text('Contraseña', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: lxMuted)), const SizedBox(height: 6),
        TextField(controller: _p, obscureText: !_show, onSubmitted: (_) => _go(), decoration: InputDecoration(
          suffixIcon: TextButton(onPressed: () => setState(() => _show = !_show), child: Text(_show ? 'Ocultar' : 'Mostrar', style: const TextStyle(color: Color(0xFF94480A), fontWeight: FontWeight.w700))))),
        const SizedBox(height: 24),
        SizedBox(width: double.infinity, child: FilledButton(onPressed: _busy ? null : _go, child: Text(_busy ? 'Ingresando…' : 'Iniciar sesión'))),
        const SizedBox(height: 18),
        const Center(child: Text('Sistema de gestión de ventas y control de insumos', style: TextStyle(color: lxMuted, fontSize: 12), textAlign: TextAlign.center))])));
    return Scaffold(body: LayoutBuilder(builder: (c, b) => b.maxWidth >= 860
      ? Row(children: [Expanded(child: brand(true)), Expanded(child: Center(child: SingleChildScrollView(child: form)))])
      : SingleChildScrollView(child: Column(children: [ClipRRect(borderRadius: const BorderRadius.vertical(bottom: Radius.circular(34)), child: brand(false)), Center(child: form)]))));
  }
}

/// RF01/RNF02: lee usuarios.rol (RLS) y abre la pantalla del rol.
class RoleRouter extends StatelessWidget {
  const RoleRouter({super.key});
  @override
  Widget build(BuildContext context) => FutureBuilder<Map<String, dynamic>?>(
    future: db.from('usuarios').select().eq('id', db.auth.currentUser!.id).maybeSingle(),
    builder: (c, s) {
      if (s.connectionState != ConnectionState.done) return const Scaffold(body: Center(child: CircularProgressIndicator()));
      final u = s.data;
      if (u == null || u['activo'] != true) return const _Bloqueado('Tu usuario no existe en "usuarios" o está inactivo.');
      final n = u['nombre_completo'] as String? ?? '', r = u['rol'] as String;
      switch (r) {
        case 'MESERO': return MeseroHome(nombre: n);
        case 'COCINERO': case 'JEFE_COCINA': return CocinaHome(nombre: n);
        case 'CAJERO': return CajaHome(nombre: n);
        case 'ADMINISTRADOR': case 'GERENTE': return AdminHome(nombre: n, rol: r);
        default: return _Bloqueado('Rol $r sin pantalla.');
      }
    });
}
class _Bloqueado extends StatelessWidget {
  final String m; const _Bloqueado(this.m);
  @override Widget build(BuildContext c) => Scaffold(body: Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [
    Text(m, textAlign: TextAlign.center), const SizedBox(height: 16),
    OutlinedButton(onPressed: () => db.auth.signOut(), child: const Text('Cerrar sesión'))]))));
}
