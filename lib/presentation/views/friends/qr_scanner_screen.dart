import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../app/providers.dart';
import '../../../core/extensions/extensions.dart';
import '../../viewmodels/auth_viewmodel.dart';

class QrScannerScreen extends ConsumerStatefulWidget {
  const QrScannerScreen({super.key});

  @override
  ConsumerState<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends ConsumerState<QrScannerScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool _processing = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_processing) return;
    final code = capture.barcodes.firstOrNull?.rawValue;
    if (code == null) return;
    final match = RegExp(r'nawa://friend/(.+)').firstMatch(code.trim());
    if (match == null) return;
    final username = match.group(1)!.toLowerCase();
    setState(() => _processing = true);
    final user = ref.read(authViewModelProvider).user;
    if (user == null) return;
    final repo = ref.read(friendsRepositoryProvider);
    final me = await ref.read(profileRepositoryProvider).loadCurrent();
    final err = await repo.sendRequest(
      selfUid: user.uid,
      selfDisplayName: me?.displayName ?? user.email ?? 'User',
      selfUsername: me?.username,
      selfPhotoUrl: me?.photoUrl,
      targetUsername: username,
    );
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      SnackBar(
        content: Text(err != null ? err.tr() : 'friends.request_sent'.tr()),
      ),
    );
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('friends.scan_qr'.tr())),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),
          Positioned(
            bottom: 24,
            left: 24,
            right: 24,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'friends.scanning'.tr(),
                style: context.text.bodyMedium?.copyWith(color: Colors.white),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
