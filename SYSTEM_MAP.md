# 🗺️ SYSTEM_MAP.md — AI Machine Index & Navigation Guide

> **Target Audience:** Autonomous AI coding agents maintaining DreamFluenzer ERP.  
> **Purpose:** 1-step rapid lookup to eliminate exploratory file searching, reduce token burn by 70%, and ensure zero architectural violations.

---

## 1. Directory & Architectural Topology

| Layer | Directory | Primary Role | Constraints |
| :--- | :--- | :--- | :--- |
| **Config** | [`lib/config/`](file:///k:/Android/dreamfluenzer_erp/lib/config) | Agency branding, default fees, credentials fallback | Human config boundary. Zero hardcoded secrets in Dart. |
| **Domain** | [`lib/domain/`](file:///k:/Android/dreamfluenzer_erp/lib/domain) | Pure enums & business invariants ([`FroyoRules`](file:///k:/Android/dreamfluenzer_erp/lib/domain/froyo_rules.dart)) | Pure Dart. No Flutter or Firestore imports allowed. |
| **Engines** | [`lib/engines/`](file:///k:/Android/dreamfluenzer_erp/lib/engines) | Pure computational math ([`RevenueEngine`](file:///k:/Android/dreamfluenzer_erp/lib/engines/revenue_engine.dart), [`DashboardAuditor`](file:///k:/Android/dreamfluenzer_erp/lib/engines/dashboard_auditor.dart)) | Pure Dart. 100% unit-tested. Zero side effects. |
| **Models** | [`lib/models/`](file:///k:/Android/dreamfluenzer_erp/lib/models) | Immutable entity schemas (`toMap`, `fromMap`, `copyWith`) | Must pass roundtrip serialization tests. |
| **Services**| [`lib/services/`](file:///k:/Android/dreamfluenzer_erp/lib/services) | External IO wrappers ([`FirestoreService`](file:///k:/Android/dreamfluenzer_erp/lib/services/firestore_service.dart), [`AuditLoggerService`](file:///k:/Android/dreamfluenzer_erp/lib/services/audit_logger_service.dart), [`lib/services/pdf/`](file:///k:/Android/dreamfluenzer_erp/lib/services/pdf)) | Encapsulates Firestore queries & modular PDF builders (<500 lines). |
| **Providers**|[`lib/providers/`](file:///k:/Android/dreamfluenzer_erp/lib/providers)| Reactive `ChangeNotifier` state & Firestore batch writes | Manages Firestore subscriptions & atomic writes. |
| **Router** | [`lib/router/`](file:///k:/Android/dreamfluenzer_erp/lib/router) | `GoRouter` configuration & auth redirect guard | Guard routes based on `AuthProvider.user`. |
| **Screens** | [`lib/screens/`](file:///k:/Android/dreamfluenzer_erp/lib/screens) | Full-page responsive views | Kept slim. Delegates complex UI to widgets. |
| **Theme** | [`lib/theme/`](file:///k:/Android/dreamfluenzer_erp/lib/theme) | Design tokens, color palette, responsive breakpoints | Single source of truth for colors and typography. |
| **Utils** | [`lib/utils/`](file:///k:/Android/dreamfluenzer_erp/lib/utils) | Pure formatters and validators | Pure helper functions. |
| **Widgets** | [`lib/widgets/`](file:///k:/Android/dreamfluenzer_erp/lib/widgets) | Modular presentation sub-components | Must be <500 lines. Re-exported via root barrel files. |

---

## 2. Entity Model & Firestore Schema Routing

| Entity Class | File Path | Firestore Collection | Key Relationships / Fields |
| :--- | :--- | :--- | :--- |
| `Project` | [`lib/models/project_model.dart`](file:///k:/Android/dreamfluenzer_erp/lib/models/project_model.dart) | `projects` | `clientId`, `dealType` (`Cash`, `Barter`, `Hybrid`, `PR`), `billingModel`, `baseBudget`, `advanceReceived` |
| `Campaign` | [`lib/models/campaign_model.dart`](file:///k:/Android/dreamfluenzer_erp/lib/models/campaign_model.dart) | `projects/{id}/campaigns` | `assignedCreators` (List), `inventoryPool` (Barter GMV items) |
| `Creator` | [`lib/models/creator_model.dart`](file:///k:/Android/dreamfluenzer_erp/lib/models/creator_model.dart) | `creators` | `baseCommercial`, `categories`, `primaryPlatform`, `strikes` |
| `Client` | [`lib/models/client_model.dart`](file:///k:/Android/dreamfluenzer_erp/lib/models/client_model.dart) | `clients` | `companyName`, `pocName`, `tier`, `billingAddress`, `gstNumber` |
| `Lead` | [`lib/models/lead_model.dart`](file:///k:/Android/dreamfluenzer_erp/lib/models/lead_model.dart) | `leads` | `brandName`, `status`, `estimatedBudget`, `pocContact` |
| `Proposal` | [`lib/models/proposal_model.dart`](file:///k:/Android/dreamfluenzer_erp/lib/models/proposal_model.dart) | `proposals` | `leadId`, `proposedCreators`, `pitchAddOns`, `agencyFee` |
| `LogEvent` | [`lib/models/log_event_model.dart`](file:///k:/Android/dreamfluenzer_erp/lib/models/log_event_model.dart) | `audit_logs` | `actorId`, `action`, `entityType`, `entityId`, `metadata` |

---

## 3. Pure Engines & Business Logic Routing

| Engine | File Path | Primary Functions |
| :--- | :--- | :--- |
| `RevenueEngine` | [`lib/engines/revenue_engine.dart`](file:///k:/Android/dreamfluenzer_erp/lib/engines/revenue_engine.dart) | `calculateInvoice()`, `calculateAdvancePool()`, `calculateDistributedGmv()`, `aggregateLedger()` |
| `DashboardAuditor` | [`lib/engines/dashboard_auditor.dart`](file:///k:/Android/dreamfluenzer_erp/lib/engines/dashboard_auditor.dart) | `auditFinancials()`, `calculateRevenueVelocity()`, `filterAnomalies()` |
| `FroyoRules` | [`lib/domain/froyo_rules.dart`](file:///k:/Android/dreamfluenzer_erp/lib/domain/froyo_rules.dart) | `canArchiveProject()` (Archive Lock), `validateAdvancePayment()` (Advance Safety Net) |
| `ProposalCompilerEngine`|[`lib/engines/proposal_compiler_engine.dart`](file:///k:/Android/dreamfluenzer_erp/lib/engines/proposal_compiler_engine.dart)| Compiles creator deliverables and pitch add-ons into commercial totals |

---

## 4. State Management Providers

| Provider | File Path | Injected Model & Scope |
| :--- | :--- | :--- |
| `ProjectProvider` | [`lib/providers/project_provider.dart`](file:///k:/Android/dreamfluenzer_erp/lib/providers/project_provider.dart) | Streams & updates `projects`. Enforces atomic cascading delete. |
| `CampaignProvider`| [`lib/providers/campaign_provider.dart`](file:///k:/Android/dreamfluenzer_erp/lib/providers/campaign_provider.dart) | Manages nested sub-collections `campaigns`, creator roster, inventory allocation. |
| `CreatorProvider` | [`lib/providers/creator_provider.dart`](file:///k:/Android/dreamfluenzer_erp/lib/providers/creator_provider.dart) | Streams & filters `creators` by category, status, and pricing. |
| `ClientProvider` | [`lib/providers/client_provider.dart`](file:///k:/Android/dreamfluenzer_erp/lib/providers/client_provider.dart) | Streams & searches `clients`. Calculates client lifetime value (LTV). |
| `LeadProvider` | [`lib/providers/lead_provider.dart`](file:///k:/Android/dreamfluenzer_erp/lib/providers/lead_provider.dart) | Streams CRM leads pipeline, converts leads to projects. |
| `ProposalProvider`| [`lib/providers/proposal_provider.dart`](file:///k:/Android/dreamfluenzer_erp/lib/providers/proposal_provider.dart) | Saves, streams, and deletes pitch proposals. |

---

## 5. UI Widget Barrel Structure (Law 4)

Always import widgets using their root barrel files. Never import internal sub-modules directly from screens:

- **Project:** `import '../widgets/project/project_widgets.dart';` (exports list, panels, cards, dialogs)
- **Creator:** `import '../widgets/creator/creator_widgets.dart';` (exports cards, dialogs, filters)
- **Client:** `import '../widgets/client/client_widgets.dart';` (exports selectors, profile, dialogs)
- **Lead:** `import '../widgets/lead/lead_widgets.dart';` (exports overview, form dialogs)
- **Proposal:** `import '../widgets/proposal/proposal_widgets.dart';` (exports row item, commercials sidebar)
- **Common:** `import '../widgets/common/ui_kit.dart';` (exports chips, headers, audit timeline modal)

---

## 6. Fast Verification Commands

```bash
# 1. Complete AI Invariant Gate (File lengths, Secret scan, Analyzer, Tests):
dart run tool/verify_invariants.dart

# 2. Fast Linter:
flutter analyze

# 3. Fast Test Suite:
flutter test
```
