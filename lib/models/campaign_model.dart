import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/app_enums.dart';
import 'proposal_model.dart';

// ===========================================================================
// THE POOL: CAMPAIGN INVENTORY (The Master Box from the Brand)
// ===========================================================================
class CampaignInventory {
  final String id;
  final String itemName;
  final int totalQuantity;
  final double gmvPerUnit; // Tracks the perceived barter value
  final bool isReturnable; // e.g., Sony Camera = true, Face Wash = false
  // TODO: [Roadmap Scaffolding] Planned for Warehouse Stock Tracking Module.
  final InventoryStatus status;

  const CampaignInventory({
    required this.id,
    required this.itemName,
    required this.totalQuantity,
    required this.gmvPerUnit,
    this.isReturnable = false,
    this.status = InventoryStatus.waitingOnBrand,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'item_name': itemName,
    'total_quantity': totalQuantity,
    'gmv_per_unit': gmvPerUnit,
    'is_returnable': isReturnable,
    'status': status.value,
  };

  factory CampaignInventory.fromMap(Map<String, dynamic> m) =>
      CampaignInventory(
        id: m['id'] ?? '',
        itemName: m['item_name'] ?? '',
        totalQuantity: m['total_quantity'] as int? ?? 0,
        gmvPerUnit: (m['gmv_per_unit'] as num?)?.toDouble() ?? 0.0,
        isReturnable: m['is_returnable'] ?? false,
        status: InventoryStatus.fromString(m['status'] ?? 'Waiting on Brand'),
      );
}

// ===========================================================================
// THE ALLOCATION: WHAT THE CREATOR ACTUALLY GETS
// ===========================================================================
class AllocatedItem {
  final String inventoryId; // Links back to the Pool
  final String itemName; // Cached for easy UI rendering
  final int quantity;
  final AllocationStatus status;
  final String notes; // "Swiggy Genie tracking link"

  const AllocatedItem({
    required this.inventoryId,
    required this.itemName,
    required this.quantity,
    this.status = AllocationStatus.pending,
    this.notes = '',
  });

  Map<String, dynamic> toMap() => {
    'inventory_id': inventoryId,
    'item_name': itemName,
    'quantity': quantity,
    'status': status.value,
    'notes': notes,
  };

  factory AllocatedItem.fromMap(Map<String, dynamic> m) => AllocatedItem(
    inventoryId: m['inventory_id'] ?? '',
    itemName: m['item_name'] ?? '',
    quantity: m['quantity'] as int? ?? 0,
    status: AllocationStatus.fromString(m['status'] ?? 'Pending Dispatch'),
    notes: m['notes'] ?? '',
  );
}

// ===========================================================================
// ASSIGNED CREATOR
// ===========================================================================
class AssignedCreator {
  final String creatorId;
  final String creatorName;
  final DateTime individualDeadline;
  final double agreedPayout;
  final PipelineStatus pipelineStatus;
  final bool isPaid;
  final List<Deliverable> deliverables;
  final double advancePaid;
  final List<AllocatedItem>
  allocatedItems; // Allocated inventory items for the creator

  AssignedCreator({
    required this.creatorId,
    required this.creatorName,
    required this.individualDeadline,
    required this.agreedPayout,
    required this.pipelineStatus,
    required this.isPaid,
    required this.deliverables,
    this.advancePaid = 0.0,
    this.allocatedItems = const [],
  });

  AssignedCreator copyWith({
    String? creatorId,
    String? creatorName,
    DateTime? individualDeadline,
    double? agreedPayout,
    PipelineStatus? pipelineStatus,
    bool? isPaid,
    List<Deliverable>? deliverables,
    double? advancePaid,
    List<AllocatedItem>? allocatedItems,
  }) {
    return AssignedCreator(
      creatorId: creatorId ?? this.creatorId,
      creatorName: creatorName ?? this.creatorName,
      individualDeadline: individualDeadline ?? this.individualDeadline,
      agreedPayout: agreedPayout ?? this.agreedPayout,
      pipelineStatus: pipelineStatus ?? this.pipelineStatus,
      isPaid: isPaid ?? this.isPaid,
      deliverables: deliverables ?? this.deliverables,
      advancePaid: advancePaid ?? this.advancePaid,
      allocatedItems: allocatedItems ?? this.allocatedItems,
    );
  }

