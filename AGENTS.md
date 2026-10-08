# 🤖 AGENTS.md — AI Maintainer System Guide

> **Target Audience:** Autonomous AI coding agents maintaining, extending, or refactoring DreamFluenzer ERP.  
> **Human Role:** Edits constants in [`lib/config/agency_config.dart`](lib/config/agency_config.dart). Does NOT touch application architecture.  
> **AI Role:** 100% responsible for feature implementation, bug fixes, state management, and maintaining architectural integrity.

---

## 1. System Architecture & Topology

The codebase follows Clean Architecture with strict separation between pure Dart business logic, reactive state providers, and presentation widgets:

```
lib/
├── config/        # ONLY editable layer for human operators (business constants & messages)
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
* Keep presentation files under 500 lines for maximum AI maintainability and zero search/replace collisions.
* Component domains (`project`, `creator`, `client`, `lead`, `proposal`, `common`) maintain root barrel files (e.g. `campaign_widgets.dart`, `creator_dialogs.dart`, `proposal_widgets.dart`) that re-export sub-components to ensure 100% backwards-compatible screen imports.

---

## 3. Human Configuration Boundary & Dual-Tier Credentials

* **Dual-Tier Config Law:** 
  - Private credentials (real Firebase API keys, real bank accounts, real UPI IDs) belong **exclusively** in [`assets/config/config.json`](assets/config/config.json) (which is `.gitignore`d).
  - Open-source defaults belong in [`assets/config/config.demo.json`](assets/config/config.demo.json) and [`lib/config/agency_config.dart`](lib/config/agency_config.dart).
  - [`AppConfig.load()`](lib/config/app_config.dart) dynamically loads `config.json` when present, or gracefully falls back to `config.demo.json`.
* **Zero Secret Leakage:** Never hardcode URLs, private keys, company tax numbers, bank accounts, or credentials directly into Dart source files.

---

## 4. Verification Protocol (Run Before Concluding Any Task)

Before reporting any coding task as complete, you must run and verify:

```bash
# 1. Verify zero lint errors or warnings:
flutter analyze

# 2. Verify all unit and engine tests pass:
flutter test
```

If either command fails, you must resolve the issue before responding to the user.
