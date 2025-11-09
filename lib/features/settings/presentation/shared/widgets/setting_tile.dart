import 'package:flutter/material.dart';
class SettingTile extends StatelessWidget {
  final IconData leading;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool? value;
  final ValueChanged<bool>? onChanged;
  const SettingTile._({
    super.key,
    required this.leading,
    required this.title,
    this.subtitle,
    this.onTap,
    this.trailing,
    this.value,
    this.onChanged,
  });
  factory SettingTile.navigation({
    required IconData leading,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return SettingTile._(
      leading: leading,
      title: title,
      subtitle: subtitle,
      onTap: onTap,
      trailing: Icon(Icons.chevron_right),
    );
  }
  factory SettingTile.link({
    required IconData leading,
    required String title,
    required VoidCallback onTap,
  }) {
    return SettingTile._(
      leading: leading,
      title: title,
      onTap: onTap,
      trailing: Icon(Icons.open_in_new),
    );
  }
  factory SettingTile.switcher({
    required IconData leading,
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool>? onChanged,
  }) {
    return SettingTile._(
      leading: leading,
      title: title,
      subtitle: subtitle,
      value: value,
      onChanged: onChanged,
    );
  }
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final leadingIcon = Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: cs.secondaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(leading, color: cs.onSecondaryContainer),
    );
    final titleText = Text(
      title,
      style: theme.textTheme.bodyLarge?.copyWith(color: cs.onSurface),
    );
    final subtitleText = subtitle == null
        ? null
        : Text(
            subtitle!,
            style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
          );
    final isSwitch = value != null;
    return ListTile(
      leading: leadingIcon,
      title: titleText,
      subtitle: subtitleText,
      onTap: isSwitch ? null : onTap,
      trailing: isSwitch
          ? Switch.adaptive(value: value!, onChanged: onChanged)
          : trailing,
      minLeadingWidth: 0,
      visualDensity: VisualDensity.standard,
      horizontalTitleGap: 12,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
    );
  }
}