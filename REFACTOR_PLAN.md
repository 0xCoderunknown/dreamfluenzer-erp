# 🏗️ DreamFluenzer ERP — AI-Maintainability Modular Refactoring Plan

> **Objective:** Refactor oversized UI, dialog, and PDF builder files into focused, single-responsibility components with strict barrel export backwards-compatibility.  
> **Target Audience:** Autonomous AI coding agents and human operators maintaining the codebase.  
> **Key Metric:** Reduce maximum file size from ~1,650 lines down to <500 lines per file, eliminating token degradation, line-offset search/replace collisions, and cross-feature regressions.

---

## 1. Executive Summary & Audit Baseline

In an AI-maintained codebase, large multi-component files create three failure modes:
1. **Context Saturation & Attention Loss:** Loading a 1,600+ line file consumes a major portion of model context tokens, increasing the chance of subtle syntax bugs or hallucinated state variables.
2. **Search/Replace Drift & Collisions:** Modifying one dialog in a multi-dialog file risks accidental edits to sibling classes that share similar variable names (`_formKey`, `_isSubmitting`, `_save`).
3. **Coupled Blast Radius:** Fixing creator deliverable tracking touches the same file that manages logistics inventory bay and campaign accordion states.

### Audit Baseline (Current Sizes)

| File | Current Lines | Current Size | Component Count & Mixed Concerns |
| :--- | :---: | :---: | :--- |
| `lib/widgets/project/campaign_widgets.dart` | **1,643** | 55.7 KB | `CampaignList` + `CampaignPanel` + `ExpandableCreatorCard` (3 heavy stateful widgets) |
| `lib/widgets/creator/creator_dialogs.dart` | **1,259** | 45.0 KB | `CreatorProfileDialog` (Viewer) + `AddEditCreatorDialog` (10-controller form) |
| `lib/services/pdf/pdf_proposal_builder.dart` | **1,144** | 38.1 KB | Document generator + duplicated `_Dt` tokens |
| `lib/widgets/project/project_dialogs.dart` | **955** | 33.9 KB | `ProjectCreationWizard` (620L) + `AddCampaignDialog` + `AssigncreatorDialog` |
| `lib/screens/proposal_screen.dart` | **868** | 36.6 KB | Full proposal workspace + commercials sidebar + compile actions |
| `lib/services/pdf/pdf_invoice_builder.dart` | **828** | 26.3 KB | Invoice generator + duplicated `_Dt` tokens |
| `lib/widgets/client/client_dialogs.dart` | **759** | 23.9 KB | `ClientProfileDialog` (Viewer) + `AddClientDialog` (Form) |
| `lib/widgets/common/ui_kit.dart` | **736** | 24.3 KB | UI kit tokens + full 300L `DreamAuditLogDialog` feature |
| `lib/widgets/lead/lead_dialogs.dart` | **678** | 23.6 KB | `LeadOverviewDialog` (Viewer) + `AddEditLeadFormWindow` (Form) |
| `lib/widgets/proposal/proposal_row_item.dart` | **462** | 17.5 KB | Single cohesive interactive component (**Keep As-Is**) |

---

## 2. Refactoring Strategy & Backwards-Compatibility Guarantee

Every refactored file will use **Dart barrel exports**.  
Existing imports in screens (e.g. `import '../widgets/project/campaign_widgets.dart';`) will continue to work without breaking, because `campaign_widgets.dart` will re-export its sub-modules.

```dart
// Example: lib/widgets/project/campaign_widgets.dart (barrel file)
export 'campaign_list.dart';
export 'campaign_panel.dart';
export 'expandable_creator_card.dart';
```

---

## 3. Phased Execution Roadmap

### Phase 1: Core Project & Creator Deconstruction — ✅ COMPLETED

*Completed on: 2026-10-08 | Verification: `flutter analyze` (0 issues), `flutter test` (all 29 tests passed)*

Decomposed the three highest-risk monolithic files into clean, focused sub-modules while preserving 100% backwards compatibility via barrel exports.

#### 1.1 Split `lib/widgets/project/campaign_widgets.dart` (Was 1,643 Lines) — [x] COMPLETED
- [x] **`lib/widgets/project/campaign_list.dart`** (59 lines): `CampaignList` and `CampaignListState` (accordion expansion state tracking).
- [x] **`lib/widgets/project/campaign_panel.dart`** (785 lines): `CampaignPanel` and `_CampaignPanelState` (inventory pool CRUD, logistics toggle, cycle dates).
- [x] **`lib/widgets/project/expandable_creator_card.dart`** (804 lines): `ExpandableCreatorCard` and `ExpandableCreatorCardState` (payout/advance inputs, `FroyoRules.validateAdvancePayment`, pipeline status chips, inventory allocation).
- [x] **`lib/widgets/project/campaign_widgets.dart`** (3 lines): Pure barrel export.

#### 1.2 Split `lib/widgets/creator/creator_dialogs.dart` (Was 1,259 Lines) — [x] COMPLETED
- [x] **`lib/widgets/creator/creator_profile_dialog.dart`** (678 lines): `CreatorProfileDialog`, `_CampaignTrackingColumn`, `_ProfileStatKpi` (CRM viewer, LTV stats, active/past tasks).
- [x] **`lib/widgets/creator/add_edit_creator_dialog.dart`** (592 lines): `AddEditCreatorDialog` and `AddEditCreatorDialogState` (10 form controllers, validation, categories, strike/status handling).
- [x] **`lib/widgets/creator/creator_dialogs.dart`** (2 lines): Pure barrel export.

