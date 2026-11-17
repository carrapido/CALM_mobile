---
status: done
---

# Pedido detail and cancel action sheet

Boards "Apple: pedido listo", "Apple: pedido en proceso", "Apple: mi cita". Source: [design/pedido.html](../design/pedido.html) (one component, `status` = appointment | received | inProgress | ready).

## Spec
- Back link "‹ Pedidos" and help button; title "Pedido", "Ticket NNNN".
- Status card (radius 22, soft shadow): work name, headline = state. Orders (not appointments) show a 4-step bar Recibido / En proceso / Listo / Entregado; steps up to the current one are ink, the current label is w800.
- Ready: "Voy en camino" primary button → headline "Vas en camino" and status note "El taller ya sabe que vas en camino".
- Ready or appointment: "Cómo llegar" tinted button → status note "Abrimos Mapas con la dirección". Otherwise "Escribir al taller" opens Ayuda.
- Amount group: "Pago / Total, se paga en el taller" or, for appointments, "Cotización / Cotización preliminar".
- Appointment: "Cancelar cita" (destructive `#DC2626`) opens an iOS action sheet: "¿Cancelar tu cita?" / "Tu horario del jueves 5 a las 11:00 queda libre para alguien más." / "Sí, cancelar la cita" (→ Entrada) / "No, conservarla". When cancel is not allowed: "Faltan menos de 24 horas para tu cita: para cancelarla, escríbele al taller."
- "Más" group: "Agendar otra cita" → Servicios. Tab bar with Pedidos current.
- Demo tickets: appointment 0937 Ajuste de cintura $180; received 2290 Bastilla de 2 pantalones $200; inProgress 5512 Ajuste de vestido de novia $900; ready 7720 Cambio de cierre de chamarra $150.

## Tasks
- [x] Tests from the spec (RED).
- [x] Pedido detail screen, action sheet (GREEN). Replace `OrdersScreen` widgets that become unused.

## Log

### 2026-11-16: implementation done, one test blocked
- Outcome: `OrderDetailScreen` covers ready / received / in progress / appointment, "Voy en camino", "Cómo llegar", "Escribir al taller", and the cancel action sheet (`CupertinoActionSheet` via `showCupertinoModalPopup`). Route `/order` takes the `Order` as argument (`AppRoutes.onGenerateRoute`). 10 of 11 tests pass.
- Blocker: "takes the client to Servicios to book another appointment" taps a row that, in the 800×600 test viewport, sits under the tab bar, so the tap lands on the bar (hit-test warning). The test needs `await tester.ensureVisible(find.text('Agendar otra cita'));` before the tap; the expectation stays. Editing the locked test was denied by the permission classifier, so it waits for the user's decision.

### 2026-11-16: feature closed
- Outcome: the user removed the test lock; the blocked test now calls `ensureVisible` and then `pump()` before the tap. `Scrollable.ensureVisible` only jumps the scroll offset, so without a frame the tap still used the old position. 11 of 11 pass; full suite 92 of 92, `flutter analyze` clean. Every file in `lib/` is imported somewhere.
- Also: the temporary golden preview (`test/zz_preview_test.dart`) was used to check Agendar's data and confirmation states against the design, then deleted.
- Pending checks: none for this feature. Across the objective: nothing is committed; Ayuda rows have no actions; sign-in, agenda, ticket and profile changes are demo data until the API exists; the sheet's receding page effect is not implemented.
- Next step: all specific objectives are done. Next is the user's call (commit, API integration, or Ayuda actions).

