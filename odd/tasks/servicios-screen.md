---
status: done
---

# Servicios catalog

Board "Apple: servicios". Source: [design/servicios.html](../design/servicios.html) (`hoja = cerrada`).

## Spec
- Help button; title "Servicios"; lead "Marca lo que necesitas y elige tu horario."
- Inset group of toggle rows (min 60 pt): name, price (`$180`, 17 w700) or "A cotizar" (15 w600 secondary), 24 pt round check (ink filled with a check when selected, ink 30 % ring otherwise).
- Catalog: Ajuste de cintura 180, Ajuste de vestido de fiesta 300, Vestido Personalizado (a cotizar), Cambio de cierre 130, Dobladillo de pantalón 100, Parche 40.
- Footnote "El precio final se confirma al revisar tu prenda."
- "Extras": "Prenda urgente" with an iOS switch and "Cargo extra" (or "+$N" when the surcharge is set); footnote "Te la entregamos antes. El cargo se suma a tus arreglos."
- Floating selection bar above the tab bar while something is selected: "1 arreglo" / "N arreglos" (+ " · urgente"), quote line, "Elegir horario" button → Agendar sheet (feature 5).
- Quote: sum of priced services (+ surcharge) as "$N MXN"; unpriced adds "a cotizar" (or "A cotizar en el taller" alone); urgent without amount adds "cargo por urgencia".
- Tab bar with Servicios current.

## Tasks
- [x] Tests from the spec (RED), including the quote rules.
- [x] Servicios screen (GREEN). Remove `ServiceCardWidget` if unused.

## Log

### 2026-11-16: feature closed
- Outcome: `ServicesScreen` replaced with the design's catalog, iOS switch for "Prenda urgente" and the floating selection bar. Quote rules live in `ServiceSelection` (`test/models/service_selection_test.dart`); screen behaviour in `test/screens/services_screen_test.dart`. `ServiceCardWidget` removed.
- Found and fixed: the tab bar had a fixed 49 pt height, so a wide font or large accessibility text clipped its labels; it now has a minimum height and single-line labels.
- Pending checks: the urgency surcharge is 0 until the workshop defines it ("Cargo extra").
- Next step: feature 5, [Agendar sheet](agendar-sheet.md).

### 2026-11-24: Servicios is for signed-in clients only ([flujo-primera-vez.md](flujo-primera-vez.md))
- S1 (user): "Pantalla de inicio de sesión donde se puede loguear o agendar una cita para los clientes primerizos. Si se seleccionaba la opcion de agendar cita debajo del mensaje de ¿Primera vez? y muestra una hoja que sube en donde seleccionas el servicio, agendas y pones tus datos de nombre, numero y nip. Y solo asi te dejaba ver los demas apartados de la aplicación."
- Entrada no longer opens Servicios; without a session /services opens Entrada (S5). A first-time client marks her repairs on the first step of the Agendar sheet, which reuses this catalog's rows, "Prenda urgente" and quote (`ServicePicker`, `ServiceSelection.fromCatalog`). Signed in, Servicios → "Elegir horario" → the sheet without "Tus datos" is unchanged.