#### 1.3 Split `lib/widgets/project/project_dialogs.dart` (Was 955 Lines) — [x] COMPLETED
- [x] **`lib/widgets/project/project_creation_wizard.dart`** (638 lines): `ProjectCreationWizard` and `_ProjectCreationWizardState` (multi-step client onboarding, deal type, billing model, GST).
- [x] **`lib/widgets/project/assign_creator_dialog.dart`** (241 lines): `AssigncreatorDialog` and `AssigncreatorDialogState` (creator search, roster filtering, rate negotiation).
- [x] **`lib/widgets/project/add_campaign_dialog.dart`** (79 lines): `AddCampaignDialog` and `AddCampaignDialogState`.
- [x] **`lib/widgets/project/project_dialogs.dart`** (3 lines): Pure barrel export.

---

### Phase 2: CRM Dialogs & Design System Isolation — ✅ COMPLETED

*Completed on: 2026-10-08 | Verification: `flutter analyze` (0 issues), `flutter test` (all 29 tests passed)*

Isolated monolithic CRM dashboards and forms into single-responsibility components and separated operational audit timeline modals from pure design tokens.

#### 2.1 Extract Audit Log Dialog from `lib/widgets/common/ui_kit.dart` (Was 736 Lines) — [x] COMPLETED
- [x] **`lib/widgets/common/dream_audit_log_dialog.dart`** (294 lines): `DreamAuditLogDialog` and `_TimelineItem` (Firestore event timeline, actor badges, JSON inspector).
- [x] **`lib/widgets/common/ui_kit.dart`** (404 lines): Clean design token primitives (`DreamStatusChip`, `DreamMetadataGrid`, `DreamGridMetaTile`, `DreamSectionBox`, `showDreamConfirm`, `DreamPageHeader`, `DreamLedgerCard`, `DreamMiniBadge`) with barrel re-export.

#### 2.2 Split `lib/widgets/client/client_dialogs.dart` (Was 759 Lines) — [x] COMPLETED
- [x] **`lib/widgets/client/client_profile_dialog.dart`** (410 lines): `ClientProfileDialog` and `_ProjectColumn` (read-only CRM metrics, LTV calculation, active/past project history).
- [x] **`lib/widgets/client/add_client_dialog.dart`** (317 lines): `AddClientDialog` and `_AddClientDialogState` (data-entry form, tier dropdown, contact details).
- [x] **`lib/widgets/client/client_dialogs.dart`** (2 lines): Pure barrel export.

#### 2.3 Split `lib/widgets/lead/lead_dialogs.dart` (Was 678 Lines) — [x] COMPLETED
- [x] **`lib/widgets/lead/lead_overview_dialog.dart`** (356 lines): `LeadOverviewDialog` (lead operations dashboard, pitch status card, convert to project action).
- [x] **`lib/widgets/lead/add_edit_lead_form_dialog.dart`** (295 lines): `AddEditLeadFormWindow` and `_AddEditLeadFormWindowState` (lead onboarding form, estimated budget, status chips).
- [x] **`lib/widgets/lead/lead_dialogs.dart`** (2 lines): Pure barrel export.

---

### Phase 3: Proposal Screen & PDF Theme Unification (🟡 Medium Priority)

#### 3.1 Extract Proposal Commercials Sidebar from `lib/screens/proposal_screen.dart` (868 Lines)
- **Extract `lib/widgets/proposal/proposal_commercials_sidebar.dart` (~350 lines):**
  - Add-on builder form & list, agency fee input, subtotal computations, "Save Draft" & "Export PDF" trigger buttons.
- Reduces `lib/screens/proposal_screen.dart` from 868 lines to ~450 lines.

#### 3.2 Unify PDF Theme across `pdf_proposal_builder.dart` & `pdf_invoice_builder.dart`
- Both builders duplicate identical design token classes `_Dt` and `_FontSet`.
- **Create `lib/services/pdf/pdf_theme.dart` (~90 lines):**
  - Export `PdfTheme` (brand purple, accent colors, text styles, margins).
  - Export `PdfFontSet` (Helvetica font bundle).
- Keep document generator layouts in their respective files to preserve procedural PDF pagination integrity.

---

## 4. Verification Protocol (Run After Each Phase)

Before marking any phase as complete, AI maintainers must execute:

```bash
# Step 1: Ensure zero lint errors, type mismatches, or dead code:
flutter analyze

# Step 2: Ensure all unit tests, Froyo rules, and engine tests pass:
flutter test
```

### Invariants Checklist (DO NOT BREAK):
- [ ] **Twin Budget Isolation:** Never merge cash (`baseBudget`, `effectiveBudget`) and barter (`gmvBudget`, `distributedGmv`).
- [ ] **Froyo Rules Archive Lock:** Verify `FroyoRules.canArchiveProject` is never bypassed in project dialogs.
- [ ] **Advance Safety Net:** Verify `FroyoRules.validateAdvancePayment` is preserved in `ExpandableCreatorCard`.
- [ ] **Audit Logging:** Every multi-document mutation must log an event via `AuditLoggerService`.
- [ ] **Zero Secret Leakage:** No credentials hardcoded into Dart source files.
