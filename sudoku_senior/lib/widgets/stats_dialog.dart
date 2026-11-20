import 'package:flutter/material.dart';
import '../managers/game_storage.dart';

/// Muestra el modal de Estadísticas desglosadas por los 4 niveles de dificultad.
Future<void> showStatsDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (ctx) => const StatsDialog(),
  );
}

class StatsDialog extends StatefulWidget {
  const StatsDialog({super.key});

  @override
  State<StatsDialog> createState() => _StatsDialogState();
}

class _StatsDialogState extends State<StatsDialog> {
  Map<int, DifficultyStats> _stats = {};
  int _dailyStreak = 0;
  int _dailyTotal = 0;
  bool _isLoading = true;

  static const Map<int, String> _levelLabels = {
    1: '🌸  Principiante',
    2: '🍃  Normal',
    3: '⛩  Maestro',
    4: '💀  Diabólico',
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final all = await GameStorage.getAllDifficultyStats();
    final streak = await GameStorage.getDailyStreak();
    final dailyDates = await GameStorage.getDailyCompletedDates();

    if (mounted) {
      setState(() {
        _stats = all;
        _dailyStreak = streak;
        _dailyTotal = dailyDates.length;
        _isLoading = false;
      });
    }
  }

  String _formatDuration(int? seconds) {
    if (seconds == null) return '—';
    final hours = seconds ~/ 3600;
    final mins = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;
    if (hours > 0) {
      return '${hours}h ${mins.toString().padLeft(2, '0')}m';
    }
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final totalWins = _stats.values.fold<int>(0, (acc, s) => acc + s.wins);
    final totalClean = _stats.values.fold<int>(
      0,
      (acc, s) => acc + s.cleanWins,
    );

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 420,
          maxHeight: MediaQuery.of(context).size.height * 0.84,
        ),
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: colors.surface,
            border: Border.all(
              color: colors.primary.withAlpha(128),
              width: 1.2,
            ),
          ),
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
            decoration: BoxDecoration(
              border: Border.all(color: colors.primary, width: 2.5),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'ESTADÍSTICAS',
                  style: TextStyle(
                    color: colors.primary,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Serif',
                    fontSize: 18,
                    letterSpacing: 4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else
                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildSummaryRow(
                            colors,
                            totalWins: totalWins,
                            totalClean: totalClean,
                          ),
                          const SizedBox(height: 12),
                          for (int level = 1; level <= 4; level++) ...[
                            _buildLevelCard(
                              colors,
                              _levelLabels[level] ?? 'Nivel $level',
                              _stats[level] ??
                                  DifficultyStats(difficulty: level),
                              isAccent: level == 4,
                            ),
                            if (level < 4) const SizedBox(height: 8),
                          ],
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 14),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero,
                    ),
                    side: BorderSide(color: colors.primary, width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'CERRAR',
                    style: TextStyle(
                      color: colors.primary,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Serif',
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(
    ColorScheme colors, {
    required int totalWins,
    required int totalClean,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: colors.secondary.withAlpha(14),
        border: Border.all(color: colors.secondary.withAlpha(80), width: 1),
      ),
      child: Row(
        children: [
          _summaryCell(colors, 'Victorias', '$totalWins'),
          _vDivider(colors),
          _summaryCell(colors, 'Limpias', '$totalClean'),
          _vDivider(colors),
          _summaryCell(colors, 'Racha día', '$_dailyStreak'),
          _vDivider(colors),
          _summaryCell(colors, 'Retos día', '$_dailyTotal'),
        ],
      ),
    );
  }

  Widget _vDivider(ColorScheme colors) {
    return Container(width: 1, height: 26, color: colors.primary.withAlpha(35));
  }

  Widget _summaryCell(ColorScheme colors, String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: colors.primary,
              fontSize: 15,
              fontWeight: FontWeight.w900,
              fontFamily: 'Serif',
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: colors.primary.withAlpha(150),
              fontSize: 9.5,
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildLevelCard(
    ColorScheme colors,
    String title,
    DifficultyStats stat, {
    bool isAccent = false,
  }) {
    final borderColor = isAccent
        ? colors.secondary.withAlpha(90)
        : colors.primary.withAlpha(45);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: colors.primary.withAlpha(8),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: isAccent ? colors.secondary : colors.primary,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Serif',
                  fontSize: 14,
                ),
              ),
              Text(
                '${stat.wins} ${stat.wins == 1 ? 'victoria' : 'victorias'}',
                style: TextStyle(
                  color: colors.primary.withAlpha(170),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _metricItem(
                colors,
                'Mejor tiempo',
                _formatDuration(stat.bestTimeSeconds),
              ),
              _metricItem(colors, 'Racha actual', '${stat.currentStreak}'),
              _metricItem(
                colors,
                'Limpias (0 err.)',
                '${stat.cleanWinPercent.toStringAsFixed(0)}% · ${stat.cleanWins}/${stat.wins}',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metricItem(ColorScheme colors, String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: colors.primary.withAlpha(135),
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              color: colors.primary,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
