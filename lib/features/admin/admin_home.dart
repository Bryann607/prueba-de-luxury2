import 'package:flutter/material.dart';
import '../../core/db.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';

/// Administrador: dashboard, menú, insumos, usuarios, mesas y auditoría. Gerente: dashboard y auditoría.
class AdminHome extends StatelessWidget {
  final String nombre, rol; const AdminHome({super.key, required this.nombre, required this.rol});
  @override
  Widget build(BuildContext context) {
    final adm = rol == 'ADMINISTRADOR';
    return LxShell(rol: adm ? 'Administración' : 'Gerencia', nombre: nombre, items: [
      const NavItem(Icons.dashboard_outlined, 'Dashboard', Dashboard()),
      if (adm) const NavItem(Icons.restaurant_menu, 'Menú', MenuAdmin()),
      if (adm) const NavItem(Icons.inventory_2_outlined, 'Insumos', InsumosAdmin()),
      if (adm) const NavItem(Icons.people_outline, 'Usuarios', UsuariosAdmin()),
      if (adm) const NavItem(Icons.table_restaurant, 'Mesas', MesasAdmin()),
      const NavItem(Icons.fact_check_outlined, 'Auditoría', AuditoriaPage()),
    ]);
  }
}

String _fecha(String? iso) { if (iso == null) return '—'; final d = DateTime.parse(iso).toLocal(); String p(int n) => n.toString().padLeft(2, '0'); return '${p(d.day)}/${p(d.month)} ${p(d.hour)}:${p(d.minute)}'; }

// ---------------- RF06 Dashboard (datos reales) ----------------
class Dashboard extends StatefulWidget { const Dashboard({super.key}); @override State<Dashboard> createState() => _DashState(); }
class _DashState extends State<Dashboard> {
  late Future<List<dynamic>> _f = _load();
  Future<List<dynamic>> _load() {
    final n = DateTime.now(), d0 = DateTime(n.year, n.month, n.day).toUtc().toIso8601String(), d7 = n.subtract(const Duration(days: 7)).toUtc().toIso8601String();
    return Future.wait([db.from('pagos').select('monto, creado_en').gte('creado_en', d0), db.from('pedidos').select('id').gte('creado_en', d0).neq('estado', 'CANCELADO'),
      db.from('alertas_cocina').select('id').eq('estado', 'NUEVA'), db.from('mesas').select('estado').eq('activa', true),
      db.from('detalle_pedido').select('cantidad, platillos(nombre)').gte('creado_en', d7)]);
  }
  Widget _kpi(String t, String v, {Color? c, bool hero = false}) => SizedBox(width: 220, child: Card(color: hero ? lxBrand : Colors.white, child: Padding(padding: const EdgeInsets.all(16),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(t, style: TextStyle(color: hero ? const Color(0xFFC9B3A8) : lxMuted, fontSize: 12, fontWeight: FontWeight.w700)),
      const SizedBox(height: 6), Text(v, style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: c ?? (hero ? Colors.white : lxInk)))]))));
  @override
  Widget build(BuildContext context) => FutureBuilder<List<dynamic>>(future: _f, builder: (c, s) {
    if (s.hasError) return Center(child: Text('Error: ${s.error}'));
    if (!s.hasData) return const Center(child: CircularProgressIndicator());
    final pagos = s.data![0] as List, ped = s.data![1] as List, al = s.data![2] as List, mesas = s.data![3] as List, det = s.data![4] as List;
    final ventas = pagos.fold<num>(0, (a, p) => a + (p['monto'] as num)), byH = <int, num>{};
    for (final p in pagos) { final h = DateTime.parse(p['creado_en']).toLocal().hour; byH[h] = (byH[h] ?? 0) + (p['monto'] as num); }
    final top = <String, int>{}; for (final d in det) { final n = d['platillos']?['nombre'] as String? ?? '—'; top[n] = (top[n] ?? 0) + (d['cantidad'] as int); }
    final topL = top.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final maxH = byH.values.fold<num>(1, (a, b) => b > a ? b : a), horas = [for (var h = 11; h <= 22; h++) h];
    int cnt(String e) => mesas.where((m) => m['estado'] == e).length;
    return ListView(children: [
      PageHead('Resumen del servicio de hoy', 'Dashboard general', actions: [IconButton(onPressed: () => setState(() => _f = _load()), icon: const Icon(Icons.refresh))]),
      Wrap(spacing: 12, runSpacing: 4, children: [_kpi('Ventas del día', soles(ventas), hero: true), _kpi('Pedidos de hoy', '${ped.length}'),
        _kpi('Ticket promedio', ped.isEmpty ? '—' : soles(ventas / ped.length)), _kpi('Insumos en alerta', '${al.length}', c: al.isEmpty ? null : lxRed)]),
      const SizedBox(height: 10),
      Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Ingresos por hora · hoy (S/)', style: TextStyle(fontWeight: FontWeight.w800)), const SizedBox(height: 12),
        SizedBox(height: 170, child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [for (final h in horas) Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 3),
          child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [Text('${(byH[h] ?? 0).round()}', style: const TextStyle(fontSize: 10, color: lxMuted)),
            Container(height: 4 + 110 * ((byH[h] ?? 0) / maxH), decoration: BoxDecoration(color: lxGold, borderRadius: BorderRadius.circular(6))), const SizedBox(height: 4), Text('${h}h', style: const TextStyle(fontSize: 11))])))]))]))),
      Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Estado del salón', style: TextStyle(fontWeight: FontWeight.w800)), const SizedBox(height: 8),
        Wrap(spacing: 10, children: [for (final e in ['DISPONIBLE', 'OCUPADA', 'POR_COBRAR']) Chip(avatar: const Icon(Icons.circle, size: 10), label: Text('${cnt(e)} ${e.replaceAll('_', ' ').toLowerCase()}'))])]))),
      Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Platos más vendidos (7 días)', style: TextStyle(fontWeight: FontWeight.w800)),
        if (topL.isEmpty) const Padding(padding: EdgeInsets.only(top: 8), child: Text('Sin ventas registradas.', style: TextStyle(color: lxMuted))),
        for (final e in topL.take(5)) ListTile(dense: true, contentPadding: EdgeInsets.zero, title: Text(e.key), trailing: Text('${e.value}', style: const TextStyle(fontWeight: FontWeight.w800)))])))]);
  });
}

