# CatatanKu - Aplikasi Catatan Android Modern & Lengkap 📝

Aplikasi catatan (Notes App) profesional untuk platform Android dengan antarmuka **Material Design 3**, arsitektur **Clean MVVM**, fitur keamanan **PIN**, serta manajemen catatan komprehensif (Arsip & Tong Sampah).

---

## ✨ Fitur-Fitur Lengkap (Disempurnakan)

### 1. 📝 Editor Catatan Canggih & Bilah Format Cepat
- **Format Cepat (Toolbar di atas keyboard):**
  - ☑️ **Checklist / Daftar Tugas:** Tambahkan item `- [ ] ` secara instan.
  - • **Bullet List & Numbered List (1, 2, 3)**
  - **B** **Tebal (Bold)** dan *I* *Miring (Italic)*
  - **#** **Heading / Judul Bagian**
  - ➖ **Garis Pemisah (Divider)**
  - 🕒 **Sisipkan Tanggal & Waktu sekarang** dalam satu klik.
- **Deteksi Otomatis To-Do List:** Kartu di beranda menampilkan ringkasan kemajuan tugas (contoh: *"2 dari 5 tugas selesai"*).
- **Statistik Teks:** Menghitung jumlah kata dan karakter secara *real-time*.

### 2. 🔒 Keamanan Catatan Pribadi (Kunci dengan PIN 4 Digit)
- Kunci catatan sensitif / rahasia dengan PIN 4-digit.
- Catatan terkunci disembunyikan isinya di beranda dengan indikator gembok 🔒.
- Membuka catatan memerlukan verifikasi PIN.
- PIN keamanan dapat diubah kapan saja melalui menu samping (*Drawer*). PIN bawaan: `1234`.

### 3. 📦 Arsip & 🗑️ Tempat Sampah (Recycle Bin)
- **Arsip Catatan:** Simpan catatan yang telah selesai tanpa mengotori layar utama.
- **Pencegahan Kehilangan Data (Tempat Sampah):** Catatan yang dihapus tidak langsung hilang, melainkan dipindahkan ke Tempat Sampah.
- **Pulihkan / Hapus Permanen:** Catatan di Tempat Sampah dapat dipulihkan kembali ke daftar utama atau dikosongkan sekaligus.

### 4. 🏷️ Kategori Kustom & Palet Warna Pastel
- Tambah kategori/label baru sesuai kebutuhan (Umum, Kerja, Pribadi, Kuliah, dsb.).
- Kelola kategori langsung melalui menu samping (*Drawer*).
- 8 pilihan warna kartu catatan Material 3 yang lembut dan nyaman di mata untuk tema Terang maupun Gelap.

### 5. 🔀 Pengurutan & Pencarian Cepat
- **Urutkan berdasarkan:**
  - Waktu Diperbarui (Terbaru / Terlama)
  - Waktu Dibuat (Terbaru)
  - Abjad Judul (A - Z / Z - A)
- **Pencarian Real-Time:** Menemukan catatan secara instan berdasarkan judul atau kata kunci dalam teks.

### 6. 📤 Ekspor, Bagikan, & Cadangan (Backup / Restore)
- **Bagikan:** Integrasi dengan *Android Native Share Sheet* (WhatsApp, Telegram, Gmail, SMS, dll.).
- **Cadangan & Pulihkan:** Ekspor seluruh data catatan ke format JSON cadangan atau impor kembali berkas JSON.

### 7. 🌗 Tema & Tampilan Fleksibel
- Beralih antara tampilan **Kisi (Grid 2-kolom)** dan **Daftar (List View)**.
- Dukungan **Dark Mode & Light Mode** otomatis.

---

## 🏗️ Struktur Arsitektur Proyek

```text
lib/
├── data/
│   ├── models/
│   │   └── note_model.dart             # Model data (Pinned, Archived, Trashed, Locked, Color, Category)
│   ├── services/
│   │   └── storage_service.dart        # Penyimpanan lokal (SharedPreferences, PIN, Kategori)
│   └── repositories/
│       └── note_repository.dart       # Single source of truth (CRUD, Sort, Filter, Backup, PIN)
├── ui/
│   ├── core/
│   │   └── theme.dart                  # Material 3 Light/Dark theme, palet warna pastel & kategori
│   └── features/
│       └── notes/
│           ├── view_models/
│           │   └── notes_view_model.dart # State management (ChangeNotifier, Reactive filtering)
│           ├── views/
│           │   ├── notes_list_screen.dart # Halaman utama, Drawer navigasi, Modal sortir & PIN
│           │   └── note_edit_screen.dart  # Editor catatan, Toolbar format cepat, Picker warna
│           └── widgets/
│               ├── category_chip.dart     # Bilah filter kategori interaktif (+ Tambah Kategori)
│               ├── note_card.dart         # Kartu catatan (indikator checklist, lock, pin, popup)
│               └── search_bar_widget.dart # Bilah pencarian instan
└── main.dart                           # Entrypoint aplikasi CatatanKu
```

---

## 🚀 Menjalankan & Menginstal

### File APK Hasil Build:
File APK Android siap pasang tersedia di:
- [**`app-debug.apk`**](file:///c:/Dishub/experiment/Note/build/app/outputs/flutter-apk/app-debug.apk)

### Perintah Berguna:
```bash
# 1. Jalankan langsung di HP / Emulator
flutter run

# 2. Pasang APK ke perangkat Android via ADB
adb install -r build\app\outputs\flutter-apk\app-debug.apk

# 3. Jalankan pengujian otomatis (Unit & Widget Tests)
flutter test

# 4. Kompilasi APK rilis
flutter build apk --release
```
