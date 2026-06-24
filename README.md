# Vitals

Private iOS app for exporting selected Apple Health data to a Vitals Web backend.

Bundle ID: `dev.tombell.vitals`

The MVP exports selected HealthKit data to `POST /apple-health/import` using bearer-token authentication. Manual exports can use a selected date range, while the Shortcuts action exports the previous full week.

## Development

```sh
make build
make test
make lint
```

Set `SIMULATOR="iPad (A16)"` or another installed simulator name to override the default.
