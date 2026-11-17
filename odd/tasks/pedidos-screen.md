---
status: done
---

# Pedidos list and tab bar

Board "Apple: pedidos". Source: [design/pedidos.html](../design/pedidos.html).

## Spec
- Header with help button only; large title "Pedidos".
- Section "Activos": inset group of rows (min 68 pt) with a status dot, work name (17/22 w600) and status (15/20). An order that needs the client ("Listo para recoger") has a filled ink dot and bold ink status; the others an outlined `#9AA1AC` dot and secondary status. Rows open the Pedido detail (feature 3).
- Section "Entregados": plain rows in secondary color, "Entregado el 12 de octubre".
- Demo data: "Cambio de cierre de chamarra" (Listo para recoger), "Ajuste de cintura" (Cita agendada), "Ajuste de vestido de novia" (En proceso); delivered "Dobladillo de pantalón".
- "Agendar una cita" tinted button (ink 6 %) with a plus icon → Servicios.
- Tab bar (shared by Pedidos, Pedido, Servicios, Perfil): 83 pt, translucent `rgba(248, 250, 252, 0.78)` with 20 px blur (solid white when the OS asks for less transparency), top hairline ink 8 %; items Pedidos / Servicios / Perfil; the current one sits in an ink 9 % pill with w800 label. Replaces `BottomNavBarWidget`.
- Ayuda sheet from the help button (feature 1).

## Tasks
- [x] Tests from the spec (RED).
- [x] Tab bar widget, Pedidos screen (GREEN).

## Log

### 2026-11-16: feature closed
- Outcome: `OrdersScreen` replaced with the design's Pedidos; `AppTabBar` (translucent, blurred, current tab in a pill) and the `TabPage` skeleton are shared by every tab screen. Tab roots open without transition and clear the stack (`AppRoutes.onGenerateRoute`). `Order` now models the design's statuses. Tests: `test/widgets/app_tab_bar_test.dart`, `test/screens/orders_screen_test.dart`.
- Pending checks: Flutter has no "reduce transparency" setting, so the bar stays translucent always. `BottomNavBarWidget` is removed with the last old screen (feature 6).
- Next step: feature 3, [Pedido detail](pedido-detail.md).

