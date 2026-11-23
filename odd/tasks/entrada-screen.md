---
status: done
---

# Entrada, Ayuda sheet and design tokens

Boards "Apple: entrada" and "Apple: ayuda". Source: [design/entrada.html](../design/entrada.html), [design/ayuda.html](../design/ayuda.html).

## Spec

### Design tokens (shared by every later feature)
- Colors: grouped background `#F2F4F7`, ink `#0F172A`, secondary text `#45464D`, cell `#FFFFFF`, separator ink at 10 %, help-circle fill ink at 7 %, pressed cell `#E9ECF1`, chevron `#9AA1AC`, grabber `#C3C8D0`, error text `#B91C1C`, sheet scrim ink at 35 %.
- Type (Plus Jakarta Sans): large title 34/40 w800 −0.02em; lead 17/24 w500; body 17/22 w600; button 17/22 w700; subhead 15/20 w600; footnote 13/18; brand 12/16 w700 +0.08em; sheet title 22/28 w800 −0.01em.
- Shapes: groups radius 16, buttons radius 14, sheet top radius 22. Press feedback: scale 0.97 (buttons) / 0.98 (cards), 160 ms, `cubic-bezier(0.23, 1, 0.32, 1)`.

### Entrada
- Header: brand "COSTURANDO A LA MEDIDA" with scissors icon, help button (44 pt target, 32 pt tinted circle).
- "Tus pedidos" + lead text; inset group with "Celular" and "NIP" rows (54 pt).
- Phone groups as `998 123 4567`, max 10 digits; completing it moves focus to the NIP. NIP: digits only, max 4, obscured.
- Errors appear only after tapping "Ver mis pedidos", one message for the first field that needs attention, and the label of that field turns red. Editing any field hides the message.
  1. No phone digits: "Escribe tu celular a 10 dígitos."
  2. Missing phone digits: "Al celular le falta 1 dígito." / "Al celular le faltan N dígitos."
  3. Empty NIP: "Escribe tu NIP de 4 dígitos."
  4. Short NIP: "Al NIP le falta 1 dígito." / "Al NIP le faltan N dígitos."
  5. Wrong pair (NIP label turns red): "Tu celular o tu NIP no coinciden. Revísalos o escríbele al taller."
- Valid pair goes to Pedidos. Until the API existed, a demo client signed in with a fixed NIP;
  sign-in now goes through Supabase (`acceso-cliente-supabase.md`), that NIP was rotated, and no
  working NIP is ever recorded in this repository.
- "Olvidé mi NIP" and the help button open the Ayuda sheet.
- Bottom: "¿Primera vez?" + card "Agenda una cita / Eliges tus arreglos y creas tu NIP." → Servicios.

### Ayuda sheet
- Modal bottom sheet over an ink 35 % scrim; enters in 420 ms with `cubic-bezier(0.32, 0.72, 0, 1)`, leaves in 240 ms; no animation when the OS asks for reduced motion.
- Grabber, title "¿Te ayudamos?", "Listo" closes it.
- Group of rows: "Escribir por WhatsApp", "Llamar al taller", "Cómo llegar"; footnote "Taller Cancún · [DIRECCIÓN DEL TALLER] · 10:00 a 18:00".

## Tasks
- [x] Tests from the spec (RED): login rules, Entrada widget behaviour, Ayuda sheet, app smoke test.
- [x] Tokens in `AppColors` / `AppText`.
- [x] Shared widgets: inset group, labeled field row, primary button, press scale, icon row, top app bar restyle, help sheet.
- [x] Entrada screen (GREEN), `flutter analyze` clean.

## Log

### 2026-11-16: feature closed
- Outcome: Entrada and the Ayuda sheet match the design at 390×844 (rendered with Plus Jakarta Sans and compared with the board). 25 tests pass (`flutter test`): login rules in `test/models/login_form_test.dart`, screen behaviour in `test/screens/inicio_sesion_screen_test.dart`, app smoke test in `test/widget_test.dart` (it replaced the template counter test, which failed). `flutter analyze` reports only 3 old issues in `services_screen.dart`, which feature 4 replaces.
- Shared pieces for the next features: tokens in `AppColors` / `AppText`, `InsetGroup`, `LabeledFieldRow`, `IconRow`, `PrimaryButton`, `PressScale`, `showHelpSheet`, restyled `TopAppBarWidget` (the old Pedidos, Perfil and Servicios screens already use it).
- Pending checks: the client's visual sign-off on a device; the Ayuda rows have no action until the workshop's WhatsApp, phone and address exist (then `url_launcher`); sign-in uses `DemoClientAccess` until the API exists, and the API must throttle NIP attempts per phone.
- Next step: feature 2, [Pedidos list and tab bar](pedidos-screen.md).

