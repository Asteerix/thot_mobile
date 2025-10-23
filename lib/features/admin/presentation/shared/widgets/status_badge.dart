import 'package:flutter/material.dart';
import 'package:thot/core/constants/spacing_constants.dart';
import 'package:thot/features/admin/presentation/shared/utils/report_helpers.dart';
class StatusBadge extends StatelessWidget {
  final String? status;
  final double fontSize;
  const StatusBadge({
    super.key,
    required this.status,
    this.fontSize = 11,
  });
  @override
  Widget build(BuildContext context) {
    final color = ReportHelpers.getStatusColor(context, status);
    final label = ReportHelpers.getStatusLabel(status);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: SpacingConstants.space8,
        vertical: SpacingConstants.space4,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(SpacingConstants.space12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: fontSize,
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
class RoleChip extends StatelessWidget {
  final String role;
  final double fontSize;
  const RoleChip({
    super.key,
    required this.role,
    this.fontSize = 11,
  });
  @override
  Widget build(BuildContext context) {
    final color = UserRoleHelpers.getRoleColor(role);
    final label = UserRoleHelpers.getRoleLabel(role);
    return Chip(
      label: Text(label),
      backgroundColor: color.withOpacity(0.1),
      labelStyle: TextStyle(
        color: color,
        fontSize: fontSize,
        fontWeight: FontWeight.w600,
      ),
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
    );
  }
}
class ReasonChip extends StatelessWidget {
  final String reason;
  final double fontSize;
  final bool showIcon;
  const ReasonChip({
    super.key,
    required this.reason,
    this.fontSize = 11,
    this.showIcon = false,
  });
  @override
  Widget build(BuildContext context) {
    final color = ReportHelpers.getReasonColor(context, reason);
    final label = ReportHelpers.getReasonLabel(reason);
    return Chip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            Icon(Icons.flag, size: fontSize + 2, color: color),
            SizedBox(width: SpacingConstants.space4),
          ],
          Text(label),
        ],
      ),
      backgroundColor: color.withOpacity(0.1),
      labelStyle: TextStyle(
        color: color,
        fontSize: fontSize,
        fontWeight: FontWeight.w600,
      ),
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
    );
  }
}
class UserStatusBadge extends StatelessWidget {
  final bool isBanned;
  final double fontSize;
  const UserStatusBadge({
    super.key,
    required this.isBanned,
    this.fontSize = 11,
  });
  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(isBanned ? 'Banni' : 'Actif'),
      backgroundColor: isBanned
          ? Theme.of(context).colorScheme.error.withOpacity(0.1)
          : Theme.of(context).colorScheme.primary.withOpacity(0.1),
      labelStyle: TextStyle(
        color: isBanned
            ? Theme.of(context).colorScheme.error
            : Theme.of(context).colorScheme.primary,
        fontSize: fontSize,
        fontWeight: FontWeight.w600,
      ),
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
    );
  }
}