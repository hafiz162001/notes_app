import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'data/repositories/note_repository.dart';
import 'data/services/storage_service.dart';
import 'ui/core/theme.dart';
import 'ui/features/notes/view_models/notes_view_model.dart';
import 'ui/features/notes/views/notes_list_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  final storageService = StorageService();
  final noteRepository = NoteRepository(storageService: storageService);
  final viewModel = NotesViewModel(repository: noteRepository);

  await viewModel.init();

  runApp(NotesApp(viewModel: viewModel));
}

class NotesApp extends StatelessWidget {
  final NotesViewModel viewModel;

  const NotesApp({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        return MaterialApp(
          title: 'CatatanKu',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: viewModel.themeMode,
          home: NotesListScreen(viewModel: viewModel),
        );
      },
    );
  }
}
