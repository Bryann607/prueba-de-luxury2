import 'package:flutter/material.dart';
import '../../core/db.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import 'nuevo_pedido.dart';

class MeseroHome extends StatelessWidget {
  final String nombre;
  const MeseroHome({super.key, required this.nombre});
  @override
  Widget build(BuildContext context) =>
      LxShell(rol: 'Mesero', nombre: nombre, items: [
        const NavItem(Icons.table_restaurant, 'Mesas', _Mesas()),
        const NavItem(
            Icons.receipt_long, 'Mis pedidos', _Pedidos(historial: false)),
        const NavItem(Icons.history, 'Historial', _Pedidos(historial: true)),
        NavItem(Icons.person, 'Perfil', _Perfil(nombre)),
      ]);
}

Color _col(String e) => e == 'DISPONIBLE'
    ? lxGreen
    : e == 'OCUPADA'
        ? lxGold
        : lxRed;

class _Mesas extends StatelessWidget {
  const _Mesas();
  void _menu(BuildContext c, Map<String, dynamic> m) {
    final libre = m['estado'] == 'DISPONIBLE';
    showModalBottomSheet(
        context: c,
        builder: (_) => SafeArea(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
              ListTile(
                  title: Text('Mesa ${m['numero']}',
                      style: const TextStyle(fontWeight: FontWeight.w800)),
                  trailing: Pill(m['estado'])),
              ListTile(
                  leading: const Icon(Icons.add_circle_outline),
                  title: Text(libre ? 'Nuevo pedido' : 'Agregar pedido'),
                  onTap: () {
                    Navigator.pop(c);
                    Navigator.push(
                        c,
                        MaterialPageRoute(
                            builder: (_) => NuevoPedido(mesa: m)));
                  }),
              if (!libre)
                ListTile(
                    leading: const Icon(Icons.visibility_outlined),
                    title: const Text('Ver pedidos'),
                    onTap: () {
                      Navigator.pop(c);
                      _ver(c, m);
                    }),
              if (!libre)
                ListTile(
                    leading: const Icon(Icons.lock_open),
                    title: const Text('Confirmar retiro y liberar'),
                    onTap: () {
                      Navigator.pop(c);
                      run(
                          c,
                          () => db.rpc('confirmar_retiro_mesa',
                              params: {'p_mesa_id': m['id']}),
                          ok: 'Mesa liberada');
                    })
            ])));
  }

  void _ver(BuildContext c, Map<String, dynamic> m) => showModalBottomSheet(
      context: c,
      isScrollControlled: true,
      builder: (_) => SafeArea(
          child: Padding(
              padding: const EdgeInsets.all(16),
              child: Loader(
                  load: () async => List<Map<String, dynamic>>.from(await db
                      .from('pedidos')
                      .select(
                          '*, detalle_pedido(cantidad, observaciones, platillos(nombre))')
                      .eq('mesa_id', m['id'])
                      .order('creado_en', ascending: false)
                      .limit(10)),
                  builder: (c, l, _) => ListView(shrinkWrap: true, children: [
                        Text('Pedidos · mesa ${m['numero']}',
                            style: const TextStyle(
                                fontSize: 20, fontWeight: FontWeight.w800)),
                        for (final p in l)
                          Card(
                              child: ListTile(
                                  title: Text(
                                      '#${p['id']} · ${soles(p['total'] ?? 0)}'),
                                  trailing: Pill(p['estado']),
                                  subtitle: Text([
                                    for (final d in p['detalle_pedido'] as List)
                                      '${d['cantidad']}× ${d['platillos']?['nombre']}${(d['observaciones'] ?? '') == '' ? '' : ' (${d['observaciones']})'}'
                                  ].join('\n'))))
                      ])))));

  @override
  Widget build(BuildContext context) => StreamBuilder<
          List<Map<String, dynamic>>>(
      stream: db.from('mesas').stream(primaryKey: ['id']).order('numero'),
      builder: (c, s) {
        if (s.hasError) return Center(child: Text('${s.error}'));
        if (!s.hasData) return const Center(child: CircularProgressIndicator());
        final mesas = s.data!.where((m) => m['activa'] == true).toList();
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const PageHead('Salón principal', 'Mesas'),
          const Wrap(spacing: 14, children: [
            Pill('DISPONIBLE'),
            Pill('OCUPADA'),
            Pill('POR_COBRAR')
          ]),
          const SizedBox(height: 12),
          Expanded(
              child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 210,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1.25),
                  itemCount: mesas.length,
                  itemBuilder: (_, i) {
                    final m = mesas[i];
                    final e = m['estado'] as String;
                    return Card(
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                            onTap: () => _menu(c, m),
                            child: Column(children: [
                              Container(height: 6, color: _col(e)),
                              Expanded(
                                  child: Padding(
                                      padding: const EdgeInsets.all(14),
                                      child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text('Mesa ${m['numero']}',
                                                style: const TextStyle(
                                                    fontSize: 20,
                                                    fontWeight:
                                                        FontWeight.w800)),
                                            Text('${m['capacidad']} personas',
                                                style: const TextStyle(
                                                    color: lxMuted)),
                                            const Spacer(),
                                            Pill(e)
                                          ])))
                            ])));
                  }))
        ]);
      });
}

class _Pedidos extends StatelessWidget {
  final bool historial;
  const _Pedidos({required this.historial});
  @override
  Widget build(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        PageHead(historial ? 'Operaciones anteriores' : 'Servicio en curso',
            historial ? 'Historial de pedidos' : 'Mis pedidos'),
        Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: db
                    .from('pedidos')
                    .stream(primaryKey: ['id'])
                    .eq('mesero_id', db.auth.currentUser!.id)
                    .order('creado_en', ascending: false),
                builder: (c, s) {
                  if (!s.hasData)
                    return const Center(child: CircularProgressIndicator());
                  final l = s.data!
                      .where((p) =>
                          (p['estado'] == 'PAGADO' ||
                              p['estado'] == 'CANCELADO') ==
                          historial)
                      .toList();
                  if (l.isEmpty)
                    return const Center(child: Text('Sin pedidos.'));
                  return ListView(children: [
                    for (final p in l)
                      Card(
                          child: ListTile(
                              title: Text(
                                  'Pedido #${p['id']} · mesa ${p['mesa_id']}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700)),
                              subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: Pill(p['estado']))),
                              trailing: Text(soles(p['total'] ?? 0),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w800))))
                  ]);
                }))
      ]);
}

class _Perfil extends StatelessWidget {
  final String nombre;
  const _Perfil(this.nombre);
  @override
  Widget build(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const PageHead('Mi cuenta', 'Perfil'),
        Card(
            child: ListTile(
                leading: const CircleAvatar(
                    backgroundColor: lxGold,
                    child: Icon(Icons.person, color: lxInk)),
                title: Text(nombre,
                    style: const TextStyle(fontWeight: FontWeight.w800)),
                subtitle: Text(db.auth.currentUser?.email ?? ''),
                trailing: const Pill('LISTO')))
      ]);
}
