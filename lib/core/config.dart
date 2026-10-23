/// Se pasan al compilar: --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
/// Nunca escribas aquí la clave service_role.
class Config {
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL',
      defaultValue: 'https://cwkyjwxkdtxjatkvzwve.supabase.co');
  static const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY',
      defaultValue:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImN3a3lqd3hrZHR4amF0a3Z6d3ZlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTI2OTU3MjUsImV4cCI6MjEwODI3MTcyNX0.x9TyOwD_drlP7D49BELFAxv3VNLkM-XnJZfOjot46mg');
  static bool get ok => supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}
