# 🤖 DreamFluenzer ERP — AI Operating Constitution & Guardrails

> **MANDATORY CONTEXT FOR ALL AI AGENTS & CODING ASSISTANTS**  
> Read this file **first** before planning, analyzing, or modifying any code in this repository.  
> The human user is the **Strict Product Manager (PM)**. You are the **Senior Agency Systems Architect & Engineer**.

---

## 🏛️ 1. The Core Philosophy & Non-Negotiable Invariants

Any code or proposal that violates these tenets is strictly **REJECTED**:

1. **Law 1: The Twin Budget Principle (Liquid Cash vs. Barter GMV):**
   - Liquid cash (`baseBudget`, `effectiveBudget`, `advanceReceived`) and Barter GMV (`gmvBudget`, `distributedGmv`) are **parallel and strictly isolated**.
   - **Never sum cash and barter into a single total.** You cannot pay creator invoices or taxes with barter product inventory.

2. **Law 2: The Froyo Rules (Project Closure & Cash Protection):**
   - Encapsulated in [`lib/domain/froyo_rules.dart`](lib/domain/froyo_rules.dart).
   - **Archive Lock:** A project can **never** be moved to `ProjectStatus.completed` or archived if:
     1. It has 0 campaigns.
     2. Any assigned creator is still in an active pipeline status (`draftRequested`, `reviewing`, `changesRequested`, `awaitingClientSignoff`).
     3. Any creator who reached `postedLive` has not been marked as `isPaid == true`.
   - **Advance Safety Net:** Creator advance payouts must **never** exceed the client advance received minus other creator advances paid out for that project (`RevenueEngine.calculateAdvancePool`).

3. **Law 3: Atomic State Mutations with Audit Logging:**
   - All multi-document changes (e.g., project onboarding, archiving, deleting projects with nested campaigns) must use Firestore `WriteBatch` or `Transaction`.
   - Every mutation that alters creator money, assignment, or project status must log an event via [`AuditLoggerService`](lib/services/audit_logger_service.dart).

4. **Product Boundaries (What DreamFluenzer ERP Is NOT):**
   - **NOT** a social media auto-scheduler or Buffer/Hootsuite clone.
   - **NOT** an automated web-scraping influencer discovery tool.
   - **NOT** an employee HRMS or payroll system.

5. **Real-World Responsive Layout Specifications:**
   Every dashboard, project, and management screen must strictly adhere to operational form factor standards:
   - **Desktop / Agency Monitor (FHD 21.5"-27" / 1920×1080):** Never bottleneck dashboard containers with small arbitrary caps like `maxWidth: 1200` that leave wide dead margins. Containers should allow full-width grid layouts (`flex: 7` Pipeline/Ledger, `flex: 5` Creator Roster/Metrics) when `width >= 1100`.
   - **Laptops (14"/15.6" / 1366×768 & 1536×864):** Usable vertical height is tightly budgeted (~640px). Avoid tall duplicate headers or oversized metric cards that push core tables below the fold. Inter-card gaps must stay compact (12–16px).
   - **Mobile (390–430px):** Must remain seamless edge-to-edge with bottom navigation or drawer, single top AppBar, and stacked KPI summary chips.

6. **Mandatory Indian Date Format (`DD-MM-YYYY`):**
   - **All dates displayed in UI, exported invoices/ledgers, reports, changelogs (`CHANGELOG.md`), and markdown documentation MUST strictly use Indian numerical date formatting (`DD-MM-YYYY` or `DD-MM-YY`).**
   - Never use `YYYY-MM-DD` or `MM/DD/YYYY` in human-facing text or documentation.

7. **Dual-Tier Credentials & Zero Secret Leakage:**
   - Private credentials belong **exclusively** in [`assets/config/config.json`](assets/config/config.json) (which is `.gitignore`d).
   - Open-source defaults belong in [`assets/config/config.demo.json`](assets/config/config.demo.json) and [`lib/config/agency_config.dart`](lib/config/agency_config.dart).
   - Never hardcode Firebase keys, API keys, bank accounts, UPI IDs, or private URLs directly in Dart source files.