  factory AssignedCreator.fromMap(Map<String, dynamic> m) {
    return AssignedCreator(
      creatorId: m['creator_id'] ?? '',
      creatorName: m['creator_name'] ?? '',
      individualDeadline: (m['individual_deadline'] is Timestamp)
          ? (m['individual_deadline'] as Timestamp).toDate()
          : DateTime.now(),
      agreedPayout: (m['agreed_payout'] as num?)?.toDouble() ?? 0.0,
      pipelineStatus: PipelineStatus.fromString(
        m['pipeline_status'] ?? 'Pending',
      ),
      isPaid: m['is_paid'] ?? false,
      deliverables: (m['deliverables'] as List? ?? [])
          .map((d) => Deliverable.fromMap(d))
          .toList(),
      advancePaid: (m['advance_paid'] as num?)?.toDouble() ?? 0.0,
      allocatedItems: (m['allocated_items'] as List? ?? [])
          .map((i) => AllocatedItem.fromMap(i))
          .toList(),
    );
  }

  Map<String, dynamic> toMap() => {
    'creator_id': creatorId,
    'creator_name': creatorName,
    'individual_deadline': Timestamp.fromDate(individualDeadline),
    'agreed_payout': agreedPayout,
    'pipeline_status': pipelineStatus.value,
    'is_paid': isPaid,
    'deliverables': deliverables.map((d) => d.toMap()).toList(),
    'advance_paid': advancePaid,
    'allocated_items': allocatedItems.map((i) => i.toMap()).toList(),
  };
}

// ===========================================================================
// CAMPAIGN
// ===========================================================================
class Campaign {
  final String id;
  final String projectId;
  final String title;
  final DateTime cycleEndDate;
  final double expenses;
  final List<CampaignInventory>
  inventoryPool; // Campaign-wide inventory items pool
  final List<AssignedCreator> assignedCreators;

  Campaign({
    required this.id,
    required this.projectId,
    required this.title,
    required this.cycleEndDate,
    required this.expenses,
    this.inventoryPool = const [],
    required this.assignedCreators,
  });

  Campaign copyWith({
    String? id,
    String? projectId,
    String? title,
    DateTime? cycleEndDate,
    double? expenses,
    List<CampaignInventory>? inventoryPool,
    List<AssignedCreator>? assignedCreators,
  }) {
    return Campaign(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      title: title ?? this.title,
      cycleEndDate: cycleEndDate ?? this.cycleEndDate,
      expenses: expenses ?? this.expenses,
      inventoryPool: inventoryPool ?? this.inventoryPool,
      assignedCreators: assignedCreators ?? this.assignedCreators,
    );
  }

  factory Campaign.fromMap(Map<String, dynamic> data, {String? id}) {
    return Campaign(
      id: id ?? data['id'] as String? ?? '',
      projectId: data['project_id'] ?? '',
      title: data['title'] ?? '',
      cycleEndDate: (data['cycle_end_date'] is Timestamp)
          ? (data['cycle_end_date'] as Timestamp).toDate()
          : DateTime.now(),
      expenses: (data['expenses'] as num?)?.toDouble() ?? 0.0,
      inventoryPool: (data['inventory_pool'] as List? ?? [])
          .map((i) => CampaignInventory.fromMap(i))
          .toList(),
      assignedCreators: (data['assigned_creators'] as List? ?? [])
          .map((c) => AssignedCreator.fromMap(c))
          .toList(),
    );
  }

  factory Campaign.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return Campaign.fromMap(data, id: doc.id);
  }

  Map<String, dynamic> toMap() => {
    'project_id': projectId,
    'title': title,
    'cycle_end_date': Timestamp.fromDate(cycleEndDate),
    'expenses': expenses,
    'inventory_pool': inventoryPool.map((i) => i.toMap()).toList(),
    'assigned_creators': assignedCreators.map((c) => c.toMap()).toList(),
  };
}
