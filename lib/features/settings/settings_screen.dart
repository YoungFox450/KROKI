import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/settings_provider.dart';
import 'terms_of_use_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('PARAMÈTRES', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2)),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _buildSectionHeader('GÉNÉRAL'),
          _buildSettingSwitch(
            'Effets sonores',
            'Sons du jeu et notifications',
            Icons.volume_up_rounded,
            settings.soundEnabled,
            (v) => notifier.toggleSound(v),
          ),
          _buildSettingSwitch(
            'Notifications',
            'Alertes de messages et invitations',
            Icons.notifications_rounded,
            settings.notificationsEnabled,
            (v) => notifier.toggleNotifications(v),
          ),
          const SizedBox(height: 24),
          _buildSectionHeader('APPARENCE'),
          _buildSettingSwitch(
            'Mode sombre',
            'Interface aux couleurs sombres',
            Icons.dark_mode_rounded,
            settings.darkMode,
            (v) => notifier.toggleDarkMode(v),
          ),
          const SizedBox(height: 24),
          _buildSectionHeader('À PROPOS'),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.info_outline_rounded, color: Colors.white38),
            title: const Text('Version', style: TextStyle(fontWeight: FontWeight.bold)),
            trailing: const Text('1.0.0', style: TextStyle(color: Colors.white38)),
          ),
          ListTile(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TermsOfUseScreen()),
              );
            },
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.description_outlined, color: Colors.white38),
            title: const Text('Conditions d\'utilisation', style: TextStyle(fontWeight: FontWeight.bold)),
            trailing: const Icon(Icons.chevron_right_rounded, color: Colors.white38),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: const TextStyle(color: Color(0xFF7C4DFF), fontWeight: FontWeight.bold, letterSpacing: 1.5, fontSize: 12),
      ),
    );
  }

  Widget _buildSettingSwitch(String title, String subtitle, IconData icon, bool value, Function(bool) onChanged) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: SwitchListTile(
          secondary: Icon(icon, color: Colors.white70),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.white38)),
          value: value,
          activeColor: const Color(0xFF7C4DFF),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
