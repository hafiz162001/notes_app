import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:notes_app/data/models/note_model.dart';
import 'package:notes_app/ui/core/theme.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';

class NoteEditScreen extends StatefulWidget {
  final Note? note;
  final List<String> availableCategories;

  const NoteEditScreen({
    super.key,
    this.note,
    this.availableCategories = const [],
  });

  @override
  State<NoteEditScreen> createState() => _NoteEditScreenState();
}

class _NoteEditScreenState extends State<NoteEditScreen> {
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  late int _selectedColorValue;
  late bool _isPinned;
  late bool _isArchived;
  late bool _isLocked;
  late String _selectedCategory;
  late List<String> _categories;
  bool _hasChanged = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note?.title ?? '');
    _contentController = TextEditingController(
      text: widget.note?.content ?? '',
    );
    _selectedColorValue = widget.note?.colorValue ?? 0xFFFFFFFF;
    _isPinned = widget.note?.isPinned ?? false;
    _isArchived = widget.note?.isArchived ?? false;
    _isLocked = widget.note?.isLocked ?? false;
    _selectedCategory = widget.note?.category ?? 'Umum';
    _categories = List<String>.from(
      widget.availableCategories.isNotEmpty
          ? widget.availableCategories
          : ['Umum', 'Pekerjaan', 'Pribadi', 'Ide', 'Tugas', 'Belanja'],
    );
    if (!_categories.contains(_selectedCategory)) {
      _categories.add(_selectedCategory);
    }

    _titleController.addListener(_onTextChanged);
    _contentController.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    if (!_hasChanged) {
      setState(() {
        _hasChanged = true;
      });
    } else {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _saveAndClose() {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    // If both empty and creating a new note, just exit without saving
    if (title.isEmpty && content.isEmpty && widget.note == null) {
      Navigator.pop(context);
      return;
    }

    final now = DateTime.now();
    final noteToSave = Note(
      id: widget.note?.id ?? const Uuid().v4(),
      title: title,
      content: content,
      createdAt: widget.note?.createdAt ?? now,
      updatedAt: now,
      colorValue: _selectedColorValue,
      isPinned: _isPinned,
      isArchived: _isArchived,
      isTrashed: widget.note?.isTrashed ?? false,
      isLocked: _isLocked,
      category: _selectedCategory,
    );

    Navigator.pop(context, noteToSave);
  }

  void _shareNote() {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();
    final text = [
      if (title.isNotEmpty) title,
      if (content.isNotEmpty) content,
    ].join('\n\n');

    if (text.isNotEmpty) {
      SharePlus.instance.share(
        ShareParams(
          text: text,
          subject: title.isNotEmpty ? title : 'Catatan dari CatatanKu',
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Catatan masih kosong, tidak ada yang dapat dibagikan.',
          ),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _copyToClipboard() {
    final text = '${_titleController.text}\n\n${_contentController.text}'
        .trim();
    if (text.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: text));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Catatan berhasil disalin ke papan klip!'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  // Quick formatting insertion helper
  void _insertFormatting(String prefix, [String suffix = '']) {
    final text = _contentController.text;
    final selection = _contentController.selection;
    final start = selection.start >= 0 ? selection.start : text.length;
    final end = selection.end >= 0 ? selection.end : text.length;

    final selectedText = text.substring(start, end);
    final replacement = '$prefix$selectedText$suffix';

    final newText = text.replaceRange(start, end, replacement);
    _contentController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(
        offset: start + prefix.length + selectedText.length + suffix.length,
      ),
    );
  }

  void _showCategoryPicker() {
    final newCatController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 20,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Pilih Kategori',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 8,
                      runSpacing: 10,
                      children: _categories.map((cat) {
                        final isSelected = _selectedCategory == cat;
                        return ChoiceChip(
                          label: Text(cat),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _selectedCategory = cat;
                                _hasChanged = true;
                              });
                              Navigator.pop(context);
                            }
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 18),
                    // Quick add category inline
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: newCatController,
                            decoration: const InputDecoration(
                              hintText: 'Tambah kategori baru...',
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        FilledButton(
                          onPressed: () {
                            final val = newCatController.text.trim();
                            if (val.isNotEmpty && !_categories.contains(val)) {
                              setSheetState(() {
                                _categories.add(val);
                              });
                              setState(() {
                                _selectedCategory = val;
                                _hasChanged = true;
                              });
                              Navigator.pop(context);
                            }
                          },
                          child: const Text('Tambah'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Color _resolveScreenBackground(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final option = AppTheme.noteColors.firstWhere(
      (opt) => opt.color.toARGB32() == _selectedColorValue,
      orElse: () => AppTheme.noteColors.first,
    );
    if (_selectedColorValue == 0xFFFFFFFF) {
      return Theme.of(context).scaffoldBackgroundColor;
    }
    return option.resolve(isDark);
  }

  Widget _buildFormattingButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Icon(
            icon,
            size: 20,
            color: isDark ? Colors.white70 : const Color(0xFF3B3B48),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = _resolveScreenBackground(context);

    final characterCount = _contentController.text.length;
    final wordCount = _contentController.text.trim().isEmpty
        ? 0
        : _contentController.text.trim().split(RegExp(r'\s+')).length;

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) return;
      },
      child: Scaffold(
        backgroundColor: bg,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            tooltip: 'Kembali & Simpan',
            onPressed: _saveAndClose,
          ),
          actions: [
            // Lock toggle
            IconButton(
              icon: Icon(
                _isLocked ? Icons.lock_rounded : Icons.lock_outline_rounded,
                color: _isLocked
                    ? (isDark ? Colors.amberAccent : Colors.amber.shade800)
                    : null,
              ),
              tooltip: _isLocked ? 'Buka Kunci' : 'Kunci Catatan (PIN)',
              onPressed: () {
                setState(() {
                  _isLocked = !_isLocked;
                  _hasChanged = true;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      _isLocked
                          ? 'Catatan dikunci dengan PIN keamanan'
                          : 'Kunci catatan dinonaktifkan',
                    ),
                    duration: const Duration(seconds: 1),
                  ),
                );
              },
            ),
            // Pin toggle
            IconButton(
              icon: Icon(
                _isPinned ? Icons.push_pin_rounded : Icons.push_pin_outlined,
                color: _isPinned
                    ? (isDark ? Colors.amberAccent : Colors.amber.shade800)
                    : null,
              ),
              tooltip: _isPinned ? 'Lepas Sematan' : 'Sematkan Catatan',
              onPressed: () {
                setState(() {
                  _isPinned = !_isPinned;
                  _hasChanged = true;
                });
              },
            ),
            // Share
            IconButton(
              icon: const Icon(Icons.share_rounded),
              tooltip: 'Bagikan Catatan',
              onPressed: _shareNote,
            ),
            // Popup more options
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded),
              onSelected: (val) {
                if (val == 'copy') {
                  _copyToClipboard();
                } else if (val == 'archive') {
                  setState(() {
                    _isArchived = !_isArchived;
                    _hasChanged = true;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        _isArchived
                            ? 'Catatan akan diarsipkan saat disimpan'
                            : 'Catatan dikembalikan dari arsip',
                      ),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'copy',
                  child: Row(
                    children: [
                      Icon(Icons.copy_rounded, size: 18),
                      SizedBox(width: 8),
                      Text('Salin Teks'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'archive',
                  child: Row(
                    children: [
                      Icon(
                        _isArchived
                            ? Icons.unarchive_outlined
                            : Icons.archive_outlined,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(_isArchived ? 'Batal Arsipkan' : 'Arsipkan Catatan'),
                    ],
                  ),
                ),
              ],
            ),
            // Save Button
            FilledButton.tonal(
              onPressed: _saveAndClose,
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_rounded, size: 18),
                  SizedBox(width: 4),
                  Text('Simpan'),
                ],
              ),
            ),
            const SizedBox(width: 12),
          ],
        ),
        body: Column(
          children: [
            // Top Bar: Category badge and date
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Row(
                children: [
                  InkWell(
                    onTap: _showCategoryPicker,
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withAlpha(25),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: theme.colorScheme.primary.withAlpha(60),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.folder_outlined,
                            size: 15,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _selectedCategory,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.arrow_drop_down,
                            size: 16,
                            color: theme.colorScheme.primary,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    widget.note != null
                        ? 'Diedit ${DateFormat('d MMM, HH:mm').format(widget.note!.updatedAt)}'
                        : 'Catatan Baru',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white60 : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 16, thickness: 0.5),

            // Note Inputs
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title Field
                    TextField(
                      controller: _titleController,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF1E1E24),
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Judul Catatan...',
                        hintStyle: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                        border: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                        fillColor: Colors.transparent,
                        filled: false,
                      ),
                      textInputAction: TextInputAction.next,
                      maxLines: null,
                    ),
                    const SizedBox(height: 12),

                    // Content Field
                    TextField(
                      controller: _contentController,
                      style: TextStyle(
                        fontSize: 16,
                        height: 1.5,
                        color: isDark
                            ? Colors.white.withAlpha(230)
                            : const Color(0xFF2C2C35),
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Tuliskan catatan Anda di sini...',
                        hintStyle: TextStyle(fontSize: 16, color: Colors.grey),
                        border: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                        fillColor: Colors.transparent,
                        filled: false,
                      ),
                      maxLines: null,
                      keyboardType: TextInputType.multiline,
                    ),
                  ],
                ),
              ),
            ),

            // Quick Formatting Bar
            Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1E1E24)
                    : const Color(0xFFEDEBF2),
                border: Border(
                  top: BorderSide(
                    color: isDark ? Colors.white12 : Colors.black12,
                    width: 0.5,
                  ),
                ),
              ),
              child: ListView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                children: [
                  _buildFormattingButton(
                    icon: Icons.check_box_outlined,
                    tooltip: 'Daftar Tugas / Checklist',
                    onTap: () => _insertFormatting('- [ ] '),
                  ),
                  _buildFormattingButton(
                    icon: Icons.format_list_bulleted_rounded,
                    tooltip: 'Bullet List',
                    onTap: () => _insertFormatting('• '),
                  ),
                  _buildFormattingButton(
                    icon: Icons.format_list_numbered_rounded,
                    tooltip: 'Numbered List',
                    onTap: () => _insertFormatting('1. '),
                  ),
                  _buildFormattingButton(
                    icon: Icons.format_bold_rounded,
                    tooltip: 'Tebal (Bold)',
                    onTap: () => _insertFormatting('**', '**'),
                  ),
                  _buildFormattingButton(
                    icon: Icons.format_italic_rounded,
                    tooltip: 'Miring (Italic)',
                    onTap: () => _insertFormatting('*', '*'),
                  ),
                  _buildFormattingButton(
                    icon: Icons.title_rounded,
                    tooltip: 'Heading / Judul Bagian',
                    onTap: () => _insertFormatting('# '),
                  ),
                  _buildFormattingButton(
                    icon: Icons.horizontal_rule_rounded,
                    tooltip: 'Garis Pemisah',
                    onTap: () => _insertFormatting('\n---\n'),
                  ),
                  _buildFormattingButton(
                    icon: Icons.access_time_rounded,
                    tooltip: 'Sisipkan Waktu Sekarang',
                    onTap: () {
                      final timeStr = DateFormat('d MMM yyyy, HH:mm')
                          .format(DateTime.now());
                      _insertFormatting('[$timeStr] ');
                    },
                  ),
                ],
              ),
            ),

            // Bottom Palette & Stats Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF16161A)
                    : theme.colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(isDark ? 50 : 15),
                    blurRadius: 10,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Color Selection Row
                    SizedBox(
                      height: 40,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: AppTheme.noteColors.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final colorOpt = AppTheme.noteColors[index];
                          final isSelected =
                              _selectedColorValue == colorOpt.color.toARGB32();

                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedColorValue = colorOpt.color.toARGB32();
                                _hasChanged = true;
                              });
                            },
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: colorOpt.resolve(isDark),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected
                                      ? theme.colorScheme.primary
                                      : (isDark
                                            ? Colors.white24
                                            : Colors.black26),
                                  width: isSelected ? 2.5 : 1,
                                ),
                              ),
                              child: isSelected
                                  ? Icon(
                                      Icons.check_rounded,
                                      size: 18,
                                      color: isDark
                                          ? Colors.white
                                          : Colors.black87,
                                    )
                                  : null,
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Word and character count status
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '$characterCount karakter • $wordCount kata',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? Colors.white54 : Colors.black45,
                          ),
                        ),
                        if (_hasChanged)
                          Row(
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: Colors.amber,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                'Ada perubahan',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark
                                      ? Colors.amberAccent
                                      : Colors.orange.shade800,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
