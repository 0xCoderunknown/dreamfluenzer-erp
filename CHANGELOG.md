# Changelog

All notable changes are documented here. Format follows [Keep a Changelog](https://keepachangelog.com).

---

## [0.8.1] — 2026-10-08 — Modular Architecture Refactoring & Security Hardening

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

## [0.8.0] — 2026-10-03 — Initial Open Source Release

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
