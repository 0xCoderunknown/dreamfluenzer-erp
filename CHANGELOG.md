# Changelog

All notable changes are documented here. Format follows [Keep a Changelog](https://keepachangelog.com). Dates follow the Indian numerical date standard (`DD-MM-YYYY`).

---

## [0.8.2] — 29-10-2026 — AI Governance Constitution, Schema Contracts & Test Suite Expansion

### AI Governance & Documentation
- **AI Operating Constitution (`AGENTS.md`):** Imported ClinicOS-grade constitution with non-negotiable invariants, Twin Budget Principle, Froyo Rules, Strict PM Interaction Protocol (Clarify & Plan First -> Respect Conventions -> Verification Gate), and responsive layout constraints (1920x1080 desktop, 1366x768 laptop, mobile).
- **Data Schema Contracts (`docs/SCHEMA_AND_MODELS.md`):** Established single source of truth for all root collections (`projects`, `creators`, `clients`, `leads`, `proposals`), subcollections, field data types, and enums.
- **Product Roadmap & Backlog (`docs/MASTER_BACKLOG.md`):** Structured future roadmap into Tier 1 (Quick wins), Tier 2 (Campaign expansions), Tier 3 (Deferred cloud multi-tenancy), and explicit Anti-Goals.

### Automated Testing Expansion (36 → 63 Tests)
- **Validators Test Suite (`test/validators_test.dart`):** Added 15 comprehensive unit tests covering Indian phone numbers (+91), emails, Instagram handles, optional UPI handles, and required fields.
- **CRM Analytics Test Suite (`test/crm_analytics_engine_test.dart`):** Added 4 tests verifying creator campaign history filtering, cumulative lifetime value math, active tasks, and upcoming deadlines.
- **Dashboard Auditor & Provider Suite (`test/dashboard_auditor_test.dart`):** Added 3 tests validating active creators, live project financial auditing, overdue project flags, and idempotent `DashboardProvider` state evaluation.
- **Screen Widget Tests (`test/screens/login_screen_test.dart`):** Added 5 widget tests validating the ERP portal login screen, loading state, form validation, password obscure toggle, and auth error presentation.
- **Invariant Gate:** 100% clean pass across formatting, <500 line limits, secret scans, `flutter analyze`, and all 63 unit/widget tests.

---

## [0.8.1] — 08-10-2026 — Modular Architecture Refactoring & Security Hardening

### Architectural Refactoring (Maintainability & Single Responsibility)
- **Campaign & Project Widgets:** Decomposed monolithic 1,600+ line `campaign_widgets.dart` into `campaign_list.dart`, `campaign_panel.dart`, and `expandable_creator_card.dart` with backwards-compatible barrel export.
- **Creator Dialogs:** Separated `creator_dialogs.dart` into standalone `creator_profile_dialog.dart` (CRM dashboard) and `add_edit_creator_dialog.dart` (onboarding/edit form).
- **Project Dialogs:** Split `project_dialogs.dart` into `project_creation_wizard.dart`, `assign_creator_dialog.dart`, and `add_campaign_dialog.dart`.
- **CRM Dialogs:** Separated `client_profile_dialog.dart`, `add_client_dialog.dart`, `lead_overview_dialog.dart`, and `add_edit_lead_form_dialog.dart`.
- **Audit System Isolation:** Extracted `dream_audit_log_dialog.dart` from `ui_kit.dart` to isolate operational event timeline modals from pure design tokens.
- **Proposal Screen:** Extracted accounting and commercials panel into `proposal_commercials_sidebar.dart` and created `proposal_widgets.dart` barrel export, reducing `proposal_screen.dart` from 868L to 484L.
- **PDF Theme Consolidation:** Unified procedural design tokens (`PdfTheme`) and font bundle (`PdfFontSet`) in `services/pdf/pdf_theme.dart` across proposal and invoice builders.

### Security & Open Source Readiness
- **Firebase Options Guard:** Enforced Git exclusion for `lib/firebase_options.dart` and wildcards in `.gitignore`, keeping private project credentials out of version control while maintaining `lib/firebase_options.dart.example`.

---

## [0.8.0] — 03-10-2026 — Initial Open Source Release

### Core Features
- **Mission Control (Projects):** Full project lifecycle — onboarding, campaign management, creator assignment pipeline (`draftRequested` → `postedLive`), atomic batch archive with Froyo Rule guards.
- **Campaign Engine:** Per-campaign creator management with atomic Firestore transactions for status transitions and payment toggles.
- **Creator CRM:** Creator registry with pipeline history, advance tracking, and audit log subcollections.
- **Client CRM:** Client registry with project associations and cascading delete protection.
- **Lead Kanban:** Lead pipeline with drag-and-drop stage transitions and CRM conversion bridge.
- **Financial Ledger:** Dual-ledger master view separating liquid cash (`baseBudget`, `effectiveBudget`) from Barter GMV (`gmvBudget`) — the Twin Budget Principle.
- **Invoice Engine:** GST-aware invoice PDF generator (inclusive and exclusive modes) via `RevenueEngine`.
- **Proposal/Pitch Engine:** Fully compiled PDF proposal builder with cover page, scope, timelines, and payment terms.
- **Dashboard:** Auditor-driven health score, financial summary cards, and active campaign overview.
- **Audit Logger:** Dual-log (project + creator history subcollections) for every money, assignment, and status mutation.

### Architecture
- Clean Architecture: Domain → Engines → Models → Providers → Services → Screens.
- Froyo Rules enforced at domain layer: Archive Lock + Advance Safety Net.
- Dual-tier credential system: private `config.json` (gitignored) with `config.demo.json` fallback.
- 29 unit tests covering `RevenueEngine`, `FroyoRules`, and `AppConfig`.
- Zero lint issues (`flutter_lints` + strict analyzer rules).
