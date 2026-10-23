import 'package:flutter/material.dart';
import 'db.dart';
import 'theme.dart';

Widget logo(double s) => ClipRRect(borderRadius: BorderRadius.circular(s * .25),
  child: Image.asset('assets/logo.png', width: s, height: s, errorBuilder: (_, __, ___) =>
    Container(width: s, height: s, color: lxGold, alignment: Alignment.center, child: Text('L', style: TextStyle(fontSize: s * .5, fontWeight: FontWeight.w900)))));

/// Estado → pastilla de color, igual que el prototipo.
class Pill extends StatelessWidget {
  final String estado; const Pill(this.estado, {super.key});
  @override
  Widget build(BuildContext context) {
    late Color bg, fg;
    switch (estado) {
      case 'DISPONIBLE': case 'LISTO': case 'PAGADO': case 'ATENDIDA': case 'REVISADA': case 'BAJA': bg = const Color(0xFFE8F3D4); fg = const Color(0xFF3B6A08);
      case 'OCUPADA': case 'EN_PREPARACION': case 'EN_PROCESO': case 'MEDIA': bg = const Color(0xFFFBE6CC); fg = const Color(0xFF8A4308);
      case 'POR_COBRAR': case 'NUEVA': case 'CANCELADO': case 'CANCELADA': case 'ALTA': bg = const Color(0xFFFCDADB); fg = const Color(0xFFA8121B);
      default: bg = const Color(0xFFFAF6F2); fg = lxMuted;
    }
    final t = estado.replaceAll('_', ' ').toLowerCase();
    return Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3), decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(99)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.circle, size: 8, color: fg), const SizedBox(width: 6),
        Text(t[0].toUpperCase() + t.substring(1), style: TextStyle(color: fg, fontWeight: FontWeight.w700, fontSize: 12))]));
  }
}

class PageHead extends StatelessWidget {
  final String eyebrow, title; final List<Widget> actions;
  const PageHead(this.eyebrow, this.title, {super.key, this.actions = const []});
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: 14), child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(eyebrow.toUpperCase(), style: const TextStyle(fontSize: 11, letterSpacing: 1.4, fontWeight: FontWeight.w700, color: Color(0xFF94480A))),
      Text(title, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: lxInk))])), ...actions]));
}

class NavItem { final IconData icon; final String label; final Widget page; const NavItem(this.icon, this.label, this.page); }

/// Marco común: barra lateral en pantallas anchas (tablet/web), barra inferior en móvil.
class LxShell extends StatefulWidget {
  final String rol, nombre; final List<NavItem> items;
  const LxShell({super.key, required this.rol, required this.nombre, required this.items});
  @override State<LxShell> createState() => _LxShellState();
}
class _LxShellState extends State<LxShell> {
  int _i = 0;
  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (c, b) {
    final page = Padding(padding: const EdgeInsets.all(16), child: widget.items[_i].page);
    if (b.maxWidth < 860) {
      return Scaffold(
        appBar: AppBar(title: Row(children: [logo(28), const SizedBox(width: 10), Text('Luxury · ${widget.rol}')]), actions: [IconButton(icon: const Icon(Icons.logout), onPressed: () => db.auth.signOut())]),
        body: page,
        bottomNavigationBar: NavigationBar(selectedIndex: _i, onDestinationSelected: (i) => setState(() => _i = i),
          destinations: [for (final n in widget.items) NavigationDestination(icon: Icon(n.icon), label: n.label)]));
    }
    return Scaffold(body: Row(children: [
      Container(width: 232, color: lxBrand, padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [logo(44), const SizedBox(width: 10), Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Luxury', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
          Text(widget.rol, style: const TextStyle(color: Color(0xFFC9B3A8), fontSize: 12))])]),
        const SizedBox(height: 24),
        for (var k = 0; k < widget.items.length; k++) Padding(padding: const EdgeInsets.only(bottom: 4), child: Material(
          color: k == _i ? lxGold : Colors.transparent, borderRadius: BorderRadius.circular(12),
          child: ListTile(dense: true, leading: Icon(widget.items[k].icon, color: k == _i ? lxInk : Colors.white70),
            title: Text(widget.items[k].label, style: TextStyle(color: k == _i ? lxInk : Colors.white, fontWeight: FontWeight.w700)),
            onTap: () => setState(() => _i = k)))),
        const Spacer(),
        Text(widget.nombre, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        TextButton.icon(onPressed: () => db.auth.signOut(), icon: const Icon(Icons.logout, size: 18, color: lxGold), label: const Text('Cerrar sesión', style: TextStyle(color: lxGold)))])),
      Expanded(child: page)]));
  });
}

/// Carga una lista de la base y permite recargarla.
class Loader extends StatefulWidget {
  final Future<List<Map<String, dynamic>>> Function() load;
  final Widget Function(BuildContext, List<Map<String, dynamic>>, VoidCallback) builder;
  const Loader({super.key, required this.load, required this.builder});
  @override State<Loader> createState() => _LoaderState();
}
class _LoaderState extends State<Loader> {
  late Future<List<Map<String, dynamic>>> _f = widget.load();
  void _reload() => setState(() => _f = widget.load());
  @override
  Widget build(BuildContext context) => FutureBuilder<List<Map<String, dynamic>>>(future: _f, builder: (c, s) {
    if (s.hasError) return Center(child: Text('Error al leer la base: ${s.error}'));
    if (!s.hasData) return const Center(child: CircularProgressIndicator());
    return widget.builder(c, s.data!, _reload);
  });
}
