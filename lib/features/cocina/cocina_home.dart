import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/db.dart';

/// RF10 + RNF08: pedidos en vivo (Supabase Realtime) y RF03: avisos de insumos.
class CocinaHome extends StatefulWidget {
  final String nombre; const CocinaHome({super.key, required this.nombre});
  @override State<CocinaHome> createState() => _S();
}
class _S extends State<CocinaHome> {
  List<Map<String, dynamic>> _p = [];
  RealtimeChannel? _ch;
  Future<void> _load() async {
    final r = await db.from('pedidos').select('*, mesas(numero), detalle_pedido(cantidad, observaciones, estado, platillos(nombre))')
      .inFilter('estado', ['PENDIENTE', 'EN_PREPARACION', 'LISTO']).order('creado_en');
    if (mounted) setState(() => _p = List<Map<String, dynamic>>.from(r));
  }
  @override
  void initState() {
    super.initState(); _load();
    _ch = db.channel('kds')
      .onPostgresChanges(event: PostgresChangeEvent.all, schema: 'public', table: 'pedidos', callback: (_) => _load())
      .onPostgresChanges(event: PostgresChangeEvent.all, schema: 'public', table: 'detalle_pedido', callback: (_) => _load())
      .subscribe();
  }
  @override void dispose() { if (_ch != null) db.removeChannel(_ch!); super.dispose(); }

  Future<void> _aviso() async {
    final t = TextEditingController();
    final ok = await showDialog<bool>(context: context, builder: (c) => AlertDialog(title: const Text('Aviso de insumo'),
      content: TextField(controller: t, decoration: const InputDecoration(hintText: 'Ej. Se acaba el sillao')),
      actions: [TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancelar')), FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Enviar'))]));
    if (ok == true && mounted) run(context, () => db.rpc('crear_alerta_cocina', params: {'p_mensaje': t.text, 'p_prioridad': 'MEDIA'}), ok: 'Aviso enviado a administración');
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text('Cocina · ${widget.nombre}'), actions: [IconButton(icon: const Icon(Icons.logout), onPressed: () => db.auth.signOut())]),
    floatingActionButton: FloatingActionButton.extended(onPressed: _aviso, icon: const Icon(Icons.warning_amber), label: const Text('Avisar insumo')),
    body: _p.isEmpty ? const Center(child: Text('Sin comandas activas')) : GridView.builder(padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 320, mainAxisExtent: 260, mainAxisSpacing: 12, crossAxisSpacing: 12),
      itemCount: _p.length, itemBuilder: (_, i) { final o = _p[i];
        return Card(child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Mesa ${o['mesas']?['numero']} · #${o['id']}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          Text('${o['estado']}'.replaceAll('_', ' ')), const Divider(),
          Expanded(child: ListView(children: [for (final d in o['detalle_pedido'] as List) ListTile(dense: true, contentPadding: EdgeInsets.zero,
            title: Text('${d['cantidad']}× ${d['platillos']?['nombre']}'), subtitle: (d['observaciones'] ?? '') == '' ? null : Text('“${d['observaciones']}”'))]))])));
      }));
}
