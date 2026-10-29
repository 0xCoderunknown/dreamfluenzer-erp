# 📊 DreamFluenzer ERP — Data Schema & Model Contracts

> **Single Source of Truth for Firestore Collections, Document IDs, and Serialization Models.**  
> **RULE:** No AI agent may add, rename, or delete any Firestore fields without updating this document and getting approval from the PM.  
> **Date Standard:** All human-facing dates strictly follow Indian numerical formatting (`DD-MM-YYYY`).

---

## 🗄️ Firestore Collections Overview

| Collection Name | Document ID Pattern | Description |
|---|---|---|
| `projects` | Auto-generated UID (UUID / Firestore ID) | Root agency project contracts, billing terms, budgets, and lifecycle states. |
| `projects/{id}/campaigns` | Auto-generated UID | Nested sub-collection containing campaign deliverables, creator rosters, and inventory. |
| `creators` | Unique creator ID or UID | Master creator roster, social metrics, commercial rates, and payout bank/UPI credentials. |
| `clients` | Auto-generated UID | Brand/client directory, tax/GST profiles, billing addresses, and client tiers. |
| `leads` | Auto-generated UID | Inbound/outbound sales leads, qualification stages, and deal types. |
| `proposals` | Auto-generated UID | Pitched client proposals, commercial deliverable line-items, and PDF snapshots. |
| `projects/{id}/history` · `creators/{id}/history` | Auto-generated UID | Append-only audit trail logging money mutations, status changes, and actor IDs. |

---

## 📁 1. `projects` Collection

- **Document ID:** Auto-generated UID (`projectId`).
- **Invariance:** Liquid cash (`baseBudget`, `advanceReceived`) and Barter GMV (`gmvBudget`) are strictly isolated. Never sum them into a single total.

### Fields
| Field | Type | Required | Description |
|---|---|---|---|
| `id` | `String` | Yes | Unique project identifier. |
| `clientId` | `String` | Yes | Reference to owning `clients/{id}` document. |
| `projectName` | `String` | Yes | Human-readable project title. |
| `leadName` | `String` | No | Associated brand lead or contact person name. |
| `dealType` | `String` | Yes | Serialized `DealType.name` (`cash`, `barter`, `hybrid`, `pr`). |
| `status` | `String` | Yes | Serialized `ProjectStatus.name` (`planning`, `active`, `completed`, `cancelled`, `archived`). |
| `deadline` | `DateTime` / `Timestamp` | Yes | Scheduled project delivery and campaign wrap date. |
| `billingModel` | `String` | Yes | Serialized `BillingModel.name` (`oneOff`, `monthlyRetainer`, `milestone`). |
| `durationMonths` | `int` | Yes | Duration in months for retainers (defaults to `1`). |
| `baseBudget` | `double` | Yes | Liquid cash deal size payable by client (excluding barter). |
| `gmvBudget` | `double` | Yes | Total Gross Merchandise Value of barter products sponsored by brand. |
| `isGstExclusive` | `bool` | Yes | If `true`, 18% GST is added on top of `baseBudget`; if `false`, budget is GST-inclusive. |
| `advanceReceived` | `double` | Yes | Total liquid cash upfront advance collected from the client. |
| `createdAt` | `DateTime` / `Timestamp` | Yes | Creation timestamp. |

---

## 📦 2. `projects/{projectId}/campaigns` Subcollection

- **Document ID:** Auto-generated UID (`campaignId`).
- **Invariance:** Projects contain one or more campaigns. Archiving a project requires all assigned creators across campaigns to have terminal deliverable status and zero unpaid `postedLive` dues.

### Fields
| Field | Type | Required | Description |
|---|---|---|---|
| `id` | `String` | Yes | Unique campaign identifier. |
| `name` | `String` | Yes | Campaign name or flight title. |
| `startDate` | `DateTime` / `Timestamp` | Yes | Campaign activation start date. |
| `endDate` | `DateTime` / `Timestamp` | Yes | Campaign live end date. |
| `assignedCreators` | `List<Map>` | Yes | Array of serialized `AssignedCreator` objects. |
| `inventoryPool` | `List<Map>` | Yes | Array of serialized `CampaignInventory` barter product items. |

