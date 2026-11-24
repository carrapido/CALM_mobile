---
status: in-progress
---

# Flujo de primera vez: agendar desde Entrada, sin abrir la app

A first-time client books from Entrada in a sheet (choose services, day and time, her data and NIP) and only then enters the app. Without a session she never reaches Servicios, Pedidos or Perfil.

## Specs

- **S1** User: "Primero el flujo de navegación, recuerdo que el flujo era: Pantalla de inicio de sesión donde se puede loguear o agendar una cita para los clientes primerizos. Si se seleccionaba la opcion de agendar cita debajo del mensaje de ¿Primera vez? y muestra una hoja que sube en donde seleccionas el servicio, agendas y pones tus datos de nombre, numero y nip. Y solo asi te dejaba ver los demas apartados de la aplicación."
- **S2** User: "Con el flujo actual un usuario nuevo desbloquea apartados de los cuales no tiene acceso porque no tiene cuenta".
- **S3** "Antes de realizar cambios en base de datos hay cosas que necesitan cambios": the remote Supabase retirement waits until this flow is fixed.
- **S4** Decision (parent, reversible): after the booking succeeds (her account and session now exist), "Ver mi cita" / "Listo" enters the app on Pedidos with her new appointment; the sheet reuses the existing booking steps, look and messages (agendar-sheet.md), adding a first step to choose the services from the real catalog.
- **S5** Every tab route (/services, /orders, /profile, /order) without a session goes to Entrada; the signed-in client keeps today's flow (Servicios → "Elegir horario" → sheet).

## Tasks

- [x] T1 (S1, S2, S4, S5) Entrada's "Agenda una cita" opens a booking sheet with service selection + day/time + data; success installs the session and enters the app; route guard for tab routes. Route: worker. Commit: this commit

## Log

- **L1** User request verbatim in S1-S3. Found: entrada-screen.md specified "¿Primera vez?" → Servicios (a tab screen), and servicios-screen.md shows tabs to visitors, so a visitor could open Pedidos/Perfil. The request changes that design.
- **L2** T1 (worker, test-first): Entrada's "Agenda una cita" → `showFirstVisitSheet` (`lib/widgets/schedule_sheet.dart`): service step on `ClientData.catalog()` (shared `ServicePicker`), then the existing `ScheduleSheet` (day, time, "Tus datos", same messages); a confirmed booking closes into Pedidos via `pushNamedAndRemoveUntil` (also when the sheet is dismissed after the ticket). `AppRoutes` wraps /services, /orders, /profile and /order in a session gate that shows Entrada. Signed-in Servicios path unchanged. RED 16 failing in `test/screens/first_visit_test.dart` + 1 in Entrada's test; GREEN 250/250, analyze clean. Entrada and Servicios specs updated.
