# Hem

Hem is an iOS app for exporting HealthKit data to your own [Hem Web](https://github.com/tombell/hem-web) instance.

## Export contract

Hem exports Hem Web schema version 1. Quantity samples, category samples, sleep samples, and workouts include their stable HealthKit UUID as `id`. The `id` field remains optional when decoding so exports queued by older app versions can still be retried.

The export source contains both display metadata and a stable `deviceIdentifier`. Hem generates this identifier once and stores it in Keychain; changing the iPhone name does not create a new Hem Web source. Existing Hem Web data keyed by device name is not migrated automatically, so the first export with this app version can appear as a new source.

Dates use strict RFC 3339 timestamps with the export time zone's offset. Daily metric dates use `YYYY-MM-DD`. HealthKit interval records are defensively constrained to the requested export range.

## Import results

Hem requires the typed Hem Web import response:

```json
{
  "ok": true,
  "importId": 42,
  "status": "created",
  "counts": {
    "categorySamples": 2,
    "dailyMetrics": 4,
    "samples": 1,
    "sleep": 1,
    "workouts": 1
  }
}
```

`created`, `duplicate`, and `replaced` are all successful imports and advance the since-last-success checkpoint. Export history and diagnostics show the server import ID/status and normalized fact counts separately from the app's local day/record counts.

## Failures and retries

- Transient URL errors, HTTP 429, and HTTP 5xx retain the encoded payload and queue it for retry.
- A 429 `Retry-After` delay is persisted; automatic queue drain will not retry that export early.
- HTTP 400, 401, and 413 are permanent failures and are not automatically queued. The app shows payload, authentication, or size guidance.
- Settings continue to verify the configured bearer token with the authenticated `/apple-health/import/test` endpoint. Hem does not preflight every export.
- Diagnostics never include the bearer token or request payload.

## Development

Run the repository gates with:

```sh
make format
make lint
make test
make build
```

The response fixtures in `HemTests/Fixtures/HemWeb` mirror Hem Web's `/openapi.json` import response schema.

## Release check

HealthKit can represent samples where `startDate == endDate`; Hem preserves those timestamps and does not invent a duration. Before release, inspect a real-device export for instant quantity/category samples. If present, Hem Web must accept `end >= start` for sample intervals.
