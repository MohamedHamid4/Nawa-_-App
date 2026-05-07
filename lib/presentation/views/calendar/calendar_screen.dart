import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../app/router.dart';
import '../../../domain/entities/note.dart';
import '../../viewmodels/notes_list_viewmodel.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  DateTime _focused = DateTime.now();
  DateTime? _selected;
  CalendarFormat _format = CalendarFormat.month;

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    final notes = ref.watch(notesListViewModelProvider).all;
    final selected = _selected ?? DateTime.now();
    final dayNotes = notes.where((n) {
      final d = n.reminderAt ?? n.updatedAt;
      return _isSameDay(d, selected);
    }).toList();

    Map<DateTime, List<Note>> grouped = {};
    for (final n in notes) {
      final d = n.reminderAt ?? n.updatedAt;
      final key = DateTime(d.year, d.month, d.day);
      grouped.putIfAbsent(key, () => []).add(n);
    }

    return Scaffold(
      appBar: AppBar(title: Text('calendar.title'.tr())),
      body: Column(
        children: [
          TableCalendar<Note>(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2100, 12, 31),
            focusedDay: _focused,
            selectedDayPredicate: (d) =>
                _selected != null && _isSameDay(d, _selected!),
            onDaySelected: (selected, focused) {
              setState(() {
                _selected = selected;
                _focused = focused;
              });
            },
            calendarFormat: _format,
            onFormatChanged: (f) => setState(() => _format = f),
            locale: context.locale.toLanguageTag(),
            eventLoader: (day) =>
                grouped[DateTime(day.year, day.month, day.day)] ?? const [],
            daysOfWeekHeight: 32,
            rowHeight: 56,
            daysOfWeekStyle: DaysOfWeekStyle(
              weekdayStyle: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.3,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              weekendStyle: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.3,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            calendarBuilders: CalendarBuilders<Note>(
              dowBuilder: (context, day) {
                final isAr = context.locale.languageCode == 'ar';
                const arFull = [
                  'الاثنين',
                  'الثلاثاء',
                  'الأربعاء',
                  'الخميس',
                  'الجمعة',
                  'السبت',
                  'الأحد',
                ];
                const enFull = [
                  'Monday',
                  'Tuesday',
                  'Wednesday',
                  'Thursday',
                  'Friday',
                  'Saturday',
                  'Sunday',
                ];
                final dayName = isAr
                    ? arFull[day.weekday - 1]
                    : enFull[day.weekday - 1];
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        dayName,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.3,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
              ),
              markerDecoration: BoxDecoration(
                color: Theme.of(context).colorScheme.tertiary,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: dayNotes.isEmpty
                ? Center(child: Text('calendar.no_notes_for_day'.tr()))
                : ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: dayNotes.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final n = dayNotes[i];
                      return Card(
                        child: ListTile(
                          title: Text(n.title.isEmpty
                              ? 'home.new_note'.tr()
                              : n.title),
                          subtitle: Text(
                            n.previewText(),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onTap: () => context.push(
                            '${AppRoutes.noteEditor}/${n.id}',
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
