# 🗺️ SYSTEM_MAP.md — AI Machine Index & Navigation Guide

> **Target Audience:** Autonomous AI coding agents maintaining DreamFluenzer ERP.  
> **Purpose:** Route common maintenance tasks to their owning modules, targeted tests, and verification command.

---

## 1. Directory & Architectural Topology

| Layer | Directory | Primary Role | Constraints |
| :--- | :--- | :--- | :--- |
| **Config** | [`lib/config/`](file:///k:/Android/dreamfluenzer_erp/lib/config) | Safe agency defaults, runtime configuration, Firestore constants | Operators edit ignored `assets/config/config.json`; never commit private config. |
| **Domain** | [`lib/domain/`](file:///k:/Android/dreamfluenzer_erp/lib/domain) | Pure enums & business invariants ([`FroyoRules`](file:///k:/Android/dreamfluenzer_erp/lib/domain/froyo_rules.dart)) | Pure Dart. No Flutter or Firestore imports allowed. |
| **Engines** | [`lib/engines/`](file:///k:/Android/dreamfluenzer_erp/lib/engines) | Financial, dashboard, proposal, and CRM computations | Pure Dart logic; cover calculations and boundary cases with focused unit tests. |
| **Models** | [`lib/models/`](file:///k:/Android/dreamfluenzer_erp/lib/models) | Immutable entity schemas (`toMap`, `fromMap`, `copyWith`) | Must pass roundtrip serialization tests. |
| **Services**| [`lib/services/`](file:///k:/Android/dreamfluenzer_erp/lib/services) | External IO wrappers ([`FirestoreService`](file:///k:/Android/dreamfluenzer_erp/lib/services/firestore_service.dart), [`AuditLoggerService`](file:///k:/Android/dreamfluenzer_erp/lib/services/audit_logger_service.dart), [`lib/services/pdf/`](file:///k:/Android/dreamfluenzer_erp/lib/services/pdf)) | Encapsulates Firestore queries & modular PDF builders (<500 lines). |
| **Providers**|[`lib/providers/`](file:///k:/Android/dreamfluenzer_erp/lib/providers)| Reactive `ChangeNotifier` state & Firestore batch writes | Manages Firestore subscriptions & atomic writes. |
| **Router** | [`lib/router/`](file:///k:/Android/dreamfluenzer_erp/lib/router) | `GoRouter` configuration & auth redirect guard | Guard routes based on `AuthProvider.user`. |
| **Screens** | [`lib/screens/`](file:///k:/Android/dreamfluenzer_erp/lib/screens) | Full-page responsive views | Kept slim. Delegates complex UI to widgets. |
| **Theme** | [`lib/theme/`](file:///k:/Android/dreamfluenzer_erp/lib/theme) | Design tokens, color palette, responsive breakpoints | Single source of truth for colors and typography. |
| **Utils** | [`lib/utils/`](file:///k:/Android/dreamfluenzer_erp/lib/utils) | Pure formatters and validators | Pure helper functions. |
| **Widgets** | [`lib/widgets/`](file:///k:/Android/dreamfluenzer_erp/lib/widgets) | Modular presentation sub-components | Keep under 500 lines. Use existing barrels where available. |

---

## 2. Entity Model & Firestore Schema Routing

| Entity Class | File Path | Firestore Collection | Key Relationships / Fields |
| :--- | :--- | :--- | :--- |
| `Project` | [`lib/models/project_model.dart`](file:///k:/Android/dreamfluenzer_erp/lib/models/project_model.dart) | `projects` | `clientId`, `dealType` (`Cash`, `Barter`, `Hybrid`, `PR`), `billingModel`, `baseBudget`, `advanceReceived` |
| `Campaign` | [`lib/models/campaign_model.dart`](file:///k:/Android/dreamfluenzer_erp/lib/models/campaign_model.dart) | `projects/{id}/campaigns` | `assignedCreators` (List), `inventoryPool` (Barter GMV items) |
| `Creator` | [`lib/models/creator_model.dart`](file:///k:/Android/dreamfluenzer_erp/lib/models/creator_model.dart) | `creators` | `fullName`, `handle`, `baseRate`, `primaryCategory`, `upiId` |
| `Client` | [`lib/models/client_model.dart`](file:///k:/Android/dreamfluenzer_erp/lib/models/client_model.dart) | `clients` | `businessName`, `contactName`, `contactPhone`, `email`, `tier` |
| `Lead` | [`lib/models/lead_model.dart`](file:///k:/Android/dreamfluenzer_erp/lib/models/lead_model.dart) | `leads` | `businessName`, `contactPerson`, `status`, `estimatedBudget` |
| `Proposal` | [`lib/models/proposal_model.dart`](file:///k:/Android/dreamfluenzer_erp/lib/models/proposal_model.dart) | `proposals` | `leadId`, `creators`, `addOns`, `agencyFee` |
| `LogEvent` | [`lib/models/log_event_model.dart`](file:///k:/Android/dreamfluenzer_erp/lib/models/log_event_model.dart) | `projects/{id}/history`, `creators/{id}/history` | `type`, `action`, `timestamp`, `actor`, optional `amount` and `reason` |

---

## 3. Pure Engines & Business Logic Routing

| Engine | File Path | Primary Functions |
| :--- | :--- | :--- |
| `RevenueEngine` | [`lib/engines/revenue_engine.dart`](file:///k:/Android/dreamfluenzer_erp/lib/engines/revenue_engine.dart) | `calculateInvoice()`, `calculateAdvancePool()`, `calculateDistributedGmv()`, `aggregateLedger()` |
| `DashboardAuditor` | [`lib/engines/dashboard_auditor.dart`](file:///k:/Android/dreamfluenzer_erp/lib/engines/dashboard_auditor.dart) | `auditFinancials()`, `calculateRevenueVelocity()`, `filterAnomalies()` |
| `CrmAnalyticsEngine` | [`lib/engines/crm_analytics_engine.dart`](file:///k:/Android/dreamfluenzer_erp/lib/engines/crm_analytics_engine.dart) | CRM pipeline analytics and metrics |
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

## 5. UI Widget Imports

Prefer these existing domain barrels where they cover the component. Do not assume every domain has a single `*_widgets.dart` barrel:

- **Project:** `project_widgets.dart` and `campaign_widgets.dart` contain the project and campaign UI; `project_dialogs.dart` exports project dialogs.
- **Creator:** `creator_dialogs.dart` exports creator forms and profile dialogs. There is no `creator_widgets.dart`.
- **Client:** `client_widgets.dart` contains client tables and components; `client_dialogs.dart` exports client dialogs.
- **Lead:** `lead_widgets.dart` contains lead components; `lead_dialogs.dart` exports lead dialogs.
- **Proposal:** `proposal_widgets.dart` exports proposal components.
- **Dashboard / Finance:** use `dashboard_widgets.dart`, `invoice_widgets.dart`, and `ledger_widgets.dart`.
- **Common:** `ui_kit.dart` exports shared UI components and the audit-log dialog.

---

## 6. Fast Verification Commands

```bash
# Single CI-equivalent gate: repository Dart formatting, presentation file sizes,
# source/config secret scan, analyzer, and the full test suite.
dart run tool/verify_invariants.dart
```
