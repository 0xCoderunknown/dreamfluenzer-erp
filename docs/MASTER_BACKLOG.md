# 🎯 DreamFluenzer ERP — Future Goals & Product Backlog

> **Single Source of Truth** for unbuilt product features, operational agency enhancements, pending campaign workflows, and non-negotiable architectural boundaries.  
> Version milestone numbers are decoupled from this backlog to accommodate rapid patch iterations; shipped releases and historical audits are recorded chronologically in [`CHANGELOG.md`](../CHANGELOG.md).  
> System topology, symbol routing, and component imports are documented in [`SYSTEM_MAP.md`](../SYSTEM_MAP.md).  
> Canonical AI operating rules and invariants are defined in [`AGENTS.md`](../AGENTS.md).  
> **Date Standard:** All human-facing dates strictly follow Indian numerical formatting (`DD-MM-YYYY`).

---

## ⚡ Tier 1: Immediate Sprint Priorities (High-ROI Operational Quick Wins)

Targeted, self-contained enhancements that eliminate daily influencer agency friction without architectural overhead.

---

### FEAT-01: 1-Tap WhatsApp Creator Brief & Payment Dispatch
- **Domain:** Creator Management / External Communication
- **Status:** Planned
- **Specification:**
  1. Add a 1-tap WhatsApp deep link button on `AssignedCreatorCard` that opens pre-populated campaign briefs, deliverable reminders, and deadline alerts.
  2. Add payout confirmation deep link once creator `advancePaid` or full settlement is marked `isPaid == true`.
  3. Pre-fill message using URL-encoded templates with brand name, deliverables count, and agreed deadline (`DD-MM-YYYY`).

---

### FEAT-02: Comprehensive Screen & Provider Unit Test Coverage
- **Domain:** System Stability & Testing
- **Status:** In Progress
- **Specification:**
  1. Add provider tests for `AuthProvider`, `ProjectProvider`, `CampaignProvider`, and `CreatorProvider`.
  2. Add widget tests for critical agency dialogs (`ProjectCreateDialog`, `AdvancePaymentDialog`, `CreatorFormDialog`).
  3. Maintain 100% clean passes with zero warnings in `tool/verify_invariants.dart`.

---

### FEAT-03: Client Ledger CSV & Financial Summary Export
- **Domain:** Finance & Reporting
- **Status:** Planned
- **Specification:**
  1. Provide a 1-tap "Export Ledger" button in `LedgerView` that generates a formatted CSV summary of receivables, GST breakdowns, creator payouts, and net agency margin.
  2. Implement as a pure Dart engine (`DataExportEngine`) with zero Flutter UI dependencies.

---

## 🚀 Tier 2: Campaign Workflow Modules (Agency Expansions)

Substantive multi-screen modules expanding campaign and agency operations.

---

### FEAT-04: Barter Courier Tracking & AWB Logistics Integration
- **Domain:** Campaign Logistics / Inventory
- **Status:** Planned
- **Specification:**
  1. Expand `AllocatedItem` in `CampaignInventory` with optional `awbTrackingNumber`, `courierPartner` (e.g. Bluedart, Delhivery, Shiprocket), and `dispatchDate`.
  2. Provide a 1-click tracking URL launcher in creator inventory allocation cards.

---

### FEAT-05: Dynamic Agency Margin Floor Alert (< 20%)
- **Domain:** Risk & Financial Safety
- **Status:** Planned
- **Specification:**
  1. When pitching in `ProposalCompilerEngine` or adding creators in `CampaignProvider`, if projected gross margin drops below 20% of `baseBudget`, display a prominent warning banner.
  2. Require explicit agency operator confirmation before saving sub-margin deals.

---

## ☁️ Tier 3: Enterprise & Multi-Agency Cloud (Deferred)

Formally deferred until cloud SaaS migration or multi-tenant commercial distribution.

---

### FEAT-06: Multi-Tenant Agency Workspaces
- **Domain:** Cloud Architecture / SaaS Multi-Tenancy
- **Status:** Formally Deferred
- **Specification:** Migrate from single-tenant collection paths to `/agencies/{agencyId}/projects` with isolated RBAC (Agency Owner, Campaign Manager, Finance Lead).

---

### FEAT-07: Direct UPI / Bulk Payout Gateway Integration
- **Domain:** Automated Disbursements
- **Status:** Formally Deferred
- **Specification:** RazorpayX or Cashfree Payouts API integration to disburse creator advances and settlements directly from bank accounts.

---

## 🚫 Product Anti-Goals (What DreamFluenzer ERP Is NOT)

1. **NOT a Social Media Auto-Scheduler:** DreamFluenzer is an ERP for business operations, deliverables, and money flow. It will **not** integrate Meta/YouTube APIs for automated reel/video publishing or buffer-like scheduling.
2. **NOT an Unauthorized Web Scraper:** Will not scrape Instagram or YouTube creator profiles without consent. Creator profiles are onboarded with consent or entered by agency managers.
3. **NOT an HRMS Payroll Tool:** Will not manage internal employee payroll, leave calendars, or Provident Fund/ESI deductions.
