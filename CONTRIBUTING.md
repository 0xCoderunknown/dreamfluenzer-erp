# Contributing to Agency ERP

Thank you for your interest! This project is maintained primarily by AI agents, but human contributions are very welcome.

## Development Environment

**Prerequisites:**
- Flutter SDK (stable channel, 3.x or later)
- Firebase CLI: `npm install -g firebase-tools`
- FlutterFire CLI: `dart pub global activate flutterfire_cli`
- A Firebase project with Firestore, Auth enabled

**Setup:**
```bash
# 1. Clone the repo
git clone https://github.com/YOUR_USERNAME/YOUR_REPO.git && cd YOUR_REPO

# 2. Install dependencies
flutter pub get

# 3. Configure Firebase
#    Option A — automatic:
flutterfire configure
#    Option B — manual: copy and fill the example file
cp lib/firebase_options.dart.example lib/firebase_options.dart

# 4. Configure your agency (edit only this file)
#    Fill in your agency name, billing details, etc.
nano lib/config/agency_config.dart

# 5. Run the app
flutter run -d chrome
```

## Architecture

This project follows Clean Architecture. The layers (from innermost to outermost) are:

| Layer | Directory | Rule |
|---|---|---|
| **Domain** | `lib/domain/` | Pure Dart — zero Flutter/Firebase dependencies |
| **Engines** | `lib/engines/` | Pure Dart computation — no side effects |
| **Models** | `lib/models/` | Immutable data classes with `copyWith` |
| **Providers** | `lib/providers/` | Reactive state + Firestore writes |
| **Services** | `lib/services/` | I/O wrappers (Firestore, PDF, audit log) |
| **Screens/Widgets** | `lib/screens/`, `lib/widgets/` | Presentation only |
| **Config** | `lib/config/` | Constants + runtime configuration |

**The #1 rule:** dependencies only point inward. Screens call Providers. Providers call Services and Engines. Engines call Domain. Never the reverse.

## The Froyo Rules

`lib/domain/froyo_rules.dart` contains the two non-negotiable financial safety guards:

1. **Archive Lock** — A project cannot be completed/archived if any creator's work is still in-flight or live creators remain unpaid.
2. **Advance Safety Net** — Creator advances cannot exceed the client advance pool for that project.

**Never bypass these checks.** Every archival and advance disbursement path must invoke `FroyoRules`.

## Code Style

- Follow `analysis_options.yaml` (extends `flutter_lints`).
- All `fromMap` / `fromFirestore` parsers must use safe casting: `(m['field'] as num?)?.toDouble() ?? 0.0`.
- All multi-document mutations must use `WriteBatch` or `Transaction`.
- All mutations that affect money, assignment, or project status must log via `AuditLoggerService`.

## Before Submitting

```bash
flutter analyze  # Must output: No issues found!
flutter test     # Must output: All tests passed!
```

Both must be clean before any PR will be reviewed.

## Submitting a PR

1. Fork the repo and create a feature branch: `git checkout -b feat/my-feature`
2. Make changes, keep commits focused.
3. Run analyze + test (see above).
4. Open a PR against `main` with a clear description of what changed and why.
