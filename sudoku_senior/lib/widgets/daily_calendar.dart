import 'package:flutter/material.dart';
import '../managers/game_storage.dart';

class DailyCalendar extends StatefulWidget {
  const DailyCalendar({super.key});

  @override
  State<DailyCalendar> createState() => _DailyCalendarState();
}

class _DailyCalendarState extends State<DailyCalendar> {
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  Set<String> _completed = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    GameStorage.getDailyCompletedDates().then((dates) {
      if (mounted) {
        setState(() {
          _completed = dates.toSet();
          _loading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    const months = [
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre',
    ];
    final today = DateTime.now();
    final days = DateTime(_month.year, _month.month + 1, 0).day;
    final offset = _month.weekday - 1;
    final colors = Theme.of(context).colorScheme;
    return AlertDialog(
      scrollable: true,
      constraints: const BoxConstraints(maxWidth: 380),
      title: const Text('Sellos del Reto del Día'),
      content: SizedBox(
        width: 320,
        child: _loading
            ? const SizedBox(
                height: 160,
                child: Center(child: CircularProgressIndicator()),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      IconButton(
                        tooltip: 'Mes anterior',
                        icon: const Icon(Icons.chevron_left),
                        onPressed: () => setState(
                          () =>
                              _month = DateTime(_month.year, _month.month - 1),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          '${months[_month.month - 1]} ${_month.year}',
                          textAlign: TextAlign.center,
                        ),
                      ),
                      IconButton(
                        tooltip: 'Mes siguiente',
                        icon: const Icon(Icons.chevron_right),
                        onPressed:
                            _month.year == today.year &&
                                _month.month == today.month
                            ? null
                            : () => setState(
                                () => _month = DateTime(
                                  _month.year,
                                  _month.month + 1,
                                ),
                              ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      for (final day in ['L', 'M', 'X', 'J', 'V', 'S', 'D'])
                        Expanded(child: Center(child: Text(day))),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Table(
                    children: [
                      for (
                        int week = 0;
                        week < (days + offset + 6) ~/ 7;
                        week++
                      )
                        TableRow(
                          children: [
                            for (int weekday = 0; weekday < 7; weekday++)
                              AspectRatio(
                                aspectRatio: 1,
                                child: _dayCell(
                                  week * 7 + weekday - offset + 1,
                                  days,
                                  today,
                                  colors,
                                ),
                              ),
                          ],
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Cada reto diario completado deja un sello. El círculo marca hoy.',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cerrar'),
        ),
      ],
    );
  }

  Widget _dayCell(int day, int days, DateTime today, ColorScheme colors) {
    if (day < 1 || day > days) return const SizedBox.shrink();
    final date = DateTime(_month.year, _month.month, day);
    final done = _completed.contains(GameStorage.formatDateKey(date));
    final isToday = DateUtils.isSameDay(date, today);
    return Semantics(
      label: '$day, ${done ? 'reto completado' : 'sin sello'}',
      child: Container(
        margin: const EdgeInsets.all(2),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: done ? colors.primaryContainer : null,
          border: isToday ? Border.all(color: colors.primary, width: 2) : null,
        ),
        child: done
            ? Icon(Icons.verified, color: colors.primary, size: 24)
            : Text('$day'),
      ),
    );
  }
}
