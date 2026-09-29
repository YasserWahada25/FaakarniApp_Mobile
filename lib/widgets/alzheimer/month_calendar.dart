import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_decorations.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/formatters.dart';

/// Month grid used by the consultation calendar and the reservations page.
/// Each day shows up to three colored dots (one per event) and a "+n" count.
class MonthCalendar extends StatelessWidget {
  const MonthCalendar({
    super.key,
    required this.month,
    required this.onPreviousMonth,
    required this.onNextMonth,
    required this.dotsForDay,
    required this.onDayTap,
    this.selectedDay,
    this.locale = 'en',
    this.accentColor = ModuleColors.alzheimer,
  });

  final DateTime month;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;

  /// Colors of the events of a given day.
  final List<Color> Function(DateTime day) dotsForDay;
  final ValueChanged<DateTime> onDayTap;
  final DateTime? selectedDay;
  final String locale;
  final Color accentColor;

  static const List<String> _weekDaysEn = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
  static const List<String> _weekDaysFr = ['Dim', 'Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam'];

  List<DateTime> _days() {
    final first = DateTime(month.year, month.month);
    final start = first.subtract(Duration(days: first.weekday % 7));
    return [for (var i = 0; i < 42; i++) DateTime(start.year, start.month, start.day + i)];
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final weekDays = locale == 'fr' ? _weekDaysFr : _weekDaysEn;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: AppDecorations.card(borderColor: AppColors.borderViolet),
      child: Column(
        children: [
          Row(
            children: [
              IconButton.filledTonal(
                tooltip: locale == 'fr' ? 'Mois précédent' : 'Previous month',
                onPressed: onPreviousMonth,
                icon: const Icon(Icons.chevron_left_rounded),
              ),
              Expanded(
                child: Text(
                  Formatters.monthYear(month, locale: locale),
                  textAlign: TextAlign.center,
                  style: text.titleLarge?.copyWith(color: AppColors.textInk),
                ),
              ),
              IconButton.filledTonal(
                tooltip: locale == 'fr' ? 'Mois suivant' : 'Next month',
                onPressed: onNextMonth,
                icon: const Icon(Icons.chevron_right_rounded),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              for (final d in weekDays)
                Expanded(
                  child: Text(
                    d,
                    textAlign: TextAlign.center,
                    style: text.labelSmall?.copyWith(color: AppColors.textSecondary),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          GridView.count(
            crossAxisCount: 7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 0.82,
            children: [for (final day in _days()) _dayCell(context, day)],
          ),
        ],
      ),
    );
  }

  Widget _dayCell(BuildContext context, DateTime day) {
    final text = Theme.of(context).textTheme;
    final inMonth = day.month == month.month;
    final isToday = day.isToday;
    final isSelected = selectedDay != null && day.isSameDay(selectedDay!);
    final dots = dotsForDay(day);
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xxs),
      child: Material(
        color: isSelected
            ? accentColor.withValues(alpha: 0.12)
            : (dots.isNotEmpty ? AppColors.bgMain : AppColors.transparent),
        borderRadius: AppRadius.smAll,
        child: InkWell(
          borderRadius: AppRadius.smAll,
          onTap: () => onDayTap(day),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: AppSizes.calendarDay,
                height: AppSizes.calendarDay,
                alignment: Alignment.center,
                decoration: isToday ? BoxDecoration(color: accentColor, shape: BoxShape.circle) : null,
                child: Text(
                  '${day.day}',
                  style: text.bodySmall?.copyWith(
                    fontWeight: isToday || isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isToday
                        ? AppColors.white
                        : inMonth
                            ? AppColors.textMain
                            : AppColors.border,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xxs),
              SizedBox(
                height: AppSizes.dot,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (final c in dots.take(3))
                      Container(
                        width: AppSizes.dot - 2,
                        height: AppSizes.dot - 2,
                        margin: const EdgeInsets.symmetric(horizontal: 1),
                        decoration: BoxDecoration(color: c, shape: BoxShape.circle),
                      ),
                  ],
                ),
              ),
              if (dots.length > 3)
                Text('+${dots.length - 3}', style: AppTypography.micro),
            ],
          ),
        ),
      ),
    );
  }
}
