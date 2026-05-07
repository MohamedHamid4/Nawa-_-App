class AppUser {
  final String uid;
  final String? email;
  final String? displayName;
  final String? photoUrl;
  final bool isAnonymous;
  final String? username;
  final String? bio;
  final DateTime? createdAt;

  const AppUser({
    required this.uid,
    this.email,
    this.displayName,
    this.photoUrl,
    this.isAnonymous = false,
    this.username,
    this.bio,
    this.createdAt,
  });

  bool get isGuest => isAnonymous;

  AppUser copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? photoUrl,
    bool? isAnonymous,
    String? username,
    String? bio,
    DateTime? createdAt,
  }) =>
      AppUser(
        uid: uid ?? this.uid,
        email: email ?? this.email,
        displayName: displayName ?? this.displayName,
        photoUrl: photoUrl ?? this.photoUrl,
        isAnonymous: isAnonymous ?? this.isAnonymous,
        username: username ?? this.username,
        bio: bio ?? this.bio,
        createdAt: createdAt ?? this.createdAt,
      );
}

class Workspace {
  final String id;
  final String name;
  final String emoji;
  final int colorValue;
  final DateTime createdAt;

  const Workspace({
    required this.id,
    required this.name,
    required this.emoji,
    required this.colorValue,
    required this.createdAt,
  });

  Workspace copyWith({String? name, String? emoji, int? colorValue}) =>
      Workspace(
        id: id,
        name: name ?? this.name,
        emoji: emoji ?? this.emoji,
        colorValue: colorValue ?? this.colorValue,
        createdAt: createdAt,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'emoji': emoji,
        'colorValue': colorValue,
        'createdAt': createdAt.millisecondsSinceEpoch,
      };

  factory Workspace.fromMap(Map<String, dynamic> m) => Workspace(
        id: m['id'] as String,
        name: (m['name'] as String?) ?? '',
        emoji: (m['emoji'] as String?) ?? '🗂️',
        colorValue: (m['colorValue'] as int?) ?? 0xFF2F6B5F,
        createdAt: DateTime.fromMillisecondsSinceEpoch(
          (m['createdAt'] as int?) ?? DateTime.now().millisecondsSinceEpoch,
        ),
      );
}
