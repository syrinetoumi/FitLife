# Sports-spaces interface preview

This module contains French-language Flutter interfaces for all five sports-space entities. It reuses the existing theme without modifying shared application code, navigation, dependencies, authentication or Supabase.

Run from the FitLife repository:

```powershell
flutter pub get
flutter devices
flutter run -t lib/features/espace_sportif/preview.dart -d emulator-5554
```

Use the role selector in the app bar to switch between manager and athlete previews. The banner identifies sample data. Changes live only in memory and reset on restart. These role controls demonstrate interfaces; they are not authentication or authorization.

Use the device ID reported by `flutter devices` if different. The API 36.1 Android emulator was used for build/install/launch verification. The web target remains optional for quick previews. See [the individual presentation guide](../../../../Fit%20Life%20Docs/VALIDATION-INTERFACES-ESPACES-SPORTIFS.md) for the complete demonstration sequence and recorded verification limits.

## Included interfaces

| Area | Interfaces and interactions |
| --- | --- |
| Discovery | Search by name/address, space type filters, available-offer filter, responsive catalogue and detail views. |
| Spaces | Manager-owned list, create/edit form, explicit activation/deactivation, description, contact details and optional paired coordinates. New spaces start inactive. |
| Equipment | Space equipment list, add/edit form, quantity and condition validation. Quantity zero retires an equipment row. |
| Opening hours | Weekly schedule, native time pickers, multiple same-day intervals, add/edit/delete with confirmation. Overlapping intervals are refused; adjacency is allowed. |
| Availability | Manager-facing date/time and equipment-quantity check. Results cover local opening hours, space status and equipment only; they explicitly exclude session occupancy. |
| Offers | Manager list/create/edit, athlete offer details and sales windows. Amounts are stored as integer millimes in this preview. One-day offers require a duration of one day. |
| Subscriptions | Athlete confirmation and own-subscription list/detail; manager subscriber list per space and across owned spaces; suspend/reactivate/cancel confirmations, effective expiry and original price/date snapshots. |
| Location | Address/coordinate cards, address copying, external map opening, directions form with travel-mode selection, and failed-launch recovery. No embedded map or fabricated distance/travel time. |

Athletes see active spaces and available offers. Manager edit actions appear only for their sample spaces. Empty/search-result states, input validation and cancellation paths are included. There are no simulated network requests; loading/error/retry handling must be added with the real repository integration.

## File map

- `preview.dart`: independent runnable MaterialApp; no Supabase initialization.
- `presentation/espaces_sportifs_screen.dart`: responsive shell, catalogue, details, subscription and availability interfaces.
- `presentation/formulaires_espaces.dart`: validated editing dialogs.
- `presentation/donnees_apercu.dart`: explicitly named presentation fixtures and in-memory state; not production database models.
- `presentation/localisation_espace.dart`: real external-map/directions actions and address-copy fallback.
- `../../../test/espace_sportif/interfaces_test.dart`: isolated widget and value-conversion checks.

## Integration boundary

The existing `lib/main.dart`, drawer, other feature folders and shared theme are unchanged. The preview is not registered in the main app. When team integration is authorized, the host app can import `presentation/espaces_sportifs_screen.dart`; replace the demo role selector and in-memory store with authenticated context and repository-backed state before shipping.

The server must remain authoritative for ownership, active profiles, subscription price/dates, permissions and concurrent writes. Embedded map/geocoding/routing APIs, session occupancy, persisted equipment requirements and backend loading/failure states are not connected. External map/directions actions are functional; their receiving app and network supply the route information. No payment collection is implemented. Preview business dates use the device date; production must obtain the Africa/Tunis business date from the backend.

The existing transitive `url_launcher` package is reused without editing shared manifests. Its import has an explicitly documented lint exemption. Promote it to a direct dependency during team integration; do not treat this temporary relationship as a production dependency declaration.

The current UI accepts offer durations from 1 to 36,500 days to keep preview date calculations bounded. This is a preview form limit, not a new database contract.

Run checks:

```powershell
dart analyze lib/features/espace_sportif test/espace_sportif
flutter test test/espace_sportif
```

Current scoped result: 12 tests passed and Dart analysis reported no issues. Android build/install/launch and a device screenshot were verified; the full on-device manual walkthrough and successful external map display are not claimed.

The pre-existing `test/models_test.dart` fixture for `ProgrammeExercice` is outside this change; see the project context for its `id_exercice` versus `external_id` discrepancy.
