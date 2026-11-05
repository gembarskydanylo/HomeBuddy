# Domigo Pro — isolated foundation (prototype)

Status: **domain matching prototype only**, not a live marketplace. Kept outside navigation and database to avoid touching the owner's newer, unpushed work on `/Volumes/Ai_Project/Home_buddy`. The branch started from the older GitHub `main`, so **do not merge it into production without reconciling local changes first**.

## Product flow
1. Professional signs up, agrees to terms, verifies email/phone (not implemented), chooses specialties, business identity, regions, availability and travel policy.
2. Professional adds one or more service areas: radius around a point or selected postal codes. A map-drawn polygon is a **future** type with geometry validation and GeoJSON/PostGIS persistence.
3. Customer creates a repair request (problem, optional photos, device details, approximate location), chooses whether to share precise address with an accepted professional.
4. Server filters out unverified/suspended professionals, matches specialty and coverage, and returns candidates **without exposing a customer's precise coordinates to the public**.
5. Customer requests a quote. Professional can accept/decline; only accepted requests reveal further contact/address details as permitted.
6. Request/offer/assignment state transitions are recorded and audited. Payment and ratings are later stages.

## Implemented now
- `GeoPoint`, `distanceKm`, `RadiusArea`, `PostalCodeArea`
- `ProProfile`, `RepairRequest`, `ProVerification`
- `matchProfessionals`: specialty and zone matching; no duplicate results; exclude inactive, rejected, suspended and, by default, unverified professionals.
- Eight focused unit tests in `test/domigo_pro_service_matching_test.dart`

## Limitations and safeguards
- Radius is straight-line distance, **not driving time or route distance**.
- Approximate coordinates are private matching input, not a public exact address.
- Client-side matching is demonstrative, **not a security barrier**. Enforce authorization, region validation, quotas and verification on a trusted server.
- No account registration, identity verification, interactive map, GPS requests, backend, UI integration, payments, push, real professionals or live bookings have been built.
- Avoid embedding precise personal addresses, identity documents or phone numbers in public GitHub fixtures.
- For a production marketplace: secure authentication, minimum necessary personal data, explicit consent for sharing, retention/deletion policy, professional verification appropriate to each market, and rate-limiting/abuse protection.
- No new dependencies and no changes to `pubspec.yaml`, `main.dart`, Drift, routes, task/reminder flows or assets.

## Recommended incremental next steps
1. Owner's Codex commits/tests the newer local working tree, and only then rebases or manually copies this isolated feature.
2. Run `flutter test test/domigo_pro_service_matching_test.dart` and `flutter analyze` on the integrated tree (not executed in this GitHub-only environment).
3. Add a standalone **preview** Flutter screen for a professional profile and service-area controls (no production route).
4. Establish identity/auth backend and data schemas before collecting real provider details.
5. Introduce a proper map provider and precise geometry tests for user-drawn polygons; avoid relying on visual map boundaries as authoritative.
