---
status: in-progress
---

# Client sign-in against Supabase

The client app stops using `DemoClientAccess` and signs in against the CALM Supabase project
(`xbhtumsycbixilajhghn`), the same database the admin panel (CALM_web) writes to.
This delivery covers sign-in only; the screens keep their mock data until the next batch.

## Specs

- **S1** — Identity is the phone number: "El cliente se loguea por medio de su telefono el cual se
  va tomar como unico, no puede haber 2 clientes con el mismo numero telefonico". The schema already
  enforces it (`clients.phone text unique check (phone ~ '^\d{10}$')`).
- **S2** — The NIP is verified with argon2id: "el nip si puede ser por argon2id". The hash lives in
  `clients.nip_hash` and, as the initial migration states, is "hashed with argon2id outside the
  database". Verification therefore runs server-side; the raw NIP never reaches the database and is
  never stored on the device.
- **S3** — No secret in the repository: "no dejes ningun secreto en el repo". Project URL and
  publishable key are read from a git-ignored file through `--dart-define-from-file`; a committed
  example file documents the shape with placeholders only. The `service_role` key never leaves the
  Supabase project.
- **S4** — Scope of this delivery: "Primero solo el login contra la base". Entrada signs a real
  client in; Servicios, Pedidos and Perfil keep their current mock sources.
- **S5** — Entrada's error wording does not change. From `odd/tasks/entrada-screen.md`, a wrong pair
  turns the NIP label red and shows: "Tu celular o tu NIP no coinciden. Revísalos o escríbele al
  taller." The existing `LoginForm.firstProblem` rules and messages stay exactly as they are; only
  the source of `credentialsMatch` changes, from `DemoClientAccess` to the backend.
- **S6** — A failed attempt must not tell the attacker which half was wrong: an unknown phone and a
  wrong NIP produce the same answer and the same message, as S5 already words it.
- **S7** — Sign-in attempts are throttled per phone. `demo_client_access.dart:7` already states the
  requirement: "The real check belongs to the API, which must throttle NIP attempts per phone."
- **S8** — A signed-in client reaches only her own data. Today every RLS policy on the eight tables
  is `private.is_admin()`; the client needs her own policies, never a relaxation of the admin ones.
- **S9** — Derived, not asked for: a sign-in can now fail for reasons the design never worded,
  because there was no backend when it was written. Two messages were added for them, and only
  them: "Demasiados intentos. Espera unos minutos e inténtalo de nuevo." (throttled) and "No
  pudimos conectarnos. Revisa tu internet e inténtalo de nuevo." (unreachable). Every message the
  design did define keeps its exact wording.

## Tasks

- [x] **T1** (S3) — Supabase bootstrap in Flutter: `supabase_flutter` dependency, git-ignored env
      file plus committed example, async `main()` initialization. Commit `ce01572`.
- [x] **T2** (S1, S8) — Migration adding the client's own RLS policies, leaving the admin policies
      untouched. `CALM_web/supabase/migrations/20261122180000_client_app_access.sql`, applied.
- [x] **T3** (S2, S6, S7) — Edge Function `client-sign-in`: looks the client up by phone, verifies
      the NIP with argon2id, throttles per phone, and returns a session.
      `CALM_web/supabase/functions/client-sign-in/index.ts` plus
      `migrations/20261122181000_client_sign_in_attempts.sql`, both applied and deployed.
- [x] **T4** (S4, S5, S9) — Flutter auth repository and Entrada wiring, replacing
      `DemoClientAccess` without changing a single message. Tests first.
- [x] **T5** (S1, S2) — One real test client with a NIP, and end-to-end verification of the sign-in.

## Log

- **L1** — Original request: "Lee este repo https://github.com/carrapido/CALM_mobile.git (estas
  dentro de la ruta del proyecto en la sesión actual) y este repo
  https://github.com/carrapido/CALM_web.git (la ruta dentro de la laptop es ~/Proyectos/CALM_web)
  para que hagas la conexión con la base de datos que etsta en Supabase, vas a conectarte por medio
  de un MCP antes de hacaer modificaciones, las tablas ya estan hechas, solo es conectarla para que
  funcione la app con datos de la base de datos."
- **L2** — MCP evidence (live project, read-only queries). Migrations applied: `20261117120718
  initial_schema`, `20261117123517 supabase_auth_access` — the database matches the CALM_web repo.
  Rows: `services` 8 (7 active), `clients` 7, `orders` 4, `appointments` 4, `admins` 1,
  `weekly_schedule` 7, `blocked_dates` 1, `auth.users` 1.
  Blocking findings: all 8 RLS policies are admin-only (`private.is_admin()`), `clients` with
  `nip_hash` = 0, `clients` with `user_id` = 0, deployed Edge Functions = 0. The client side of the
  backend was never written, so "only connect it" is not possible as stated: the access path has to
  be built first.
- **L3** — User decision on authentication: "El cliente se loguea por medio de su telefono el cual
  se va tomar como unico, no puede haber 2 clientes con el mismo numero telefonico, el nip si puede
  ser por argon2id" → Edge Function route, not the email-alias shortcut and not SMS OTP.
- **L4** — User decision on scope: "Primero solo el login contra la base".
- **L5** — User constraint: "no dejes ningun secreto en el repo".
- **L7** — Verification of the delivered sign-in, against the live project.
  Rejection: an unknown phone and a wrong NIP both answer HTTP 401 with the same body; a
  malformed pair answers 400. Success: `998 123 4567` + `2580` answers HTTP 200 with a session;
  `auth.users` went from 1 to 2, the account was created once and reused across three sign-ins,
  and `clients.user_id` of client 2 points at `9981234567@clients.calm.app`.
  Row level security with that session: `clients` returns exactly her own row, while `orders`,
  `services` and `sign_in_attempts` return nothing, and anon without a session returns nothing.
  Throttling: a failed attempt is counted, a successful sign-in clears it.
  Flutter: 94 tests pass, `flutter analyze` clean.
- **L8** — Self-verification after the independent verifier came back unavailable (the configured
  subagent model failed to authenticate; it was not retried). Two findings were fixed and the
  function redeployed as v2: an error thrown while creating or linking the auth user escaped the
  handler and could have reached the caller, so the whole sign-in is wrapped and answers one
  wording while the detail goes to the function log; and the answer carried an `access_token`
  nobody used, so only the refresh token travels now.
  Checks run after that: throttling locks the phone on the sixth consecutive failure (five 401s,
  then 429) and `sign_in_attempts` was emptied afterwards; an unknown phone and a wrong NIP take
  about the same time (1.20/1.22, 1.40/1.34, 0.71/1.32 seconds), so the decoy hash does its job;
  Supabase security advisors report nothing new beyond the intentional INFO that
  `sign_in_attempts` has RLS with no policy, which is how only the service role reaches it.
  The exact Dart contract the app depends on was exercised from a throwaway project outside the
  repository: `functions.invoke` returns `{refresh_token, client}` with status 200,
  `auth.setSession(refresh_token)` installs the session of `9981234567@clients.calm.app`, that
  session reads only her own `clients` row and no `orders`, a wrong NIP raises
  `FunctionException` with status 401, and the sixth attempt raises status 429 — the three
  branches `SupabaseClientAccess` maps.
  Still unverified: the screen has not been run on a device; only its contract and its widget
  tests were exercised.
- **L6** — Who creates the NIP is already answered by `odd/tasks/entrada-screen.md`: "¿Primera vez?"
  → "Agenda una cita / Eliges tus arreglos y creas tu NIP." Enrollment belongs to the booking flow,
  out of this delivery's scope; T5 seeds one client so the sign-in can be verified.
