import 'package:flutter/material.dart';
import 'package:notes_app/data/models/note_model.dart';
import 'package:notes_app/data/repositories/note_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum NoteSection {
  all,
  archive,
  trash,
}

class NotesViewModel extends ChangeNotifier {
  final NoteRepository _repository;

  NotesViewModel({NoteRepository? repository})
      : _repository = repository ?? NoteRepository();

  List<Note> _allNotes = [];
  List<String> _categories = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedCategory = 'Semua';
  bool _isGridView = true;
  ThemeMode _themeMode = ThemeMode.system;
  NoteSection _currentSection = NoteSection.all;
  NoteSortOption _sortOption = NoteSortOption.updatedDesc;

  // Getters
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  String get selectedCategory => _selectedCategory;
  bool get isGridView => _isGridView;
  ThemeMode get themeMode => _themeMode;
  NoteSection get currentSection => _currentSection;
  NoteSortOption get sortOption => _sortOption;
  List<String> get categories => _categories;

  int get activeNotesCount =>
      _allNotes.where((n) => !n.isTrashed && !n.isArchived).length;
  int get archivedNotesCount =>
      _allNotes.where((n) => n.isArchived && !n.isTrashed).length;
  int get trashedNotesCount => _allNotes.where((n) => n.isTrashed).length;

  List<Note> get filteredNotes {
    final query = _searchQuery.trim().toLowerCase();

    // 1. Filter by active section
    Iterable<Note> baseNotes;
    switch (_currentSection) {
      case NoteSection.all:
        baseNotes = _allNotes.where((n) => !n.isTrashed && !n.isArchived);
        break;
      case NoteSection.archive:
        baseNotes = _allNotes.where((n) => n.isArchived && !n.isTrashed);
        break;
      case NoteSection.trash:
        baseNotes = _allNotes.where((n) => n.isTrashed);
        break;
    }

    // 2. Filter by category
    if (_selectedCategory != 'Semua') {
      baseNotes = baseNotes.where(
        (n) => n.category.toLowerCase() == _selectedCategory.toLowerCase(),
      );
    }

    // 3. Filter by search query
    if (query.isNotEmpty) {
      baseNotes = baseNotes.where((n) {
        final titleMatch = n.title.toLowerCase().contains(query);
        final contentMatch = n.content.toLowerCase().contains(query);
        return titleMatch || contentMatch;
      });
    }

    final result = baseNotes.toList();

    // 4. Sort
    switch (_sortOption) {
      case NoteSortOption.updatedDesc:
        result.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        break;
      case NoteSortOption.updatedAsc:
        result.sort((a, b) => a.updatedAt.compareTo(b.updatedAt));
        break;
      case NoteSortOption.createdDesc:
        result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case NoteSortOption.titleAsc:
        result.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
        break;
      case NoteSortOption.titleDesc:
        result.sort((a, b) => b.title.toLowerCase().compareTo(a.title.toLowerCase()));
        break;
    }

    return result;
  }

  List<Note> get pinnedNotes =>
      filteredNotes.where((note) => note.isPinned).toList();

  List<Note> get unpinnedNotes =>
      filteredNotes.where((note) => !note.isPinned).toList();

  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      _isGridView = prefs.getBool('pref_is_grid_view') ?? true;
      final themeIndex = prefs.getInt('pref_theme_mode') ?? ThemeMode.system.index;
      _themeMode = ThemeMode.values[themeIndex];
      final sortIndex = prefs.getInt('pref_sort_option') ?? NoteSortOption.updatedDesc.index;
      _sortOption = NoteSortOption.values[sortIndex];

      _allNotes = await _repository.getAllNotes();
      _categories = await _repository.getCategories();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setCurrentSection(NoteSection section) {
    _currentSection = section;
    _searchQuery = '';
    _selectedCategory = 'Semua';
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setSelectedCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  Future<void> setSortOption(NoteSortOption option) async {
    _sortOption = option;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('pref_sort_option', option.index);
  }

  Future<void> toggleViewMode() async {
    _isGridView = !_isGridView;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('pref_is_grid_view', _isGridView);
  }

  Future<void> toggleThemeMode(BuildContext context) async {
    if (_themeMode == ThemeMode.light) {
      _themeMode = ThemeMode.dark;
    } else if (_themeMode == ThemeMode.dark) {
      _themeMode = ThemeMode.system;
    } else {
      _themeMode = ThemeMode.light;
    }
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('pref_theme_mode', _themeMode.index);
  }

  Future<void> saveNote(Note note) async {
    await _repository.saveNote(note);
    _allNotes = await _repository.getAllNotes();
    notifyListeners();
  }

  Future<void> moveToTrash(String id) async {
    await _repository.moveToTrash(id);
    _allNotes = await _repository.getAllNotes();
    notifyListeners();
  }

  Future<void> restoreFromTrash(String id) async {
    await _repository.restoreFromTrash(id);
    _allNotes = await _repository.getAllNotes();
    notifyListeners();
  }

  Future<void> permanentlyDelete(String id) async {
    await _repository.permanentlyDelete(id);
    _allNotes = await _repository.getAllNotes();
    notifyListeners();
  }

  Future<void> emptyTrash() async {
    await _repository.emptyTrash();
    _allNotes = await _repository.getAllNotes();
    notifyListeners();
  }

  Future<void> toggleArchive(String id) async {
    await _repository.toggleArchive(id);
    _allNotes = await _repository.getAllNotes();
    notifyListeners();
  }

  Future<void> togglePin(String id) async {
    await _repository.togglePin(id);
    _allNotes = await _repository.getAllNotes();
    notifyListeners();
  }

  Future<void> toggleLock(String id) async {
    await _repository.toggleLock(id);
    _allNotes = await _repository.getAllNotes();
    notifyListeners();
  }

  Future<bool> verifyPin(String enteredPin) async {
    final correctPin = await _repository.getSecurityPin();
    return enteredPin == correctPin;
  }

  Future<bool> setPin(String newPin) async {
    return _repository.setSecurityPin(newPin);
  }

  Future<void> addCategory(String category) async {
    await _repository.addCategory(category);
    _categories = await _repository.getCategories();
    notifyListeners();
  }

  Future<void> removeCategory(String category) async {
    await _repository.removeCategory(category);
    _categories = await _repository.getCategories();
    if (_selectedCategory == category) {
      _selectedCategory = 'Semua';
    }
    notifyListeners();
  }

  Future<String> exportBackup() async {
    return _repository.exportBackupJson();
  }

  Future<bool> importBackup(String rawJson) async {
    final success = await _repository.importBackupJson(rawJson);
    if (success) {
      _allNotes = await _repository.getAllNotes();
      _categories = await _repository.getCategories();
      notifyListeners();
    }
    return success;
  }
}
