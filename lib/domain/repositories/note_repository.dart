import '../../core/errors/result.dart';
import '../entities/note.dart';

abstract class NoteRepository {
  Stream<List<Note>> watchNotes(String userId);
  Future<Result<Note?>> getNote(String id);
  Future<Result<void>> saveNote(Note note);
  Future<Result<void>> deleteNote(String id);
  Future<Result<List<Note>>> search(String query);
  Future<Result<void>> wipeUser(String uid);
  int pendingOpsCount();
  Future<void> flushPending();
}
