import 'package:cloud_firestore/cloud_firestore.dart';

import '../config/agency_config.dart';
import '../domain/app_enums.dart';

class Lead {
  final String id;
  final String businessName;
  final String contactPerson;
  final String phone;
  final double estimatedBudget;
  final LeadStatus status;
  final PrimaryCategory primaryCategory;
  final String notes;

  // Custom tracking additions capture straightforward traffic outcomes
  final String customObjective;
  final String locationCity;

  const Lead({
    required this.id,
    required this.businessName,
    required this.contactPerson,
    required this.phone,
    required this.estimatedBudget,
    required this.status,
    required this.primaryCategory,
    required this.notes,
    this.customObjective = '',
    this.locationCity = AgencyConfig.defaultCity,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'business_name': businessName,
    'contact_person': contactPerson,
    'phone': phone,
    'estimated_budget': estimatedBudget,
    'status': status.value,
    'primary_category': primaryCategory.value,
    'notes': notes,
    'custom_objective': customObjective,
    'location_city': locationCity,
  };

  factory Lead.fromMap(Map<String, dynamic> m, {String? id}) => Lead(
    id: id ?? m['id'] as String? ?? '',
    businessName: m['business_name'] as String? ?? '',
    contactPerson: m['contact_person'] as String? ?? '',
    phone: m['phone'] as String? ?? '',
    estimatedBudget: (m['estimated_budget'] as num?)?.toDouble() ?? 0.0,
    status: LeadStatus.fromString(m['status'] as String? ?? 'Identified'),
    primaryCategory: PrimaryCategory.fromString(
      m['primary_category'] as String? ?? 'Apparel / Clothing',
    ),
    notes: m['notes'] as String? ?? '',
    customObjective: m['custom_objective'] as String? ?? '',
    locationCity: m['location_city'] as String? ?? AgencyConfig.defaultCity,
  );

  factory Lead.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return Lead.fromMap(data, id: doc.id);
  }

  Lead copyWith({
    String? id,
    String? businessName,
    String? contactPerson,
    String? phone,
    double? estimatedBudget,
    LeadStatus? status,
    PrimaryCategory? primaryCategory,
    String? notes,
    String? customObjective,
    String? locationCity,
  }) {
    return Lead(
      id: id ?? this.id,
      businessName: businessName ?? this.businessName,
      contactPerson: contactPerson ?? this.contactPerson,
      phone: phone ?? this.phone,
      estimatedBudget: estimatedBudget ?? this.estimatedBudget,
      status: status ?? this.status,
      primaryCategory: primaryCategory ?? this.primaryCategory,
      notes: notes ?? this.notes,
      customObjective: customObjective ?? this.customObjective,
      locationCity: locationCity ?? this.locationCity,
    );
  }

  @override
  String toString() => 'Lead($businessName, ${status.value})';
}
