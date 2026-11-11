# Sports spaces backend and configuration

## Brevo subscription emails — implementation started 2026-11-11

The user replaced mobile push with Brevo transactional email. No mobile notification SDK, Firebase setup, public provider App ID, device alias or notification permission is required. Supabase remains the backend and Auth provider. This feature does not change Supabase Auth's existing email configuration.

Backend preparation is deployed as of 2026-11-11. The user asked to continue while Brevo SMS verification is stuck. No tests, worker invocation, app build or email send was performed. The existing merge baseline still has duplicate sports routes, missing shared-role helpers and mismatched preview/connected sports interfaces; those earlier problems are outside this provider replacement.

| Component | Current preparation state |
| --- | --- |
| Brevo account / sender | Account created; the chosen sender is verified in Brevo. Phone verification is blocking API-key generation. The user approved a key restricted to transactional email; no key has been generated yet. |
| Notification migration | Applied as `20261111030309_notifications_espaces_brevo`; local filename matches hosted history. |
| Scheduler prerequisites | Applied as `20261111030615_preparer_planification_notifications`; pg_cron and pg_net enabled. |
| Email worker | `espaces-notifications` deployed; latest observed function version 2. |
| Backend settings | Sender email/name, worker secret and `BREVO_SENDING_ENABLED=false` stored in Supabase. `BREVO_API_KEY` is still pending. |
| Vault / cron | Worker URL and scoped worker secret stored in Vault. `fitlife-notifications-espaces` exists with a one-minute schedule and **active=false**. |
| Delivery | Disabled both by the worker's sending flag and the inactive cron job. No email or test request was sent. |

Read-only metadata confirms queue RLS is enabled, no anon/authenticated table grants exist, and the three worker RPCs are executable by service_role but not anon/authenticated. This is configuration inspection, not behavioral acceptance. Temporary secret-bearing setup files were removed; the primary backend env file remains ignored.

### Configuration and activation

1. Create/use a Brevo account and configure a verified sending address or authenticated sending domain.
2. Set backend secrets `BREVO_API_KEY`, `BREVO_SENDER_EMAIL`, `BREVO_SENDER_NAME` (defaults to FitLife), `BREVO_SENDING_ENABLED` and a strong random `NOTIFICATIONS_WORKER_SECRET`. Use an API key, not an SMTP password. Keep `BREVO_SENDING_ENABLED=false` during preparation. Templates contain variable names only. No provider credential belongs in Flutter or root client `.env`.
3. For a new environment, apply `notifications_espaces_brevo` and `preparer_planification_notifications` through the established migration workflow. They are already applied to FitLife. They add the private outbox, subscription-insert trigger, service-only worker RPCs and scheduler extensions. The earlier uncommitted push migration was never applied and was replaced; do not replay hosted history.
4. Deploy `functions/espaces-notifications`. Its gateway JWT check is disabled because the scheduler endpoint uses a dedicated `x-worker-secret` check; clients cannot choose email recipients or message contents. Only the server uses the Supabase service-role credential.
5. For a new environment, enable pg_cron and pg_net and create the two Vault entries `fitlife_notifications_url` and `fitlife_notifications_secret`. Execute [the scheduler setup](tasks/planifier_notifications.sql) to create a one-minute job **inactive**. These preparation steps are complete on FitLife. After the Brevo key is configured and delivery is ready, set `BREVO_SENDING_ENABLED=true` and explicitly activate the named job using the command at the end of that file.
6. Verify the actual sender, recipient, delivery and failure paths later using [the plan](../../Fit%20Life%20Docs/PLANS.md). Tests and live emails remain deferred at the user's request.

### Delivery behavior

A successful subscription transaction queues one confirmation. The scheduler queues one reminder per active subscription/end date three days before expiry, using Africa/Tunis dates. Confirmations are valid for 24 hours; reminders are valid only on the three-day reminder date. Existing subscriptions receive no retroactive confirmation, but may receive eligible reminders after activation.

The worker derives the recipient from `auth.users` using the subscription's owner and requires a confirmed email and active profile. Addresses never come from a Flutter request or editable profile field. The worker rechecks subscription/profile/date eligibility just before sending; cancelled, expired and changed-date events are excluded. The email includes space/offer, validity dates and the subscription's stored amount as plain text. It does not auto-create Brevo marketing contacts or use mailing campaigns.

Private queue rows are locked/claimed with a five-minute lease in batches of at most 20. Network/provider failures do not roll back the subscription. Events retain a stable UUID passed as `headers.idempotencyKey` in the Brevo JSON payload. Brevo's documented deduplication window is only 30 minutes. To avoid blindly resending an email after that window, automatic retries stop 25 minutes after the first claimed attempt and move the event to `A_VERIFIER`; reconcile it in Brevo before manually deciding what to do. Failures inside that window retry after 15 minutes.

Brevo `messageId` responses and idempotency `duplicate_parameter` responses mark the event `ACCEPTEE`. This means provider acceptance, not inbox delivery. Invalidated events become `IGNOREE`. The queue stores status codes and provider message IDs, not recipient addresses or entire provider responses. There is no delivery-webhook, unsubscribe/preferences UI or marketing-message implementation in this first step.

The worker sends no emails unless `BREVO_SENDING_ENABLED=true`, its credentials are configured and an authorized invocation occurs. The cron job is currently inactive. Flutter dependency resolution completed after removing the push SDK; no tests, app build or live send were performed.

References: [transactional sending](https://developers.brevo.com/docs/send-a-transactional-email), [API reference](https://developers.brevo.com/reference/send-transac-email), [idempotency and its window](https://developers.brevo.com/docs/heterogenous-versions-batch-emails).


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
