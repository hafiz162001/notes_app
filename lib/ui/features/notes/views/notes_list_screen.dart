import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:notes_app/data/models/note_model.dart';
import 'package:notes_app/data/repositories/note_repository.dart';
import 'package:notes_app/ui/features/notes/view_models/notes_view_model.dart';
import 'package:notes_app/ui/features/notes/views/note_edit_screen.dart';
import 'package:notes_app/ui/features/notes/widgets/category_chip.dart';
import 'package:notes_app/ui/features/notes/widgets/note_card.dart';
import 'package:notes_app/ui/features/notes/widgets/search_bar_widget.dart';
import 'package:share_plus/share_plus.dart';

class NotesListScreen extends StatelessWidget {
  final NotesViewModel viewModel;

  const NotesListScreen({super.key, required this.viewModel});

  Future<void> _openCreateNote(BuildContext context) async {
    final newNote = await Navigator.push<Note>(
      context,
      MaterialPageRoute(
        builder: (context) =>
            NoteEditScreen(availableCategories: viewModel.categories),
      ),
    );

    if (newNote != null) {
      await viewModel.saveNote(newNote);
    }
  }

  Future<void> _handleNoteTap(BuildContext context, Note note) async {
    if (note.isTrashed) {
      _showTrashedNoteOptions(context, note);
      return;
    }

    if (note.isLocked) {
      final unlocked = await _promptPinVerification(context);
      if (!unlocked) return;
    }

    if (!context.mounted) return;
    final updatedNote = await Navigator.push<Note>(
      context,
      MaterialPageRoute(
        builder: (context) => NoteEditScreen(
          note: note,
          availableCategories: viewModel.categories,
        ),
      ),
    );

    if (updatedNote != null) {
      await viewModel.saveNote(updatedNote);
    }
  }

