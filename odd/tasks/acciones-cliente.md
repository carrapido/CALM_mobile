---
status: in-progress
---

# Client actions write to Supabase (batch 3)

Agendar, cancelar, "Voy en camino", Perfil (phone and NIP) and "Cerrar sesión" stop being local
and act on the CALM Supabase project. Builds on `acceso-cliente-supabase.md` (sign-in) and
`datos-reales-cliente.md` (reads).

## Specs

- **S1** — Scope: "sigamos con la siguiente tanda", the batch defined in
  `datos-reales-cliente.md` S1: "Queda para la tanda 3: agendar, cancelar, voy en camino, cambiar
  NIP." Plus the open point recorded there (L7): "Cerrar sesión" ends the Supabase session.
- **S2** — The account rule, verbatim: "el verdaderi flujo es, alno tener una cuenta agendas y
  pones tu numero, nombre y nip para crear la cuenta, en otros dispositivos solo con el telefono y
  nip pueden acceder, conocer solo el telefono no te da acceso a la cuenta, en resumen no se puede
  crear una cuenta solo con telefono, requiere ambos datos de a fuerzas".
- **S3** — Derived from S2 for a phone that already exists: with a NIP, booking needs that NIP and
  a wrong one gets the sign-in answer, "Tu celular o tu NIP no coinciden. Revísalos o escríbele al
  taller."; without a NIP, booking is refused with "Ese celular ya está registrado en el taller.
  Escríbele para que te dé tu NIP." — typing someone's phone never grants access to their orders.
- **S4** — Booking is decided by the server, never by the app: the services must be active, the
  slot must be free under the agenda rules of `datos-reales-cliente.md` S5, the preliminary total
  is the sum of the priced services plus the urgency charge when the garment is urgent, and the
  ticket follows the panel's rule (CALM_web `src/orders/domain/ticket.ts`): "4 random digits that
  no active ticket uses", active being open orders and appointments still to come. A slot taken
  meanwhile answers "Ese horario se acaba de ocupar. Elige otro.". NIP checks made by booking count
  against the same per-phone throttle as sign-in.
- **S5** — A booked client is signed in: the sheet shows the real ticket and "Ver mi cita" opens it.
- **S6** — Cancelling: only her own appointment, with no order yet, more than 24 hours ahead on
  Cancún's wall clock. It is deleted, as the panel cancels (CALM_web
  `supabase-agenda-repository.ts:49-50`), so the slot is free again.
- **S7** — "Voy en camino": only her own order in `ready` becomes `onTheWay`. From then on the
  order reads "Vas en camino" (`odd/tasks/pedido-detail.md`), in Pedidos as in Pedido.
- **S8** — Perfil saves the phone and the NIP on the server, checking the current NIP there; a
  phone another client uses is refused.
- **S9** — "Cerrar sesión" ends the Supabase session on the device before returning to Entrada.
- **S10** — No secret in either repository, and no NIP in any file or log.

## Tasks

- [x] **T1** (S2–S5, S10) — CALM_web: shared NIP and session code; `client-sign-in` on it;
      `client-book` Edge Function. Deployed and checked against the live project. CALM_web
      `b182282`.
- [x] **T2** (S6, S7) — CALM_web: `cancel_my_appointment` and `mark_on_my_way` functions.
      CALM_web `189e11a`.
- [x] **T3** (S8) — CALM_web: `client-update-profile` Edge Function. CALM_web `68c6cb3`.
- [x] **T4** (S3–S5) — App: "Agendar cita" books on the server. A slot taken meanwhile is
      marked booked in the sheet, which moves to the nearest free time.
- [ ] **T5** (S6, S7) — App: cancel and "Voy en camino" on the server.
- [ ] **T6** (S8, S9) — App: Perfil saves on the server; "Cerrar sesión" ends the session.

## Log

- **L1** — Request: "Haz las pruebas de review, par los clientes que tienen solo numeros de
  telefono sin nip, asignales un NIP,y sigamos con la siguiente tanda".
- **L2** — NIPs assigned to the three clients that had a phone and no NIP (ids 4, 6, 7): random
  4-digit NIPs avoiding repeated digits and sequences, hashed with argon2id as sign-in verifies
  them, written with a guard on `phone` and `nip_hash is null`. Each signs in with its NIP (200) and
  is refused with another (401). The NIPs were given to the user in the conversation only.
- **L4** — Evidence for T1 (live project, test phones `99900000xx`, all removed afterwards):
  `client-sign-in` v3 on the shared module answers as before, 200 / 401 / 401 / 400, with the
  wrong-NIP and unknown-phone timings alike (1.03 s and 1.08 s). `client-book`: malformed 400; a
  new phone books and gets an account with an argon2id NIP linked to Auth (200); the same slot
  again 409 `slot_taken`; María with a wrong NIP 401, then with hers 200 keeping her stored name;
  an inactive service 409 `service_unavailable`; a blocked day, a closed Sunday, closing time and
  a past day all 409 `slot_taken`; a phone with no NIP 409 `phone_without_nip`. The database was
  back to 7 clients, 4 appointments and 5 auth users afterwards.
- **L5** — Evidence for T2: anon cannot execute either function (401); María cannot mark
  Lucía's order nor Lucía Carlos's; Lucía marks her ready order once (204), a second time is
  refused; cancelling is refused for another client's appointment and for one less than 24 hours
  ahead, works more than 24 hours ahead (204, gone from her list) and is refused once gone. The
  fixtures (order 5512 set ready, two bookings) were restored.
- **L6** — Evidence for T3 with Juan's account: no session 401, short phone 400, no change 200,
  wrong current NIP 401, short or equal new NIP 400, NIP changed and then restored (the new one
  signs in, the old one does not), a phone in use 409, phone changed and restored with the auth
  alias following it. Juan was left with his phone and NIP.
- **L7** — Evidence for T4: the app's exact `functions.invoke('client-book')` books and installs
  the session of the new account, which reads its own appointment; a taken slot raises
  `FunctionException` 409 with `details` a `Map` whose `code` is `slot_taken`; a wrong NIP 401.
- **L3** — Review: the open lineage `review-fc190b36772165fa` failed a third time with "no model is
  configured for review-risk"; the routing file is not readable by the agent. Per-role models are
  set in `/gentle:profiles`.
