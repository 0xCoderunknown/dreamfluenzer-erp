import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/app_enums.dart';

class Creator {
  final String id;
  final String fullName;
  final String handle;
  final String phoneNumber;
  final CreatorStatus status;

  // ─── NEW EXPANDED DATA AXIS FIELDS ───
  final CreatorType type;
  final PrimaryCategory primaryCategory;
  final String secondaryNiche;

  // Availability Dates
  final DateTime? busyFrom;
  final DateTime? busyTo;

  // ─── Milestone Tracking Clocks ───
  // TODO: [Roadmap Scaffolding] Planned for Creator Milestone & Trial Lifecycle Tracking.
  final DateTime? trialStartedAt;
  final DateTime? trainingStartedAt;

  // Metrics & Finance
  final double baseRate;
  final int followerCount;
  final String upiId;
  final String location;
  final String notes;
  final double rating;
  final int strikeLevel;

  // ─── Private Performance Engagement Anchors ───
  // TODO: [Roadmap Scaffolding] Planned for Creator Performance & Engagement Analytics Module.
  final int totalSaves;
  final int totalSends;
  final double averageCompletionRate;

  const Creator({
    required this.id,
    required this.fullName,
    required this.handle,
    required this.phoneNumber,
    required this.status,
    required this.type,
    required this.primaryCategory,
    required this.secondaryNiche,
    this.busyFrom,
    this.busyTo,
    this.trialStartedAt,
    this.trainingStartedAt,
    required this.baseRate,
    required this.followerCount,
    required this.upiId,
    required this.location,
    required this.notes,
    required this.rating,
    this.strikeLevel = 0,
    this.totalSaves = 0,
    this.totalSends = 0,
    this.averageCompletionRate = 0.0,
  });

  // ─── Data Conversion Engine ───

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'full_name': fullName,
      'handle': handle,
      'phone_number': phoneNumber,
      'status': status.value,
      'type': type.value,
      'primary_category': primaryCategory.value,
      'secondary_niche': secondaryNiche,
      'base_rate': baseRate,
      'follower_count': followerCount,
      'upi_id': upiId,
      'location': location,
      'notes': notes,
      'rating': rating,
      'strike_level': strikeLevel,
      'busy_from': busyFrom != null ? Timestamp.fromDate(busyFrom!) : null,
      'busy_to': busyTo != null ? Timestamp.fromDate(busyTo!) : null,
      'trial_started_at': trialStartedAt != null
          ? Timestamp.fromDate(trialStartedAt!)
          : null,
      'training_started_at': trainingStartedAt != null
          ? Timestamp.fromDate(trainingStartedAt!)
          : null,
      'total_saves': totalSaves,
      'total_sends': totalSends,
      'average_completion_rate': averageCompletionRate,
    };
  }

  factory Creator.fromMap(Map<String, dynamic> m, {String? id}) {
    DateTime? parseDateTime(dynamic val) {
      if (val is Timestamp) return val.toDate();
      return null;
    }

    return Creator(
      id: id ?? m['id'] ?? '',
      fullName: m['full_name'] ?? '',
      handle: m['handle'] ?? '',
      phoneNumber: m['phone_number'] ?? '',
      status: CreatorStatus.fromString(m['status'] ?? 'Trial'),
      type: CreatorType.fromString(m['type'] ?? 'Influencer'),
      primaryCategory: PrimaryCategory.fromString(
        m['primary_category'] ?? 'General UGC Content',
      ),
      secondaryNiche: m['secondary_niche'] ?? '',
      busyFrom: parseDateTime(m['busy_from']),
      busyTo: parseDateTime(m['busy_to']),
      trialStartedAt: parseDateTime(m['trial_started_at']),
      trainingStartedAt: parseDateTime(m['training_started_at']),
      baseRate: (m['base_rate'] as num?)?.toDouble() ?? 0.0,
      followerCount: (m['follower_count'] as num?)?.toInt() ?? 0,
      upiId: m['upi_id'] ?? '',
      location: m['location'] ?? '',
      notes: m['notes'] ?? '',
      rating: (m['rating'] as num?)?.toDouble() ?? 5.0,
      strikeLevel: (m['strike_level'] as num?)?.toInt() ?? 0,
      totalSaves: (m['total_saves'] as num?)?.toInt() ?? 0,
      totalSends: (m['total_sends'] as num?)?.toInt() ?? 0,
      averageCompletionRate:
          (m['average_completion_rate'] as num?)?.toDouble() ?? 0.0,
    );
  }

  factory Creator.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return Creator.fromMap(data, id: doc.id);
  }

  Creator copyWith({
    String? id,
    String? fullName,
    String? handle,
    String? phoneNumber,
    CreatorStatus? status,
    CreatorType? type,
    PrimaryCategory? primaryCategory,
    String? secondaryNiche,
    DateTime? busyFrom,
    DateTime? busyTo,
    DateTime? trialStartedAt,
    DateTime? trainingStartedAt,
    double? baseRate,
    int? followerCount,
    String? upiId,
    String? location,
    String? notes,
    double? rating,
    int? strikeLevel,
    int? totalSaves,
    int? totalSends,
    double? averageCompletionRate,
  }) {
    return Creator(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      handle: handle ?? this.handle,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      status: status ?? this.status,
      type: type ?? this.type,
      primaryCategory: primaryCategory ?? this.primaryCategory,
      secondaryNiche: secondaryNiche ?? this.secondaryNiche,
      busyFrom: busyFrom ?? this.busyFrom,
      busyTo: busyTo ?? this.busyTo,
      trialStartedAt: trialStartedAt ?? this.trialStartedAt,
      trainingStartedAt: trainingStartedAt ?? this.trainingStartedAt,
      baseRate: baseRate ?? this.baseRate,
      followerCount: followerCount ?? this.followerCount,
      upiId: upiId ?? this.upiId,
      location: location ?? this.location,
      notes: notes ?? this.notes,
      rating: rating ?? this.rating,
      strikeLevel: strikeLevel ?? this.strikeLevel,
      totalSaves: totalSaves ?? this.totalSaves,
      totalSends: totalSends ?? this.totalSends,
      averageCompletionRate:
          averageCompletionRate ?? this.averageCompletionRate,
    );
  }

  @override
  String toString() =>
      'Creator($handle, Type: ${type.value}, Category: ${primaryCategory.value})';
}
