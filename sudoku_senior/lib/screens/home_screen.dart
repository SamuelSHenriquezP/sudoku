import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../managers/game_storage.dart';
import '../managers/ad_manager.dart';
import '../managers/audio_manager.dart';
import '../widgets/zen_background.dart';
import '../widgets/stats_dialog.dart';
import '../widgets/daily_calendar.dart';
import 'game_screen.dart';
import 'settings_screen.dart';
import 'collection_screen.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback onThemeChanged;

  const HomeScreen({super.key, required this.onThemeChanged});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  bool _hasSavedGame = false;
  bool _diabolicoUnlocked = false;
  int _maestroWins = 0;
  bool _isDailyCompletedToday = false;
  int _dailyStreak = 0;

  BannerAd? _bannerAd;
  bool _isBannerLoaded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkState();
    _loadBanner();
  }

  void _loadBanner() {
    final ad = BannerAd(
      adUnitId: AdManager.bannerId,
      // Tamaño adaptativo para que ocupe el ancho completo
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (mounted) setState(() => _isBannerLoaded = true);
        },
        onAdFailedToLoad: (ad, _) => ad.dispose(),
      ),
    )..load();
    _bannerAd = ad;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _checkState();
  }

  void _checkState() async {
    final state = await GameStorage.loadGameState();
    final unlocked = await GameStorage.isDiabolicoUnlocked();
    final maestroWins = await GameStorage.getMaestroWins();
    final dailyCompleted = await GameStorage.isDailyCompletedToday();
    final dailyStreak = await GameStorage.getDailyStreak();

    if (mounted) {
      setState(() {
        _hasSavedGame = state != null;
        _diabolicoUnlocked = unlocked;
        _maestroWins = maestroWins;
        _isDailyCompletedToday = dailyCompleted;
        _dailyStreak = dailyStreak;
      });
    }
  }

  void _startGame(
    BuildContext context,
    String mode,
    int difficulty, {
    int gridSize = 9,
  }) {
    AudioManager.playClick();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            GameScreen(mode: mode, difficulty: difficulty, gridSize: gridSize),
      ),
    ).then((_) => _checkState());
  }

  void _continueGame(BuildContext context) {
    AudioManager.playClick();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GameScreen(mode: 'continue', difficulty: 1),
      ),
    ).then((_) => _checkState());
  }

  void _showDifficultyDialog(BuildContext context, String mode) {
    final colors = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 30, vertical: 24),
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
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
            decoration: BoxDecoration(
              border: Border.all(color: colors.primary, width: 2.5),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  "SELECCIONA NIVEL",
                  style: TextStyle(
                    color: colors.primary,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Serif',
                    fontSize: 18,
                    letterSpacing: 4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                _difficultyTile(
                  ctx,
                  context,
                  "🌸  Principiante",
                  "41 pistas • Ideal para aprender",
                  mode,
                  1,
                  colors,
                ),
                _difficultyTile(
                  ctx,
                  context,
                  "🍃  Normal",
                  "32 pistas • Requiere atención",
                  mode,
                  2,
                  colors,
                ),
                _difficultyTile(
                  ctx,
                  context,
                  "⛩  Maestro",
                  "24 pistas • Dominio del tablero",
                  mode,
                  3,
                  colors,
                ),
                _difficultyTile(
                  ctx,
                  context,
                  "🌿  Aprendiz",
                  "Modo 4×4 • Tablero más sencillo",
                  'aprendiz',
                  0,
                  colors,
                  gridSize: 4,
                ),
                Divider(color: colors.primary.withAlpha(60), height: 24),
                _diabolicoTile(ctx, context, mode, colors),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.zero,
                      ),
                      side: BorderSide(color: colors.primary, width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () => Navigator.pop(ctx),
                    child: Text(
                      "CERRAR",
                      style: TextStyle(
                        color: colors.primary,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Serif',
                        letterSpacing: 2,
                      ),
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

  Widget _difficultyTile(
    BuildContext ctx,
    BuildContext screenCtx,
    String title,
    String subtitle,
    String mode,
    int difficulty,
    ColorScheme colors, {
    int gridSize = 9,
  }) {
    return ListTile(
      title: Text(
        title,
        style: TextStyle(
          color: colors.primary,
          fontWeight: FontWeight.bold,
          fontFamily: 'Serif',
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: colors.primary.withAlpha(140), fontSize: 12),
      ),
      onTap: () {
        Navigator.pop(ctx);
        _startGame(screenCtx, mode, difficulty, gridSize: gridSize);
      },
    );
  }

  Widget _diabolicoTile(
    BuildContext ctx,
    BuildContext screenCtx,
    String mode,
    ColorScheme colors,
  ) {
    if (_diabolicoUnlocked) {
      return ListTile(
        title: Text(
          "💀  Diabólico",
          style: TextStyle(
            color: colors.secondary,
            fontWeight: FontWeight.bold,
            fontFamily: 'Serif',
          ),
        ),
        subtitle: Text(
          "17 pistas • Para verdaderos maestros",
          style: TextStyle(
            color: colors.secondary.withAlpha(160),
            fontSize: 12,
          ),
        ),
        onTap: () {
          Navigator.pop(ctx);
          _startGame(screenCtx, mode, 4);
        },
      );
    } else {
      return ListTile(
        leading: Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: Icon(Icons.lock_outline, color: colors.primary.withAlpha(100)),
        ),
        title: Text(
          "💀  Diabólico",
          style: TextStyle(
            color: colors.primary.withAlpha(100),
            fontFamily: 'Serif',
          ),
        ),
        subtitle: Text(
          "Gana $_maestroWins/10 partidas Reto Maestro para desbloquear",
          style: TextStyle(color: colors.primary.withAlpha(80), fontSize: 11),
        ),
        onTap: () {
          ScaffoldMessenger.of(screenCtx).showSnackBar(
            SnackBar(
              content: Text(
                "Gana ${10 - _maestroWins} partidas más en Reto Maestro para desbloquear.",
              ),
              duration: const Duration(seconds: 2),
            ),
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmall = screenHeight < 700;

    return ZenBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          actions: [
            IconButton(
              icon: Icon(Icons.bar_chart_rounded, color: colors.primary),
              tooltip: "Estadísticas",
              onPressed: () {
                AudioManager.playClick();
                showStatsDialog(context);
              },
            ),
            IconButton(
              icon: Icon(Icons.settings, color: colors.primary),
              tooltip: "Ajustes",
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SettingsScreen(),
                  ),
                );
              },
            ),
            IconButton(
              icon: Icon(Icons.palette_outlined, color: colors.primary),
              tooltip: "Cambiar Tema",
              onPressed: widget.onThemeChanged,
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              // ── CABECERA ──────────────────────────────────────────
              Padding(
                padding: EdgeInsets.only(top: isSmall ? 4 : 10, bottom: 0),
                child: Column(
                  children: [
                    // Círculo Ensō con título superpuesto
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        // Círculo decorativo (referencia al Ensō del fondo)
                        Container(
                          width: isSmall ? 130 : 160,
                          height: isSmall ? 130 : 160,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: colors.surface.withAlpha(220),
                            border: Border.all(
                              color: colors.secondary.withAlpha(200),
                              width: 3,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: colors.secondary.withAlpha(30),
                                blurRadius: 16,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                        ),
                        // Kanji centrado
                        Text(
                          "数",
                          style: TextStyle(
                            fontSize: isSmall ? 46 : 56,
                            color: colors.primary,
                            fontFamily: 'Serif',
                            fontWeight: FontWeight.bold,
                            height: 1,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Títulos pegados al círculo
                    Text(
                      "S U D O K U",
                      style: TextStyle(
                        fontSize: isSmall ? 20 : 24,
                        fontWeight: FontWeight.w900,
                        color: colors.primary,
                        letterSpacing: 8,
                        height: 1.1,
                      ),
                    ),
                    Text(
                      "禅  Z E N",
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w400,
                        color: colors.secondary,
                        letterSpacing: 6,
                      ),
                    ),
                  ],
                ),
              ),

              // ── SEPARADOR CUADRICULADO ─────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                child: _gridDivider(colors),
              ),

              // ── OPCIONES DE JUEGO ──────────────────────────────────
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (_hasSavedGame) ...[
                              _buildContinueCard(context, colors),
                              const SizedBox(height: 8),
                            ],

                            // Reto del Día
                            _buildDailyChallengeCard(context, colors),
                            TextButton.icon(
                              onPressed: () => showDialog<void>(
                                context: context,
                                builder: (_) => const DailyCalendar(),
                              ),
                              icon: const Icon(Icons.calendar_month_outlined),
                              label: const Text('Calendario de sellos'),
                            ),
                            const SizedBox(height: 8),

                            // Opciones de juego
                            _buildModeSection(context, colors),

                            const SizedBox(height: 8),

                            // Biblioteca de sabiduría
                            _buildLibraryCard(context, colors),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              // ── PIE con cuadrícula decorativa ─────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: _gridDivider(colors),
              ),

              // ── BANNER PUBLICITARIO ────────────────────────────────
              if (_isBannerLoaded && _bannerAd != null)
                SizedBox(
                  width: double.infinity,
                  height: _bannerAd!.size.height.toDouble(),
                  child: AdWidget(ad: _bannerAd!),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Separador con patrón de cuadrícula (evoca papel milimetrado)
  Widget _gridDivider(ColorScheme colors) {
    return Row(
      children: List.generate(
        12,
        (i) => Expanded(
          child: Container(
            height: 1,
            color: i.isEven
                ? colors.primary.withAlpha(40)
                : colors.primary.withAlpha(15),
          ),
        ),
      ),
    );
  }

  /// Los dos modos en fila tipo cuadrícula
  Widget _buildModeSection(BuildContext context, ColorScheme colors) {
    return Column(children: [_buildModeRow(context, colors)]);
  }

  Widget _buildModeRow(BuildContext context, ColorScheme colors) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _buildModeCard(
              context,
              "MODO\nZEN",
              "Sin límite · Meditación",
              Icons.spa_outlined,
              () => _showDifficultyDialog(context, 'zen'),
              colors,
              accentColor: colors.secondary,
            ),
          ),
          Container(width: 1, color: colors.primary.withAlpha(25)),
          Expanded(
            child: _buildModeCard(
              context,
              "MODO\nRETO",
              "Tiempo · 3 errores máx.",
              Icons.timer_outlined,
              () => _showDifficultyDialog(context, 'reto'),
              colors,
              accentColor: colors.primary,
            ),
          ),
        ],
      ),
    );
  }

  static const List<String> _monthShortNames = [
    'ene',
    'feb',
    'mar',
    'abr',
    'may',
    'jun',
    'jul',
    'ago',
    'sep',
    'oct',
    'nov',
    'dic',
  ];

  String _formatTodayShort() {
    final now = DateTime.now();
    return '${now.day} ${_monthShortNames[now.month - 1]}';
  }

  void _onDailyChallengeTap(BuildContext context) async {
    final saved = await GameStorage.loadGameState();
    if (!context.mounted) return;
    if (saved?.mode == 'daily' &&
        saved?.dailyDate == GameStorage.formatDateKey(DateTime.now())) {
      _continueGame(context);
      return;
    }
    if (!_isDailyCompletedToday) {
      _startGame(context, 'daily', 2);
      return;
    }

    AudioManager.playClick();
    final colors = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          "Reto del Día completado",
          style: TextStyle(color: colors.primary, fontFamily: 'Serif'),
        ),
        content: Text(
          "Ya sellaste el reto de hoy (racha actual: $_dailyStreak ${_dailyStreak == 1 ? 'día' : 'días'}). ¿Deseas jugarlo de nuevo como práctica?",
          style: TextStyle(color: colors.primary.withAlpha(185)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cerrar"),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              _startGame(context, 'daily', 2);
            },
            child: const Text("Jugar de nuevo"),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyChallengeCard(BuildContext context, ColorScheme colors) {
    final completed = _isDailyCompletedToday;
    final accent = completed ? colors.primary : colors.secondary;

    return InkWell(
      onTap: () => _onDailyChallengeTap(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: completed
              ? colors.primary.withAlpha(10)
              : colors.secondary.withAlpha(16),
          border: Border.all(
            color: completed
                ? colors.primary.withAlpha(70)
                : colors.secondary.withAlpha(120),
            width: 1.4,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: accent.withAlpha(18),
                border: Border.all(color: accent.withAlpha(80)),
              ),
              child: Icon(
                completed ? Icons.verified_outlined : Icons.wb_sunny_outlined,
                size: 22,
                color: accent,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          "RETO DEL DÍA",
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w900,
                            color: colors.primary,
                            letterSpacing: 1.1,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: accent.withAlpha(24),
                          border: Border.all(
                            color: accent.withAlpha(90),
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          completed ? "COMPLETADO" : "PENDIENTE",
                          style: TextStyle(
                            fontSize: 8.5,
                            fontWeight: FontWeight.w800,
                            color: accent,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    completed
                        ? "${_formatTodayShort()} · Sello diario grabado"
                        : "${_formatTodayShort()} · Tablero único del día",
                    style: TextStyle(
                      fontSize: 10.5,
                      color: colors.primary.withAlpha(160),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Insignia de racha diaria
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: colors.secondary.withAlpha(16),
                border: Border.all(color: colors.secondary.withAlpha(90)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.local_fire_department_rounded,
                    size: 14,
                    color: colors.secondary,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    "$_dailyStreak",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: colors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContinueCard(BuildContext context, ColorScheme colors) {
    return InkWell(
      onTap: () => _continueGame(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: colors.secondary.withAlpha(18),
          border: Border.all(
            color: colors.secondary.withAlpha(100),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colors.secondary.withAlpha(25),
                border: Border.all(color: colors.secondary.withAlpha(80)),
              ),
              child: Icon(
                Icons.play_arrow_rounded,
                size: 24,
                color: colors.secondary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "CONTINUAR PARTIDA",
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: colors.primary,
                      letterSpacing: 1.2,
                    ),
                  ),
                  Text(
                    "Reanuda tu última meditación",
                    style: TextStyle(
                      fontSize: 11,
                      color: colors.primary.withAlpha(160),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: colors.secondary,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
    ColorScheme colors, {
    required Color accentColor,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        decoration: BoxDecoration(
          color: accentColor.withAlpha(10),
          border: Border.all(color: accentColor.withAlpha(60), width: 1.2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: accentColor.withAlpha(15),
                border: Border.all(color: accentColor.withAlpha(80), width: 1),
              ),
              child: Icon(icon, size: 26, color: accentColor),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: colors.primary,
                letterSpacing: 1,
                height: 1.2,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 10,
                color: colors.primary.withAlpha(140),
                height: 1.3,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLibraryCard(BuildContext context, ColorScheme colors) {
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const CollectionScreen()),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: colors.primary.withAlpha(8),
          border: Border.all(color: colors.primary.withAlpha(40), width: 1),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colors.primary.withAlpha(12),
                border: Border.all(color: colors.primary.withAlpha(50)),
              ),
              child: Icon(
                Icons.menu_book_outlined,
                size: 22,
                color: colors.primary,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "BIBLIOTECA DE SABIDURÍA",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: colors.primary,
                      letterSpacing: 1,
                    ),
                  ),
                  Text(
                    "Colecciona pergaminos y frases de iluminación",
                    style: TextStyle(
                      fontSize: 10,
                      color: colors.primary.withAlpha(150),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: colors.primary.withAlpha(120),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
