import 'dart:async';

import '../../domain/repositories/note_repository.dart';
import '../network/connectivity_service.dart';

class SyncService {
  final NoteRepository _notes;
  final ConnectivityService _connectivity;

  StreamSubscription<bool>? _connSub;
  Timer? _timer;

  SyncService({
    required NoteRepository notes,
    required ConnectivityService connectivity,
  })  : _notes = notes,
        _connectivity = connectivity;

  void start() {
    _connSub ??= _connectivity.onChange.listen((online) {
      if (online) {
        _notes.flushPending();
      }
    });
    _timer ??= Timer.periodic(const Duration(seconds: 30), (_) {
      _notes.flushPending();
    });
  }

  Future<void> stop() async {
    await _connSub?.cancel();
    _connSub = null;
    _timer?.cancel();
    _timer = null;
  }
}
