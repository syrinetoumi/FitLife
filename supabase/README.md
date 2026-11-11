# Sports spaces backend and configuration

## Current notifications — Novu, confirmation only (2026-11-11)

Novu replaces the earlier email integration. The only notification is **“Votre souscription est confirmée.”** It appears in FitLife's bell/inbox on the home and connected sports screens. Opening the bell loads the signed-in user's inbox; tapping an unread message marks it read. The badge refreshes after subscription/reading, on app resume and every 30 seconds while foregrounded. The inbox lists the latest 50 messages and provides refresh/retry controls. Notification delivery may complete shortly after the subscription; refresh the inbox if needed.

- The Development workflow `fitlife-subscription-confirmed` is created, active, tagged `fitlife-confirmation`, with one in-app step and no email, push, SMS or expiry steps.
- The approved Novu key is stored in ignored backend configuration and Supabase secrets. `NOVU_API_URL=https://api.novu.co`, `NOVU_WORKFLOW_ID=fitlife-subscription-confirmed` and `NOVU_ENABLED=true` are configured. Flutter receives no Novu credential.
- Applied migration `20261111070018_notifications_novu_confirmation` adds the server-owned recipient, replaces queue processing with confirmations only and stops creation of expiry reminders. Pending events from the previous provider are marked ignored; no old subscription confirmations are replayed.
- `espaces-notifications` is deployed with explicit Supabase Auth verification for inbox/sync/read actions. It derives the subscriber ID from the validated JWT and requires an active profile. The scheduler uses its separate worker secret. Private queue/RPC access remains service-only.
- The one-minute scheduler `fitlife-notifications-espaces` is enabled for confirmation processing. Successful subscriptions request an immediate owner-scoped sync; provider failures leave committed subscriptions intact and the scheduler retries. Stable UUIDs are used as both Novu idempotency headers and transaction IDs; the existing conservative 25-minute retry cutoff remains.
- The home sports card now opens `/espaces` with `EspacesConnectesScreen`, rather than directly creating a local preview. `EspacesSportifsScreen` requires an explicit data source, preventing accidental default demo data. The separate preview entry point remains explicit and is outside normal app navigation.
- Runtime tests, live test notifications and application launches were not performed for this Novu setup, at the user's request. Earlier API test records below concern the previous provider and do not validate Novu. Restart the app after changing from the already-open demo screen.

Inbox reader correction (2026-11-11): the deployed adapter accepts both a direct `data` list and a nested `data.data` list for Novu inbox responses, and normalizes count envelopes. Previously, a valid direct list could be rejected as malformed and displayed as unavailable. Diagnostic logs contain only fixed error codes/statuses, never subscriber IDs or notification content. No test notifications were sent for this correction.