### Sub-Model: `AssignedCreator`
| Field | Type | Description |
|---|---|---|
| `creatorId` | `String` | Foreign key referencing master `creators/{id}` document. |
| `creatorName` | `String` | Cached creator name for fast offline/presentation rendering. |
| `individualDeadline` | `DateTime` | Specific milestone deadline for this creator. |
| `agreedPayout` | `double` | Total contracted liquid cash payout for this creator. |
| `pipelineStatus` | `String` | `PipelineStatus.name` (`draftRequested`, `reviewing`, `changesRequested`, `awaitingClientSignoff`, `postedLive`, `dropped`). |
| `isPaid` | `bool` | Settlement flag; must be `true` before archiving if `postedLive`. |
| `deliverables` | `List<Map>` | Deliverables list (`Deliverable`: `type`, `count`, `status`, `notes`). |
| `advancePaid` | `double` | Cash advance disbursed to the creator (capped by client advance pool). |
| `allocatedItems` | `List<Map>` | Barter items assigned (`AllocatedItem`: `inventoryId`, `itemName`, `quantity`, `status`, `notes`). |

---

## 🌟 3. `creators` Collection

- **Document ID:** Unique creator identifier (`creatorId`).

### Fields
| Field | Type | Required | Description |
|---|---|---|---|
| `id` | `String` | Yes | Unique creator identifier. |
| `fullName` | `String` | Yes | Creator legal or display name. |
| `handle` | `String` | Yes | Social handle (e.g. `@johndoe`). |
| `platform` | `String` | Yes | Primary platform (`instagram`, `youtube`, `linkedin`, `twitter`). |
| `primaryCategory` | `String` | Yes | Primary niche (e.g. `Tech`, `Fashion`, `Finance`). |
| `secondaryCategories` | `List<String>` | No | Secondary niches. |
| `followersCount` | `int` | Yes | Total follower / subscriber count. |
| `engagementRate` | `double` | Yes | Engagement percentage (e.g. `3.4`). |
| `city` | `String` | Yes | Primary residence city. |
| `state` | `String` | Yes | Primary residence state. |
| `gender` | `String` | Yes | `'Male'`, `'Female'`, or `'Other'`. |
| `baseRate` | `double` | Yes | Standard rate per sponsored post/reel. |
| `email` | `String` | Yes | Creator contact email. |
| `phone` | `String` | Yes | Creator 10-digit contact phone. |
| `upiId` | `String` | No | Payout UPI VPA address. |
| `bankAccountNumber`| `String` | No | Beneficiary bank account number. |
| `bankIfsc` | `String` | No | Bank branch IFSC code. |
| `bankBeneficiaryName`| `String` | No | Name registered on bank account. |
| `notes` | `String` | No | Internal agency notes, strengths, and manager feedback. |
| `isActive` | `bool` | Yes | Roster active flag. |
| `createdAt` | `DateTime` / `Timestamp` | Yes | Onboarding timestamp. |

---

## 🏢 4. `clients` Collection

- **Document ID:** Auto-generated UID (`clientId`).

### Fields
| Field | Type | Required | Description |
|---|---|---|---|
| `id` | `String` | Yes | Unique client identifier. |
| `businessName` | `String` | Yes | Registered brand or company name. |
| `contactName` | `String` | Yes | Primary brand POC name. |
| `contactPhone` | `String` | Yes | Brand POC phone number. |
| `email` | `String` | Yes | Brand POC billing / communication email. |
| `brandCategory` | `String` | Yes | Industry sector (e.g. `FMCG`, `Fintech`, `D2C`). |
| `billingAddress` | `String` | No | Official billing address for invoices. |
| `gstNumber` | `String` | No | 15-character Indian GSTIN. |
| `tier` | `String` | Yes | Client tier: `bronze`, `silver`, `gold`, `platinum`. |
| `createdAt` | `DateTime` / `Timestamp` | Yes | Client onboarding timestamp. |
| `notes` | `String` | No | Account manager context and contract history. |

