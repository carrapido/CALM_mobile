---
status: done
---

# Perfil

Board "Apple: perfil". Source: [design/perfil.html](../design/perfil.html).

## Spec
- Help button; title "Perfil"; card with initials avatar (52 pt ink circle), name "Carlos Ruiz", saved phone.
- "Celular": row "Número" (grouped digits); footnote "Con este número entras y te avisamos por WhatsApp."
- "NIP": rows "Actual" and "Nuevo" (4 digits, obscured); footnote "No es para pagar. Escribe el actual para cambiar tu NIP o tu celular."
- Save validation, first problem only, red label: "Escribe tu celular a 10 dígitos." / "Tu NIP actual no coincide." / "El NIP nuevo necesita 4 dígitos." / "El NIP nuevo debe ser distinto del actual." Changing the NIP is optional. A new phone needs the current NIP: "Escribe tu NIP actual para cambiar tu celular." (odd/tasks/telefono-mapa.md).
- Saved: status note "Guardamos tus cambios" replaces the button until the next edit; the card shows the new phone.
- "Cerrar sesión" (destructive) → Entrada, clearing the stack. Tab bar with Perfil current.

## Tasks
- [x] Tests from the spec (RED).
- [x] Perfil screen (GREEN).
- [x] Remove widgets and tokens of the old design left unused (`BotonTaller`, `CampoTaller`, `BottomNavBarWidget`, old `AppColors`/`AppText`/`AppConstants` entries).

## Log

### 2026-11-16: feature closed
- Outcome: `ProfileScreen` replaced with the design: identity card (`UserProfile.initials`), "Celular" and "NIP" groups, save validation in `ProfileForm` (`test/models/profile_form_test.dart`), "Guardamos tus cambios" until the next edit, and "Cerrar sesión" back to Entrada with the stack cleared (`test/screens/profile_screen_test.dart`). `DemoClientAccess.hasNip` checks the current NIP without exposing it.
- Shared pieces: `FormAlert` (centered red message, used by Perfil and the Agendar sheet); `LabeledFieldRow.labelWidth`; `LabeledFieldRow` now sets `maintainHintSize: false`, so a hidden hint leaves the widget tree instead of staying at opacity 0 (same layout, the hint and the text share one line style).
- Removed: `BotonTaller`, `CampoTaller`, `BottomNavBarWidget`, `UserProfile.ticket`, 13 old colors, 11 old text styles and 15 old constants. `AppTheme` now seeds Material from `AppColors.ink`.
- Pending checks: saving changes stays on the device until the API exists. `test/zz_preview_test.dart` is a temporary golden preview that could not be edited or deleted under the test lock; delete it with the lock decision of [Pedido detail](pedido-detail.md).
- Next step: unblock feature 3, [Pedido detail](pedido-detail.md): the user decides on the `ensureVisible` change to its locked test.

