# Local environment

`env/supabase.json` holds the Supabase project this app keeps the client's session with and the
URL of the CALM API it reads and writes her data through. The app never reads Supabase tables nor
calls edge functions or RPCs: every screen goes through the CALM API (see the section "API de la
app de clientas" of [CALM_web/docs/api.md](../../CALM_web/docs/api.md#api-de-la-app-de-clientas)
and the [CALM_web README](../../CALM_web/README.md)). It is git-ignored: no credential is ever
committed, not even the publishable key.

Copy the example and fill it with the values of the CALM project (Supabase dashboard →
Project Settings → API, or `get_project_url` / `get_publishable_keys` over the Supabase MCP):

```bash
cp env/supabase.example.json env/supabase.json
```

| Key | What it is |
|---|---|
| `SUPABASE_URL` | The CALM Supabase project. Only Supabase Auth is used: it keeps, refreshes and ends the client's session. |
| `SUPABASE_PUBLISHABLE_KEY` | Its publishable key. |
| `API_URL` | The CALM Express API, `/api` included. Every screen goes through `API_URL/client/*` with the client's access token. |

`API_URL` is `http://10.0.2.2:3000/api` for the Android emulator: inside the emulator,
`10.0.2.2` is the computer running it, so the backend started with `npm run dev` on port 3000 is
reached there (`localhost` would be the emulator itself). A physical phone on the same Wi-Fi needs
the computer's LAN IP instead, for example `http://192.168.1.50:3000/api`; plain HTTP is only
allowed to `10.0.2.2`, `localhost` and `127.0.0.1` (see
`android/app/src/main/res/xml/network_security_config.xml`), so a LAN IP needs that host added
there or an HTTPS URL. With `adb reverse tcp:3000 tcp:3000` a physical phone can also use
`http://localhost:3000/api`.

Then, with the backend running and an Android emulator started, run the app with the file:

```bash
flutter run --dart-define-from-file=env/supabase.json
```

Without any of the three keys the app opens a screen that says what is missing instead of the
sign-in.

Only the **publishable** key belongs here. The `service_role` key never leaves the server: the
backend uses it to issue the client's session at sign-in, and putting it in a mobile app would
hand every client full admin access to the database.
