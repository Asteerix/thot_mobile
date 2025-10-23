import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:go_router/go_router.dart';
import 'package:thot/core/navigation/route_names.dart';
class AboutScreen extends StatelessWidget {
  AboutScreen({super.key}) : _packageInfoFuture = PackageInfo.fromPlatform();
  final Future<PackageInfo> _packageInfoFuture;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            HapticFeedback.selectionClick();
            context.pop();
          },
        ),
        title: const Text(
          'À propos',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const _Header(),
                  const SizedBox(height: 20),
                  FutureBuilder<PackageInfo>(
                    future: _packageInfoFuture,
                    builder: (context, snapshot) {
                      final version = snapshot.data?.version ?? '—';
                      final buildNumber = snapshot.data?.buildNumber ?? '—';
                      return _VersionChip(
                          version: version, buildNumber: buildNumber);
                    },
                  ),
                  const SizedBox(height: 24),
                  const _DescriptionCard(),
                  const SizedBox(height: 32),
                  const _SectionHeader('Ressources'),
                  const SizedBox(height: 12),
                  LinkTile(
                    icon: Icons.language,
                    title: 'Site web',
                    subtitle: 'thot-app.com',
                    onTap: () => _launchExternal(
                      context,
                      Uri.parse('https://thot-app.com'),
                      mode: LaunchMode.externalApplication,
                    ),
                  ),
                  LinkTile(
                    icon: Icons.privacy_tip_outlined,
                    title: 'Politique de confidentialité',
                    subtitle: 'Données, stockage et droits',
                    onTap: () => context.push(RouteNames.privacyPolicy),
                  ),
                  LinkTile(
                    icon: Icons.description_outlined,
                    title: 'Conditions d\'utilisation',
                    subtitle: 'Règles et obligations',
                    onTap: () => context.push(RouteNames.termsOfService),
                  ),
                  const SizedBox(height: 24),
                  const _SectionHeader('Contact'),
                  const SizedBox(height: 12),
                  LinkTile(
                    icon: Icons.email_outlined,
                    title: 'Équipe support',
                    subtitle: 'support@thot-app.com',
                    onTap: () => _composeEmail(
                      context,
                      'support@thot-app.com',
                      subject: 'À propos de THOT',
                    ),
                    onLongPress: () => _copyToClipboard(
                      context,
                      'support@thot-app.com',
                      label: 'Adresse copiée',
                    ),
                  ),
                  const SizedBox(height: 40),
                  const _Footer(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
class _Header extends StatelessWidget {
  const _Header();
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 2,
            ),
          ),
          child: const Icon(Icons.newspaper, size: 64, color: Colors.white),
        ),
        const SizedBox(height: 20),
        const Text(
          'THOT',
          style: TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }
}
class _VersionChip extends StatelessWidget {
  const _VersionChip({required this.version, required this.buildNumber});
  final String version;
  final String buildNumber;
  @override
  Widget build(BuildContext context) {
    final text = 'Version $version ($buildNumber)';
    return InkWell(
      onLongPress: () =>
          _copyToClipboard(context, text, label: 'Version copiée'),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withOpacity(0.2),
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
class _DescriptionCard extends StatelessWidget {
  const _DescriptionCard();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
        ),
      ),
      child: Column(
        children: [
          Icon(Icons.info_outline, size: 36, color: Colors.white.withOpacity(0.9)),
          const SizedBox(height: 16),
          Text(
            'THOT est une plateforme de journalisme citoyen permettant aux journalistes professionnels de publier des contenus vérifiés et aux citoyens de s\'informer en toute transparence.',
            textAlign: TextAlign.center,
            style: TextStyle(
              height: 1.6,
              color: Colors.white.withOpacity(0.7),
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}
class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.text);
  final String text;
  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          letterSpacing: 1.2,
          color: Colors.white.withOpacity(0.5),
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}
class LinkTile extends StatelessWidget {
  const LinkTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.onLongPress,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
        ),
      ),
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              _IconBadge(icon: icon),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Colors.white.withOpacity(0.3),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
class _IconBadge extends StatelessWidget {
  const _IconBadge({required this.icon});
  final IconData icon;
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
        ),
      ),
      child: Icon(icon, color: Colors.white.withOpacity(0.9), size: 22),
    );
  }
}
class _Footer extends StatelessWidget {
  const _Footer();
  @override
  Widget build(BuildContext context) {
    final year = DateTime.now().year;
    return Column(
      children: [
        Text(
          '© $year THOT. Tous droits réservés.',
          style: TextStyle(
            color: Colors.white.withOpacity(0.4),
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Fait avec soin pour un journalisme libre',
          style: TextStyle(
            color: Colors.white.withOpacity(0.4),
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}
Future<void> _launchExternal(
  BuildContext context,
  Uri uri, {
  LaunchMode mode = LaunchMode.platformDefault,
}) async {
  try {
    if (await canLaunchUrl(uri)) {
      final ok = await launchUrl(uri, mode: mode);
      if (!ok && context.mounted) {
        _showSnack(context, 'Impossible d\'ouvrir ${uri.toString()}');
      }
    } else if (context.mounted) {
      _showSnack(context, 'Aucune application compatible pour ${uri.scheme}');
    }
  } catch (e) {
    if (context.mounted) _showSnack(context, 'Erreur: $e');
  }
}
Future<void> _composeEmail(
  BuildContext context,
  String to, {
  String? subject,
  String? body,
}) async {
  final uri = Uri(
    scheme: 'mailto',
    path: to,
    queryParameters: {
      if (subject != null) 'subject': subject,
      if (body != null) 'body': body,
    },
  );
  await _launchExternal(context, uri);
}
Future<void> _copyToClipboard(
  BuildContext context,
  String text, {
  required String label,
}) async {
  await Clipboard.setData(ClipboardData(text: text));
  if (context.mounted) _showSnack(context, label);
}
void _showSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: Colors.white.withOpacity(0.1),
      behavior: SnackBarBehavior.floating,
    ),
  );
}