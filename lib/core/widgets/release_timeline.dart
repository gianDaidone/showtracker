import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class ReleaseTimeline<T extends Object> extends StatelessWidget {
  final List<T> items;
  final DateTime? Function(T item) dateFor;
  final Key Function(T item) keyFor;
  final Widget Function(BuildContext context, T item) cardBuilder;
  final DateTime now;

  const ReleaseTimeline({
    super.key,
    required this.items,
    required this.now,
    required this.dateFor,
    required this.keyFor,
    required this.cardBuilder,
  });

  static const _weekdays = [
    'Lunedì',
    'Martedì',
    'Mercoledì',
    'Giovedì',
    'Venerdì',
    'Sabato',
    'Domenica',
  ];
  static const _months = [
    'Gen',
    'Feb',
    'Mar',
    'Apr',
    'Mag',
    'Giu',
    'Lug',
    'Ago',
    'Set',
    'Ott',
    'Nov',
    'Dic',
  ];

  String _dayLabel(DateTime day) {
    final today = DateUtils.dateOnly(now);
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final weekday = day == today
        ? 'Oggi'
        : day == tomorrow
            ? 'Domani'
            : _weekdays[day.weekday - 1];
    final year = day.year == now.year ? '' : ' ${day.year}';
    return '$weekday · ${day.day} ${_months[day.month - 1]}$year';
  }

  @override
  Widget build(BuildContext context) {
    final byDay = <DateTime?, List<T>>{};
    for (final item in items) {
      final date = dateFor(item);
      final day = date == null ? null : DateUtils.dateOnly(date.toLocal());
      (byDay[day] ??= []).add(item);
    }

    final rows = <({Key key, String? label, T? item})>[];
    final days = byDay.keys.whereType<DateTime>().toList()..sort();
    for (final day in [...days, if (byDay.containsKey(null)) null]) {
      rows.add((
        key: ValueKey(day),
        label: day == null ? 'Data da annunciare' : _dayLabel(day),
        item: null,
      ));
      for (final item in byDay[day]!) {
        rows.add((key: keyFor(item), label: null, item: item));
      }
    }
    final rowIndices = {
      for (final (index, row) in rows.indexed) row.key: index
    };

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final row = rows[index];
                final item = row.item;
                return Stack(
                  key: row.key,
                  children: [
                    Positioned(
                      left: 5,
                      top: index == 0 ? 19 : 0,
                      bottom: 0,
                      width: 1,
                      child: const ColoredBox(color: AppColors.divider),
                    ),
                    if (item == null)
                      Positioned(
                        left: 1,
                        top: 15,
                        child: Container(
                          width: 9,
                          height: 9,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.accent,
                          ),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.only(left: 20),
                      child: item == null
                          ? Padding(
                              padding: const EdgeInsets.symmetric(vertical: 9),
                              child: Semantics(
                                header: true,
                                child: Text(
                                  row.label!,
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            )
                          : Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: cardBuilder(context, item),
                            ),
                    ),
                  ],
                );
              },
              childCount: rows.length,
              findChildIndexCallback: (key) => rowIndices[key],
            ),
          ),
        ),
      ],
    );
  }
}
