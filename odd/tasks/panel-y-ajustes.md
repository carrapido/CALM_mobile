---
status: in-progress
---

# Panel client enrollment, policy and agenda adjustments, review findings (batch 4)

Spans CALM_web (`feat/panel-clientes`) and calm_mobil (`feat/agenda-y-hallazgos`). Both `main`
branches were merged first, as asked; calm_mobil `main` is pushed, CALM_web `main` waits on its
due review.

## Specs

- **S1** — Order of work: "haz el merge antes de volver a modificar algo".
- **S2** — "Agrega a CALM_web el poder dar de alta a usuarios como dices", as chosen: "Página
  Clientes: alta + NIP que dicta el cliente" — a new section listing the clients, where the admin
  creates a client (name, phone) or picks an existing one, and types the NIP the client tells her
  at the counter. Account rule of `acciones-cliente.md` S2 still holds: an account needs phone and
  NIP.
- **S3** — "Activar el "Leaked password protection"".
- **S4** — "Regenera el database.types.ts en CALM_web".
- **S5** — "Reseulve las polices de lectura": the advisor's `multiple_permissive_policies` on the
  admin and client SELECT policies, without widening or narrowing what anyone reads.
- **S6** — "Haz que la agenda muestre los dias siguientes al mes en curso, para que al fina de mes
  no muestre pocos dias para agendar", as chosen: "Flechas para pasar al mes siguiente" — the
  calendar stays one month with ‹ › to the next; booking covers the current and the next month.
- **S7** — Review findings of lineage `review-fc190b36772165fa`, all of them ("Todos"):
  R1-001 rotate María's NIP and keep working credentials out of committed docs;
  R2-credentialsMatch-true-trick, R2-isSigningIn-setState-without-ui,
  R2-stale-spec-line-reference, R2-unrelated-gitignore-entry, R2-unused-client-payload-parsing,
  R3-partial-session-on-parse-failure, R3-stale-answer-after-edit, R3-untested-status-mapping,
  R4-session-installed-before-parse, R4-signin-no-timeout-stuck-guard.
  R2-demo-access-name-collision is already gone: batch 3 removed `DemoClientAccess`.
- **S8** — Out of scope by the user's word: "Se puede ignorar lo de test dobladillo y el cargo por
  urgencia"; "Por el momento dejamos sin asignar el "como llegar", el Whatsapp y el "lalmar al
  taller"".
- **S9** — No secret and no working NIP in any committed file.
- **S10** — Derived: where the sheet opens across two months. Batch 2's rule (first free day after
  today; today only when no later day is free) now looks at both months, so on the last morning of
  a month it opens on the next month's first free day. ‹ and › go only to a month with a free day;
  another month opens on its first free day at the free time closest to the one chosen.

## Tasks

- [x] **T0** (S1) — Merge both feature branches into `main`; push calm_mobil (`1468610`).
- [x] **T1** (S7, S9) — Rotate María's NIP; remove working NIPs from the docs.
- [x] **T2** (S7) — Sign-in findings: parse before installing the session, timeout, disabled
      button while waiting, outcome ignored when the form changed, mapping tests, named form API.
- [x] **T1 commit** — `f4e5d16`; **T2** — `be5a019`.
- [x] **T3** (S6, S10) — `booking_calendar` covers this month and the next; the sheet navigates ‹ ›.
      CALM_web `b633ff8`.
- [ ] **T4** (S5) — One SELECT policy per table and role.
- [ ] **T5** (S2) — `admin-enroll-client` function and the panel's Clientes page.
- [ ] **T6** (S4) — `database.types.ts` regenerated.
- [ ] **T7** (S3) — Leaked password protection on.

## Log

- **L1** — Request, verbatim: "En teoria ya lo resolvi lo de los modelos review, haz el merge antes
  de volver a modificar algo / Se puede ignorar lo de test dobladillo y el cargo por urgencia /
  Agrega a CALM_web el poder dar de alta a usuarios como dices / Activar el "Leaked password
  protection" / Regenera el database.types.ts en CALM_web / Reseulve las polices de lectura / Haz
  que la agenda muestre los dias siguientes al mes en curso, para que al fina de mes no muestre
  pocos dias para agendar / Por el momento dejamos sin asignar el "como llegar", el Whatsapp y el
  "lalmar al taller"". Choices: merge local and push; Clientes page with the NIP the client
  dictates; arrows to the next month; fix all findings.
- **L2** — Review of the sign-in (calm_mobil, `review-fc190b36772165fa`): approved by four
  reviewers, twelve non-blocking findings (S7). Its acknowledgement could not be applied: bound
  STATUS reports the lineage `unrelated` to the current candidate and offers no continuation.
- **L3** — CALM_web delivery: assess reported `reviewDue: true` (`high_risk`, auth in
  `_shared/client-auth.ts`). Review `review-a5346d502e5ebea2` ran its three lenses, then needed the
  refuter, whose model (`google/gemini-4-argon`) answered 403 "Permission denied on the service".
  The push waits on it; CALM_web work continues on `feat/panel-clientes`.
- **L5** — Evidence for T1 (R1-001): María's NIP replaced by a random one given to the user in the
  conversation only; her 12 auth sessions deleted, so no refresh token issued under the old NIP
  survives; the old NIP answers 401 and the new one 200. The docs that claimed a working pair
  (`acceso-cliente-supabase.md` L7, `entrada-screen.md`) no longer name a NIP; the old value still
  appears as typed input in tests against fakes and in the design prototypes, where it opens
  nothing. R2-stale-spec-line-reference fixed in the same pass. R2-unrelated-gitignore-entry kept
  as is: `.pi/` still keeps the local MCP config out of git, and the published history is not
  rewritten.
- **L6** — T2 closes eight sign-in findings. The session is installed last, once the answer is
  known to carry a refresh token, and the unused client payload is no longer parsed
  (R2-unused-client-payload-parsing, R3-partial-session-on-parse-failure,
  R4-session-installed-before-parse); the call gives up after 15 s as unavailable and the button
  reads "Entrando…" disabled meanwhile (R4-signin-no-timeout-stuck-guard,
  R2-isSigningIn-setState-without-ui); a refusal for a pair edited meanwhile is dropped while a
  granted sign-in still goes on, its session being installed (R3-stale-answer-after-edit);
  `LoginForm.incompleteProblem` and `LoginForm.mismatch` replace the double `firstProblem` call
  (R2-credentialsMatch-true-trick); `SupabaseClientAccess.using` takes stand-ins, and nine unit
  tests cover 401, 429, other statuses, no network, answers without a token, a session that fails
  to install, and the timeout (R3-untested-status-mapping). 155 tests, analyze clean. "Entrando…"
  is new wording the design never needed. `ActionButton.onPressed` became nullable, which no
  existing caller notices.
- **L7** — Evidence for T3: `booking_calendar` applied (recorded as `20261123000424`, the file
  carries that name); a day blocked in December for the test appeared in its answer and was
  removed; grants unchanged (anon, authenticated). The app's `BookingMonths.fromCalendar` on the
  live answer: November 6 free days from the 23rd, December 27 from the 1st, opening on the 23rd.
  168 tests, analyze clean.
- **L4** — CALM_web's `src/access` tests failed to load on `main` before any of this work too:
  `node_modules` predated `@supabase/supabase-js`. `npm ci` fixed it: 22 files, 130 tests pass.
