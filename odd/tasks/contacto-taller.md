---
status: in-progress
---

# Teléfono del taller y ejemplos genéricos (app)

The app side (T3) of CALM_web/odd/tasks/borrar-clientes-contacto.md; its Specs S1 and S2 are authoritative.

## Tasks

- [x] T3 (S1, S2) "Escribir al taller" opens WhatsApp and "Llamar al taller" dials the workshop phone; phone examples read "998 XXX XXXX".

## Log

- **L1** S1: the phone lives once in `AppConstants` (`workshopPhone` "998 325 9560", `workshopWhatsAppUrl` https://wa.me/529983259560, `workshopCallUrl` tel:+529983259560), next to the address and map link. `openWorkshopWhatsApp` / `callWorkshop` (lib/services/external_links.dart) go through `LinkOpenerScope`. Pedido's "Escribir al taller" (orders not needing the client) now opens WhatsApp directly instead of the help sheet; Ayuda's "Escribir por WhatsApp" and "Llamar al taller" rows open WhatsApp and the dialer. When nothing takes the link they say "No pudimos abrir WhatsApp. Escríbenos al 998 325 9560" / "No pudimos abrir el teléfono. Llámanos al 998 325 9560", in the "Cómo llegar" FormAlert style (the sheet shows one failure at a time). Android 11+ `<queries>` gains DIAL for `tel`; iOS needs no LSApplicationQueriesSchemes (launchUrl only). S2: Entrada, Agendar and Perfil phone hints read "998 XXX XXXX" (all from `AppConstants.hintPhone`); the name hint stays "Tu nombre"; no other realistic example is shown in lib. Doc comments in utils/telefono_formatter.dart and models/user_profile.dart keep "998 123 4567" (not user-facing); test fixtures keep their sample data.
