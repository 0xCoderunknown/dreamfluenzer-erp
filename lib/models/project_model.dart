import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/app_enums.dart';
import '../engines/revenue_engine.dart';

class Project {
  final String id;
  final String clientId;
  final String projectName;
  final String leadName;
  final DealType dealType;
  final ProjectStatus status;
  final DateTime deadline;
  final BillingModel billingModel;
  final int durationMonths;
  final double baseBudget;
  final double gmvBudget;
  final bool isGstExclusive;
  final double advanceReceived;
  final DateTime createdAt;

  const Project({
    required this.id,
    required this.clientId,
    required this.projectName,
    required this.leadName,
    required this.dealType,
    required this.status,
    required this.deadline,
    required this.billingModel,
    required this.durationMonths,
    required this.baseBudget,
    this.gmvBudget = 0.0,
    required this.isGstExclusive,
    required this.advanceReceived,
    required this.createdAt,
  });

  // ─── Financial Calculations ───

  bool get isRetainer => billingModel == BillingModel.retainer;

  /// Returns the project name.
  String get displayProjectName => projectName;

  /// Evaluates total contract financials based on the billing model.
  double get totalContractValue =>
      isRetainer ? baseBudget * durationMonths : baseBudget;

  /// Uses the RevenueEngine's central GST rate instead of hardcoding 1.18
  double get effectiveBudget {
    if (!isGstExclusive) return totalContractValue;
    return totalContractValue * (1 + RevenueEngine.currentGstRate);
  }

  double get balanceDue => effectiveBudget - advanceReceived;

  // ─── DATA CONVERSION ───

  factory Project.fromMap(Map<String, dynamic> m, {String? id}) {
    DateTime parseDate(dynamic field) {
      if (field is Timestamp) return field.toDate();
      if (field is String) return DateTime.tryParse(field) ?? DateTime.now();
      return DateTime.now();
    }

    return Project(
      id: id ?? m['id'] as String? ?? '',
      clientId: m['client_id'] ?? '',
      projectName: m['project_name'] ?? '',
      leadName: m['lead_name'] ?? '',
      dealType: DealType.fromString(m['deal_type'] ?? 'Cash'),
      status: ProjectStatus.fromString(m['status'] ?? 'Active'),
      deadline: parseDate(m['deadline']),
      billingModel: BillingModel.fromString(m['billing_model'] ?? 'One-Off'),
      durationMonths: (m['duration_months'] as num?)?.toInt() ?? 1,
      baseBudget: (m['base_budget'] as num?)?.toDouble() ?? 0.0,
      gmvBudget: (m['gmv_budget'] as num?)?.toDouble() ?? 0.0,
      isGstExclusive: m['is_gst_exclusive'] ?? false,
      advanceReceived: (m['advance_received'] as num?)?.toDouble() ?? 0.0,
      createdAt: parseDate(m['created_at']),
    );
  }

  factory Project.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return Project.fromMap(data, id: doc.id);
  }

  Map<String, dynamic> toMap() => {
    'client_id': clientId,
    'project_name': projectName,
    'lead_name': leadName,
    'deal_type': dealType.value,
    'status': status.value,
    'deadline': Timestamp.fromDate(deadline),
    'billing_model': billingModel.value,
    'duration_months': durationMonths,
    'base_budget': baseBudget,
    'gmv_budget': gmvBudget,
    'is_gst_exclusive': isGstExclusive,
    'advance_received': advanceReceived,
    'created_at': Timestamp.fromDate(createdAt),
  };

  // ─── IMMUTABILITY: copyWith ───

  Project copyWith({
    String? projectName,
    String? leadName,
    DealType? dealType,
    ProjectStatus? status,
    DateTime? deadline,
    BillingModel? billingModel,
    int? durationMonths,
    double? baseBudget,
    double? gmvBudget,
    bool? isGstExclusive,
    double? advanceReceived,
  }) {
    return Project(
      id: id,
      clientId: clientId,
      projectName: projectName ?? this.projectName,
      leadName: leadName ?? this.leadName,
      dealType: dealType ?? this.dealType,
      status: status ?? this.status,
      deadline: deadline ?? this.deadline,
      billingModel: billingModel ?? this.billingModel,
      durationMonths: durationMonths ?? this.durationMonths,
      baseBudget: baseBudget ?? this.baseBudget,
      gmvBudget: gmvBudget ?? this.gmvBudget,
      isGstExclusive: isGstExclusive ?? this.isGstExclusive,
      advanceReceived: advanceReceived ?? this.advanceReceived,
      createdAt: createdAt,
    );
  }

  bool get isOverdue {
    final today = DateTime.now();
    return deadline.isBefore(DateTime(today.year, today.month, today.day)) &&
        status == ProjectStatus.active;
  }

  /// Checks if payment is pending. Excludes PR/Gift deals.
  bool get isPaymentPending {
    return (advanceReceived < effectiveBudget) &&
        status == ProjectStatus.completed &&
        dealType != DealType.prGift;
  }
}