  Future<bool> _promptPinVerification(BuildContext context) async {
    final pinController = TextEditingController();
    var hasError = false;

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.lock_rounded, color: Colors.amber),
              SizedBox(width: 8),
              Text('Catatan Terkunci'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Masukkan PIN 4-digit keamanan untuk membuka:'),
              const SizedBox(height: 12),
              TextField(
                controller: pinController,
                keyboardType: TextInputType.number,
                maxLength: 4,
                obscureText: true,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: '••••',
                  errorText: hasError ? 'PIN salah!' : null,
                  counterText: '',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx, false),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () async {
                final isValid = await viewModel.verifyPin(
                  pinController.text.trim(),
                );
                if (isValid) {
                  if (context.mounted) Navigator.pop(dialogCtx, true);
                } else {
                  setDialogState(() {
                    hasError = true;
                    pinController.clear();
                  });
                }
              },
              child: const Text('Buka'),
            ),
          ],
        ),
      ),
    );

    return result ?? false;
  }

  void _showTrashedNoteOptions(BuildContext context, Note note) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                note.title.isNotEmpty ? note.title : 'Catatan Tanpa Judul',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              const Text(
                'Catatan ini berada di Tempat Sampah. Pulihkan untuk membaca atau mengedit kembali.',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(
                  Icons.restore_from_trash_rounded,
                  color: Colors.blue,
                ),
                title: const Text('Pulihkan Catatan'),
                onTap: () async {
                  Navigator.pop(sheetCtx);
                  await viewModel.restoreFromTrash(note.id);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Catatan berhasil dipulihkan'),
                      ),
                    );
                  }
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.delete_forever_rounded,
                  color: Colors.red,
                ),
                title: const Text(
                  'Hapus Permanen',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(sheetCtx);
                  _confirmPermanentDelete(context, note);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDeleteNote(BuildContext context, Note note) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Pindahkan ke Sampah?'),
        content: Text(
          note.title.isNotEmpty
              ? 'Catatan "${note.title}" akan dipindahkan ke Tempat Sampah.'
              : 'Catatan ini akan dipindahkan ke Tempat Sampah.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(dialogCtx);
              await viewModel.moveToTrash(note.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Catatan dipindahkan ke Tempat Sampah'),
                    action: SnackBarAction(
                      label: 'Urungkan',
                      onPressed: () {
                        viewModel.restoreFromTrash(note.id);
                      },
                    ),
                  ),
                );
              }
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  void _confirmPermanentDelete(BuildContext context, Note note) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Hapus Permanen?'),
        content: const Text(
          'Catatan ini akan dihapus secara permanen dan tidak dapat dipulihkan lagi.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(dialogCtx);
              await viewModel.permanentlyDelete(note.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Catatan dihapus permanen')),
                );
              }
            },
            child: const Text('Hapus Permanen'),
          ),
        ],
      ),
    );
  }

  void _confirmEmptyTrash(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Kosongkan Sampah?'),
        content: const Text(
          'Semua catatan di Tempat Sampah akan dihapus secara permanen.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(dialogCtx);
              await viewModel.emptyTrash();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Tempat Sampah telah dikosongkan'),
                  ),
                );
              }
            },
            child: const Text('Kosongkan'),
          ),
        ],
      ),
    );
  }

  void _showSortSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Urutkan Catatan',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              _buildSortTile(
                sheetCtx,
                'Waktu Diperbarui (Terbaru)',
                NoteSortOption.updatedDesc,
              ),
              _buildSortTile(
                sheetCtx,
                'Waktu Diperbarui (Terlama)',
                NoteSortOption.updatedAsc,
              ),
              _buildSortTile(
                sheetCtx,
                'Waktu Dibuat (Terbaru)',
                NoteSortOption.createdDesc,
              ),
              _buildSortTile(
                sheetCtx,
                'Judul (A - Z)',
                NoteSortOption.titleAsc,
              ),
              _buildSortTile(
                sheetCtx,
                'Judul (Z - A)',
                NoteSortOption.titleDesc,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSortTile(
    BuildContext context,
    String title,
    NoteSortOption option,
  ) {
    final isSelected = viewModel.sortOption == option;
    return ListTile(
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? Theme.of(context).colorScheme.primary : null,
        ),
      ),
      trailing: isSelected
          ? Icon(
              Icons.check_rounded,
              color: Theme.of(context).colorScheme.primary,
            )
          : null,
      onTap: () {
        Navigator.pop(context);
        viewModel.setSortOption(option);
      },
    );
  }

  void _showAddCategoryDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tambah Kategori'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Nama kategori baru...'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () async {
              final val = controller.text.trim();
              if (val.isNotEmpty) {
                await viewModel.addCategory(val);
                if (ctx.mounted) Navigator.pop(ctx);
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _showManageCategoriesDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Kelola Kategori / Label'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 250),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: viewModel.categories.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final cat = viewModel.categories[i];
                      return ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: Text(cat),
                        trailing: IconButton(
                          icon: const Icon(
                            Icons.delete_outline_rounded,
                            size: 20,
                            color: Colors.red,
                          ),
                          onPressed: () async {
                            await viewModel.removeCategory(cat);
                            setDialogState(() {});
                          },
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => _showAddCategoryDialog(context),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Tambah Kategori'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Tutup'),
            ),
          ],
        ),
      ),
    );
  }

  void _showSecurityPinDialog(BuildContext context) {
    final oldPinController = TextEditingController();
    final newPinController = TextEditingController();
    var errorMessage = '';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.shield_rounded, color: Colors.indigo),
              SizedBox(width: 8),
              Text('Atur PIN Keamanan'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'PIN ini digunakan untuk mengunci dan membuka catatan penting/pribadi.',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: oldPinController,
                keyboardType: TextInputType.number,
                maxLength: 4,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'PIN Saat Ini (Standar: 1234)',
                  counterText: '',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: newPinController,
                keyboardType: TextInputType.number,
                maxLength: 4,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'PIN Baru (4 Digit)',
                  counterText: '',
                ),
              ),
              if (errorMessage.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  errorMessage,
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () async {
                final isOldCorrect = await viewModel.verifyPin(
                  oldPinController.text.trim(),
                );
                if (!isOldCorrect) {
                  setDialogState(() {
                    errorMessage = 'PIN saat ini tidak cocok!';
                  });
                  return;
                }
                final newPin = newPinController.text.trim();
                if (newPin.length != 4) {
                  setDialogState(() {
                    errorMessage = 'PIN baru harus 4 digit angka!';
                  });
                  return;
                }
                await viewModel.setPin(newPin);
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('PIN keamanan berhasil diperbarui!'),
                    ),
                  );
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  void _showBackupRestoreDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.backup_rounded, color: Colors.teal),
            SizedBox(width: 8),
            Text('Cadangan & Pulihkan'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Simpan cadangan data catatan Anda atau pulihkan catatan dari berkas JSON.',
              style: TextStyle(fontSize: 13),
            ),
          ],
        ),
        actions: [
          OutlinedButton.icon(
            icon: const Icon(Icons.file_upload_outlined, size: 18),
            label: const Text('Ekspor Cadangan'),
            onPressed: () async {
              Navigator.pop(ctx);
              final backupStr = await viewModel.exportBackup();
              SharePlus.share(
                backupStr,
                subject:
                    'Cadangan CatatanKu - ${DateFormat('yyyy-MM-dd').format(DateTime.now())}',
              );
            },
          ),
          FilledButton.icon(
            icon: const Icon(Icons.file_download_outlined, size: 18),
            label: const Text('Impor JSON'),
            onPressed: () {
              Navigator.pop(ctx);
              _showImportDialog(context);
            },
          ),
        ],
      ),
    );
  }

  void _showImportDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Impor Catatan dari JSON'),
        content: TextField(
          controller: controller,
          maxLines: 6,
          decoration: const InputDecoration(
            hintText: 'Tempelkan data JSON cadangan di sini...',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () async {
              final raw = controller.text.trim();
              if (raw.isNotEmpty) {
                final success = await viewModel.importBackup(raw);
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        success
                            ? 'Catatan cadangan berhasil diimpor!'
                            : 'Format JSON tidak valid atau gagal diimpor.',
                      ),
                    ),
                  );
                }
              }
            },
            child: const Text('Impor'),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title,
    IconData icon,
    int count,
  ) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 15, color: theme.colorScheme.primary),
          const SizedBox(width: 6),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withAlpha(30),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesLayout(
    BuildContext context,
    List<Note> notes,
    bool isGrid,
  ) {
    if (isGrid) {
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          mainAxisExtent: 210,
        ),
        itemCount: notes.length,
        itemBuilder: (context, index) {
          final note = notes[index];
          return NoteCard(
            note: note,
            isGrid: true,
            onTap: () => _handleNoteTap(context, note),
            onPinToggle: !note.isTrashed
                ? () => viewModel.togglePin(note.id)
                : null,
            onArchiveToggle: () => viewModel.toggleArchive(note.id),
            onLockToggle: () => viewModel.toggleLock(note.id),
            onDelete: () => _confirmDeleteNote(context, note),
            onRestore: () => viewModel.restoreFromTrash(note.id),
            onPermanentDelete: () => _confirmPermanentDelete(context, note),
          );
        },
      );
    } else {
      return ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: notes.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final note = notes[index];
          return NoteCard(
            note: note,
            isGrid: false,
            onTap: () => _handleNoteTap(context, note),
            onPinToggle: !note.isTrashed
                ? () => viewModel.togglePin(note.id)
                : null,
            onArchiveToggle: () => viewModel.toggleArchive(note.id),
            onLockToggle: () => viewModel.toggleLock(note.id),
            onDelete: () => _confirmDeleteNote(context, note),
            onRestore: () => viewModel.restoreFromTrash(note.id),
            onPermanentDelete: () => _confirmPermanentDelete(context, note),
          );
        },
      );
    }
  }

  String _getScreenTitle() {
    switch (viewModel.currentSection) {
      case NoteSection.all:
        return 'CatatanKu';
      case NoteSection.archive:
        return 'Arsip Catatan';
      case NoteSection.trash:
        return 'Tempat Sampah';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        final pinned = viewModel.pinnedNotes;
        final unpinned = viewModel.unpinnedNotes;
        final totalFiltered = viewModel.filteredNotes.length;

        return Scaffold(
          drawer: Drawer(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                DrawerHeader(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        theme.colorScheme.primary,
                        theme.colorScheme.primary.withAlpha(200),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          Icons.edit_note_rounded,
                          color: theme.colorScheme.primary,
                          size: 32,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'CatatanKu',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        'Aplikasi Catatan Pintar & Aman',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),

                // Main navigation items
                ListTile(
                  leading: const Icon(Icons.notes_rounded),
                  title: const Text('Semua Catatan'),
                  trailing: Text(
                    '${viewModel.activeNotesCount}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  selected: viewModel.currentSection == NoteSection.all,
                  onTap: () {
                    Navigator.pop(context);
                    viewModel.setCurrentSection(NoteSection.all);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.archive_outlined),
                  title: const Text('Arsip'),
                  trailing: Text(
                    '${viewModel.archivedNotesCount}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  selected: viewModel.currentSection == NoteSection.archive,
                  onTap: () {
                    Navigator.pop(context);
                    viewModel.setCurrentSection(NoteSection.archive);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete_outline_rounded),
                  title: const Text('Tempat Sampah'),
                  trailing: Text(
                    '${viewModel.trashedNotesCount}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  selected: viewModel.currentSection == NoteSection.trash,
                  onTap: () {
                    Navigator.pop(context);
                    viewModel.setCurrentSection(NoteSection.trash);
                  },
                ),

                const Divider(indent: 16, endIndent: 16),

                // Category management
                ListTile(
                  leading: const Icon(Icons.label_outline_rounded),
                  title: const Text('Kelola Kategori / Label'),
                  onTap: () {
                    Navigator.pop(context);
                    _showManageCategoriesDialog(context);
                  },
                ),

                // Security PIN
                ListTile(
                  leading: const Icon(Icons.shield_outlined),
                  title: const Text('Atur PIN Keamanan'),
                  onTap: () {
                    Navigator.pop(context);
                    _showSecurityPinDialog(context);
                  },
                ),

                // Backup & Restore
                ListTile(
                  leading: const Icon(Icons.backup_outlined),
                  title: const Text('Cadangan & Pulihkan'),
                  onTap: () {
                    Navigator.pop(context);
                    _showBackupRestoreDialog(context);
                  },
                ),
              ],
            ),
          ),
          appBar: AppBar(
            title: Row(
              children: [
                Text(
                  _getScreenTitle(),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${viewModel.filteredNotes.length}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSecondaryContainer,
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              // Empty trash button if in trash section
              if (viewModel.currentSection == NoteSection.trash &&
                  viewModel.trashedNotesCount > 0)
                IconButton(
                  icon: const Icon(
                    Icons.delete_sweep_rounded,
                    color: Colors.red,
                  ),
                  tooltip: 'Kosongkan Sampah',
                  onPressed: () => _confirmEmptyTrash(context),
                ),
              // Sort menu
              IconButton(
                icon: const Icon(Icons.sort_rounded),
                tooltip: 'Urutkan Catatan',
                onPressed: () => _showSortSheet(context),
              ),
              // Grid / List toggle
              IconButton(
                icon: Icon(
                  viewModel.isGridView
                      ? Icons.view_agenda_outlined
                      : Icons.grid_view_rounded,
                ),
                tooltip: viewModel.isGridView
                    ? 'Tampilan Daftar'
                    : 'Tampilan Kisi',
                onPressed: () => viewModel.toggleViewMode(),
              ),
              // Theme toggle
              IconButton(
                icon: Icon(
                  viewModel.themeMode == ThemeMode.dark
                      ? Icons.dark_mode_rounded
                      : viewModel.themeMode == ThemeMode.light
                      ? Icons.light_mode_rounded
                      : Icons.brightness_auto_rounded,
                ),
                tooltip: 'Ganti Tema',
                onPressed: () => viewModel.toggleThemeMode(context),
              ),
              const SizedBox(width: 6),
            ],
          ),
          body: viewModel.isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: () => viewModel.init(),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    children: [
                      // Search bar
                      SearchBarWidget(
                        initialValue: viewModel.searchQuery,
                        onChanged: (val) => viewModel.setSearchQuery(val),
                        onClear: () => viewModel.setSearchQuery(''),
                      ),
                      const SizedBox(height: 14),

                      // Category filters
                      CategoryFilterBar(
                        categories: viewModel.categories,
                        selectedCategory: viewModel.selectedCategory,
                        onSelectCategory: (cat) =>
                            viewModel.setSelectedCategory(cat),
                        onAddCategory: () => _showAddCategoryDialog(context),
                      ),
                      const SizedBox(height: 8),

                      // Empty state
                      if (totalFiltered == 0) ...[
                        const SizedBox(height: 60),
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 90,
                                height: 90,
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.white.withAlpha(15)
                                      : Colors.black.withAlpha(8),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  viewModel.searchQuery.isNotEmpty
                                      ? Icons.search_off_rounded
                                      : viewModel.currentSection ==
                                            NoteSection.archive
                                      ? Icons.archive_outlined
                                      : viewModel.currentSection ==
                                            NoteSection.trash
                                      ? Icons.delete_outline_rounded
                                      : Icons.note_alt_outlined,
                                  size: 46,
                                  color: isDark
                                      ? Colors.white54
                                      : Colors.black45,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                viewModel.searchQuery.isNotEmpty
                                    ? 'Tidak ada catatan yang cocok'
                                    : viewModel.currentSection ==
                                          NoteSection.archive
                                    ? 'Belum ada catatan yang diarsipkan'
                                    : viewModel.currentSection ==
                                          NoteSection.trash
                                    ? 'Tempat Sampah kosong'
                                    : 'Belum ada catatan',
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                viewModel.searchQuery.isNotEmpty
                                    ? 'Coba gunakan kata kunci pencarian lainnya'
                                    : viewModel.currentSection ==
                                          NoteSection.all
                                    ? 'Tekan tombol + di bawah untuk membuat catatan baru'
                                    : '',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDark
                                      ? Colors.white60
                                      : Colors.black54,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ] else ...[
                        // Pinned notes section (only in main active view)
                        if (viewModel.currentSection == NoteSection.all &&
                            pinned.isNotEmpty) ...[
                          _buildSectionHeader(
                            context,
                            'DISEMATKAN',
                            Icons.push_pin_rounded,
                            pinned.length,
                          ),
                          _buildNotesLayout(
                            context,
                            pinned,
                            viewModel.isGridView,
                          ),
                        ],

                        // Unpinned notes section
                        if (unpinned.isNotEmpty) ...[
                          if (viewModel.currentSection == NoteSection.all &&
                              pinned.isNotEmpty)
                            _buildSectionHeader(
                              context,
                              'CATATAN LAINNYA',
                              Icons.notes_rounded,
                              unpinned.length,
                            ),
                          _buildNotesLayout(
                            context,
                            unpinned,
                            viewModel.isGridView,
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
          floatingActionButton: viewModel.currentSection == NoteSection.all
              ? FloatingActionButton.extended(
                  onPressed: () => _openCreateNote(context),
                  icon: const Icon(Icons.add_rounded, size: 24),
                  label: const Text(
                    'Catatan Baru',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  elevation: 3,
                )
              : null,
        );
      },
    );
  }
}
