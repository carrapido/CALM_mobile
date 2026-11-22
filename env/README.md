# Local environment

`env/supabase.json` holds the Supabase project this app talks to. It is git-ignored: no
credential is ever committed, not even the publishable key.

Copy the example and fill it with the values of the CALM project (Supabase dashboard →
Project Settings → API, or `get_project_url` / `get_publishable_keys` over the Supabase MCP):

```bash
cp env/supabase.example.json env/supabase.json
```

Then run the app with the file:

```bash
flutter run --dart-define-from-file=env/supabase.json
```

Only the **publishable** key belongs here. The `service_role` key never leaves the Supabase
project: it is what the `client-sign-in` Edge Function uses on the server side, and putting it in
a mobile app would hand every client full admin access to the database.
