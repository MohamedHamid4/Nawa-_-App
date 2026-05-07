import 'dart:io';
import 'dart:typed_data';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gal/gal.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';

import '../../../app/providers.dart';
import '../../../app/router.dart';
import '../../../domain/entities/user.dart';

class QrCodeScreen extends ConsumerStatefulWidget {
  const QrCodeScreen({super.key});

  @override
  ConsumerState<QrCodeScreen> createState() => _QrCodeScreenState();
}

class _QrCodeScreenState extends ConsumerState<QrCodeScreen> {
  final ScreenshotController _screenshotController = ScreenshotController();
  AppUser? _user;
  bool _loading = true;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  Future<void> _load() async {
    final me = await ref.read(profileRepositoryProvider).loadCurrent();
    if (!mounted) return;
    setState(() {
      _user = me;
      _loading = false;
    });
  }

  String _qrPayload(AppUser user) {
    final uname = user.username;
    if (uname != null && uname.isNotEmpty) return 'nawa://friend/$uname';
    return 'nawa://user/${user.uid}';
  }

  String _handle(AppUser user) {
    final uname = user.username;
    if (uname != null && uname.isNotEmpty) return '@$uname';
    final emailPrefix = user.email?.split('@').first;
    if (emailPrefix != null && emailPrefix.isNotEmpty) return '@$emailPrefix';
    return '@${user.uid.substring(0, user.uid.length < 8 ? user.uid.length : 8)}';
  }

  String _displayName(AppUser user) {
    final dn = user.displayName?.trim();
    if (dn != null && dn.isNotEmpty) return dn;
    final emailPrefix = user.email?.split('@').first;
    if (emailPrefix != null && emailPrefix.isNotEmpty) return emailPrefix;
    return 'Nawa';
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: Text('friends.my_qr_title'.tr())),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final user = _user;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: Text('friends.my_qr_title'.tr())),
        body: Center(child: Text('common.not_signed_in'.tr())),
      );
    }

    final qrData = _qrPayload(user);
    final displayName = _displayName(user);
    final handle = _handle(user);
    final hasUsername = user.username != null && user.username!.isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: Text('friends.my_qr_title'.tr())),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),
            Screenshot(
              controller: _screenshotController,
              child: Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: colors.outlineVariant, width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: colors.shadow.withValues(alpha: 0.05),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: colors.primaryContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.note_alt_rounded,
                            size: 22,
                            color: colors.primary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Nawa',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: colors.onSurface,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: QrImageView(
                        data: qrData,
                        version: QrVersions.auto,
                        size: 220,
                        backgroundColor: Colors.white,
                        eyeStyle: QrEyeStyle(
                          eyeShape: QrEyeShape.square,
                          color: colors.primary,
                        ),
                        dataModuleStyle: const QrDataModuleStyle(
                          dataModuleShape: QrDataModuleShape.square,
                          color: Colors.black,
                        ),
                        errorCorrectionLevel: QrErrorCorrectLevel.M,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      displayName,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: colors.onSurface,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      handle,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'friends.my_qr_subtitle'.tr(),
              style: TextStyle(
                fontSize: 14,
                color: colors.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            if (!hasUsername) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colors.tertiaryContainer.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline,
                        size: 18, color: colors.onTertiaryContainer),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'friends.set_username_subtitle'.tr(),
                        style: TextStyle(
                          fontSize: 13,
                          color: colors.onTertiaryContainer,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.push(AppRoutes.usernameSetup),
                      child: Text('common.continue'.tr()),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _isProcessing ? null : _shareQr,
              icon: const Icon(Icons.share),
              label: Text('friends.share_qr'.tr()),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _isProcessing ? null : _saveQrToGallery,
              icon: const Icon(Icons.download),
              label: Text('friends.save_qr'.tr()),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Future<Uint8List?> _capture() => _screenshotController.capture(
        pixelRatio: 3.0,
        delay: const Duration(milliseconds: 50),
      );

  Future<void> _shareQr() async {
    setState(() => _isProcessing = true);
    try {
      final imageBytes = await _capture();
      if (imageBytes == null) throw Exception('capture_failed');

      final tempDir = await getTemporaryDirectory();
      final stamp = DateTime.now().millisecondsSinceEpoch;
      final file = File('${tempDir.path}/nawa_qr_$stamp.png');
      await file.writeAsBytes(imageBytes);

      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'friends.share_text'.tr(),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('common.error'.tr())),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _saveQrToGallery() async {
    setState(() => _isProcessing = true);
    try {
      final imageBytes = await _capture();
      if (imageBytes == null) throw Exception('capture_failed');

      final hasAccess = await Gal.hasAccess(toAlbum: true);
      if (!hasAccess) {
        final granted = await Gal.requestAccess(toAlbum: true);
        if (!granted) throw Exception('permission_denied');
      }

      await Gal.putImageBytes(
        imageBytes,
        album: 'Nawa',
        name: 'nawa_qr_${DateTime.now().millisecondsSinceEpoch}',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('friends.qr_saved'.tr()),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('common.error'.tr())),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }
}