// ---------------- RF02 / RF08 Menú ----------------
class MenuAdmin extends StatefulWidget { const MenuAdmin({super.key}); @override State<MenuAdmin> createState() => _MenuState(); }
class _MenuState extends State<MenuAdmin> {
  String _q = ''; int _k = 0;
  Future<void> _nuevo() async {
    final cats = List<Map<String, dynamic>>.from(await db.from('categorias').select().eq('activa', true).order('orden'));
    if (!mounted || cats.isEmpty) return;
    final n = TextEditingController(), d = TextEditingController(), p = TextEditingController(); int cat = cats.first['id'];
    final ok = await showDialog<bool>(context: context, builder: (c) => StatefulBuilder(builder: (c, set) => AlertDialog(title: const Text('Nuevo platillo'), content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
      TextField(controller: n, decoration: const InputDecoration(labelText: 'Nombre')), const SizedBox(height: 8), TextField(controller: d, decoration: const InputDecoration(labelText: 'Descripción')),
      const SizedBox(height: 8), TextField(controller: p, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Precio (S/)')), const SizedBox(height: 8),
      DropdownButtonFormField<int>(value: cat, items: [for (final x in cats) DropdownMenuItem(value: x['id'] as int, child: Text(x['nombre']))], onChanged: (v) => set(() => cat = v!))])),
      actions: [TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancelar')), FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Guardar'))])));
    if (ok == true && mounted) { final pr = num.tryParse(p.text); if (n.text.trim().isEmpty || pr == null) { run(context, () => throw 'Nombre y precio válidos'); return; }
      if (await run(context, () => db.from('platillos').insert({'nombre': n.text.trim(), 'descripcion': d.text.trim(), 'precio': pr, 'categoria_id': cat}), ok: 'Platillo creado')) setState(() => _k++); }
  }
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    PageHead('Catálogo', 'Menú', actions: [FilledButton.icon(onPressed: _nuevo, icon: const Icon(Icons.add), label: const Text('Platillo'))]),
    TextField(decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Buscar platillo'), onChanged: (v) => setState(() => _q = v.toLowerCase())), const SizedBox(height: 10),
    Expanded(child: Loader(key: ValueKey(_k), load: () async => List<Map<String, dynamic>>.from(await db.from('platillos').select('*, categorias(nombre)').order('nombre')),
      builder: (c, l, reload) => ListView(children: [for (final p in l.where((p) => p['nombre'].toString().toLowerCase().contains(_q))) Card(child: ListTile(
        title: Text(p['nombre'], style: const TextStyle(fontWeight: FontWeight.w700)), subtitle: Text('${p['categorias']?['nombre'] ?? ''} · ${p['descripcion'] ?? ''}'),
        trailing: Row(mainAxisSize: MainAxisSize.min, children: [Text(soles(p['precio']), style: const TextStyle(fontWeight: FontWeight.w800)), const SizedBox(width: 8), const Text('Agotado'),
          Switch(value: p['agotado'] == true, onChanged: (v) async { if (await run(c, () => db.from('platillos').update({'agotado': v}).eq('id', p['id']))) reload(); })])))])))]);
}

