import 'package:flutter/material.dart';
import '../../core/db.dart';

/// RF05/RF14: turno de caja y cobro. El cobro lo valida la función registrar_pago en la base.
class CajaHome extends StatefulWidget {
  final String nombre; const CajaHome({super.key, required this.nombre});
  @override State<CajaHome> createState() => _S();
}
class _S extends State<CajaHome> {
  Map<String, dynamic>? _turno; List<Map<String, dynamic>> _p = [];
  @override void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    final t = await db.from('turnos_caja').select().eq('cajero_id', db.auth.currentUser!.id).isFilter('cerrado_en', null).maybeSingle();
    final p = await db.from('pedidos').select('*, mesas(numero)').inFilter('estado', ['LISTO', 'POR_COBRAR']).order('creado_en');
    if (mounted) setState(() { _turno = t; _p = List<Map<String, dynamic>>.from(p); });
  }
  Future<void> _abrir() async { if (await run(context, () => db.from('turnos_caja').insert({'cajero_id': db.auth.currentUser!.id, 'monto_apertura': 0}), ok: 'Turno abierto')) _load(); }
  Future<void> _cobrar(Map<String, dynamic> o, String metodo) async {
    if (await run(context, () => db.rpc('registrar_pago', params: {'p_pedido_id': o['id'], 'p_metodo': metodo, 'p_monto': o['total'],
      if (metodo == 'EFECTIVO') 'p_efectivo_recibido': o['total']}), ok: 'Pago registrado')) _load();
  }
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text('Caja · ${widget.nombre}'), actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _load), IconButton(icon: const Icon(Icons.logout), onPressed: () => db.auth.signOut())]),
    body: Column(children: [
      if (_turno == null) MaterialBanner(content: const Text('No hay turno abierto. Ábrelo para cobrar.'), actions: [TextButton(onPressed: _abrir, child: const Text('Abrir turno'))]),
      Expanded(child: _p.isEmpty ? const Center(child: Text('Nada por cobrar')) : ListView(children: [for (final o in _p) Card(child: ListTile(
        title: Text('Mesa ${o['mesas']?['numero']} · #${o['id']}'), subtitle: Text(soles(o['total'])),
        trailing: PopupMenuButton<String>(enabled: _turno != null, onSelected: (m) => _cobrar(o, m), child: Chip(label: Text(_turno == null ? 'Sin turno' : 'Cobrar')),
          itemBuilder: (_) => const [PopupMenuItem(value: 'EFECTIVO', child: Text('Efectivo')), PopupMenuItem(value: 'YAPE_PLIN', child: Text('Yape / Plin')), PopupMenuItem(value: 'TARJETA', child: Text('Tarjeta'))])))]))]));
}
