import 'package:uuid/uuid.dart';

const _uuid = Uuid();

enum TextStyleHint { heading, subheading, body, quote, code }

sealed class NoteBlock {
  final String id;
  final DateTime updatedAt;
  const NoteBlock({required this.id, required this.updatedAt});

  String get type;

  Map<String, dynamic> toMap();

  static NoteBlock fromMap(Map<String, dynamic> raw) {
    final m = Map<String, dynamic>.from(raw);
    final id = (m['id'] as String?) ?? _uuid.v4();
    final updatedAt = DateTime.fromMillisecondsSinceEpoch(
      (m['updatedAt'] as int?) ?? DateTime.now().millisecondsSinceEpoch,
    );
    switch (m['type']) {
      case 'text':
        return TextBlock(
          id: id,
          updatedAt: updatedAt,
          text: (m['text'] as String?) ?? '',
          style: TextStyleHint.values.firstWhere(
            (s) => s.name == (m['style'] as String? ?? 'body'),
            orElse: () => TextStyleHint.body,
          ),
        );
      case 'checklist':
        final items = (m['items'] as List? ?? [])
            .map((e) => ChecklistItem.fromMap(Map<String, dynamic>.from(e as Map)))
            .toList();
        return ChecklistBlock(id: id, updatedAt: updatedAt, items: items);
      case 'image':
        return ImageBlock(
          id: id,
          updatedAt: updatedAt,
          localPath: m['localPath'] as String?,
          remoteUrl: m['remoteUrl'] as String?,
          caption: (m['caption'] as String?) ?? '',
        );
      case 'video':
        return VideoBlock(
          id: id,
          updatedAt: updatedAt,
          localPath: m['localPath'] as String?,
          remoteUrl: m['remoteUrl'] as String?,
          caption: (m['caption'] as String?) ?? '',
          thumbnailUrl: m['thumbnailUrl'] as String?,
        );
      case 'audio':
        return AudioBlock(
          id: id,
          updatedAt: updatedAt,
          localPath: m['localPath'] as String?,
          remoteUrl: m['remoteUrl'] as String?,
          durationMs: (m['durationMs'] as int?) ?? 0,
          transcript: (m['transcript'] as String?) ?? '',
        );
      case 'file':
        return FileBlock(
          id: id,
          updatedAt: updatedAt,
          localPath: m['localPath'] as String?,
          remoteUrl: m['remoteUrl'] as String?,
          fileName: (m['fileName'] as String?) ?? 'file',
          mimeType: m['mimeType'] as String?,
          size: (m['size'] as int?) ?? 0,
        );
      case 'link':
        return LinkBlock(
          id: id,
          updatedAt: updatedAt,
          url: (m['url'] as String?) ?? '',
          title: m['title'] as String?,
          description: m['description'] as String?,
          imageUrl: m['imageUrl'] as String?,
        );
      default:
        return TextBlock(id: id, updatedAt: updatedAt, text: '');
    }
  }
}

class TextBlock extends NoteBlock {
  final String text;
  final TextStyleHint style;
  const TextBlock({
    required super.id,
    required super.updatedAt,
    required this.text,
    this.style = TextStyleHint.body,
  });

  @override
  String get type => 'text';

  TextBlock copyWith({String? text, TextStyleHint? style, DateTime? updatedAt}) =>
      TextBlock(
        id: id,
        updatedAt: updatedAt ?? DateTime.now(),
        text: text ?? this.text,
        style: style ?? this.style,
      );

  @override
  Map<String, dynamic> toMap() => {
        'id': id,
        'type': type,
        'updatedAt': updatedAt.millisecondsSinceEpoch,
        'text': text,
        'style': style.name,
      };
}

class ChecklistItem {
  final String id;
  final String text;
  final bool done;
  ChecklistItem({required this.id, required this.text, required this.done});

  ChecklistItem copyWith({String? text, bool? done}) => ChecklistItem(
        id: id,
        text: text ?? this.text,
        done: done ?? this.done,
      );

  Map<String, dynamic> toMap() => {'id': id, 'text': text, 'done': done};

