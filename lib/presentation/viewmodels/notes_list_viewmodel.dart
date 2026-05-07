import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../domain/entities/note.dart';

enum NotesFilter { all, pinned, archived }

class NotesListState {
  final List<Note> all;
  final NotesFilter filter;
  final String search;

  const NotesListState({
    this.all = const [],
    this.filter = NotesFilter.all,
    this.search = '',
  });

  NotesListState copyWith({
    List<Note>? all,
    NotesFilter? filter,
    String? search,
  }) =>
      NotesListState(
        all: all ?? this.all,
        filter: filter ?? this.filter,
        search: search ?? this.search,
      );

  List<Note> get visible {
    Iterable<Note> list = all;
    switch (filter) {
      case NotesFilter.all:
        list = list.where((n) => !n.archived);
      case NotesFilter.pinned:
        list = list.where((n) => n.pinned && !n.archived);
      case NotesFilter.archived:
        list = list.where((n) => n.archived);
    }
    if (search.trim().isNotEmpty) {
      final q = search.toLowerCase();
      list = list.where((n) => n.plainTextSearchable.contains(q));
    }
    final result = list.toList();
    result.sort((a, b) {
      if (a.pinned != b.pinned) return a.pinned ? -1 : 1;
      return b.updatedAt.compareTo(a.updatedAt);
    });
    return result;
  }
}

class NotesListViewModel extends Notifier<NotesListState> {
  @override
  NotesListState build() {
    final auth = ref.watch(authStateProvider);
    final uid = auth.value?.uid;
    if (uid == null) return const NotesListState();
    final repo = ref.watch(noteRepositoryProvider);
    final sub = repo.watchNotes(uid).listen((notes) {
      state = state.copyWith(all: notes);
    });
    ref.onDispose(sub.cancel);
    return const NotesListState();
  }

  void setFilter(NotesFilter f) => state = state.copyWith(filter: f);
  void setSearch(String q) => state = state.copyWith(search: q);

  Future<void> togglePin(Note note) async {
    final updated = note.copyWith(pinned: !note.pinned);
    await ref.read(noteRepositoryProvider).saveNote(updated);
  }

  Future<void> toggleArchive(Note note) async {
    final updated = note.copyWith(archived: !note.archived);
    await ref.read(noteRepositoryProvider).saveNote(updated);
  }

  Future<void> delete(Note note) async {
    await ref.read(noteRepositoryProvider).deleteNote(note.id);
  }

  Future<void> setColor(Note note, int? colorValue) async {
    final updated = colorValue == null
        ? note.copyWith(clearColor: true)
        : note.copyWith(colorValue: colorValue);
    await ref.read(noteRepositoryProvider).saveNote(updated);
  }
}

final notesListViewModelProvider =
    NotifierProvider<NotesListViewModel, NotesListState>(
        NotesListViewModel.new);
