---
status: done
---

# Agendar with an active session

A signed-in client books without typing her name, phone and NIP again. Builds on
`acciones-cliente.md` (S2–S4: the account rule and server-side booking).

## Specs

- **S1** — The bug, verbatim: "un usuario logueado, al momenro de quere generar una cita y
  seleccionar el horario, en la parte de abajo le vuelve a pedir el nombre, celular y nip, cuando
  no deberia porque tiene una sesión activa."
- **S2** — The rule, verbatim: "Lo de pedir el nombre, celular y nip, solo se lo debe de mostrar a
  usuario que todavia no tienen una cuenta."
- **S3** — Decision, verbatim: "eligo la opción uno, que se encargue el backend." The chosen
  option: `client-book` accepts the session (valid JWT → the client linked to that auth user) and
  books for her without name, phone or NIP; the app hides "Tus datos" when there is a session.
  Without a session, booking behaves exactly as before (`acciones-cliente.md` S2–S4).

## Tasks

- [x] **T1** (S3) — CALM_web: `signedInClient` moves to `_shared/client-auth.ts`; `client-book`
  books for the signed-in client without contact fields, no NIP check, no new refresh token.
  Route: inline. Commit: CALM_web 82ef4ab (deno check OK; no runtime test runner for functions).
- [x] **T2** (S1–S3) — App: `ClientData.isSignedIn`; the Agendar sheet hides "Tus datos" and sends
  no contact data when signed in; `book()` installs a session only when the answer carries one.
  Route: inline, test-first (RED 2 failing, GREEN 170/170, analyze clean). Commit: this one.

## Log

- **L1** — User request: "en base al contexto que tienes de calm_mobile, hay un error de flujo en
  la pantalla de order_screen, un usuario logueado, al momenro de quere generar una cita y
  seleccionar el horario, en la parte de abajo le vuelve a pedir el nombre, celular y nip, cuando
  no deberia porque tiene una sesión activa. Lo de pedir el nombre, celular y nip, solo se lo debe
  de mostrar a usuario que todavia no tienen una cuenta."
- **L2** — Evidence: the sheet is `lib/widgets/schedule_sheet.dart`; deployed `client-book` v5
  (`verify_jwt: false`) always required name, phone and a 4-digit NIP and never read the session.
- **L3** — User: "eligo la opción uno, que se encargue el backend. Te doy el permiso para
  editarlo" (edit of `../CALM_web` authorized; deploy not yet authorized).
- **L4** — Independent verify (gentle-ai-verify): S1–S3 met, no blockers; flutter analyze clean,
  170/170 tests, deno check OK. Advisory: an expired or unlinked session hides "Tus datos" and the
  server answers 400. `client-book` not deployed yet (not authorized).
- **L5** — User: "despliegalo, haz el push de las ramas y prueba la rama, despues de que hagas eso
  decidimos que hacer cuando la sesión vence". Deployed `client-book` v6 (verify_jwt false; v5 was
  identical to CALM_web main). Native review of CALM_web approved (risk + reliability; 4 advisory
  findings, incl. expired session → generic 400 and no runtime test of the session branch). Both
  branches pushed. Live checks without writes: anon key or invalid token without contact → 400
  "Revisa los datos de tu cita."; guest with contact and a past slot → 409 slot_taken, no client
  created. Signed-in path not exercised live (needs a real client session).