  factory ChecklistItem.fromMap(Map<String, dynamic> m) => ChecklistItem(
        id: (m['id'] as String?) ?? _uuid.v4(),
        text: (m['text'] as String?) ?? '',
        done: (m['done'] as bool?) ?? false,
      );

  factory ChecklistItem.create(String text) =>
      ChecklistItem(id: _uuid.v4(), text: text, done: false);
}

class ChecklistBlock extends NoteBlock {
  final List<ChecklistItem> items;
  const ChecklistBlock({
    required super.id,
    required super.updatedAt,
    required this.items,
  });

  @override
  String get type => 'checklist';

  ChecklistBlock copyWith({List<ChecklistItem>? items, DateTime? updatedAt}) =>
      ChecklistBlock(
        id: id,
        updatedAt: updatedAt ?? DateTime.now(),
        items: items ?? this.items,
      );

  @override
  Map<String, dynamic> toMap() => {
        'id': id,
        'type': type,
        'updatedAt': updatedAt.millisecondsSinceEpoch,
        'items': items.map((e) => e.toMap()).toList(),
      };
}

class ImageBlock extends NoteBlock {
  final String? localPath;
  final String? remoteUrl;
  final String caption;
  const ImageBlock({
    required super.id,
    required super.updatedAt,
    this.localPath,
    this.remoteUrl,
    this.caption = '',
  });

  @override
  String get type => 'image';

  ImageBlock copyWith({
    String? localPath,
    String? remoteUrl,
    String? caption,
    DateTime? updatedAt,
  }) =>
      ImageBlock(
        id: id,
        updatedAt: updatedAt ?? DateTime.now(),
        localPath: localPath ?? this.localPath,
        remoteUrl: remoteUrl ?? this.remoteUrl,
        caption: caption ?? this.caption,
      );

  @override
  Map<String, dynamic> toMap() => {
        'id': id,
        'type': type,
        'updatedAt': updatedAt.millisecondsSinceEpoch,
        'localPath': localPath,
        'remoteUrl': remoteUrl,
        'caption': caption,
      };
}

class VideoBlock extends NoteBlock {
  final String? localPath;
  final String? remoteUrl;
  final String caption;
  final String? thumbnailUrl;
  const VideoBlock({
    required super.id,
    required super.updatedAt,
    this.localPath,
    this.remoteUrl,
    this.caption = '',
    this.thumbnailUrl,
  });

  @override
  String get type => 'video';

  VideoBlock copyWith({
    String? localPath,
    String? remoteUrl,
    String? caption,
    String? thumbnailUrl,
    DateTime? updatedAt,
  }) =>
      VideoBlock(
        id: id,
        updatedAt: updatedAt ?? DateTime.now(),
        localPath: localPath ?? this.localPath,
        remoteUrl: remoteUrl ?? this.remoteUrl,
        caption: caption ?? this.caption,
        thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      );

  @override
  Map<String, dynamic> toMap() => {
        'id': id,
        'type': type,
        'updatedAt': updatedAt.millisecondsSinceEpoch,
        'localPath': localPath,
        'remoteUrl': remoteUrl,
        'caption': caption,
        'thumbnailUrl': thumbnailUrl,
      };
}

class AudioBlock extends NoteBlock {
  final String? localPath;
  final String? remoteUrl;
  final int durationMs;
  final String transcript;
  const AudioBlock({
    required super.id,
    required super.updatedAt,
    this.localPath,
    this.remoteUrl,
    this.durationMs = 0,
    this.transcript = '',
  });

  @override
  String get type => 'audio';

  AudioBlock copyWith({
    String? localPath,
    String? remoteUrl,
    int? durationMs,
    String? transcript,
    DateTime? updatedAt,
  }) =>
      AudioBlock(
        id: id,
        updatedAt: updatedAt ?? DateTime.now(),
        localPath: localPath ?? this.localPath,
        remoteUrl: remoteUrl ?? this.remoteUrl,
        durationMs: durationMs ?? this.durationMs,
        transcript: transcript ?? this.transcript,
      );

