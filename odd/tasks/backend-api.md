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

- [ ] F1 (S1-S3) ApiClientAccess and ApiClientData implementing the existing ports over HTTP; `API_URL` dart-define; Android cleartext only for development; main.dart wires them; tests with a fake HTTP client. Route: worker. Commit: —

## Log

- **L1** User: "Si, la aplicación movil debe pasar por el backend, por que tambien debe de haber modificaciones en flutter". Decisions in CALM_web/odd/tasks/app-movil-backend.md L3.
