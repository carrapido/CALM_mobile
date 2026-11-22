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

## Tasks

- [ ] **T1** (S3) — Supabase bootstrap in Flutter: `supabase_flutter` dependency, git-ignored env
      file plus committed example, async `main()` initialization.
- [ ] **T2** (S1, S8) — Migration adding the client's own RLS policies, leaving the admin policies
      untouched.
- [ ] **T3** (S2, S6, S7) — Edge Function `client-sign-in`: looks the client up by phone, verifies
      the NIP with argon2id, throttles per phone, and returns a session.
- [ ] **T4** (S4, S5) — Flutter auth repository and Entrada wiring, replacing `DemoClientAccess`
      without changing a single message. Tests first.
- [ ] **T5** (S1, S2) — One real test client with a NIP, and end-to-end verification of the sign-in.

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
- **L6** — Who creates the NIP is already answered by `odd/tasks/entrada-screen.md`: "¿Primera vez?"
  → "Agenda una cita / Eliges tus arreglos y creas tu NIP." Enrollment belongs to the booking flow,
  out of this delivery's scope; T5 seeds one client so the sign-in can be verified.
