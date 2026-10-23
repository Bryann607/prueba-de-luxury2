# Luxury · Sistema de Gestión y Control (entrega 2)
Flutter (web + móvil) sobre Supabase. Datos de conexión en `lib/core/config.dart` o con `--dart-define`.

    flutter pub get
    flutter run -d chrome

## Roles y pantallas
- MESERO: mesas en vivo con menú de acciones, nuevo pedido, mis pedidos, historial, perfil.
- COCINERO / JEFE_COCINA: comandas en vivo y avisos de insumo.
- CAJERO: turno de caja y cobro.
- ADMINISTRADOR: dashboard, menú (alta y agotado), insumos/alertas/solicitudes, usuarios, mesas, auditoría.
- GERENTE: dashboard y auditoría.

## Pendiente
Reportes con filtros y CSV (RF06/RF07 completo), RF11, RF15, RF16 (anulación/extorno), cambio de estado en cocina,
caché offline (RNF09), crear usuarios (requiere Auth admin), reabastecimiento desde la app.
