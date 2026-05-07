import '../../core/errors/result.dart';
import '../entities/note.dart';
import '../entities/note_block.dart';
import '../repositories/ai_service.dart';
import '../repositories/note_repository.dart';

class SaveNote {
  final NoteRepository repo;
  SaveNote(this.repo);
  Future<Result<void>> call(Note note) => repo.saveNote(note);
}

class DeleteNote {
  final NoteRepository repo;
  DeleteNote(this.repo);
  Future<Result<void>> call(String id) => repo.deleteNote(id);
}

class WatchNotes {
  final NoteRepository repo;
  WatchNotes(this.repo);
  Stream<List<Note>> call(String userId) => repo.watchNotes(userId);
}

class ExtractTasks {
  final AiService ai;
  ExtractTasks(this.ai);
  Future<Result<ChecklistBlock>> call(String input, String lang) async {
    final r = await ai.extractTasks(input, language: lang);
    return r.when(
      success: (tasks) {
        final items = tasks
            .where((t) => t.trim().isNotEmpty)
            .map((t) => ChecklistItem.create(t.trim()))
            .toList();
        if (items.isEmpty) items.add(ChecklistItem.create(''));
        return Success(NoteBlockFactory.newChecklist(items: items));
      },
      failure: (f) => FailureResult(f),
    );
  }
}

class SummarizeNote {
  final AiService ai;
  SummarizeNote(this.ai);
  Future<Result<String>> call(String input, String lang) =>
      ai.summarize(input, language: lang);
}
