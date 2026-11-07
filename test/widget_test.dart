import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notes_app/data/models/note_model.dart';
import 'package:notes_app/data/repositories/note_repository.dart';
import 'package:notes_app/main.dart';
import 'package:notes_app/ui/features/notes/view_models/notes_view_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('Note model serialization and copyWith works properly with new fields', () {
    final now = DateTime.now();
    final note = Note(
      id: 'test-1',
      title: 'Catatan Tes',
      content: 'Isi catatan tes',
      createdAt: now,
      updatedAt: now,
      colorValue: 0xFFFFF9C4,
      isPinned: true,
      isArchived: false,
      isTrashed: false,
      isLocked: true,
      category: 'Pekerjaan',
    );

    final jsonStr = note.toJson();
    final decoded = Note.fromJson(jsonStr);

    expect(decoded.id, 'test-1');
    expect(decoded.title, 'Catatan Tes');
    expect(decoded.content, 'Isi catatan tes');
    expect(decoded.isPinned, true);
    expect(decoded.isLocked, true);
    expect(decoded.category, 'Pekerjaan');

    final updated = decoded.copyWith(
      title: 'Judul Baru',
      isPinned: false,
      isArchived: true,
      isTrashed: true,
    );
    expect(updated.title, 'Judul Baru');
    expect(updated.isPinned, false);
    expect(updated.isArchived, true);
    expect(updated.isTrashed, true);
  });

  test('NotesViewModel comprehensive features: trash, archive, pin, categories, and PIN', () async {
    final repo = NoteRepository();
    final vm = NotesViewModel(repository: repo);
    await vm.init();

    expect(vm.activeNotesCount, greaterThan(0));

    // 1. Add Note
    final testNote = Note(
      id: 'feature-test',
      title: 'Catatan Fitur Baru',
      content: '- [ ] Tugas 1\n- [x] Tugas 2',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      category: 'Tugas',
    );
    await vm.saveNote(testNote);
    expect(vm.activeNotesCount, greaterThan(3));

    // 2. Archive
    await vm.toggleArchive('feature-test');
    expect(vm.filteredNotes.any((n) => n.id == 'feature-test'), isFalse);
    vm.setCurrentSection(NoteSection.archive);
    expect(vm.filteredNotes.any((n) => n.id == 'feature-test'), isTrue);

    // 3. Move to Trash
    await vm.moveToTrash('feature-test');
    vm.setCurrentSection(NoteSection.trash);
    expect(vm.filteredNotes.any((n) => n.id == 'feature-test'), isTrue);

    // 4. Restore from Trash
    await vm.restoreFromTrash('feature-test');
    vm.setCurrentSection(NoteSection.all);
    expect(vm.filteredNotes.any((n) => n.id == 'feature-test'), isTrue);

    // 5. Category management
    await vm.addCategory('Olahraga');
    expect(vm.categories.contains('Olahraga'), isTrue);
    await vm.removeCategory('Olahraga');
    expect(vm.categories.contains('Olahraga'), isFalse);

    // 6. PIN Security
    final isDefaultPin = await vm.verifyPin('1234');
    expect(isDefaultPin, isTrue);
    await vm.setPin('5678');
    final isNewPin = await vm.verifyPin('5678');
    expect(isNewPin, isTrue);

    // 7. Backup and Restore
    final backup = await vm.exportBackup();
    expect(backup.contains('Catatan Fitur Baru'), isTrue);
    final restored = await vm.importBackup(backup);
    expect(restored, isTrue);
  });

  testWidgets('NotesApp renders with Drawer navigation and actions', (WidgetTester tester) async {
    final noteRepository = NoteRepository();
    final viewModel = NotesViewModel(repository: noteRepository);
    await viewModel.init();

    await tester.pumpWidget(NotesApp(viewModel: viewModel));
    await tester.pumpAndSettle();

    expect(find.text('CatatanKu'), findsOneWidget);
    expect(find.text('Catatan Baru'), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsOneWidget);

    // Open Drawer
    final scaffoldState = tester.state(find.byType(Scaffold)) as ScaffoldState;
    scaffoldState.openDrawer();
    await tester.pumpAndSettle();

    expect(find.text('Semua Catatan'), findsOneWidget);
    expect(find.text('Arsip'), findsOneWidget);
    expect(find.text('Tempat Sampah'), findsOneWidget);
    expect(find.text('Kelola Kategori / Label'), findsOneWidget);
    expect(find.text('Atur PIN Keamanan'), findsOneWidget);
    expect(find.text('Cadangan & Pulihkan'), findsOneWidget);
  });
}
