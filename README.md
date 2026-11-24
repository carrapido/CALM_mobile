# calm_mobile

The client app of CALM (Costurando a la Medida): the client signs in with her phone and NIP,
books appointments, follows her orders and edits her profile.

The app talks only to the CALM API (`/api/client/*`, the Express backend in the `CALM_web`
repository), like the admin panel: Flutter → `/api/client/*` → backend → Postgres. It does not
read or write Supabase tables, call RPCs or invoke edge functions. Supabase Auth only keeps her
session on the device (`Supabase.initialize`, `setSession`, `currentSession`, `signOut`): the
API's sign-in answers with a refresh token, the app installs it with `supabase_flutter`, and every
request carries the session's access token as `Authorization: Bearer <token>`.

The backend, how to run it and the API contract live in `CALM_web`: see its
[README](../CALM_web/README.md) and the section "API de la app de clientas" of
[docs/api.md](../CALM_web/docs/api.md#api-de-la-app-de-clientas).

## Running it

On the Android emulator, with the backend running on the same computer:

1. Start the backend of `CALM_web` (`backend/`, `npm run dev`, see its README); it listens on
   port 3000.
2. Create `env/supabase.json` from `env/supabase.example.json` with the Supabase URL, the
   publishable key and `API_URL=http://10.0.2.2:3000/api` (see [env/README.md](env/README.md)).
   Inside the emulator `10.0.2.2` is the computer running it.
3. Start an Android emulator and run the app with that file:

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
