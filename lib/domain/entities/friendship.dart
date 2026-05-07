enum FriendshipStatus { pending, accepted, blocked }

class Friendship {
  final String id;
  final String requesterId;
  final String addresseeId;
  final FriendshipStatus status;
  final DateTime createdAt;
  final String? otherDisplayName;
  final String? otherUsername;
  final String? otherPhotoUrl;

  const Friendship({
    required this.id,
    required this.requesterId,
    required this.addresseeId,
    required this.status,
    required this.createdAt,
    this.otherDisplayName,
    this.otherUsername,
    this.otherPhotoUrl,
  });

  String otherUserIdOf(String selfUid) =>
      selfUid == requesterId ? addresseeId : requesterId;

  bool get isAccepted => status == FriendshipStatus.accepted;
  bool get isPending => status == FriendshipStatus.pending;

  Map<String, dynamic> toMap() => {
        'id': id,
        'requesterId': requesterId,
        'addresseeId': addresseeId,
        'status': status.name,
        'createdAt': createdAt.millisecondsSinceEpoch,
        if (otherDisplayName != null) 'otherDisplayName': otherDisplayName,
        if (otherUsername != null) 'otherUsername': otherUsername,
        if (otherPhotoUrl != null) 'otherPhotoUrl': otherPhotoUrl,
      };

  factory Friendship.fromMap(Map<String, dynamic> m) => Friendship(
        id: m['id'] as String,
        requesterId: m['requesterId'] as String,
        addresseeId: m['addresseeId'] as String,
        status: FriendshipStatus.values.firstWhere(
          (s) => s.name == (m['status'] as String?),
          orElse: () => FriendshipStatus.pending,
        ),
        createdAt: m['createdAt'] is int
            ? DateTime.fromMillisecondsSinceEpoch(m['createdAt'] as int)
            : DateTime.now(),
        otherDisplayName: m['otherDisplayName'] as String?,
        otherUsername: m['otherUsername'] as String?,
        otherPhotoUrl: m['otherPhotoUrl'] as String?,
      );
}
