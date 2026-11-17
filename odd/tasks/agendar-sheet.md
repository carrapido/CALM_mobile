---
status: done
---

# Agendar sheet and confirmation

Boards "Apple: agendar en una hoja" and "Apple: cita agendada". Source: [design/servicios.html](../design/servicios.html) (`hoja = abierta | confirmada`).

## Spec
- Sheet from 54 pt below the top, page behind recedes (scale 0.94, radius 16); 420 ms in / 240 ms out.
- Header: "Cancelar" (while choosing), title "Agendar cita", "Listo" (when confirmed).
- Summary card: selected names (+ " · Urgente") and "Cotización preliminar: …".
- "Día": month calendar (Noviembre 2026, weeks start Monday, today = 4). Days without free slots are gray and not tappable (past days, Sundays, blocked 6th). Selected day ink circle; today ink ring.
- "Hora": two alarm-style wheels (hours of the day's free range, minutes 00/30), 40 pt rows, center highlight; unavailable values gray; an unavailable time settles to the nearest free slot. Business slots 10:00–17:30 every 30 min; today only 15:30–17:30; the 5th has 12:00, 12:30, 14:30 booked.
- "Tus datos": Nombre, Celular (grouped digits), NIP (4 digits). Errors on confirm: "Escribe tu nombre." / "Escribe los 10 dígitos de tu celular." / "Elige un NIP de 4 dígitos."
- Footer button "Confirmar · Jue 5, 11:00".
- Confirmed: check badge, "Cita agendada", "{summary} · {names}", ticket card "Tu ticket 0937", note, "Ver mi cita" → Pedido detail (appointment).

## Tasks
- [x] Tests from the spec (RED), including free-slot and nearest-slot rules.
- [x] Sheet, calendar, wheels, confirmation (GREEN).

## Log

### 2026-11-16: feature closed
- Outcome: `showScheduleSheet` (`lib/widgets/schedule_sheet.dart`) opens from "Elegir horario" with the calendar, the `CupertinoPicker` wheels, the client's data and the confirmation with ticket 0937; "Ver mi cita" opens the appointment in Pedido detail. Rules live in `AppointmentAgenda` and `BookingForm`; `FieldProblem<F>` now backs both `LoginProblem` and the booking errors. `HelpSheet` and this sheet share `sheetMotion` and `SheetGrabber` (`sheet_parts.dart`).
- Deviation: the page behind does not recede (scale 0.94, radius 16). `showModalBottomSheet` has no such transition; `CupertinoSheetRoute` does, but `showCupertinoSheet`'s `builder` is deprecated in this SDK. Revisit with `CupertinoSheetRoute` if the effect matters.
- Pending checks: agenda, ticket and booking are demo data until the API exists; the new appointment is not added to `Order.demoOrders`.
- Next step: feature 6, [Perfil](perfil-screen.md).

