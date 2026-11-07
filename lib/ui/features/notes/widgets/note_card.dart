import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:notes_app/data/models/note_model.dart';
import 'package:notes_app/ui/core/theme.dart';

class NoteCard extends StatelessWidget {
  final Note note;
  final bool isGrid;
  final VoidCallback onTap;
  final VoidCallback? onPinToggle;
  final VoidCallback? onArchiveToggle;
  final VoidCallback? onLockToggle;
  final VoidCallback? onDelete;
  final VoidCallback? onRestore;
  final VoidCallback? onPermanentDelete;

  const NoteCard({
    super.key,
    required this.note,
    this.isGrid = false,
    required this.onTap,
    this.onPinToggle,
    this.onArchiveToggle,
    this.onLockToggle,
    this.onDelete,
    this.onRestore,
    this.onPermanentDelete,
  });

  Color _resolveCardColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final option = AppTheme.noteColors.firstWhere(
      (opt) => opt.color.toARGB32() == note.colorValue,
      orElse: () => AppTheme.noteColors.first,
    );
    return option.resolve(isDark);
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final noteDate = DateTime(dt.year, dt.month, dt.day);

    if (noteDate == today) {
      return 'Hari ini, ${DateFormat('HH:mm').format(dt)}';
    } else if (noteDate == today.subtract(const Duration(days: 1))) {
      return 'Kemarin, ${DateFormat('HH:mm').format(dt)}';
    } else {
      return DateFormat('d MMM yyyy, HH:mm').format(dt);
    }
  }

  // Calculate to-do checklist statistics if present
  String? _getChecklistSummary(String content) {
    final lines = content.split('\n');
    int total = 0;
    int completed = 0;
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.startsWith('- [ ]') || trimmed.startsWith('[ ]')) {
        total++;
      } else if (trimmed.startsWith('- [x]') ||
          trimmed.startsWith('- [X]') ||
          trimmed.startsWith('[x]') ||
          trimmed.startsWith('[X]')) {
        total++;
        completed++;
      }
    }
    if (total > 0) {
      return '$completed dari $total tugas selesai';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardBgColor = _resolveCardColor(context);

    final titleColor = isDark
        ? (note.colorValue == 0xFFFFFFFF
            ? Colors.white
            : Colors.white.withAlpha(240))
        : const Color(0xFF1F1F24);
    final contentColor = isDark
        ? (note.colorValue == 0xFFFFFFFF
            ? Colors.white70
            : Colors.white.withAlpha(200))
        : const Color(0xFF4A4A55);

    final checklistSummary = _getChecklistSummary(note.content);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cardBgColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark
                  ? Colors.white.withAlpha(20)
                  : Colors.black.withAlpha(15),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(isDark ? 30 : 10),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header Row: Category badge & Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withAlpha(25)
                          : theme.colorScheme.primary.withAlpha(25),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      note.category,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? Colors.white.withAlpha(220)
                            : theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Lock indicator
                      if (note.isLocked) ...[
                        Icon(
                          Icons.lock_rounded,
                          size: 16,
                          color: isDark ? Colors.amberAccent : Colors.amber.shade800,
                        ),
                        const SizedBox(width: 6),
                      ],

                      // Pin Button (only if not trashed)
                      if (!note.isTrashed && onPinToggle != null) ...[
                        IconButton(
                          icon: Icon(
                            note.isPinned
                                ? Icons.push_pin_rounded
                                : Icons.push_pin_outlined,
                            size: 19,
                            color: note.isPinned
                                ? (isDark
                                    ? Colors.amberAccent
                                    : Colors.amber.shade800)
                                : (isDark ? Colors.white54 : Colors.black38),
                          ),
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          tooltip:
                              note.isPinned ? 'Lepas Sematan' : 'Sematkan Catatan',
                          onPressed: onPinToggle,
                        ),
                        const SizedBox(width: 6),
                      ],

                      // Popup Menu
                      PopupMenuButton<String>(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: Icon(
                          Icons.more_vert_rounded,
                          size: 19,
                          color: isDark ? Colors.white54 : Colors.black45,
                        ),
                        onSelected: (value) {
                          switch (value) {
                            case 'pin':
                              onPinToggle?.call();
                              break;
                            case 'archive':
                              onArchiveToggle?.call();
                              break;
                            case 'lock':
                              onLockToggle?.call();
                              break;
                            case 'trash':
                              onDelete?.call();
                              break;
                            case 'restore':
                              onRestore?.call();
                              break;
                            case 'delete_permanent':
                              onPermanentDelete?.call();
                              break;
                          }
                        },
                        itemBuilder: (context) {
                          if (note.isTrashed) {
                            return [
                              const PopupMenuItem(
                                value: 'restore',
                                child: Row(
                                  children: [
                                    Icon(Icons.restore_from_trash_rounded,
                                        size: 18),
                                    SizedBox(width: 8),
                                    Text('Pulihkan Catatan'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'delete_permanent',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete_forever_rounded,
                                        color: Colors.red, size: 18),
                                    SizedBox(width: 8),
                                    Text('Hapus Permanen',
                                        style: TextStyle(color: Colors.red)),
                                  ],
                                ),
                              ),
                            ];
                          }

                          return [
                            PopupMenuItem(
                              value: 'pin',
                              child: Row(
                                children: [
                                  Icon(
                                    note.isPinned
                                        ? Icons.push_pin_outlined
                                        : Icons.push_pin_rounded,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(note.isPinned
                                      ? 'Lepas Sematan'
                                      : 'Sematkan'),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'archive',
                              child: Row(
                                children: [
                                  Icon(
                                    note.isArchived
                                        ? Icons.unarchive_outlined
                                        : Icons.archive_outlined,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(note.isArchived
                                      ? 'Keluarkan dari Arsip'
                                      : 'Arsipkan'),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'lock',
                              child: Row(
                                children: [
                                  Icon(
                                    note.isLocked
                                        ? Icons.lock_open_rounded
                                        : Icons.lock_outline_rounded,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(note.isLocked
                                      ? 'Buka Kunci'
                                      : 'Kunci Catatan'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'trash',
                              child: Row(
                                children: [
                                  Icon(Icons.delete_outline_rounded,
                                      color: Colors.red, size: 18),
                                  SizedBox(width: 8),
                                  Text('Pindahkan ke Sampah',
                                      style: TextStyle(color: Colors.red)),
                                ],
                              ),
                            ),
                          ];
                        },
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Title
              if (note.title.isNotEmpty) ...[
                Text(
                  note.title,
                  maxLines: isGrid ? 1 : 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: titleColor,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 6),
              ],

              // Content / Locked preview
              if (note.isLocked) ...[
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.black.withAlpha(60)
                        : Colors.black.withAlpha(15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.lock_clock_rounded,
                          size: 16,
                          color: isDark ? Colors.white70 : Colors.black54),
                      const SizedBox(width: 6),
                      Text(
                        'Catatan Terkunci (PIN)',
                        style: TextStyle(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          color: isDark ? Colors.white70 : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
              ] else if (note.content.isNotEmpty) ...[
                Text(
                  note.content,
                  maxLines: isGrid ? 2 : 5,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13.5,
                    color: contentColor,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 8),
              ],

              // Checklist summary badge if applicable
              if (!note.isLocked && checklistSummary != null) ...[
                Row(
                  children: [
                    Icon(
                      Icons.check_circle_outline_rounded,
                      size: 14,
                      color: isDark ? Colors.tealAccent : Colors.teal.shade700,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      checklistSummary,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color:
                            isDark ? Colors.tealAccent : Colors.teal.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],

              // Timestamp footer
              Text(
                _formatDate(note.updatedAt),
                style: TextStyle(
                  fontSize: 11,
                  color: isDark
                      ? Colors.white.withAlpha(140)
                      : Colors.black.withAlpha(120),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
