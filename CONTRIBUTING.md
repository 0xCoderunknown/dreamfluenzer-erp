# Contributing to Agency ERP

Thank you for your interest! This project is maintained primarily by AI agents, but human contributions are very welcome.

## Development Environment

Follow [`AGENTS.md`](AGENTS.md) as the canonical source for AI-maintenance rules and
business invariants.

**Prerequisites:**
- Flutter 3.47.6
- Firebase CLI: `npm install -g firebase-tools`
- FlutterFire CLI: `dart pub global activate flutterfire_cli`
- A Firebase project with Firestore, Auth enabled

**Setup:**
```bash
# 1. Clone the repo
git clone https://github.com/0xCoderunknown/dreamfluenzer-erp.git && cd dreamfluenzer-erp

# 2. Install dependencies
flutter pub get

# 3. Configure Firebase
#    Option A — automatic:
flutterfire configure
#    Option B — manual: copy and fill the example file
cp lib/firebase_options.dart.example lib/firebase_options.dart

# 4. Configure local agency settings (never commit this file)
cp assets/config/config.demo.json assets/config/config.json
# Fill in your agency name and billing details in assets/config/config.json

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

## Before Submitting

```bash
dart run tool/verify_invariants.dart
```

This is the same quality gate used in CI. It checks formatting, presentation file
sizes, repository source/config secrets, analysis, and the full test suite.

## Submitting a PR

1. Fork the repo and create a feature branch: `git checkout -b feat/my-feature`
2. Make changes, keep commits focused.
3. Run the quality gate (see above).
4. Open a PR against `main` with a clear description of what changed and why.
