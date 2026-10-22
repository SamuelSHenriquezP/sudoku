import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../managers/audio_manager.dart';
import '../managers/game_storage.dart';
import 'tutorial_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  int _played = 0;
  int _won = 0;
  int _maestroWon = 0;
  bool _musicOn = AudioManager.isMusicOn;
  bool _sfxOn = AudioManager.isSfxOn;
  bool _hapticOn = AudioManager.isHapticOn;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  void _loadStats() async {
    final stats = await GameStorage.getStats();
    if (mounted) {
      setState(() {
        _played = stats['played'] ?? 0;
        _won = stats['won'] ?? 0;
        _maestroWon = stats['maestroWon'] ?? 0;
      });
    }
  }

  Widget _sectionHeader(String text, ColorScheme colors) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 8, left: 16),
      child: Text(
        text,
        style: TextStyle(
          color: colors.secondary,
          fontWeight: FontWeight.bold,
          fontSize: 12,
          letterSpacing: 2,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Ajustes",
          style: TextStyle(color: colors.primary, letterSpacing: 2),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: colors.primary),
      ),
      body: ListView(
        children: [
          _sectionHeader("AUDIO Y VIBRACIÓN", colors),
          SwitchListTile(
            title: Text("Música Zen", style: TextStyle(color: colors.primary)),
            subtitle: Text(
              "Sonido de fondo relajante",
              style: TextStyle(color: colors.primary.withAlpha(140), fontSize: 12),
            ),
            value: _musicOn,
            activeThumbColor: colors.primary,
            activeTrackColor: colors.secondary,
            onChanged: (val) {
              setState(() => _musicOn = val);
              AudioManager.toggleMusic(val);
            },
          ),
          SwitchListTile(
            title:
                Text("Efectos de Sonido", style: TextStyle(color: colors.primary)),
            subtitle: Text(
              "Sonidos al pulsar y al completar",
              style:
                  TextStyle(color: colors.primary.withAlpha(140), fontSize: 12),
            ),
            value: _sfxOn,
            activeThumbColor: colors.primary,
            activeTrackColor: colors.secondary,
            onChanged: (val) {
              setState(() => _sfxOn = val);
              AudioManager.toggleSFX(val);
            },
          ),
          SwitchListTile(
            title:
                Text("Respuesta Táctil", style: TextStyle(color: colors.primary)),
            subtitle: Text(
              "Vibración sutil al interactuar",
              style:
                  TextStyle(color: colors.primary.withAlpha(140), fontSize: 12),
            ),
            value: _hapticOn,
            activeThumbColor: colors.primary,
            activeTrackColor: colors.secondary,
            onChanged: (val) {
              setState(() => _hapticOn = val);
              AudioManager.toggleHaptic(val);
              if (val) AudioManager.vibrateLight();
            },
          ),

          _sectionHeader("ESTADÍSTICAS — MODO RETO", colors),
          _statRow("Partidas jugadas", "$_played", colors),
          _statRow("Partidas ganadas", "$_won", colors),
          _statRow("Victorias Maestro", "$_maestroWon / 10", colors,
              subtitle: _maestroWon >= 10
                  ? "💀 Diabólico desbloqueado"
                  : "Faltan ${10 - _maestroWon} para desbloquear Diabólico"),

          _sectionHeader("INFORMACIÓN Y PRIVACIDAD", colors),
          ListTile(
            leading: Icon(Icons.school_outlined, color: colors.primary),
            title: Text("Tutorial de Juego", style: TextStyle(color: colors.primary)),
            subtitle: Text(
              "Repasa las reglas y modos de Sudoku Zen",
              style: TextStyle(color: colors.primary.withAlpha(140), fontSize: 12),
            ),
            trailing: Icon(Icons.chevron_right, color: colors.primary.withAlpha(140)),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (ctx) => TutorialScreen(
                    onFinished: () => Navigator.pop(ctx),
                  ),
                ),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.privacy_tip_outlined, color: colors.primary),
            title: Text("Política de Privacidad", style: TextStyle(color: colors.primary)),
            subtitle: Text(
              "Uso de datos locales, permisos y Google AdMob",
              style: TextStyle(color: colors.primary.withAlpha(140), fontSize: 12),
            ),
            trailing: Icon(Icons.chevron_right, color: colors.primary.withAlpha(140)),
            onTap: () => _showPrivacyPolicyDialog(context, colors),
          ),
          ListTile(
            leading: Icon(Icons.tune_outlined, color: colors.primary),
            title: Text("Preferencias de Anuncios", style: TextStyle(color: colors.primary)),
            subtitle: Text(
              "Gestionar consentimiento de publicidad (GDPR / UMP)",
              style: TextStyle(color: colors.primary.withAlpha(140), fontSize: 12),
            ),
            trailing: Icon(Icons.chevron_right, color: colors.primary.withAlpha(140)),
            onTap: () => _manageAdConsent(context),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Future<void> _manageAdConsent(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final status = await ConsentInformation.instance.getPrivacyOptionsRequirementStatus();
      if (status == PrivacyOptionsRequirementStatus.required) {
        ConsentForm.showPrivacyOptionsForm((formError) {
          if (formError != null) {
            messenger.showSnackBar(
              SnackBar(content: Text("No se pudo abrir el formulario: ${formError.message}")),
            );
          }
        });
      } else {
        messenger.showSnackBar(
          const SnackBar(
            content: Text("Las opciones adicionales de consentimiento GDPR no son requeridas en tu región actual."),
          ),
        );
      }
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text("Opciones de consentimiento no disponibles sin conexión."),
        ),
      );
    }
  }

  void _showPrivacyPolicyDialog(BuildContext context, ColorScheme colors) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.surface,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        title: Text(
          "Política de Privacidad",
          style: TextStyle(
            color: colors.primary,
            fontWeight: FontWeight.bold,
            fontFamily: 'Serif',
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Sudoku Zen — Inventus Tech Studio\nContacto: samuelshenriquezp@gmail.com",
                style: TextStyle(
                  color: colors.secondary,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "1. Almacenamiento Local\n"
                "Tu progreso de partida, estadísticas del Modo Reto, pergaminos desbloqueados y ajustes de sonido o tema se guardan exclusivamente en tu dispositivo mediante SharedPreferences. No solicitamos cuentas de usuario ni recopilamos datos personales como nombre, correo o contactos.\n\n"
                "2. Publicidad (Google AdMob)\n"
                "Para mantener la aplicación gratuita, Sudoku Zen utiliza el SDK oficial de Google AdMob para mostrar anuncios (banners, intersticiales y videos bonificados opcionales). AdMob puede utilizar el Identificador de Publicidad de tu dispositivo Android (AD_ID) y datos de diagnóstico para mostrar anuncios relevantes y prevenir fraude.\n\n"
                "3. Consentimiento y Control\n"
                "En regiones sujetas a normativas de privacidad (como el EEE y Reino Unido), puedes gestionar tu consentimiento publicitario en cualquier momento desde la opción «Preferencias de Anuncios» en esta pantalla de Ajustes. Puedes borrar todos tus datos locales desinstalando la aplicación o limpiando el almacenamiento desde los ajustes de Android.",
                style: TextStyle(
                  color: colors.primary.withAlpha(210),
                  fontSize: 13,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
        actions: [
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: colors.primary,
              foregroundColor: colors.surface,
              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text("ENTENDIDO"),
          ),
        ],
      ),
    );
  }

  Widget _statRow(String label, String value, ColorScheme colors,
      {String? subtitle}) {
    return ListTile(
      title: Text(label, style: TextStyle(color: colors.primary)),
      subtitle: subtitle != null
          ? Text(subtitle,
              style: TextStyle(
                  color: colors.secondary.withAlpha(200), fontSize: 12))
          : null,
      trailing: Text(
        value,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: colors.primary,
        ),
      ),
    );
  }
}
