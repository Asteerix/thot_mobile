import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/themes/web_theme.dart';
import '../../../../../core/navigation/route_names.dart';
import '../../shared/widgets/gradient_border_card.dart';
import '../../shared/widgets/info_tile.dart';
import '../../shared/widgets/selectable_copy_text.dart';
class BannedAccountScreenWeb extends StatefulWidget {
  final String? reason;
  final String? message;
  final DateTime? suspendedUntil;
  final bool isSuspended;
  final VoidCallback? onContactSupport;
  final VoidCallback? onOpenRules;
  final VoidCallback? onLogout;
  const BannedAccountScreenWeb({
    super.key,
    this.reason,
    this.message,
    this.suspendedUntil,
    this.isSuspended = false,
    this.onContactSupport,
    this.onOpenRules,
    this.onLogout,
  });
  @override
  State<BannedAccountScreenWeb> createState() => _BannedAccountScreenWebState();
}
class _BannedAccountScreenWebState extends State<BannedAccountScreenWeb> {
  Timer? _ticker;
  Duration? _remaining;
  @override
  void initState() {
    super.initState();
    _initTickerIfNeeded();
  }
  void _initTickerIfNeeded() {
    if (widget.isSuspended && widget.suspendedUntil != null) {
      _updateRemaining();
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        setState(_updateRemaining);
      });
    }
  }
  void _updateRemaining() {
    final until = widget.suspendedUntil!;
    final diff = until.difference(DateTime.now());
    _remaining = diff.isNegative ? Duration.zero : diff;
  }
  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
  String _two(int n) => n.toString().padLeft(2, '0');
  String _formatAbsoluteDate(BuildContext context, DateTime dt) {
    final l10n = MaterialLocalizations.of(context);
    final date = l10n.formatFullDate(dt);
    final time = l10n.formatTimeOfDay(
      TimeOfDay.fromDateTime(dt),
      alwaysUse24HourFormat: true,
    );
    return '$date à $time';
  }
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isSuspended = widget.isSuspended;
    final statusColor = isSuspended ? scheme.tertiary : scheme.error;
    final headerIcon = isSuspended ? Icons.hourglass_top_rounded : Icons.block;
    final title = isSuspended ? 'Compte suspendu' : 'Compte banni';
    return Scaffold(
      backgroundColor: scheme.surface,
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0, -0.6),
            radius: 1.1,
            colors: [
              scheme.surfaceContainerHighest.withOpacity(0.20),
              scheme.surface,
            ],
            stops: const [0.0, 1.0],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 600),
              padding: const EdgeInsets.all(WebTheme.xxl),
              child: GradientBorderCard(
                color: statusColor,
                radius: 20,
                child: Card(
                  elevation: 0,
                  clipBehavior: Clip.antiAlias,
                  color: scheme.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: const EdgeInsets.fromLTRB(32, 40, 32, 28),
                        color: statusColor.withOpacity(0.08),
                        child: Column(
                          children: [
                            Icon(
                              headerIcon,
                              size: 64,
                              color: statusColor,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              title,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.headlineMedium?.copyWith(
                                color: statusColor,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isSuspended
                                  ? 'Votre compte est temporairement restreint.'
                                  : 'Votre compte est définitivement désactivé.',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: scheme.onSurface,
                                fontSize: 16,
                              ),
                            ),
                            if (widget.reason != null &&
                                widget.reason!.trim().isNotEmpty) ...[
                              const SizedBox(height: 24),
                              InfoTile(
                                icon: Icons.gavel_rounded,
                                label: 'Raison',
                                accent: scheme.error,
                                child: SelectableCopyText(
                                  text: widget.reason!,
                                  textStyle: theme.textTheme.bodyMedium
                                      ?.copyWith(
                                    height: 1.45,
                                    color: scheme.onSurface,
                                  ),
                                  onCopiedTooltip: 'Raison copiée',
                                ),
                              ),
                            ],
                            if (widget.message != null &&
                                widget.message!.trim().isNotEmpty) ...[
                              const SizedBox(height: 16),
                              InfoTile(
                                icon: Icons.message_outlined,
                                label: 'Message de l\'administrateur',
                                accent: scheme.primary,
                                child: SelectableCopyText(
                                  text: widget.message!,
                                  textStyle: theme.textTheme.bodyMedium
                                      ?.copyWith(
                                    height: 1.45,
                                    color: scheme.onSurfaceVariant,
                                  ),
                                  onCopiedTooltip: 'Message copié',
                                ),
                              ),
                            ],
                            if (isSuspended &&
                                widget.suspendedUntil != null) ...[
                              const SizedBox(height: 20),
                              _buildDeadlinePill(scheme, theme),
                            ],
                            const SizedBox(height: 32),
                            if (!isSuspended)
                              Center(
                                child: Text(
                                  'Si vous pensez qu\'il s\'agit d\'une erreur, ouvrez une demande au support.',
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            const SizedBox(height: 24),
                            _buildActions(scheme, theme),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
  Widget _buildDeadlinePill(ColorScheme scheme, ThemeData theme) {
    final rem = _remaining;
    final done = rem == Duration.zero;
    final label = done
        ? 'Suspension terminée'
        : 'Jusqu\'au ${_formatAbsoluteDate(context, widget.suspendedUntil!)}';
    final countdown = (rem == null || done)
        ? null
        : '${rem.inDays}j ${_two(rem.inHours % 24)}h ${_two(rem.inMinutes % 60)}m ${_two(rem.inSeconds % 60)}s';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: scheme.tertiaryContainer.withOpacity(0.25),
        border: Border.all(color: scheme.tertiary.withOpacity(0.35)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.schedule, size: 20, color: scheme.tertiary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    )),
                if (countdown != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    countdown,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: scheme.tertiary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildActions(ColorScheme scheme, ThemeData theme) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: WebTheme.buttonHeightLarge,
          child: FilledButton(
            onPressed: () => context.go(RouteNames.welcome),
            child: const Text('Retour à l\'accueil'),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: widget.onContactSupport,
                icon: const Icon(Icons.help_center_outlined),
                label: const Text('Support'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, WebTheme.buttonHeightLarge),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: widget.onOpenRules,
                icon: const Icon(Icons.rule_folder_outlined),
                label: const Text('Règles'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, WebTheme.buttonHeightLarge),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextButton.icon(
          onPressed: widget.onLogout,
          icon: Icon(Icons.logout, color: scheme.onSurfaceVariant),
          label: Text(
            'Déconnexion',
            style: theme.textTheme.labelLarge?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}