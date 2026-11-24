---
status: in-progress
---

# Teléfono con NIP y "Cómo llegar" (app)

The app side (T2) of CALM_web/odd/tasks/telefono-whatsapp-mapa.md; its Specs S1, S2, S4, S5 are authoritative.

## Tasks

- [x] T2 (S1, S2, S4, S5) Perfil asks the current NIP for a phone change; "Cómo llegar" in Pedido and Ayuda opens the Maps link; address placeholders filled.

## Log

- **L1** Perfil (S2): `ProfileForm` takes `savedPhone`; a different phone (by digits) with an empty "Actual" stops on that field with "Escribe tu NIP actual para cambiar tu celular." before anything is sent. With a new phone the current NIP alone changes no NIP (only `phone` + `currentNip` travel, as `ApiClientData.saveProfile` already sent it); a new NIP keeps today's rules. The API's 400/401 `current_nip` stays on "Actual" with its wording, 429 stays the throttled message. "Cómo llegar" (S4) in `OrderDetailScreen` and in `HelpSheet` opens https://maps.app.goo.gl/nGsvenuYn4VE4rBfA?g_st=aw through `openWorkshopMap` (lib/services/external_links.dart: url_launcher, `LaunchMode.externalApplication`, behind `LinkOpenerScope` so tests read the link); Pedido keeps "Abrimos Mapas con la dirección" when it opens, and both say "No pudimos abrir Mapas. Estamos en <dirección>" when nothing takes it. Android 11+ `<queries>` for https VIEW added; iOS needs no LSApplicationQueriesSchemes (launchUrl on https, no canLaunchUrl). Address and link live in `AppConstants.workshopAddress` / `workshopMapsUrl` (S5): the Ayuda footnote is now "Taller Cancún · Benito Juárez 223, casa 22, Los Héroes, Mz 10, 77517 Cancún, Q.R. · 10:00 a 18:00". odd/design/ayuda.html still shows the old placeholder (outside this task's edit surface).
