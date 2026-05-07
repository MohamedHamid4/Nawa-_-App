import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

class ConnectivityService {
  final Connectivity _connectivity = Connectivity();
  final InternetConnection _internet = InternetConnection();

  final _controller = StreamController<bool>.broadcast();
  bool _online = true;
  bool get isOnline => _online;
  Stream<bool> get onChange => _controller.stream;

  StreamSubscription<List<ConnectivityResult>>? _connSub;
  StreamSubscription<InternetStatus>? _netSub;

  Future<void> init() async {
    final initial = await _internet.hasInternetAccess;
    _online = initial;
    _controller.add(_online);

    _connSub = _connectivity.onConnectivityChanged.listen((results) async {
      final hasNet = await _internet.hasInternetAccess;
      _setOnline(hasNet);
    });
    _netSub = _internet.onStatusChange.listen((status) {
      _setOnline(status == InternetStatus.connected);
    });
  }

  void _setOnline(bool value) {
    if (value == _online) return;
    _online = value;
    _controller.add(_online);
  }

  Future<void> dispose() async {
    await _connSub?.cancel();
    await _netSub?.cancel();
    await _controller.close();
  }
}
