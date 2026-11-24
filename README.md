# calm_mobile

The client app of CALM (Costurando a la Medida): the client signs in with her phone and NIP,
books appointments, follows her orders and edits her profile.

The app reads and writes everything through the CALM Express API (`/api/client/*`, in the
`CALM_web` repository), like the admin panel. Supabase Auth only keeps her session on the device:
the API's sign-in answers with a refresh token, the app installs it with `supabase_flutter`, and
every request carries the session's access token as `Authorization: Bearer <token>`.

## Running it

1. Start the backend of `CALM_web` (`backend/`, see its README); it listens on port 3000.
2. Create `env/supabase.json` from `env/supabase.example.json` with the Supabase URL, the
   publishable key and `API_URL` (see [env/README.md](env/README.md)). On the Android emulator
   `API_URL` is `http://10.0.2.2:3000/api`.
3. Run the app with that file:

   ```bash
   flutter pub get
   flutter run --dart-define-from-file=env/supabase.json
   ```

Without the file, or with any key missing, the app opens a screen that says what is missing.

## Tests

```bash
flutter test
```

The screens are tested with fake data sources, and the API client with a fake HTTP client
(`package:http/testing`), so no backend or network is needed.
