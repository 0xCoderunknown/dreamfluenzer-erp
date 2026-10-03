import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/app_enums.dart';

class Client {
  final String id;
  final String businessName;
  final String industryType;
  final String contactName;
  final String contactPhone;
  final String email;
  final String instaHandle;
  final String location;
  final ClientTier tier; // ─── NOW AN ENUM
  final String notes;

  const Client({
    required this.id,
    required this.businessName,
    required this.industryType,
    required this.contactName,
    required this.contactPhone,
    required this.email,
    required this.instaHandle,
    required this.location,
    required this.tier,
    required this.notes,
  });

  // ─── THE BRAIN: Data Conversion ───

  Map<String, dynamic> toMap() => {
    'id': id,
    'business_name': businessName,
    'industry_type': industryType,
    'contact_name': contactName,
    'contact_phone': contactPhone,
    'email': email,
    'insta_handle': instaHandle,
    'location': location,
    'tier': tier.value, // Stores the string representation in Firestore
    'notes': notes,
  };

  factory Client.fromMap(Map<String, dynamic> m) => Client(
    id: m['id'] as String? ?? '',
    businessName: m['business_name'] as String? ?? '',
    industryType: m['industry_type'] as String? ?? '',
    contactName: m['contact_name'] as String? ?? '',
    contactPhone: m['contact_phone'] as String? ?? '',
    email: m['email'] as String? ?? '',
    instaHandle: m['insta_handle'] as String? ?? '',
    location: m['location'] as String? ?? '',
    tier: ClientTier.fromString(m['tier'] as String? ?? 'Tier 1'),
    notes: m['notes'] as String? ?? '',
  );

  factory Client.fromFirestore(DocumentSnapshot doc) {
    final m = doc.data() as Map<String, dynamic>? ?? {};
    return Client.fromMap({'id': doc.id, ...m}); // Reuses the fromMap logic
  }

  // ─── IMMUTABILITY: The update engine ───

  Client copyWith({
    String? id,
    String? businessName,
    String? industryType,
    String? contactName,
    String? contactPhone,
    String? email,
    String? instaHandle,
    String? location,
    ClientTier? tier,
    String? notes,
  }) => Client(
    id: id ?? this.id,
    businessName: businessName ?? this.businessName,
    industryType: industryType ?? this.industryType,
    contactName: contactName ?? this.contactName,
    contactPhone: contactPhone ?? this.contactPhone,
    email: email ?? this.email,
    instaHandle: instaHandle ?? this.instaHandle,
    location: location ?? this.location,
    tier: tier ?? this.tier,
    notes: notes ?? this.notes,
  );

  @override
  String toString() => 'Client($businessName, ${tier.value})';
}
