import 'dart:convert';
import '../models/note_model.dart';
import '../services/storage_service.dart';

enum NoteSortOption {
  updatedDesc, // Terbaru diperbarui
  updatedAsc,  // Terlama diperbarui
  createdDesc, // Terbaru dibuat
  titleAsc,    // Judul A - Z
  titleDesc,   // Judul Z - A
}

class NoteRepository {
  final StorageService _storageService;

  NoteRepository({StorageService? storageService})
      : _storageService = storageService ?? StorageService();

  Future<List<Note>> getAllNotes() async {
    return _storageService.loadNotes();
  }

  Future<void> saveNote(Note note) async {
    final notes = await _storageService.loadNotes();
    final index = notes.indexWhere((n) => n.id == note.id);
    if (index >= 0) {
      notes[index] = note;
    } else {
      notes.insert(0, note);
    }
    await _storageService.saveNotes(notes);
  }

  Future<void> moveToTrash(String id) async {
    final notes = await _storageService.loadNotes();
    final index = notes.indexWhere((n) => n.id == id);
    if (index >= 0) {
      notes[index] = notes[index].copyWith(isTrashed: true, isPinned: false);
      await _storageService.saveNotes(notes);
    }
  }

  Future<void> restoreFromTrash(String id) async {
    final notes = await _storageService.loadNotes();
    final index = notes.indexWhere((n) => n.id == id);
    if (index >= 0) {
      notes[index] = notes[index].copyWith(isTrashed: false, isArchived: false);
      await _storageService.saveNotes(notes);
    }
  }

  Future<void> permanentlyDelete(String id) async {
    final notes = await _storageService.loadNotes();
    notes.removeWhere((n) => n.id == id);
    await _storageService.saveNotes(notes);
  }

  Future<void> emptyTrash() async {
    final notes = await _storageService.loadNotes();
    notes.removeWhere((n) => n.isTrashed);
    await _storageService.saveNotes(notes);
  }

  Future<void> toggleArchive(String id) async {
    final notes = await _storageService.loadNotes();
    final index = notes.indexWhere((n) => n.id == id);
    if (index >= 0) {
      final target = notes[index];
      notes[index] = target.copyWith(
        isArchived: !target.isArchived,
        isPinned: false, // unpin when archived
      );
      await _storageService.saveNotes(notes);
    }
  }

  Future<void> togglePin(String id) async {
    final notes = await _storageService.loadNotes();
    final index = notes.indexWhere((n) => n.id == id);
    if (index >= 0) {
      final target = notes[index];
      notes[index] = target.copyWith(isPinned: !target.isPinned);
      await _storageService.saveNotes(notes);
    }
  }

  Future<void> toggleLock(String id) async {
    final notes = await _storageService.loadNotes();
    final index = notes.indexWhere((n) => n.id == id);
    if (index >= 0) {
      final target = notes[index];
      notes[index] = target.copyWith(isLocked: !target.isLocked);
      await _storageService.saveNotes(notes);
    }
  }

  // Categories
  Future<List<String>> getCategories() async {
    return _storageService.loadCategories();
  }

  Future<void> addCategory(String category) async {
    final cats = await _storageService.loadCategories();
    final trimmed = category.trim();
    if (trimmed.isNotEmpty && !cats.any((c) => c.toLowerCase() == trimmed.toLowerCase())) {
      cats.add(trimmed);
      await _storageService.saveCategories(cats);
    }
  }

  Future<void> removeCategory(String category) async {
    final cats = await _storageService.loadCategories();
    cats.removeWhere((c) => c.toLowerCase() == category.toLowerCase());
    await _storageService.saveCategories(cats);
  }

  // Security PIN
  Future<String> getSecurityPin() async => _storageService.getSecurityPin();
  Future<bool> setSecurityPin(String pin) async => _storageService.setSecurityPin(pin);

  // Backup & Restore
  Future<String> exportBackupJson() async {
    final notes = await _storageService.loadNotes();
    final categories = await _storageService.loadCategories();
    return json.encode({
      'version': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'categories': categories,
      'notes': notes.map((n) => n.toMap()).toList(),
    });
  }

  Future<bool> importBackupJson(String rawJson) async {
    try {
      final map = json.decode(rawJson) as Map<String, dynamic>;
      final rawNotes = map['notes'] as List<dynamic>?;
      if (rawNotes == null) return false;

      final parsedNotes = rawNotes
          .map((item) => Note.fromMap(item as Map<String, dynamic>))
          .toList();

      final existingNotes = await _storageService.loadNotes();
      final mergedNotesMap = <String, Note>{
        for (var n in existingNotes) n.id: n,
        for (var n in parsedNotes) n.id: n,
      };

      await _storageService.saveNotes(mergedNotesMap.values.toList());

      final rawCategories = map['categories'] as List<dynamic>?;
      if (rawCategories != null) {
        final existingCats = await _storageService.loadCategories();
        for (var c in rawCategories) {
          final catName = c.toString();
          if (!existingCats.contains(catName)) {
            existingCats.add(catName);
          }
        }
        await _storageService.saveCategories(existingCats);
      }

      return true;
    } catch (_) {
      return false;
    }
  }
}