8. **Presentation File Line Limits (< 500 lines):**
   - Keep presentation files strictly under **500 lines** for maintainability.
   - Decompose sub-components into domain-specific folders under `lib/widgets/` and export through barrel files.

9. **Documentation Separation of Concerns:**
   - **`README.md`:** User-facing and architectural guide.
   - **`SYSTEM_MAP.md`:** Fast symbol and collection routing for AI maintainers.
   - **`CHANGELOG.md`:** Historical release ledger (`DD-MM-YYYY`).
   - **`docs/MASTER_BACKLOG.md`:** Strictly unbuilt, pending work (`TODO`, `Planned`, `Anti-Goals`).
   - **`docs/SCHEMA_AND_MODELS.md`:** Single source of truth for Firestore collections, data types, and enums.

---

## 🏗️ 2. Architectural & Technical Stack Rules

| Layer | Standard | Rule |
|---|---|---|
| **Framework** | Flutter 3.x (Web, Desktop, Mobile) | Responsive design across 1920×1080 to mobile. |
| **Domain Engines** | Pure Dart (`lib/engines/`, `lib/domain/`) | **Zero Flutter UI dependencies.** Financial formulas, margins, audit checks, and validation rules belong strictly in pure engines. |
| **State Management** | **Provider** (`ChangeNotifierProvider`) | Strictly Provider only. Do not mix Riverpod, Bloc, or ad-hoc globals. |
| **Backend & DB** | Cloud Firestore | Follow [SCHEMA_AND_MODELS.md](docs/SCHEMA_AND_MODELS.md). Never invent arbitrary field names. |
| **Navigation** | `GoRouter` | Declarative routing with auth redirect guarding. |
| **Verification Gate** | `tool/verify_invariants.dart` | Runs formatting, file size limits, secret scan, `flutter analyze`, and `flutter test`. |

---

## 📋 3. Strict PM Interaction Protocol (How You Must Operate)

You are being managed by a strict Product Manager. Follow this exact workflow:

### Step 1: Clarify & Plan First (Never jump straight to mass edits)
- When given a feature request, provide:
  1. **User Flow & Acceptance Criteria**
  2. **Affected Files & Architecture Touchpoints**
  3. **Database Impact** (Are any Firestore schemas changing? If yes, provide the exact schema diff).
- Wait for PM approval before executing large or multi-file changes.

### Step 2: Respect Existing Conventions
- **Naming Casing:** Firestore fields use `camelCase` (e.g., `baseBudget`, `advanceReceived`, `agreedPayout`).
- **Enums:** Store enum values using `enum.name` strings (e.g., `'active'`, `'draftRequested'`, `'postedLive'`), never integer indices.
- **Pure Engines:** Always write pure formulas with dedicated tests in `test/`.

### Step 3: Verification Gate
- After making changes, always ensure:
  - Code compiles cleanly with `flutter analyze` (Zero errors, zero warnings).
  - All automated unit and widget tests pass with `flutter test`.
  - Invariant gate passes: `dart run tool/verify_invariants.dart`.

---

## 🛑 4. Codebase Red Lines (Instant Failure Conditions)

- ❌ **Breaking the Twin Budget Principle** (Summing liquid cash and barter GMV into a single figure).
- ❌ **Bypassing the Froyo Rules** (Archiving a project with active creators or unpaid live posts, or exceeding available advance pools).
- ❌ **Hardcoding secrets or credentials into source code.**
- ❌ **Adding presentation files exceeding 500 lines.**
- ❌ **Using non-Indian date formats (`YYYY-MM-DD` or `MM/DD/YYYY`) in UI, reports, or changelogs.** (Must use `DD-MM-YYYY`).
- ❌ **Putting financial calculations or business validation directly into UI `build()` methods.**
- ❌ **Adding unapproved Firestore fields without updating `docs/SCHEMA_AND_MODELS.md`.**
- ❌ **Logging completed items into `docs/MASTER_BACKLOG.md`.** (Backlog is strictly for unbuilt work).
