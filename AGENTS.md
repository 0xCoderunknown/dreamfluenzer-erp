# 🤖 AGENTS.md — AI Maintainer System Guide

> **Target Audience:** Autonomous AI coding agents maintaining, extending, or refactoring DreamFluenzer ERP.  
> **Agency Operator Role:** Maintains deployment-specific values in the ignored local `assets/config/config.json`. Does NOT touch application architecture.
> **AI Role:** 100% responsible for feature implementation, bug fixes, state management, and maintaining architectural integrity.

---

## 1. System Architecture & Topology

The codebase follows Clean Architecture with strict separation between pure Dart business logic, reactive state providers, and presentation widgets:

```
lib/
├── config/        # Safe defaults, runtime configuration, Firestore constants
├── domain/        # Pure domain constraints & validation rules (FroyoRules, AppEnums)
├── engines/       # PURE DART computational engines (RevenueEngine, DashboardAuditor)
├── models/        # Immutable domain schemas & Firestore DTOs with copyWith
├── providers/     # Reactive state management (ChangeNotifier) & atomic Firestore transactions
├── router/        # GoRouter navigation & authentication guarding
├── screens/       # Top-level route views (responsive desktop/mobile layouts)
├── services/      # IO wrappers (FirestoreService, AuditLoggerService, PDF builders)
├── theme/         # Central design tokens & dynamic status color resolvers
├── utils/         # Pure validators and string formatters
└── widgets/       # Modular, reusable presentation components (with barrel exports)
```

---

## 2. Sacred Business Invariants (DO NOT BREAK)

When modifying any part of this system, you must strictly uphold these domain laws:

### Law 1: The Twin Budget Principle (Liquid Cash vs. Barter GMV)
* Liquid cash (`baseBudget`, `effectiveBudget`, `advanceReceived`) and Barter GMV (`gmvBudget`, `distributedGmv`) are **parallel and strictly isolated**.
* **Never sum cash and barter into a single total.** You cannot pay creator invoices or taxes with barter product inventory.

### Law 2: The Froyo Rules (Project Closure & Cash Protection)
* Encapsulated in [`lib/domain/froyo_rules.dart`](lib/domain/froyo_rules.dart).
* **Archive Lock:** A project can **never** be moved to `ProjectStatus.completed` or archived if:
  1. It has 0 campaigns.
  2. Any assigned creator is still in an active pipeline status (`draftRequested`, `reviewing`, `changesRequested`, `awaitingClientSignoff`).
  3. Any creator who reached `postedLive` has not been marked as `isPaid == true`.
* **Advance Safety Net:** Creator advance payouts must **never** exceed the client advance received minus other creator advances paid out for that project.

### Law 3: Atomic State Mutations with Audit Logging
* All multi-document changes (e.g., project onboarding, archiving, deleting projects with nested campaigns) must use `WriteBatch` or `Transaction`.
* Every mutation that alters creator money, assignment, or project status must log an event via [`AuditLoggerService`](lib/services/audit_logger_service.dart).

### Law 4: Modular Presentation & Barrel Exports
* Keep presentation files under 500 lines for AI maintainability. The invariant gate enforces this limit for screens and widgets.
* Use existing domain barrel files when available. Update a barrel when adding public components; do not add a barrel solely to wrap a single module.

---

## 3. Human Configuration Boundary & Dual-Tier Credentials

* **Dual-Tier Config Law:**
  - Private credentials (real Firebase API keys, real bank accounts, real UPI IDs) belong **exclusively** in [`assets/config/config.json`](assets/config/config.json) (which is `.gitignore`d).
  - Open-source defaults belong in [`assets/config/config.demo.json`](assets/config/config.demo.json) and [`lib/config/agency_config.dart`](lib/config/agency_config.dart).
  - [`AppConfig.load()`](lib/config/app_config.dart) dynamically loads `config.json` when present, or gracefully falls back to `config.demo.json`.
  - Agency operators edit their local `config.json`; AI maintainers own changes to application defaults and architecture.
* **Zero Secret Leakage:** Never hardcode URLs, private keys, company tax numbers, bank accounts, or credentials directly into Dart source files.

---

## 4. AI Fast Navigation & Canonical Recipes

> **Full Codebase Index:** Refer to [`SYSTEM_MAP.md`](SYSTEM_MAP.md) for 1-step symbol routing, collection schemas, and provider mappings.

### Recipe 1: Modifying or Extending an Entity Model
1. Update immutable class fields in `lib/models/<name>_model.dart`.
2. Update `toMap()`, `fromMap()`, and `copyWith()`.
3. If new test fields are needed, update [`test/fixtures/mock_factory.dart`](test/fixtures/mock_factory.dart).
4. Run `flutter test test/models_serialization_test.dart` to verify roundtrip serialization passes without silent data corruption.

### Recipe 2: Modifying Financial Calculations or Invariants
1. Pure financial formulas belong **strictly** in [`lib/engines/revenue_engine.dart`](lib/engines/revenue_engine.dart).
2. Business validation rules belong **strictly** in [`lib/domain/froyo_rules.dart`](lib/domain/froyo_rules.dart).
3. Add a corresponding test case in [`test/revenue_engine_test.dart`](test/revenue_engine_test.dart) or [`test/froyo_rules_test.dart`](test/froyo_rules_test.dart).
4. Run `flutter test`.

### Recipe 3: Creating or Modifying UI Components
1. Keep every presentation file strictly under **500 lines** (ideally 200–350 lines).
2. Decompose sub-sections into sibling files in the same domain folder (e.g. `lib/widgets/project/`).
3. Re-export all sub-modules through the domain's root barrel file (e.g. `project_widgets.dart`, `campaign_widgets.dart`).
4. Screens should import the existing domain barrel when one covers the component; otherwise use the module's current public import pattern.

---

## 5. Verification Protocol (Run Before Concluding Any Task)

Before reporting any coding task as complete, run the same gate CI uses:

```bash
# Checks repository Dart formatting, presentation file sizes, source/config secrets,
# analysis, and the full test suite.
dart run tool/verify_invariants.dart
```

If any check fails, you must resolve the issue before responding to the user.
