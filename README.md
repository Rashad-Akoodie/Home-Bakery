# home_bakery_assistant

Flutter desktop app for managing a home bakery.

## Utility Scripts

Reset all local app data:

```bash
dart run tool/reset_all_data.dart --yes
```

Reset all data and remove generated invoice files too:

```bash
dart run tool/reset_all_data.dart --yes --delete-invoices
```

Seed a full demo dataset:

```bash
dart run tool/seed_demo_data.dart
```

Append another batch of demo data without resetting first:

```bash
dart run tool/seed_demo_data.dart --append
```

The scripts target the same `home_bakery.db` used by the macOS app container.
