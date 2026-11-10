# Sports spaces backend and configuration

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
