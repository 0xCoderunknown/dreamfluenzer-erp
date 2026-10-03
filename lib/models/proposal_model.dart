import 'package:cloud_firestore/cloud_firestore.dart';

import '../config/proposal_templates.dart';
import '../domain/app_enums.dart';

// ===========================================================================
// STRUCTURED DELIVERABLE
// ===========================================================================
class Deliverable {
  final DeliverableType type;
  final int quantity;

  const Deliverable({required this.type, this.quantity = 1});

  Map<String, dynamic> toMap() => {'type': type.value, 'quantity': quantity};

  factory Deliverable.fromMap(Map<String, dynamic> m) => Deliverable(
    type: DeliverableType.fromString(m['type'] ?? ''),
    quantity: (m['quantity'] as num?)?.toInt() ?? 1,
  );
}

// ===========================================================================
// PROPOSED CREATOR (The Contract)
// ===========================================================================
class ProposedCreator {
  final String creatorId;
  final String name;
  final double baseRate;
  final double proposedAdvance;
  final List<Deliverable> deliverables;

  // Outbound execution constraints for usage and exclusivity
  final String usageRightsDuration;
  final String categoryExclusivity;

  const ProposedCreator({
    required this.creatorId,
    required this.name,
    required this.baseRate,
    this.proposedAdvance = 0.0,
    required this.deliverables,
    this.usageRightsDuration = ProposalTextBlueprintManager.defaultUsageRights,
    this.categoryExclusivity = ProposalTextBlueprintManager.defaultExclusivity,
  });

  ProposedCreator copyWith({
    double? baseRate,
    double? proposedAdvance,
    List<Deliverable>? deliverables,
    String? usageRightsDuration,
    String? categoryExclusivity,
  }) => ProposedCreator(
    creatorId: creatorId,
    name: name,
    baseRate: baseRate ?? this.baseRate,
    proposedAdvance: proposedAdvance ?? this.proposedAdvance,
    deliverables: deliverables ?? this.deliverables,
    usageRightsDuration: usageRightsDuration ?? this.usageRightsDuration,
    categoryExclusivity: categoryExclusivity ?? this.categoryExclusivity,
  );

  Map<String, dynamic> toMap() => {
    'creator_id': creatorId,
    'name': name,
    'base_rate': baseRate,
    'proposed_advance': proposedAdvance,
    'deliverables': deliverables.map((d) => d.toMap()).toList(),
    'usage_rights_duration': usageRightsDuration,
    'category_exclusivity': categoryExclusivity,
  };

  factory ProposedCreator.fromMap(Map<String, dynamic> m) => ProposedCreator(
    creatorId: m['creator_id'] ?? '',
    name: m['name'] ?? '',
    baseRate: (m['base_rate'] as num?)?.toDouble() ?? 0.0,
    proposedAdvance: (m['proposed_advance'] as num?)?.toDouble() ?? 0.0,
    deliverables: (m['deliverables'] as List? ?? [])
        .map((d) => Deliverable.fromMap(d))
        .toList(),
    usageRightsDuration:
        m['usage_rights_duration'] ??
        ProposalTextBlueprintManager.defaultUsageRights,
    categoryExclusivity:
        m['category_exclusivity'] ??
        ProposalTextBlueprintManager.defaultExclusivity,
  );
}

// ===========================================================================
// PITCH ADD-ON (Logistics, Shoots, Extra Costs)
// ===========================================================================
class PitchAddOn {
  final String id;
  final String description;
  final double price;
  final String? creatorId;

  const PitchAddOn({
    required this.id,
    required this.description,
    required this.price,
    this.creatorId,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'description': description,
    'price': price,
    'creatorId': creatorId,
  };

  factory PitchAddOn.fromMap(Map<String, dynamic> m) => PitchAddOn(
    id: m['id'] ?? 'addon_${DateTime.now().millisecondsSinceEpoch}',
    description: m['description'] ?? '',
    price: (m['price'] as num?)?.toDouble() ?? 0.0,
    creatorId: m['creatorId'],
  );
}

// ===========================================================================
// THE PROPOSAL
// ===========================================================================
class Proposal {
  final String id;
  final String leadId;
  final ProposalType proposalType; // The layout formatting and phrasing trigger
  final List<ProposedCreator> creators;
  final List<PitchAddOn> addOns;
  final double agencyFee;
  final ProposalStatus status;
  final DateTime createdAt;
  final String internalNotes;

  final double? _storedClientPrice;

  const Proposal({
    required this.id,
    required this.leadId,
    required this.proposalType,
    required this.creators,
    required this.addOns,
    required this.agencyFee,
    required this.status,
    required this.createdAt,
    this.internalNotes = '',
    this._storedClientPrice,
  });

  double get totalBaseCost =>
      creators.fold(0.0, (double sum, c) => sum + c.baseRate);

  double get totalAddOnsCost =>
      addOns.fold(0.0, (double sum, a) => sum + a.price);

  double get totalClientPrice =>
      _storedClientPrice ?? (totalBaseCost + agencyFee + totalAddOnsCost);

  factory Proposal.fromMap(Map<String, dynamic> m, {String? id}) {
    return Proposal(
      id: id ?? m['id'] as String? ?? '',
      leadId: m['lead_id'] ?? '',
      proposalType: ProposalType.fromString(
        m['proposal_type'] ?? 'Local Visibility',
      ),
      creators: (m['creators'] as List? ?? [])
          .map((c) => ProposedCreator.fromMap(c))
          .toList(),
      addOns: (m['add_ons'] as List? ?? [])
          .map((a) => PitchAddOn.fromMap(a))
          .toList(),
      agencyFee: (m['agency_fee'] as num?)?.toDouble() ?? 0.0,
      status: ProposalStatus.fromString(m['status'] ?? 'Draft'),
      createdAt: (m['created_at'] is Timestamp)
          ? (m['created_at'] as Timestamp).toDate()
          : DateTime.now(),
      internalNotes: m['internal_notes'] ?? '',
      storedClientPrice: (m['total_client_price'] as num?)?.toDouble(),
    );
  }

  factory Proposal.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return Proposal.fromMap(data, id: doc.id);
  }

  Map<String, dynamic> toMap() => {
    'lead_id': leadId,
    'proposal_type': proposalType.value,
    'creators': creators.map((c) => c.toMap()).toList(),
    'add_ons': addOns.map((a) => a.toMap()).toList(),
    'agency_fee': agencyFee,
    'total_client_price': totalClientPrice,
    'status': status.value,
    'created_at': Timestamp.fromDate(createdAt),
    'internal_notes': internalNotes,
  };

  Proposal copyWith({
    ProposalType? proposalType,
    List<ProposedCreator>? creators,
    List<PitchAddOn>? addOns,
    double? agencyFee,
    ProposalStatus? status,
    String? internalNotes,
  }) {
    return Proposal(
      id: id,
      leadId: leadId,
      proposalType: proposalType ?? this.proposalType,
      creators: creators ?? this.creators,
      addOns: addOns ?? this.addOns,
      agencyFee: agencyFee ?? this.agencyFee,
      status: status ?? this.status,
      createdAt: createdAt,
      internalNotes: internalNotes ?? this.internalNotes,
      storedClientPrice: _storedClientPrice,
    );
  }
}
