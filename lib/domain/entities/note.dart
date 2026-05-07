import 'package:uuid/uuid.dart';

import 'note_block.dart';

const _uuid = Uuid();

enum NoteFontStyle {
  defaultStyle,
  bold,
  italic,
  cursive,
  heavy,
  mono,
}

class Note {
  final String id;
  final String userId;
  final String title;
  final List<NoteBlock> blocks;
  final List<String> tags;
  final String? aiSummary;
  final DateTime? reminderAt;
  final Duration reminderLeadTime;
  final bool pinned;
  final bool archived;
  final bool encrypted;
  final String? workspaceId;
  final int? colorValue;
  final List<String> collaboratorIds;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool deleted;
  final NoteFontStyle fontStyle;

  const Note({
    required this.id,
    required this.userId,
    required this.title,
    required this.blocks,
    this.tags = const [],
    this.aiSummary,
    this.reminderAt,
    this.reminderLeadTime = Duration.zero,
    this.pinned = false,
    this.archived = false,
    this.encrypted = false,
    this.workspaceId,
    this.colorValue,
    this.collaboratorIds = const [],
    required this.createdAt,
    required this.updatedAt,
    this.deleted = false,
    this.fontStyle = NoteFontStyle.defaultStyle,
  });

  factory Note.create({required String userId}) {
    final now = DateTime.now();
    return Note(
      id: _uuid.v4(),
      userId: userId,
      title: '',
      blocks: [NoteBlockFactory.newText()],
      createdAt: now,
      updatedAt: now,
    );
  }

  Note copyWith({
    String? title,
    List<NoteBlock>? blocks,
    List<String>? tags,
    String? aiSummary,
    DateTime? reminderAt,
    bool clearReminder = false,
    Duration? reminderLeadTime,
    bool? pinned,
    bool? archived,
    bool? encrypted,
    String? workspaceId,
    bool clearWorkspace = false,
    int? colorValue,
    bool clearColor = false,
    List<String>? collaboratorIds,
    DateTime? updatedAt,
    bool? deleted,
    NoteFontStyle? fontStyle,
  }) {
    return Note(
      id: id,
      userId: userId,
      title: title ?? this.title,
      blocks: blocks ?? this.blocks,
      tags: tags ?? this.tags,
      aiSummary: aiSummary ?? this.aiSummary,
      reminderAt: clearReminder ? null : (reminderAt ?? this.reminderAt),
      reminderLeadTime: reminderLeadTime ?? this.reminderLeadTime,
      pinned: pinned ?? this.pinned,
      archived: archived ?? this.archived,
      encrypted: encrypted ?? this.encrypted,
      workspaceId:
          clearWorkspace ? null : (workspaceId ?? this.workspaceId),
      colorValue: clearColor ? null : (colorValue ?? this.colorValue),
      collaboratorIds: collaboratorIds ?? this.collaboratorIds,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      deleted: deleted ?? this.deleted,
      fontStyle: fontStyle ?? this.fontStyle,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'userId': userId,
        'title': title,
        'blocks': blocks.map((b) => b.toMap()).toList(),
        'tags': tags,
        'aiSummary': aiSummary,
        'reminderAt': reminderAt?.millisecondsSinceEpoch,
        'reminderLeadTimeMin': reminderLeadTime.inMinutes,
        'pinned': pinned,
        'archived': archived,
        'encrypted': encrypted,
        'workspaceId': workspaceId,
        'colorValue': colorValue,
        'collaboratorIds': collaboratorIds,
        'createdAt': createdAt.millisecondsSinceEpoch,
        'updatedAt': updatedAt.millisecondsSinceEpoch,
        'deleted': deleted,
        'fontStyle': fontStyle.name,
      };

  factory Note.fromMap(Map<String, dynamic> raw) {
    final m = Map<String, dynamic>.from(raw);
    final blocks = (m['blocks'] as List? ?? [])
        .map((e) => NoteBlock.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
    return Note(
      id: m['id'] as String,
      userId: (m['userId'] as String?) ?? '',
      title: (m['title'] as String?) ?? '',
      blocks: blocks.isEmpty ? [NoteBlockFactory.newText()] : blocks,
      tags: ((m['tags'] as List?) ?? []).map((e) => '$e').toList(),
      aiSummary: m['aiSummary'] as String?,
      reminderAt: m['reminderAt'] == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(m['reminderAt'] as int),
      reminderLeadTime: Duration(
        minutes: (m['reminderLeadTimeMin'] as num?)?.toInt() ?? 0,
      ),
      pinned: (m['pinned'] as bool?) ?? false,
      archived: (m['archived'] as bool?) ?? false,
      encrypted: (m['encrypted'] as bool?) ?? false,
      workspaceId: m['workspaceId'] as String?,
      colorValue: (m['colorValue'] as num?)?.toInt(),
      collaboratorIds: ((m['collaboratorIds'] as List?) ?? [])
          .map((e) => '$e')
          .toList(),
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        (m['createdAt'] as int?) ?? DateTime.now().millisecondsSinceEpoch,
      ),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        (m['updatedAt'] as int?) ?? DateTime.now().millisecondsSinceEpoch,
      ),
      deleted: (m['deleted'] as bool?) ?? false,
      fontStyle: NoteFontStyle.values.firstWhere(
        (s) => s.name == m['fontStyle'],
        orElse: () => NoteFontStyle.defaultStyle,
      ),
    );
  }

  String get plainTextSearchable {
    final buffer = StringBuffer()..write(title);
    if (aiSummary != null) buffer.write(' $aiSummary');
    for (final t in tags) {
      buffer.write(' $t');
    }
    for (final block in blocks) {
      switch (block) {
        case TextBlock b:
          buffer.write(' ${b.text}');
        case ChecklistBlock b:
          for (final item in b.items) {
            buffer.write(' ${item.text}');
          }
        case ImageBlock b:
          buffer.write(' ${b.caption}');
        case VideoBlock b:
          buffer.write(' ${b.caption}');
        case AudioBlock b:
          buffer.write(' ${b.transcript}');
        case FileBlock b:
          buffer.write(' ${b.fileName}');
        case LinkBlock b:
          buffer.write(' ${b.url} ${b.title ?? ''} ${b.description ?? ''}');
      }
    }
    return buffer.toString().toLowerCase();
  }

  String previewText() {
    for (final block in blocks) {
      if (block is TextBlock && block.text.trim().isNotEmpty) {
        return block.text.trim();
      }
      if (block is ChecklistBlock && block.items.isNotEmpty) {
        return block.items.map((i) => '• ${i.text}').join('\n');
      }
      if (block is LinkBlock) return block.title ?? block.url;
      if (block is ImageBlock) return block.caption;
      if (block is AudioBlock) return block.transcript;
    }
    return '';
  }
}
