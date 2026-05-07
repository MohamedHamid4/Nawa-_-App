import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../core/extensions/extensions.dart';

class ReminderPicker {
  /// Show a smart reminder picker. Quick picks first, then optional custom date.
  static Future<DateTime?> show(BuildContext context,
      {DateTime? initial}) async {
    final selected = await showModalBottomSheet<DateTime?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: ctx.colors.surface,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: ctx.colors.outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'reminder.quick_picks'.tr(),
                style: ctx.text.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            _QuickPick(
              icon: Icons.access_time,
              label: 'reminder.in_one_hour'.tr(),
              onTap: () => Navigator.pop(
                ctx,
                DateTime.now().add(const Duration(hours: 1)),
              ),
            ),
            _QuickPick(
              icon: Icons.nights_stay_outlined,
              label: 'reminder.tonight'.tr(),
              onTap: () {
                final n = DateTime.now();
                Navigator.pop(
                  ctx,
                  DateTime(n.year, n.month, n.day, 20),
                );
              },
            ),
            _QuickPick(
              icon: Icons.wb_sunny_outlined,
              label: 'reminder.tomorrow_morning'.tr(),
              onTap: () {
                final t = DateTime.now().add(const Duration(days: 1));
                Navigator.pop(
                  ctx,
                  DateTime(t.year, t.month, t.day, 9),
                );
              },
            ),
            _QuickPick(
              icon: Icons.calendar_view_week_outlined,
              label: 'reminder.next_week'.tr(),
              onTap: () {
                final t = DateTime.now().add(const Duration(days: 7));
                Navigator.pop(
                  ctx,
                  DateTime(t.year, t.month, t.day, 9),
                );
              },
            ),
            const Divider(height: 24),
            _QuickPick(
              icon: Icons.event_outlined,
              label: 'reminder.custom_date'.tr(),
              onTap: () => Navigator.pop(ctx, _customSentinel),
            ),
              ],
            ),
          ),
        ),
      ),
    );
    if (selected == null) return null;
    if (selected == _customSentinel) {
      if (!context.mounted) return null;
      return _pickCustom(context, initial);
    }
    return selected;
  }

  static final DateTime _customSentinel = DateTime.fromMillisecondsSinceEpoch(0);

  static Future<DateTime?> _pickCustom(
      BuildContext context, DateTime? initial) async {
    final now = DateTime.now();
    final start = initial ?? now.add(const Duration(hours: 1));
    final date = await showDatePicker(
      context: context,
      initialDate: start.isBefore(now) ? now : start,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365 * 5)),
    );
    if (date == null) return null;
    if (!context.mounted) return null;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(start),
    );
    if (time == null) return null;
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }
}

class _QuickPick extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _QuickPick({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: context.colors.primary),
      title: Text(label),
      onTap: onTap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}
