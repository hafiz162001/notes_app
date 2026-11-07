import 'dart:convert';

class Note {
  final String id;
  final String title;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int colorValue;
  final bool isPinned;
  final bool isArchived;
  final bool isTrashed;
  final bool isLocked;
  final String category;

  const Note({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    this.colorValue = 0xFFFFFFFF,
    this.isPinned = false,
    this.isArchived = false,
    this.isTrashed = false,
    this.isLocked = false,
    this.category = 'Umum',
  });

  Note copyWith({
    String? id,
    String? title,
    String? content,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? colorValue,
    bool? isPinned,
    bool? isArchived,
    bool? isTrashed,
    bool? isLocked,
    String? category,
  }) {
    return Note(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      colorValue: colorValue ?? this.colorValue,
      isPinned: isPinned ?? this.isPinned,
      isArchived: isArchived ?? this.isArchived,
      isTrashed: isTrashed ?? this.isTrashed,
      isLocked: isLocked ?? this.isLocked,
      category: category ?? this.category,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'colorValue': colorValue,
      'isPinned': isPinned,
      'isArchived': isArchived,
      'isTrashed': isTrashed,
      'isLocked': isLocked,
      'category': category,
    };
  }

  factory Note.fromMap(Map<String, dynamic> map) {
    return Note(
      id: map['id'] as String,
      title: map['title'] as String? ?? '',
      content: map['content'] as String? ?? '',
      createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(map['updatedAt'] as String? ?? '') ??
          DateTime.now(),
      colorValue: (map['colorValue'] as num?)?.toInt() ?? 0xFFFFFFFF,
      isPinned: map['isPinned'] as bool? ?? false,
      isArchived: map['isArchived'] as bool? ?? false,
      isTrashed: map['isTrashed'] as bool? ?? false,
      isLocked: map['isLocked'] as bool? ?? false,
      category: map['category'] as String? ?? 'Umum',
    );
  }

  String toJson() => json.encode(toMap());

  factory Note.fromJson(String source) =>
      Note.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Note && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