// ---------------- RF03 / RF13 Insumos, alertas, solicitudes ----------------
class InsumosAdmin extends StatelessWidget {
  const InsumosAdmin({super.key});
  @override
  Widget build(BuildContext context) => DefaultTabController(length: 3, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    const PageHead('Cocina y compras', 'Insumos'),
    const TabBar(tabs: [Tab(text: 'Insumos'), Tab(text: 'Alertas'), Tab(text: 'Solicitudes')]),
    Expanded(child: TabBarView(children: [
      Loader(load: () async => List<Map<String, dynamic>>.from(await db.from('insumos').select().order('nombre')), builder: (c, l, _) => ListView(children: [for (final i in l) Card(child: ListTile(
        title: Text(i['nombre']), subtitle: Text('Stock ${i['stock_actual']} ${i['unidad']} · mínimo ${i['stock_minimo']}'),
        trailing: (i['stock_actual'] as num) <= (i['stock_minimo'] as num) ? const Pill('NUEVA') : const Pill('LISTO')))])),
      Loader(load: () async => List<Map<String, dynamic>>.from(await db.from('alertas_cocina').select('*, insumos(nombre)').order('creado_en', ascending: false)), builder: (c, l, reload) => l.isEmpty ? const Center(child: Text('Sin alertas.')) : ListView(children: [for (final a in l) Card(child: ListTile(
        title: Text(a['mensaje']), subtitle: Text('${a['insumos']?['nombre'] ?? 'General'} · ${_fecha(a['creado_en'])}'),
        trailing: a['estado'] == 'NUEVA' ? FilledButton(onPressed: () async { if (await run(c, () => db.rpc('revisar_alerta_cocina', params: {'p_alerta_id': a['id']}), ok: 'Alerta revisada')) reload(); }, child: const Text('Revisar')) : const Pill('REVISADA')))])),
      Loader(load: () async => List<Map<String, dynamic>>.from(await db.from('solicitudes_reabastecimiento').select('*, solicitud_items(cantidad, insumos(nombre))').order('creado_en', ascending: false)), builder: (c, l, _) => l.isEmpty ? const Center(child: Text('Sin solicitudes.')) : ListView(children: [for (final s in l) Card(child: ListTile(
        title: Text('Solicitud #${s['id']} · ${_fecha(s['creado_en'])}'), trailing: Pill(s['estado']),
        subtitle: Text([for (final it in s['solicitud_items'] as List) '${it['cantidad']} ${it['insumos']?['nombre']}', if ((s['observaciones'] ?? '') != '') '“${s['observaciones']}”'].join('\n'))))]))]))]));
}

