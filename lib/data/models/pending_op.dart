enum PendingOpKind { upsert, delete }

class PendingOp {
  final String id;
  final String userId;
  final String noteId;
  final PendingOpKind kind;
  final Map<String, dynamic>? snapshot;
  final int attempts;
  final int createdAt;

  PendingOp({
    required this.id,
    required this.userId,
    required this.noteId,
    required this.kind,
    this.snapshot,
    this.attempts = 0,
    required this.createdAt,
  });

  PendingOp incrementAttempts() => PendingOp(
        id: id,
        userId: userId,
        noteId: noteId,
        kind: kind,
        snapshot: snapshot,
        attempts: attempts + 1,
        createdAt: createdAt,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'userId': userId,
        'noteId': noteId,
        'kind': kind.name,
        'snapshot': snapshot,
        'attempts': attempts,
        'createdAt': createdAt,
      };

  factory PendingOp.fromMap(Map<String, dynamic> raw) {
    final m = Map<String, dynamic>.from(raw);
    return PendingOp(
      id: m['id'] as String,
      userId: (m['userId'] as String?) ?? '',
      noteId: (m['noteId'] as String?) ?? '',
      kind: PendingOpKind.values.firstWhere(
        (k) => k.name == (m['kind'] as String? ?? 'upsert'),
        orElse: () => PendingOpKind.upsert,
      ),
      snapshot: m['snapshot'] == null
          ? null
          : Map<String, dynamic>.from(m['snapshot'] as Map),
      attempts: (m['attempts'] as int?) ?? 0,
      createdAt: (m['createdAt'] as int?) ?? DateTime.now().millisecondsSinceEpoch,
    );
  }
}
