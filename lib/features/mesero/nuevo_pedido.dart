import 'package:flutter/material.dart';
import '../../core/db.dart';

/// RF09 + RF12: registra el pedido con detalle y muestra la descripción del platillo.
class NuevoPedido extends StatefulWidget {
  final Map<String, dynamic> mesa; const NuevoPedido({super.key, required this.mesa});
  @override State<NuevoPedido> createState() => _S();
}
class _S extends State<NuevoPedido> {
  final Map<int, int> _cart = {}; final Map<int, String> _obs = {};
  int _comensales = 2, _cat = 0; bool _busy = false;
  late final Future<List<dynamic>> _f = Future.wait([
    db.from('categorias').select().eq('activa', true).order('orden'),
    db.from('platillos').select().eq('activo', true).order('nombre')]);

  Future<void> _enviar() async {
    setState(() => _busy = true);
    // VERIFICAR en Supabase el formato exacto de p_items de crear_pedido.
    final items = [for (final e in _cart.entries) {'platillo_id': e.key, 'cantidad': e.value, 'observaciones': _obs[e.key] ?? ''}];
    final ok = await run(context, () => db.rpc('crear_pedido', params: {
      'p_mesa_id': widget.mesa['id'], 'p_comensales': _comensales, 'p_items': items}), ok: 'Pedido enviado a cocina');
    if (mounted) { setState(() => _busy = false); if (ok) Navigator.pop(context); }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<List<dynamic>>(future: _f, builder: (c, s) {
    if (s.hasError) return Scaffold(appBar: AppBar(), body: Center(child: Text('${s.error}')));
    if (!s.hasData) return Scaffold(appBar: AppBar(), body: const Center(child: CircularProgressIndicator()));
    final cats = (s.data![0] as List).cast<Map<String, dynamic>>(), pl = (s.data![1] as List).cast<Map<String, dynamic>>();
    final byId = {for (final p in pl) p['id'] as int: p};
    final vis = cats.isEmpty ? <Map<String, dynamic>>[] : pl.where((p) => p['categoria_id'] == cats[_cat]['id']).toList();
    final total = _cart.entries.fold<num>(0, (a, e) => a + e.value * (byId[e.key]!['precio'] as num));
    return Scaffold(
      appBar: AppBar(title: Text('Mesa ${widget.mesa['numero']} · Nuevo pedido')),
      body: Column(children: [
        SizedBox(height: 56, child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.all(8), children: [
          for (var i = 0; i < cats.length; i++) Padding(padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(label: Text(cats[i]['nombre']), selected: i == _cat, onSelected: (_) => setState(() => _cat = i)))])),
        Expanded(child: ListView(children: [for (final p in vis) ListTile(
          enabled: p['agotado'] != true,
          title: Text(p['nombre']), subtitle: Text('${p['descripcion'] ?? ''}${p['agotado'] == true ? '  · AGOTADO' : ''}'),
          trailing: Row(mainAxisSize: MainAxisSize.min, children: [
            Text(soles(p['precio'])),
            IconButton(icon: const Icon(Icons.remove_circle_outline), onPressed: (_cart[p['id']] ?? 0) == 0 ? null : () => setState(() { final q = _cart[p['id']]! - 1; if (q == 0) { _cart.remove(p['id']); } else { _cart[p['id']] = q; } })),
            Text('${_cart[p['id']] ?? 0}'),
            IconButton(icon: const Icon(Icons.add_circle), onPressed: p['agotado'] == true ? null : () => setState(() => _cart[p['id']] = (_cart[p['id']] ?? 0) + 1))]),
          onLongPress: () async { final t = TextEditingController(text: _obs[p['id']]);
            await showDialog(context: c, builder: (_) => AlertDialog(title: Text('Nota: ${p['nombre']}'), content: TextField(controller: t, decoration: const InputDecoration(hintText: 'Sin cebolla, sin picante…')),
              actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text('Listo'))])); _obs[p['id']] = t.text; })])),
        SafeArea(child: Padding(padding: const EdgeInsets.all(12), child: Row(children: [
          const Text('Personas'), IconButton(icon: const Icon(Icons.remove), onPressed: _comensales > 1 ? () => setState(() => _comensales--) : null),
          Text('$_comensales'), IconButton(icon: const Icon(Icons.add), onPressed: () => setState(() => _comensales++)), const Spacer(),
          FilledButton(onPressed: _cart.isEmpty || _busy ? null : _enviar, child: Text('Enviar · ${soles(total)}'))])))]));
  });
}
