/// Where the app finds the CALM API (`/api/client/*`).
///
/// The value comes from `--dart-define-from-file=env/supabase.json`, like the Supabase keys. On the
/// Android emulator the computer running the backend is `10.0.2.2`, so the demo uses
/// `http://10.0.2.2:3000/api`. See `env/README.md`.
class ApiConfig {
  const ApiConfig._();

  static const url = String.fromEnvironment('API_URL');

  static bool get isComplete => url.isNotEmpty;
}
