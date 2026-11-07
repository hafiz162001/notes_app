import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/note_model.dart';

class StorageService {
  static const String _notesKey = 'notes_storage_key';
  static const String _initializedKey = 'app_initialized_key';
  static const String _categoriesKey = 'app_custom_categories_key';
  static const String _pinKey = 'app_security_pin_key';

  static const List<String> defaultCategories = [
    'Umum',
    'Pekerjaan',
    'Pribadi',
    'Ide',
    'Tugas',
    'Belanja',
  ];

  Future<List<Note>> loadNotes() async {
    final prefs = await SharedPreferences.getInstance();

    final isInitialized = prefs.getBool(_initializedKey) ?? false;
    if (!isInitialized) {
      final initialNotes = _getInitialSampleNotes();
      await saveNotes(initialNotes);
      await saveCategories(defaultCategories);
      await prefs.setBool(_initializedKey, true);
      return initialNotes;
    }

    final rawJsonList = prefs.getStringList(_notesKey);
    if (rawJsonList == null || rawJsonList.isEmpty) {
      return [];
    }

    try {
      return rawJsonList
          .map((item) => Note.fromMap(json.decode(item) as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<bool> saveNotes(List<Note> notes) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = notes.map((note) => json.encode(note.toMap())).toList();
    return prefs.setStringList(_notesKey, jsonList);
  }

  Future<List<String>> loadCategories() async {
    final prefs = await SharedPreferences.getInstance();
    final categories = prefs.getStringList(_categoriesKey);
    if (categories == null || categories.isEmpty) {
      return List<String>.from(defaultCategories);
    }
    return categories;
  }

  Future<bool> saveCategories(List<String> categories) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.setStringList(_categoriesKey, categories);
  }

  Future<String> getSecurityPin() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_pinKey) ?? '1234';
  }

  Future<bool> setSecurityPin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.setString(_pinKey, pin);
  }

  List<Note> _getInitialSampleNotes() {
    final now = DateTime.now();
    return [
      Note(
        id: '1',
        title: 'Selamat Datang di CatatanKu! 📝',
        content:
            'Aplikasi catatan pintar dengan fitur terlengkap:\n\n'
            '• Format teks cepat (Daftar periksa, Tebal, Miring, Heading)\n'
            '• Sematkan (Pin) catatan prioritas di atas\n'
            '• Kunci catatan pribadi dengan PIN keamanan 🔒\n'
            '• Arsipkan catatan atau buang ke Tong Sampah\n'
            '• Personalisasi warna pastel & kategori kustom\n'
            '• Pencarian teks instan & pengurutan fleksibel',
        createdAt: now.subtract(const Duration(minutes: 45)),
        updatedAt: now.subtract(const Duration(minutes: 45)),
        colorValue: 0xFFFFF9C4, // Pastel Yellow
        isPinned: true,
        category: 'Umum',
      ),
      Note(
        id: '2',
        title: 'Rencana Tugas & Checklist Hari Ini ✅',
        content:
            '- [x] Coba fitur aplikasi CatatanKu\n'
            '- [ ] Buat catatan baru dengan palet warna\n'
            '- [ ] Coba format daftar periksa (checklist)\n'
            '- [ ] Uji sematkan catatan ke bagian atas\n'
            '- [ ] Bagikan catatan ke teman atau rekan kerja',
        createdAt: now.subtract(const Duration(hours: 2)),
        updatedAt: now.subtract(const Duration(hours: 1)),
        colorValue: 0xFFC8E6C9, // Pastel Green
        isPinned: true,
        category: 'Tugas',
      ),
      Note(
        id: '3',
        title: 'Catatan Rahasia / Diary 🔒',
        content:
            'Ini adalah contoh catatan yang dikunci dengan PIN keamanan.\n\n'
            'PIN standar: 1234\n'
            '(Anda dapat mengubah PIN ini kapan saja di menu pengaturan samping)',
        createdAt: now.subtract(const Duration(hours: 5)),
        updatedAt: now.subtract(const Duration(hours: 4)),
        colorValue: 0xFFE1BEE7, // Pastel Purple
        isPinned: false,
        isLocked: true,
        category: 'Pribadi',
      ),
      Note(
        id: '4',
        title: 'Daftar Belanja Kebutuhan Dapur 🛒',
        content:
            '- [ ] Kopi Arabika Robusta 500g\n'
            '- [ ] Beras pandan wangi 5 kg\n'
            '- [x] Telur ayam 1 kg\n'
            '- [ ] Susu UHT kemasan 1 Liter\n'
            '- [ ] Minyak goreng 2 Liter',
        createdAt: now.subtract(const Duration(days: 1)),
        updatedAt: now.subtract(const Duration(days: 1)),
        colorValue: 0xFFFFCCBC, // Pastel Coral
        isPinned: false,
        category: 'Belanja',
      ),
    ];
  }
}