  @override
  Map<String, dynamic> toMap() => {
        'id': id,
        'type': type,
        'updatedAt': updatedAt.millisecondsSinceEpoch,
        'localPath': localPath,
        'remoteUrl': remoteUrl,
        'durationMs': durationMs,
        'transcript': transcript,
      };
}

class FileBlock extends NoteBlock {
  final String? localPath;
  final String? remoteUrl;
  final String fileName;
  final String? mimeType;
  final int size;
  const FileBlock({
    required super.id,
    required super.updatedAt,
    this.localPath,
    this.remoteUrl,
    required this.fileName,
    this.mimeType,
    this.size = 0,
  });

  @override
  String get type => 'file';

  FileBlock copyWith({
    String? localPath,
    String? remoteUrl,
    String? fileName,
    String? mimeType,
    int? size,
    DateTime? updatedAt,
  }) =>
      FileBlock(
        id: id,
        updatedAt: updatedAt ?? DateTime.now(),
        localPath: localPath ?? this.localPath,
        remoteUrl: remoteUrl ?? this.remoteUrl,
        fileName: fileName ?? this.fileName,
        mimeType: mimeType ?? this.mimeType,
        size: size ?? this.size,
      );

  @override
  Map<String, dynamic> toMap() => {
        'id': id,
        'type': type,
        'updatedAt': updatedAt.millisecondsSinceEpoch,
        'localPath': localPath,
        'remoteUrl': remoteUrl,
        'fileName': fileName,
        'mimeType': mimeType,
        'size': size,
      };
}

class LinkBlock extends NoteBlock {
  final String url;
  final String? title;
  final String? description;
  final String? imageUrl;
  const LinkBlock({
    required super.id,
    required super.updatedAt,
    required this.url,
    this.title,
    this.description,
    this.imageUrl,
  });

  @override
  String get type => 'link';

  LinkBlock copyWith({
    String? url,
    String? title,
    String? description,
    String? imageUrl,
    DateTime? updatedAt,
  }) =>
      LinkBlock(
        id: id,
        updatedAt: updatedAt ?? DateTime.now(),
        url: url ?? this.url,
        title: title ?? this.title,
        description: description ?? this.description,
        imageUrl: imageUrl ?? this.imageUrl,
      );

  @override
  Map<String, dynamic> toMap() => {
        'id': id,
        'type': type,
        'updatedAt': updatedAt.millisecondsSinceEpoch,
        'url': url,
        'title': title,
        'description': description,
        'imageUrl': imageUrl,
      };
}

class NoteBlockFactory {
  static TextBlock newText({String text = '', TextStyleHint style = TextStyleHint.body}) =>
      TextBlock(
        id: _uuid.v4(),
        updatedAt: DateTime.now(),
        text: text,
        style: style,
      );

  static ChecklistBlock newChecklist({List<ChecklistItem>? items}) =>
      ChecklistBlock(
        id: _uuid.v4(),
        updatedAt: DateTime.now(),
        items: items ?? [ChecklistItem.create('')],
      );

  static ImageBlock newImage({String? localPath, String? remoteUrl}) => ImageBlock(
        id: _uuid.v4(),
        updatedAt: DateTime.now(),
        localPath: localPath,
        remoteUrl: remoteUrl,
      );

  static VideoBlock newVideo({String? localPath, String? remoteUrl}) => VideoBlock(
        id: _uuid.v4(),
        updatedAt: DateTime.now(),
        localPath: localPath,
        remoteUrl: remoteUrl,
      );

  static AudioBlock newAudio({String? localPath, int durationMs = 0}) => AudioBlock(
        id: _uuid.v4(),
        updatedAt: DateTime.now(),
        localPath: localPath,
        durationMs: durationMs,
      );

  static FileBlock newFile({
    required String fileName,
    String? localPath,
    String? mimeType,
    int size = 0,
  }) =>
      FileBlock(
        id: _uuid.v4(),
        updatedAt: DateTime.now(),
        fileName: fileName,
        localPath: localPath,
        mimeType: mimeType,
        size: size,
      );

  static LinkBlock newLink(String url) => LinkBlock(
        id: _uuid.v4(),
        updatedAt: DateTime.now(),
        url: url,
      );
}
