/// Where the app finds its Supabase project.
///
/// The values come from `--dart-define-from-file=env/supabase.json`, a git-ignored file, so no
/// credential lives in the repository. See `env/README.md`.
class SupabaseConfig {
  const SupabaseConfig._();

  static const url = String.fromEnvironment('SUPABASE_URL');

  /// The publishable (anon) key. It is meant to reach the client: row level security, not this
  /// key, is what keeps a client inside her own data.
  static const publishableKey = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');

  static bool get isComplete => url.isNotEmpty && publishableKey.isNotEmpty;

  /// What to tell whoever runs the app without the env file, instead of a stack trace. It also
  /// names API_URL, which comes from the same file (see `ApiConfig`).
  static const missingMessage =
      'Faltan las credenciales de Supabase o la URL de la API (API_URL). Copia '
      'env/supabase.example.json a env/supabase.json y corre la app con '
      '--dart-define-from-file=env/supabase.json';
}