---

## 🎯 5. `leads` Collection

- **Document ID:** Auto-generated UID (`leadId`).

### Fields
| Field | Type | Required | Description |
|---|---|---|---|
| `id` | `String` | Yes | Unique lead identifier. |
| `businessName` | `String` | Yes | Prospective client company name. |
| `contactPerson` | `String` | Yes | Prospect contact name. |
| `contactPhone` | `String` | Yes | Prospect phone number. |
| `email` | `String` | Yes | Prospect email. |
| `status` | `String` | Yes | `LeadStatus.name` (`newLead`, `contacted`, `proposalSent`, `negotiating`, `won`, `lost`). |
| `estimatedBudget`| `double` | Yes | Expected pipeline budget in INR. |
| `dealType` | `String` | Yes | Expected deal model (`cash`, `barter`, `hybrid`, `pr`). |
| `notes` | `String` | No | CRM notes, pitch history, objections. |
| `createdAt` | `DateTime` / `Timestamp` | Yes | Ingestion timestamp. |
| `updatedAt` | `DateTime` / `Timestamp` | Yes | Most recent pipeline update timestamp. |

---

## 📝 6. `proposals` Collection

- **Document ID:** Auto-generated UID (`proposalId`).

### Fields
| Field | Type | Required | Description |
|---|---|---|---|
| `id` | `String` | Yes | Unique proposal identifier. |
| `leadId` | `String` | Yes | Associated CRM lead reference. |
| `clientBusinessName` | `String` | Yes | Pitch target business name. |
| `contactPerson` | `String` | Yes | Prospect contact person. |
| `conceptSummary` | `String` | Yes | Campaign creative angle and deliverables brief. |
| `deliverables` | `List<Map>` | Yes | Array of pitched deliverables (`type`, `count`, `unitPrice`). |
| `creators` | `List<Map>` | Yes | Pitched creator recommendations. |
| `addOns` | `List<Map>` | Yes | Pitch add-ons (`id`, `title`, `price`). |
| `agencyFeePercentage`| `double` | Yes | Agency commission cut % (e.g. `15.0`). |
| `agencyFeeFlat` | `double` | Yes | Flat agency management retainer fee if applicable. |
| `validUntil` | `DateTime` / `Timestamp` | Yes | Proposal expiration date. |
| `createdAt` | `DateTime` / `Timestamp` | Yes | Proposal issue date. |
| `status` | `String` | Yes | `ProposalStatus.name` (`draft`, `sent`, `accepted`, `rejected`, `expired`). |
| `pdfUrl` | `String` | No | Cloud storage link to compiled pitch PDF. |

---

## 📜 7. `audit_logs` & History Subcollections

- **Paths:** `projects/{id}/history`, `creators/{id}/history`.
- **Invariance:** **Append-only ledger.** Entries are never updated or deleted.

### Fields
| Field | Type | Required | Description |
|---|---|---|---|
| `id` | `String` | Yes | Unique audit event identifier. |
| `timestamp` | `DateTime` / `Timestamp` | Yes | Exact mutation timestamp. |
| `actor` | `String` | Yes | User email or operator ID executing the action. |
| `type` | `String` | Yes | Event domain type (e.g. `financial`, `statusChange`, `allocation`). |
| `action` | `String` | Yes | Specific action verb (e.g. `advance_disbursed`, `project_archived`). |
| `amount` | `double?` | No | Financial transaction amount if applicable. |
| `reason` | `String?` | No | Mandatory justification for overrides, payouts, or status jumps. |
| `metadata` | `Map<String, dynamic>` | No | Context snapshot of state prior to mutation. |
