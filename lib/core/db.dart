import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
SupabaseClient get db => Supabase.instance.client;
String soles(num n) => 'S/ ${n.toStringAsFixed(2)}';
/// Ejecuta una acción y muestra el error real de la base (RLS / RPC) al usuario.
Future<bool> run(BuildContext c, Future<dynamic> Function() f, {String? ok}) async {
  final m = ScaffoldMessenger.of(c);
  try { await f(); if (ok != null) m.showSnackBar(SnackBar(content: Text(ok))); return true; }
  on PostgrestException catch (e) { m.showSnackBar(SnackBar(content: Text(e.message), backgroundColor: Colors.red)); }
  catch (e) { m.showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red)); }
  return false;
}
