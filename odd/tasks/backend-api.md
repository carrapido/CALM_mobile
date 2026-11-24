---
status: in-progress
---

# La app pasa por el backend de CALM

The app stops reading and writing Supabase directly and calls the CALM Express API. The full specification, API contract and log live in `/home/deankoro/Proyectos/CALM_web/odd/tasks/app-movil-backend.md` (S1-S6, contract table); read it first. Supabase Auth still keeps the client's session (supabase_flutter for `setSession`, refresh and sign-out only).

## Specs

- **S1** User: "Si, la aplicación movil debe pasar por el backend, por que tambien debe de haber modificaciones en flutter".
- **S2** Demo on the Android emulator: the API is `http://10.0.2.2:3000/api`.
- **S3** Every screen keeps its current behavior and messages (sign-in outcomes, booking outcomes, cancel/on-my-way refusals, profile field errors).

## Tasks

- [x] F1 (S1-S3) ApiClientAccess and ApiClientData implementing the existing ports over HTTP; `API_URL` dart-define; Android cleartext only for development; main.dart wires them; tests with a fake HTTP client. Route: worker. Commit: pending

## Log

- **L1** User: "Si, la aplicación movil debe pasar por el backend, por que tambien debe de haber modificaciones en flutter". Decisions in CALM_web/odd/tasks/app-movil-backend.md L3.
- **L2** Cleanup after the move to the API (CALM_web M4/M5 side): nothing in lib/ or test/ imports the Supabase data implementations any more; lib/services/supabase_client_access.dart, lib/services/supabase_client_data.dart and test/services/supabase_client_access_test.dart are left for the parent to delete. Supabase stays only for the session (Supabase.initialize, setSession, currentSession, signOut). Verifier advisory fixed test-first: a 401 `signed_out` on cancel and on-my-way now says "Tu sesión terminó. Vuelve a entrar." (AppConstants.bookingSignedOut) instead of unavailable. README.md and env/README.md point to the CALM API (CALM_web README, docs/api.md "API de la app de clientas") and the emulator run with API_URL=http://10.0.2.2:3000/api; stale comments about row level security and the workshop's functions rewritten.
