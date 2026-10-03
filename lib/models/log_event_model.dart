import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/app_enums.dart';

class LogEvent {
  final String id;
  final LogType type; // ─── NOW AN ENUM
  final String action;
  final String note;
  final DateTime timestamp;
  final String actor;
  final double? amount;
  final String? reason;

  const LogEvent({
    required this.id,
    required this.type,
    required this.action,
    required this.note,
    required this.timestamp,
    required this.actor,
    this.amount,
    this.reason,
  });

  // ─── THE BRAIN: Data Conversion ───

  Map<String, dynamic> toMap() => {
    'type': type.value,
    'action': action,
    'note': note,
    'timestamp': Timestamp.fromDate(timestamp),
    'actor': actor,
    'amount': amount,
    'reason': reason,
  };

  factory LogEvent.fromMap(Map<String, dynamic> m, {String? id}) => LogEvent(
    id: id ?? m['id'] as String? ?? '',
    type: LogType.fromString(m['type'] as String? ?? 'System'),
    action: m['action'] as String? ?? 'Unknown',
    note: m['note'] as String? ?? '',
    timestamp: (m['timestamp'] is Timestamp)
        ? (m['timestamp'] as Timestamp).toDate()
        : DateTime.now(),
    actor: m['actor'] as String? ?? 'System',
    amount: (m['amount'] as num?)?.toDouble(),
    reason: m['reason'] as String?,
  );

  factory LogEvent.fromFirestore(DocumentSnapshot doc) {
    return LogEvent.fromMap(doc.data() as Map<String, dynamic>, id: doc.id);
  }

  // ─── IMMUTABILITY: The update engine ───

  LogEvent copyWith({
    LogType? type,
    String? action,
    String? note,
    DateTime? timestamp,
    String? actor,
    double? amount,
    String? reason,
  }) => LogEvent(
    id: id,
    type: type ?? this.type,
    action: action ?? this.action,
    note: note ?? this.note,
    timestamp: timestamp ?? this.timestamp,
    actor: actor ?? this.actor,
    amount: amount ?? this.amount,
    reason: reason ?? this.reason,
  );

  @override
  String toString() => 'LogEvent(${type.value} - $action by $actor)';
}
