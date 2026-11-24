/// Where the app finds the Supabase project that keeps the client's session (Supabase Auth only;
/// her data goes through the CALM API, see `ApiConfig`).
///
/// The values come from `--dart-define-from-file=env/supabase.json`, a git-ignored file, so no
/// credential lives in the repository. See `env/README.md`.
class SupabaseConfig {
  const SupabaseConfig._();

  static const url = String.fromEnvironment('SUPABASE_URL');

  /// The publishable (anon) key. It is meant to reach the client: the app uses it only for
  /// Supabase Auth, and the CALM API, not this key, keeps a client inside her own data.
  static const publishableKey = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');

  static bool get isComplete => url.isNotEmpty && publishableKey.isNotEmpty;

  /// What to tell whoever runs the app without the env file, instead of a stack trace. It also
  /// names API_URL, which comes from the same file (see `ApiConfig`).
  static const missingMessage =
      'Faltan las credenciales de Supabase o la URL de la API (API_URL). Copia '
      'env/supabase.example.json a env/supabase.json y corre la app con '
      '--dart-define-from-file=env/supabase.json';
}
