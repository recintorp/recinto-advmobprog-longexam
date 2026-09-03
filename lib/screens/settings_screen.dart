import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/user_service.dart';
import '../providers/theme_provider.dart';
import 'signin_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final UserService _userService = UserService();

  Future<void> _handleLogout() async {
    await _userService.logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const SigninScreen()),
      (route) => false,
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(subtitle, style: TextStyle(fontSize: 14, color: theme.hintColor)),
        ],
      ),
    );
  }

  Widget _buildListTile(IconData icon, String title, {VoidCallback? onTap, Color? iconColor, Color? textColor}) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final defaultColor = isDark ? Colors.white : Colors.black87;

    return ListTile(
      leading: Icon(icon, color: iconColor ?? theme.iconTheme.color, size: 26),
      title: Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: textColor ?? defaultColor)),
      onTap: onTap ?? () {},
    );
  }

  Widget _buildSwitchTile(IconData icon, String title, bool value, ValueChanged<bool> onChanged) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final defaultColor = isDark ? Colors.white : Colors.black87;

    return SwitchListTile(
      secondary: Icon(icon, color: theme.iconTheme.color, size: 26),
      title: Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: defaultColor)),
      value: value,
      activeThumbColor: Colors.brown,
      onChanged: onChanged,
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final fieldFillColor = isDark ? Colors.grey[800] : Colors.grey[200];

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Settings & privacy', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(icon: Icon(Icons.search, color: theme.iconTheme.color), onPressed: () {}),
        ],
      ),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search settings',
                prefixIcon: Icon(Icons.search, color: theme.iconTheme.color),
                filled: true,
                fillColor: fieldFillColor,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const Divider(thickness: 1, height: 1),
          _buildSectionHeader('Tools and resources', 'Our tools help you control and manage your privacy.'),
          _buildListTile(Icons.lock_outline, 'Privacy Checkup'),
          _buildListTile(Icons.family_restroom, 'Family Center'),
          _buildListTile(Icons.settings_outlined, 'Default audience settings'),
          const Divider(thickness: 1, height: 32),
          _buildSectionHeader('Preferences', 'Customize your experience on Moppibook.'),
          _buildSwitchTile(
            Icons.dark_mode_outlined,
            'Dark Mode',
            themeProvider.isDarkMode,
            (value) => themeProvider.toggleTheme(value),
          ),
          _buildListTile(Icons.tune, 'Content preferences'),
          _buildListTile(Icons.thumb_up_alt_outlined, 'Reaction preferences'),
          _buildListTile(Icons.notifications_none, 'Notifications'),
          _buildListTile(Icons.accessibility_new, 'Accessibility'),
          _buildListTile(Icons.push_pin_outlined, 'Tab bar'),
          _buildListTile(Icons.language, 'Language and region'),
          const Divider(thickness: 1, height: 32),
          _buildListTile(
            Icons.logout,
            'Sign Out',
            iconColor: Colors.red,
            textColor: Colors.red,
            onTap: _handleLogout,
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}