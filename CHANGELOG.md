# Changelog

All notable changes are documented here. Format follows [Keep a Changelog](https://keepachangelog.com).

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
