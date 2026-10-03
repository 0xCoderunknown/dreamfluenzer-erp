import 'package:flutter/material.dart';

import '../config/proposal_templates.dart';
import '../domain/app_enums.dart';
import '../../models/creator_model.dart';
import '../../models/proposal_model.dart';
import '../services/firestore_service.dart';

class ProposalCompilerEngine {
  /// Transforms raw interactive UI controller fields into a packaged, database-ready Proposal state.
  static Proposal compile({
    required String? existingProposalId,
    required String leadId,
    required ProposalType proposalType,
    required Set<String> selectedCreatorIds,
    required List<PitchAddOn> addOnsList,
    required double agencyFee,
    required String internalNotes,
    required Map<String, TextEditingController> payoutControllers,
    required Map<String, TextEditingController> usageRightsControllers,
    required Map<String, TextEditingController> exclusivityControllers,
    required Map<String, Map<DeliverableType, int>> deliverableSelections,
    required List<Creator> allRosterCreators,
    required ProposalStatus defaultStatus,
    required DateTime defaultCreatedAt,
  }) {
    final creatorList = <ProposedCreator>[];

    for (var id in selectedCreatorIds) {
      final modelRef = allRosterCreators.firstWhere((c) => c.id == id);

      final agreedPayout =
          double.tryParse(payoutControllers[id]?.text ?? '0') ??
          modelRef.baseRate;

      final usageRights =
          usageRightsControllers[id]?.text.trim() ??
          ProposalTextBlueprintManager.defaultUsageRights;
      final exclusivity =
          exclusivityControllers[id]?.text.trim() ??
          ProposalTextBlueprintManager.defaultExclusivity;

      final delList = <Deliverable>[];
      deliverableSelections[id]!.forEach((type, qty) {
        if (qty > 0) {
          delList.add(Deliverable(type: type, quantity: qty));
        }
      });

      creatorList.add(
        ProposedCreator(
          creatorId: id,
          name: modelRef.fullName,
          baseRate: agreedPayout,
          deliverables: delList,
          usageRightsDuration: usageRights,
          categoryExclusivity: exclusivity,
        ),
      );
    }

    return Proposal(
      id: existingProposalId ?? FirestoreService().generateId('proposals'),
      leadId: leadId,
      proposalType: proposalType,
      creators: creatorList,
      addOns: addOnsList,
      agencyFee: agencyFee,
      status: defaultStatus,
      createdAt: defaultCreatedAt,
      internalNotes: internalNotes,
    );
  }
}
