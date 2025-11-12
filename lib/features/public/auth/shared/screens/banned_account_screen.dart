import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:thot/shared/widgets/branding/logo.dart';
import 'package:thot/core/routing/route_names.dart';

class BannedAccountScreen extends StatefulWidget {
  final String? reason;
  final String? message;
  final DateTime? suspendedUntil;
  final bool isSuspended;
  final VoidCallback? onContactSupport;
  final VoidCallback? onOpenRules;
  final VoidCallback? onLogout;
  const BannedAccountScreen({
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
  State<BannedAccountScreen> createState() => _BannedAccountScreenState();
}

class _BannedAccountScreenState extends State<BannedAccountScreen>
    with TickerProviderStateMixin {
  late final AnimationController _pulse;
  Timer? _ticker;
  Duration? _remaining;
  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1600),
      lowerBound: 0.95,
      upperBound: 1.05,
    )..repeat(reverse: true);
    _initTickerIfNeeded();
  }

  void _initTickerIfNeeded() {
    if (widget.isSuspended && widget.suspendedUntil != null) {
      _updateRemaining();
      _ticker = Timer.periodic(Duration(seconds: 1), (_) {
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
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isSuspended = widget.isSuspended;
    final statusColor = isSuspended ? scheme.tertiary : scheme.error;
    final headerIcon = isSuspended ? Icons.hourglass_empty : Icons.block;
    final title = isSuspended ? 'Compte suspendu' : 'Compte banni';
    return Scaffold(
      backgroundColor: scheme.surface,
      body: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
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
            ),
          ),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  child: Column(
                    children: [
                      const SizedBox(height: 16),
                      const Hero(tag: 'logo', child: Logo()),
                      const SizedBox(height: 24),
                      _GradientBorder(
                        color: statusColor,
                        radius: 16,
                        child: Card(
                          elevation: 0,
                          clipBehavior: Clip.antiAlias,
                          color: scheme.surface,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Container(
                                padding:
                                    const EdgeInsets.fromLTRB(24, 28, 24, 20),
                                color: statusColor.withOpacity(0.08),
                                child: Column(
                                  children: [
                                    ScaleTransition(
                                      scale: _pulse,
                                      child: Semantics(
                                        label: isSuspended
                                            ? 'Compte suspendu'
                                            : 'Compte banni',
                                        child: Icon(
                                          headerIcon,
                                          size: 56,
                                          color: statusColor,
                                          semanticLabel: null,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      title,
                                      textAlign: TextAlign.center,
                                      style: theme.textTheme.headlineSmall
                                          ?.copyWith(
                                        color: statusColor,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.all(24),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      isSuspended
                                          ? 'Votre compte est temporairement restreint.'
                                          : 'Votre compte est définitivement désactivé.',
                                      style:
                                          theme.textTheme.bodyLarge?.copyWith(
                                        color: scheme.onSurface,
                                      ),
                                    ),
                                    if (widget.reason != null &&
                                        widget.reason!.trim().isNotEmpty) ...[
                                      const SizedBox(height: 20),
                                      _InfoTile(
                                        icon: Icons.gavel,
                                        label: 'Raison',
                                        accent: scheme.error,
                                        child: _SelectableCopy(
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
                                      const SizedBox(height: 12),
                                      _InfoTile(
                                        icon: Icons.forum,
                                        label: 'Message de l\'administrateur',
                                        accent: scheme.primary,
                                        child: _SelectableCopy(
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
                                      const SizedBox(height: 16),
                                      _DeadlinePill(
                                        until: widget.suspendedUntil!,
                                        remaining: _remaining,
                                        scheme: scheme,
                                        theme: theme,
                                      ),
                                    ],
                                    const SizedBox(height: 28),
                                    if (!isSuspended)
                                      Center(
                                        child: Text(
                                          'Si vous pensez qu\'il s\'agit d\'une erreur, ouvrez une demande au support.',
                                          textAlign: TextAlign.center,
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                            color: scheme.onSurfaceVariant,
                                          ),
                                        ),
                                      ),
                                    const SizedBox(height: 16),
                                    _Actions(
                                      onHome: () =>
                                          context.go(RouteNames.welcome),
                                      onSupport: widget.onContactSupport,
                                      onRules: widget.onOpenRules,
                                      onLogout: widget.onLogout,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GradientBorder extends StatelessWidget {
  final Widget child;
  final Color color;
  final double radius;
  const _GradientBorder({
    required this.child,
    required this.color,
    this.radius = 16,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.55), color.withOpacity(0.18)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Container(
        margin: EdgeInsets.all(1.5),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(radius - 1),
        ),
        child: child,
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color accent;
  final Widget child;
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.accent,
    required this.child,
  });
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withOpacity(0.25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withOpacity(0.28), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, size: 22, color: accent),
            const SizedBox(width: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: accent,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const Spacer(),
          ]),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _SelectableCopy extends StatelessWidget {
  final String text;
  final TextStyle? textStyle;
  final String onCopiedTooltip;
  const _SelectableCopy({
    required this.text,
    required this.textStyle,
    required this.onCopiedTooltip,
  });
  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: SelectableText(
            text,
            style: textStyle,
          ),
        ),
        const SizedBox(width: 8),
        Tooltip(
          message: 'Copier',
          child: IconButton(
            icon: Icon(Icons.copy, size: 18),
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: text));
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(onCopiedTooltip),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _DeadlinePill extends StatelessWidget {
  final DateTime until;
  final Duration? remaining;
  final ColorScheme scheme;
  final ThemeData theme;
  const _DeadlinePill({
    required this.until,
    required this.remaining,
    required this.scheme,
    required this.theme,
  });
  String _two(int n) => n.toString().padLeft(2, '0');
  @override
  Widget build(BuildContext context) {
    final rem = remaining;
    final done = rem == Duration.zero;
    final label = done
        ? 'Suspension terminée'
        : 'Jusqu\'au ${_formatAbsoluteDate(context, until)}';
    final countdown = (rem == null || done)
        ? null
        : '${rem.inDays}j ${_two(rem.inHours % 24)}h ${_two(rem.inMinutes % 60)}m ${_two(rem.inSeconds % 60)}s';
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: scheme.tertiaryContainer.withOpacity(0.25),
        border: Border.all(color: scheme.tertiary.withOpacity(0.35)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(Icons.schedule, size: 18, color: scheme.tertiary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    )),
                if (countdown != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    countdown,
                    style: theme.textTheme.titleMedium?.copyWith(
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

  String _formatAbsoluteDate(BuildContext context, DateTime dt) {
    final l10n = MaterialLocalizations.of(context);
    final date = l10n.formatFullDate(dt);
    final time = l10n.formatTimeOfDay(
      TimeOfDay.fromDateTime(dt),
      alwaysUse24HourFormat: true,
    );
    return '$date à $time';
  }
}

class _Actions extends StatelessWidget {
  final VoidCallback onHome;
  final VoidCallback? onSupport;
  final VoidCallback? onRules;
  final VoidCallback? onLogout;
  const _Actions({
    required this.onHome,
    this.onSupport,
    this.onRules,
    this.onLogout,
  });
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 56,
          child: FilledButton(
            onPressed: onHome,
            child: const Text('Retour à l\'accueil'),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onSupport,
                icon: Icon(Icons.help_outline),
                label: const Text('Support'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onRules,
                icon: Icon(Icons.article),
                label: const Text('Règles'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.center,
          child: TextButton.icon(
            onPressed: onLogout,
            icon: Icon(Icons.logout, color: scheme.onSurfaceVariant),
            label: Text(
              'Déconnexion',
              style: theme.textTheme.labelLarge?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
