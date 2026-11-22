---
status: in-progress
---

# Client screens read real data (batch 2)

Pedidos, Pedido, Servicios, Perfil and the agenda of "Agendar cita" stop reading mocks and read the
CALM Supabase project, signed in as in `odd/tasks/acceso-cliente-supabase.md`. Read-only: every
client action keeps its current local behavior until batch 3.

## Specs

- **S1** — Scope, as chosen: "Solo lecturas (recomendado)" — "Pedidos: órdenes + citas sin orden
  del cliente / Detalle de pedido / Servicios: catálogo activo (también sin sesión, para "¿Primera
  vez?") / Perfil: nombre y teléfono reales / Agenda: horario semanal, días bloqueados y turnos
  ocupados. Queda para la tanda 3: agendar, cancelar, voy en camino, cambiar NIP. Backend: solo
  policies RLS de lectura y una función para los turnos ocupados (sin exponer quién reservó)."
- **S2** — Pedidos lists the signed-in client's orders and her appointments that have no order yet,
  and nobody else's. Row level security enforces it, not the app.
- **S3** — Servicios lists the active catalog, also without a session. A service of category
  `extra` is the urgent-garment charge ("Prenda urgente"), not a repair: it is not listed, and its
  price becomes the urgency charge the quote already words.
- **S4** — Perfil shows the signed-in client's real name and phone.
- **S5** — The agenda follows the panel's rules (CALM_web `src/agenda/domain/schedule.ts`,
  `day-agenda.ts`): 30-minute slots "from `start` up to, but not including, `end`" of each
  weekday's `opens_at`/`closes_at`; a closed weekday has none; blocked days and booked slots are
  not free; a slot that has started (Cancún wall-clock time) is not free. Booked slots reach the
  app without saying who booked them.
- **S6** — Derived, not asked for: mapping rows the design never had to word.
  `onTheWay` reads as "Listo para recoger" until batch 3 builds "Voy en camino"; `cancelled` orders
  are not listed; an appointment without an order is listed from its day on; a delivered order
  shows its `delivery_date`; "Activos" puts what needs the client first (ready, then appointments
  by date, then in progress, then received) and "Entregados" the most recent first.
- **S7** — Derived: loading and failure states. While data loads the screen shows a spinner; when
  it cannot load it says "No pudimos cargar tus datos. Revisa tu internet e inténtalo de nuevo."
  with a "Reintentar" button. Pedidos with nothing at all says "Todavía no tienes pedidos.", and
  a section with nothing in it is not shown.
- **S8** — No secret in either repository (from batch 1: "no dejes ningun secreto en el repo").

## Tasks

- [x] **T1** (S8) — CALM_web: branch `feat/acceso-cliente-app`, commit batch 1's backend files.
      CALM_web `1139c01`.
- [x] **T2** (S2, S3, S5) — Migration: client read policies and the `booking_calendar` function;
      applied and checked with a client session and without one. CALM_web `0b07065`.
- [x] **T3** (S3, S7) — Servicios from the database. `92907d5`.
- [x] **T4** (S2, S6, S7) — Pedidos and Pedido from the database. Pedido needs no load of its
      own: it shows the order Pedidos hands it.
- [x] **T4 commit** — `f98a6fc`.
- [x] **T5** (S4, S7) — Perfil from the database.
- [ ] **T6** (S5, S7) — The agenda of "Agendar cita" from the database.

## Log

- **L1** — Request: "Ya puse los modelos de los review, sigamos con la siguiente tanda". Choices:
  scope "Solo lecturas (recomendado)"; CALM_web "Commitear en una rama feat de CALM_web".
- **L2** — For batch 3, the user's account rule, verbatim: "Esos datos son solo de pruebasm el
  verdaderi flujo es, alno tener una cuenta agendas y pones tu numero, nombre y nip para crear la
  cuenta, en otros dispositivos solo con el telefono y nip pueden acceder, conocer solo el telefono
  no te da acceso a la cuenta, en resumen no se puede crear una cuenta solo con telefono, requiere
  ambos datos de a fuerzas". Open for batch 3: a phone that already exists without a NIP.
- **L3** — Evidence that shaped T2: the panel reads `weekly_schedule` with `select('*')`
  (CALM_web `src/agenda/infrastructure/supabase-agenda-repository.ts:20`), so narrowing column
  privileges for clients would break the admin panel. The agenda reaches clients through a
  `security definer` function instead, and no table grant changes.
- **L5** — Evidence for T2, against the live project. With María's session (client 2):
  `appointments` returns only her `4821`, `orders` returns nothing (all four belong to others),
  `appointment_services` only her two, `services` the seven active ones, `clients` only her row.
  Without a session: no order, appointment or link, the seven active services, `weekly_schedule`
  empty, and `booking_calendar` answering. Advisors: two intended WARNs that anon and
  authenticated execute `booking_calendar` (see L3), nothing else new.
- **L6** — Evidence for T4: the exact queries of `SupabaseClientData.orders()` with María's
  session return her appointment with `"orders": null`, the shape PostgREST gives a one-to-one
  embed; `Order.listFrom` drops it because it was on the 17th, so she sees "Todavía no tienes
  pedidos."; the same row moved to today maps to "Dobladillo de pantalón, Cambio de cierre",
  "$250 MXN", "domingo 22 a las 23:30", not cancellable.
- **L7** — Evidence for T5: with María's session `clients.select('name, phone').single()`
  returns `{name: María López, phone: 9981234567}`; after `signOut` it raises `PGRST116` (no
  row), which Perfil shows as the load failure. Open for batch 3: "Cerrar sesión" only returns to
  Entrada and leaves the Supabase session on the device; ending it is an auth action outside this
  read-only batch.
- **L4** — Routing: every `gentle-ai-explore` run this session failed with an auth error (five
  runs), as did `gentle-ai-verify`; the native review relay reports no model for `review-risk`.
  Exploration and implementation run inline.