Configuration template: [functions/.env.example](functions/.env.example). Provider reference: [Novu API](https://docs.novu.co/api-reference), [current OpenAPI contract](https://api.novu.co/openapi.json), [idempotency](https://docs.novu.co/api-reference/idempotency).

## Manual API data preparation

Data preparation update (2026-11-11): at the user's request, [ajouter_donnees_espaces.sql](tasks/ajouter_donnees_espaces.sql) added eight randomly named fictional spaces, five offers per space across all 13 spaces (65 added offers; 52 active), 52 equipment rows and missing weekly opening hours. It filled missing coordinates/contact fields without changing existing names, owners or statuses. City/neighborhood addresses are searchable public references; coordinates are reused test landmarks, not verified fictional-business locations. A free one-day offer is included per space. No subscriptions, notifications or external API calls were created by the data script. The script is repeatable and belongs to manual data preparation, not migration history.

## Historical email preparation — superseded by Novu

## Resend subscription emails — implementation started 2026-11-11

Resend replaces Brevo after phone verification blocked its API key. Supabase remains the database, Auth and worker backend. The earlier mobile-push integration was removed. This feature does not change Supabase Auth email configuration.

Backend preparation is deployed as of 2026-11-11. No tests, worker invocation, app build or email send was performed. Existing merge issues in sports routes, shared-role helpers and preview/connected interfaces remain outside this provider replacement.

| Component | Current preparation state |
| --- | --- |
| Resend account / key | Account created; approved key “FitLife subscription emails” created with Sending access. Stored in ignored backend configuration and Supabase secrets. |
| Sender / recipients | `onboarding@resend.dev`; restricted to the Resend account email. No owned domain is configured. |
| Notification migration | Applied as `20261111030309_notifications_espaces_brevo`; retained unchanged because it is already hosted history. Its private queue is provider-independent. |
| Scheduler prerequisites | Applied as `20261111030615_preparer_planification_notifications`; pg_cron and pg_net enabled. |
| Email worker | Resend implementation deployed as `espaces-notifications`; deployment returned ACTIVE version 4. Later secret changes may advance its version. |
| Backend settings | Resend key, sender settings, restricted recipient, worker secret and `EMAIL_SENDING_ENABLED=false` configured. Unused Brevo settings removed. |
| Vault / cron | Worker URL and scoped worker secret stored in Vault. One-minute `fitlife-notifications-espaces` job confirmed **active=false**. |
| Delivery | Disabled by both the worker flag and inactive cron. Runtime delivery remains unverified. |

Read-only metadata previously confirmed queue RLS, no anon/authenticated table grants, and service-only execution of the three worker RPCs. This is configuration inspection, not behavioral acceptance. Private credentials must never enter Flutter, source control or documentation.

### Verification update — 2026-11-11

The user subsequently requested API tests and approved one test email. Hosted geocoding returned HTTP 200 with five public-place results. Walking, cycling and driving routes returned HTTP 200 with positive distance/duration and route geometry using an explicit public starting point. Unauthenticated calls returned 401 and athlete geocoding returned 403. The repeatable check is [check_location_apis.py](../scripts/check_location_apis.py); it uses ignored test-account credentials and logs no tokens or account addresses.

One direct Resend API test returned HTTP 200; the authenticated Resend dashboard showed **Delivered** for “FitLife — API connection test.” The sending-only key correctly refuses email-status reads, so dashboard access supplied delivery evidence. An authenticated worker request still returned HTTP 503 with sending disabled. Automatic sending and cron remain disabled. This test does not establish subscription-trigger/reminder delivery acceptance.

Both existing location-dialog widget tests passed (automatic initial calculation and denied-permission recovery). Device GPS, browser permission prompts and an actual device position were not exercised. Location permission is requested only by the estimate action; external map/directions links do not request FitLife location access. A destination needs coordinates, and connected data must be loaded for the estimate button to be available.

### Configuration and activation

1. Backend settings: `RESEND_API_KEY`, `RESEND_SENDER_EMAIL`, `RESEND_SENDER_NAME` (defaults to FitLife), `RESEND_ALLOWED_RECIPIENT`, `EMAIL_SENDING_ENABLED` and `NOTIFICATIONS_WORKER_SECRET`. Keep sending false during preparation. The checked-in template contains no credentials.
2. Without an owned domain, use `onboarding@resend.dev` and set `RESEND_ALLOWED_RECIPIENT` to the account email in private configuration. The worker requires this restriction for a resend.dev sender; other recipients are skipped as `IGNOREE` / `DESTINATAIRE_RESTREINT`. This mode cannot deliver subscription emails to other users.
3. For delivery to real users, verify an owned sending domain in Resend, replace the sender and remove the account-only restriction. Prepare and review this change before enabling automatic processing.
4. Both notification/scheduler migrations are already applied to FitLife. Preserve their historical filenames. In a new environment, apply them through the migration workflow; do not replay hosted history.
5. Deploy `functions/espaces-notifications`. Gateway JWT verification is disabled because the endpoint authenticates `x-worker-secret`; only the server uses the service-role credential. Clients cannot select recipients or message contents.
6. Vault entries `fitlife_notifications_url` and `fitlife_notifications_secret` and [the inactive scheduler](tasks/planifier_notifications.sql) are configured. When delivery is ready and activation is authorized, set `EMAIL_SENDING_ENABLED=true` and activate the named job using the script's final command.
7. Verify sender, eligibility, retries and actual delivery later using [the plan](../../Fit%20Life%20Docs/PLANS.md). Tests and live sends remain deferred at the user's request.

### Delivery behavior

A committed subscription queues one confirmation. The scheduler queues one reminder per active subscription/end date three days before expiry, using Africa/Tunis dates. Confirmations are valid for 24 hours; reminders only on the reminder date. Existing subscriptions receive no retroactive confirmation.

Recipients come from confirmed `auth.users` emails belonging to active profiles. The worker rechecks subscription/profile/date eligibility before sending. Emails contain space, offer, validity dates and stored amount as plain text. No marketing contacts or campaigns are created.

The private queue uses five-minute leases and batches of at most 20. Provider failures do not roll back subscriptions. The event UUID becomes the Resend `Idempotency-Key` HTTP header. Resend retains keys for 24 hours. The existing migration conservatively stops retries after 25 minutes from the first attempt and moves unresolved events to `A_VERIFIER`; failures within that window retry after 15 minutes. This shorter policy is retained without rewriting applied migrations.

A successful response with an `id` marks `ACCEPTEE`, meaning provider acceptance, not inbox delivery. A 409 `invalid_idempotent_request` becomes `A_VERIFIER`; it is not success. Invalidated/restricted events become `IGNOREE`. The queue stores codes and provider IDs, not recipient addresses or complete provider responses. Delivery webhooks and preferences UI are deferred.

References: [Resend sending API](https://resend.com/docs/api-reference/emails/send-email), [idempotency](https://resend.com/docs/dashboard/emails/idempotency-keys), [account-only resend.dev sending](https://resend.com/docs/knowledge-base/403-error-resend-dev-domain), [verified domains](https://resend.com/docs/dashboard/domains/introduction).

Implementation snapshot: 2026-11-03, based on branch `espaces-sportifs`, commit `26fc6c1` plus the current uncommitted integration changes.

The target is the existing FitLife Supabase project. The four October migrations were recovered from its applied migration history. They depend on the shared `profiles` table and user enums; this directory is not a bootstrap for the whole application. The two November migrations are applied remotely and their filenames match the hosted versions. Do not replay the history blindly.

## Private files

- `../.env`: public client settings only. Launch with `flutter run --dart-define-from-file=.env` or build with `flutter build apk --release --dart-define-from-file=.env`.
- `functions/.env`: backend provider settings. Fill `OPENROUTESERVICE_API_KEY` and `GEOCODING_CONTACT_EMAIL`. The other variables identify the geocoding provider and app. This file is ignored and is never a Flutter asset or build input.
- `../.env.test.local`: test account emails and password. Never pass it to Flutter build defines or deploy it as function secrets.
- `.env.example` templates contain no credential values. Supabase URL and publishable key are public client configuration; secret/service-role keys must remain on the backend.

Local files do not automatically update hosted function secrets. Use Supabase Dashboard > Edge Functions > Secrets to add only the provider variables, then test the function. Supabase supplies its own server credentials to hosted functions automatically. Alternatively use the verified CLI `npx --yes supabase secrets set --env-file supabase/functions/.env --remote=uewrslcvajwqcndfcjxr` after signing in. Do not upload `.env.test.local`.

## Location APIs

`espaces-localisation` is deployed. Gateway JWT verification is disabled because the function itself validates each bearer token with Supabase Auth and checks the active server profile. Missing/invalid tokens return 401; insufficient roles return 403. Geocoding is restricted to managers/admins. Routes validate the destination using the caller’s RLS-protected client. Only the backend receives supplier keys.

Geocoding uses manual searches of public establishments, selected results, provider attribution, a shared database throttle, and a 30-day cache. There is no autocomplete. On a cache miss the database reserves a 20-second request slot; a successful cache write releases it after another two seconds. Errors retain the longer cooldown. The provider base URL is configurable. Follow the [Nominatim policy](https://operations.osmfoundation.org/policies/nominatim/); do not send private/confidential addresses or use the service for bulk searches. Routing uses OpenRouteService with explicit starting coordinates and one of walking/cycling/driving modes. Starting coordinates are not written to the database.

Provider secrets were deliberately deferred by the user. Successful external geocoding/routing responses are not yet verified. Auth/refusal paths were exercised against the deployed function. The two APIs cannot be counted as fully validated until their success paths pass with configured provider access.

## Accounts

The manager account was created through Supabase Auth with `GESTIONNAIRE_ESPACE`. The admin profile was corrected to `ADMIN`. Both are currently unconfirmed, and the admin rejected the supplied test password. Their owner must confirm/setup those accounts using a trusted Supabase Auth administration flow. An optional local script, `python scripts/configure_test_accounts.py` from the app root, uses the official Auth admin API to confirm only these two approved accounts and set the supplied private test password. Fill `SUPABASE_SECRET_KEY` in ignored `.env.admin.local` first; this key is for one-time local administration only and must never enter Flutter or hosted provider secrets. The script has not been executed against Auth because no admin key was supplied. The athlete and both coach logins passed with the private test configuration. Do not fix this by disabling email confirmation globally or inserting password hashes into Auth tables.

## Verification

`tests/espaces_integration.sql` exercises manager creation, hours and overlap refusal, exact offer price, athlete subscription and duplicate refusal, status transitions without extending dates, ownership denial, role escalation denial, admin activation, and anonymous profile denial. It rolls back every temporary business row. This verifies database roles/claims, not successful manager/admin Auth sign-in or the complete Android journey.

Run `node supabase/tests/localisation_validation_test.mjs` for coordinate/profile boundary checks. The Flutter repository test checks real request shapes, exact monetary strings, server-generated ownership/IDs, and offline read-only behaviour using an HTTP mock.

The Docker executable exists, but its daemon is stopped. No isolated local Supabase stack was provisioned. Four nutrition tables still have disabled RLS; they belong to another module and were not changed. Session occupancy and training equipment requirements remain a coordination task. Availability in the sports UI explicitly covers weekly hours/equipment only and does not reserve a coach session.

## Latest application checks

The final working tree passed 19 Flutter tests and scoped analysis with no issues. The Android release was built using only `../.env` public settings. The handoff APK is `../build/releases/fitlife-sports-integration-2026-11-03-release.apk`; its adjacent JSON records the hash and limitations. It uses the project’s existing development signing configuration. This is not a store-signed release or physical-phone acceptance result.

Android smoke verification: the release installed and cold-launched successfully on `emulator-5554`; the supplied athlete signed in, the home sports-space card opened the live catalogue, and the process remained running. The catalogue correctly showed zero spaces because no persistent demonstration business rows were seeded. Screenshots are saved beside the release APK. Manager creation/athlete discovery with persistent records and physical-device acceptance remain pending account setup.

The exact final APK also installed and cold-launched successfully after replacing only the emulator’s FitLife package while retaining its data. The athlete session survived, and the home sports-space card remained accessible. The emulator initially lacked space for an in-place update; no other application was removed.

## Demo catalogue seeded, 2026-11-04

At the user’s request, `seeds/espaces_demo.sql` added four active fictitious venues owned by the existing manager test account: Atlas Training Club, Terrain Horizon, Bassin Azur and Parc Énergie. Names carry a Démo prefix and descriptions explicitly identify illustrative locations. There are 12 equipment rows, 28 weekly opening intervals and 8 active offers. No subscriptions or account changes were created. The script inserts only missing demo venues and does not overwrite existing data. A real athlete sign-in verified all four venues and their related equipment/hours/offers through the same RLS-protected HTTP API used by the app. Refresh the sports-space screen to load them. The earlier zero-row observations above are historical.

## API configuration completed, 2026-11-04

The user supplied the provider key privately. Nominatim contact/provider settings and the OpenRouteService key are now configured in the ignored backend env file and the hosted function secrets. No provider key was added to Flutter, source control or these notes. The deployed location function now uses `https://api.heigit.org/openrouteservice/v2/directions/{profile}/geojson`, following the provider’s [endpoint migration announcement](https://ask.openrouteservice.org/t/deprecating-api-openrouteservice-org-in-favour-of-api-heigit-org/7912).

A real athlete Auth session called the deployed function for a walking route from a public Tunis point to the seeded Atlas demo space. The response passed validation: approximately 8.25 km, 99 minutes and 185 geometry points. A direct Nominatim public-city query also returned valid coordinates. Manager geocoding through the app is still unverified because the manager Auth account returns `email_not_confirmed`; its confirmation is the remaining account prerequisite. These results supersede earlier statements that provider settings were deferred.

No mobile rebuild is needed for the hosted secret/endpoint changes. In the integrated app, use Espaces sportifs > Localisation > Estimer distance et durée. The geocoding search is in the manager’s space editing form.

## Direct test-account setup and working geocoding, 2026-11-04

The user requested direct Supabase setup without confirmation emails for the supplied test users. The existing manager/admin users were marked confirmed through the Auth admin API and configured with the supplied private test password. All five test logins passed and roles were preserved. The administration credential was used only in memory and was not stored in the client or local configuration.

Nominatim returned HTTP 403 from the hosted function even though a direct public-city lookup worked from the development machine. The configured provider is now `GEOCODING_PROVIDER=heigit`, using the existing key’s Pelias geocoding service. An authenticated manager search passed through the deployed function. Results retain provider/source attribution and the cache key includes the provider. Nominatim remains an optional adapter; it is not retried as an automatic fallback when the selected provider refuses access. Earlier unconfirmed-account and missing-provider notes above are historical.

The new mobile estimate obtains the current device location automatically after OS permission, then uses the existing authenticated routing API. It requires the updated APK because GPS is a new native plugin/permission. Starting coordinates are not stored in the database. No background location access was added.
