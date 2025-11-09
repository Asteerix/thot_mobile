import 'package:flutter/material.dart';
import '../../../../../core/themes/web_theme.dart';
import '../../../../../shared/widgets/web/web_scaffold.dart';
import '../../../../../shared/widgets/web/web_two_column_layout.dart'
    as web_layout;
class SettingsScreenWeb extends StatefulWidget {
  final String currentRoute;
  final Function(String route) onNavigate;
  const SettingsScreenWeb({
    super.key,
    required this.currentRoute,
    required this.onNavigate,
  });
  @override
  State<SettingsScreenWeb> createState() => _SettingsScreenWebState();
}
class _SettingsScreenWebState extends State<SettingsScreenWeb> {
  String _selectedSection = 'account';
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return WebScaffold(
      currentRoute: widget.currentRoute,
      onNavigate: widget.onNavigate,
      body: web_layout.WebTwoColumnLayout(
        leftColumnWidth: 280,
        leftColumn: _buildSettingsMenu(context, colorScheme),
        rightColumn: _buildSettingsContent(context, colorScheme),
        padding: const EdgeInsets.all(WebTheme.xl),
      ),
    );
  }
  Widget _buildSettingsMenu(BuildContext context, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Settings',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: WebTheme.xl),
        _buildMenuItem(context, 'Account', 'account', Icons.person),
        _buildMenuItem(context, 'Privacy', 'privacy', Icons.lock),
        _buildMenuItem(context, 'Notifications', 'notifications',
            Icons.notifications),
        _buildMenuItem(
            context, 'Appearance', 'appearance', Icons.palette),
        _buildMenuItem(
            context, 'Accessibility', 'accessibility', Icons.accessibility),
        _buildMenuItem(context, 'Language', 'language', Icons.language),
        const SizedBox(height: WebTheme.lg),
        Divider(color: colorScheme.outline),
        const SizedBox(height: WebTheme.lg),
        _buildMenuItem(context, 'Help & Support', 'help', Icons.help_outline),
        _buildMenuItem(context, 'About', 'about', Icons.info),
      ],
    );
  }
  Widget _buildMenuItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final isSelected = _selectedSection == value;
    return Material(
      color: isSelected
          ? colorScheme.primaryContainer
          : Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(WebTheme.borderRadiusMedium),
      child: InkWell(
        onTap: () => setState(() => _selectedSection = value),
        borderRadius: BorderRadius.circular(WebTheme.borderRadiusMedium),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: WebTheme.md,
            vertical: WebTheme.md,
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 22,
                color: isSelected
                    ? colorScheme.onPrimaryContainer
                    : colorScheme.onSurface.withOpacity(0.7),
              ),
              const SizedBox(width: WebTheme.md),
              Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected
                      ? colorScheme.onPrimaryContainer
                      : colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildSettingsContent(BuildContext context, ColorScheme colorScheme) {
    switch (_selectedSection) {
      case 'account':
        return _buildAccountSettings(context, colorScheme);
      case 'privacy':
        return _buildPrivacySettings(context, colorScheme);
      case 'notifications':
        return _buildNotificationSettings(context, colorScheme);
      case 'appearance':
        return _buildAppearanceSettings(context, colorScheme);
      default:
        return _buildAccountSettings(context, colorScheme);
    }
  }
  Widget _buildAccountSettings(BuildContext context, ColorScheme colorScheme) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Account Settings',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: WebTheme.xl),
          _buildSettingCard(
            context,
            colorScheme,
            'Profile Information',
            'Update your name, username, and bio',
            Icons.edit,
            () {},
          ),
          _buildSettingCard(
            context,
            colorScheme,
            'Email Address',
            'johndoe@example.com',
            Icons.mail,
            () {},
          ),
          _buildSettingCard(
            context,
            colorScheme,
            'Change Password',
            'Update your password',
            Icons.lock,
            () {},
          ),
          _buildSettingCard(
            context,
            colorScheme,
            'Delete Account',
            'Permanently delete your account and data',
            Icons.delete,
            () {},
            isDestructive: true,
          ),
        ],
      ),
    );
  }
  Widget _buildPrivacySettings(BuildContext context, ColorScheme colorScheme) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Privacy Settings',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: WebTheme.xl),
          _buildSwitchSetting(
            context,
            colorScheme,
            'Private Account',
            'Only approved followers can see your posts',
            false,
            (value) {},
          ),
          _buildSwitchSetting(
            context,
            colorScheme,
            'Activity Status',
            'Show when you\'re active',
            true,
            (value) {},
          ),
          _buildSwitchSetting(
            context,
            colorScheme,
            'Read Receipts',
            'Let people know when you\'ve read their messages',
            true,
            (value) {},
          ),
        ],
      ),
    );
  }
  Widget _buildNotificationSettings(
      BuildContext context, ColorScheme colorScheme) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Notification Settings',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: WebTheme.xl),
          _buildSwitchSetting(
            context,
            colorScheme,
            'Push Notifications',
            'Receive push notifications',
            true,
            (value) {},
          ),
          _buildSwitchSetting(
            context,
            colorScheme,
            'Email Notifications',
            'Receive email updates',
            false,
            (value) {},
          ),
          _buildSwitchSetting(
            context,
            colorScheme,
            'Comment Notifications',
            'Get notified when someone comments',
            true,
            (value) {},
          ),
        ],
      ),
    );
  }
  Widget _buildAppearanceSettings(
      BuildContext context, ColorScheme colorScheme) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Appearance Settings',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: WebTheme.xl),
          _buildSwitchSetting(
            context,
            colorScheme,
            'Dark Mode',
            'Enable dark theme',
            false,
            (value) {},
          ),
        ],
      ),
    );
  }
  Widget _buildSettingCard(
    BuildContext context,
    ColorScheme colorScheme,
    String title,
    String description,
    IconData icon,
    VoidCallback onTap, {
    bool isDestructive = false,
  }) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: WebTheme.md),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(WebTheme.borderRadiusMedium),
        side: BorderSide(color: colorScheme.outline.withOpacity(0.2)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(WebTheme.borderRadiusMedium),
        child: Padding(
          padding: const EdgeInsets.all(WebTheme.lg),
          child: Row(
            children: [
              Icon(
                icon,
                color: isDestructive ? colorScheme.error : colorScheme.primary,
                size: 24,
              ),
              const SizedBox(width: WebTheme.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDestructive
                            ? colorScheme.error
                            : colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 14,
                        color: colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: colorScheme.onSurface.withOpacity(0.3),
              ),
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildSwitchSetting(
    BuildContext context,
    ColorScheme colorScheme,
    String title,
    String description,
    bool value,
    Function(bool) onChanged,
  ) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: WebTheme.md),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(WebTheme.borderRadiusMedium),
        side: BorderSide(color: colorScheme.outline.withOpacity(0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(WebTheme.lg),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      color: colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }
}