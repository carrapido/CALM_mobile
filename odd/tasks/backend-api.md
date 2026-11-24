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
- [x] F2 (S3; CALM_web L7) Session ended, not "error de conexión": refresh a missing/expired/expiring (<60 s) access token before each API request; a refused refresh or any 401 `signed_out` (reads and actions) signs out locally and opens Entrada with "Tu sesión terminó. Vuelve a entrar."; a load failure without a session shows no tab bar, with a session keeps tabs and "Reintentar". Route: worker. Commit: pending

## Log

- **L1** User: "Si, la aplicación movil debe pasar por el backend, por que tambien debe de haber modificaciones en flutter". Decisions in CALM_web/odd/tasks/app-movil-backend.md L3.
- **L2** Cleanup after the move to the API (CALM_web M4/M5 side): nothing in lib/ or test/ imports the Supabase data implementations any more; lib/services/supabase_client_access.dart, lib/services/supabase_client_data.dart and test/services/supabase_client_access_test.dart are left for the parent to delete. Supabase stays only for the session (Supabase.initialize, setSession, currentSession, signOut). Verifier advisory fixed test-first: a 401 `signed_out` on cancel and on-my-way now says "Tu sesión terminó. Vuelve a entrar." (AppConstants.bookingSignedOut) instead of unavailable. README.md and env/README.md point to the CALM API (CALM_web README, docs/api.md "API de la app de clientas") and the emulator run with API_URL=http://10.0.2.2:3000/api; stale comments about row level security and the workshop's functions rewritten.
- **L3** User emulator report (CALM_web app-movil-backend.md L7). Root cause in the app: `ApiClient.forSupabase` sent `currentSession?.accessToken` as stored, with no refresh. supabase_flutter 2.18.3 stops the auto-refresh ticker on pause (supabase_auth.dart didChangeAppLifecycleState) and gotrue 2.27.3 keeps an expired session when a refresh fails for the network (gotrue_client.dart `_doRefresh`, AuthRetryableFetchException), so an expired token reached the API, which answered 401 `signed_out`; `Loaded` told every read failure as "No pudimos cargar tus datos. Revisa tu internet…" with the tab bar (TabPage always rendered AppTabBar). Fix: `ApiClient.forAuth` awaits `auth.refreshSession()` when the token is missing, expired or within 60 s of expiry (network failure → ApiUnreachable, timeout → ApiTimeout, refused refresh → `ApiException.signedOut`); reads throw `SessionEnded`, cancel/on-my-way answer `ActionSignedOut`, Perfil `ProfileSignedOut`; `endSession` (lib/widgets/session_end.dart) signs out and opens Entrada with the notice; the booking sheet keeps its "Volver a entrar" button, now through the same path; `TabPage.showsTabBar` hides the tabs on a load failure without a session. Tests: test/services/api_session_test.dart drives a real GoTrueClient over a fake Auth server.