// ---------------- RF01 Usuarios ----------------
class UsuariosAdmin extends StatelessWidget {
  const UsuariosAdmin({super.key});
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const PageHead('Seguridad y accesos', 'Usuarios'),
    Expanded(child: Loader(load: () async => List<Map<String, dynamic>>.from(await db.from('usuarios').select().order('nombre_completo')), builder: (c, l, reload) => ListView(children: [for (final u in l) Card(child: ListTile(
      leading: CircleAvatar(backgroundColor: lxGold, child: Text(u['nombre_completo'].toString().substring(0, 1), style: const TextStyle(color: lxInk, fontWeight: FontWeight.w800))),
      title: Text(u['nombre_completo'], style: const TextStyle(fontWeight: FontWeight.w700)), subtitle: Text('${u['correo']} · ${u['rol'].toString().replaceAll('_', ' ')}'),
      trailing: Switch(value: u['activo'] == true, onChanged: (v) async { if (await run(c, () => db.from('usuarios').update({'activo': v}).eq('id', u['id']))) reload(); })))])))]);
}

class MesasAdmin extends StatelessWidget {
  const MesasAdmin({super.key});
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const PageHead('Salón', 'Mesas'),
    Expanded(child: Loader(load: () async => List<Map<String, dynamic>>.from(await db.from('mesas').select().order('numero')), builder: (c, l, _) => ListView(children: [for (final m in l) Card(child: ListTile(
      title: Text('Mesa ${m['numero']}'), subtitle: Text('${m['capacidad']} personas${m['activa'] == true ? '' : ' · inactiva'}'), trailing: Pill(m['estado'])))])))]);
}

// ---------------- RF07 Auditoría (lectura real de auditoria_movimientos) ----------------
class AuditoriaPage extends StatefulWidget { const AuditoriaPage({super.key}); @override State<AuditoriaPage> createState() => _AudState(); }
class _AudState extends State<AuditoriaPage> {
  String _q = ''; int _k = 0;
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    PageHead('Trazabilidad', 'Movimientos', actions: [IconButton(onPressed: () => setState(() => _k++), icon: const Icon(Icons.refresh))]),
    TextField(decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Filtrar por acción, entidad o rol'), onChanged: (v) => setState(() => _q = v.toLowerCase())), const SizedBox(height: 10),
    Expanded(child: Loader(key: ValueKey(_k), load: () async {
      final r = await Future.wait([db.from('auditoria_movimientos').select().order('creado_en', ascending: false).limit(300), db.from('usuarios').select('id, nombre_completo')]);
      final nom = {for (final u in r[1]) u['id']: u['nombre_completo']};
      return [for (final a in r[0]) {...a, 'actor': nom[a['actor_id']] ?? (a['actor_id'] == null ? 'Sistema' : 'Usuario')}];
    }, builder: (c, l, _) {
      final f = l.where((a) => '${a['accion']} ${a['entidad']} ${a['actor_rol']} ${a['actor']}'.toLowerCase().contains(_q)).toList();
      if (l.isEmpty) return const Center(child: Padding(padding: EdgeInsets.all(24), child: Text('Aún no hay movimientos en auditoria_movimientos.\nSi ya operaste, revisa que las funciones de la base inserten ahí y que tu rol tenga permiso de lectura.', textAlign: TextAlign.center)));
      return ListView(children: [for (final a in f) Card(child: ListTile(leading: const Icon(Icons.history_toggle_off, color: lxGold),
        title: Text('${a['accion']} · ${a['entidad']} #${a['entidad_id']}', style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text('${a['actor']} (${a['actor_rol'] ?? '—'})'), trailing: Text(_fecha(a['creado_en']), style: const TextStyle(color: lxMuted))))]);
    }))]);
}
