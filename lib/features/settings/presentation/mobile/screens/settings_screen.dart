import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:thot/features/authentication/application/providers/auth_provider.dart';
import 'package:thot/core/navigation/route_names.dart';
import 'package:thot/core/utils/safe_navigation.dart';
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}
class _SettingsScreenState extends State<SettingsScreen> {
  bool notifEnabled = true;
  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (!mounted) return;
      SafeNavigation.showSnackBar(
        context,
        const SnackBar(
          content: Text('Ouverture impossible', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  Future<void> _handleLogout() async {
    HapticFeedback.lightImpact();
    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black87,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.black,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.1),
                  border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
                ),
                child: Icon(Icons.logout, color: Colors.white, size: 28),
              ),
              const SizedBox(height: 24),
              const Text(
                'Déconnexion',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Êtes-vous sûr de vouloir vous déconnecter ?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(color: Colors.white.withOpacity(0.3)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Annuler',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(ctx).pop(true),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Déconnexion',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (confirmed == true) {
      try {
        if (!mounted) return;
        await context.read<AuthProvider>().logout();
        if (!mounted) return;
        context.go(RouteNames.welcome);
      } catch (e) {
        if (!mounted) return;
        SafeNavigation.showSnackBar(
          context,
          SnackBar(
            content: Text('Erreur lors de la déconnexion: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  Future<void> _confirmDeleteAccount() async {
    HapticFeedback.mediumImpact();
    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black87,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.black,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.red.withOpacity(0.1),
                  border: Border.all(color: Colors.red.withOpacity(0.5), width: 2),
                ),
                child: Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
              ),
              const SizedBox(height: 24),
              const Text(
                'Supprimer le compte',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Cette action est irréversible. Toutes vos données seront définitivement supprimées.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(color: Colors.white.withOpacity(0.3)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Annuler',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(ctx).pop(true),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Supprimer',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (confirmed == true) {
      await _deleteAccount();
    }
  }
  Future<void> _deleteAccount() async {
    try {
      await context.read<AuthProvider>().deleteAccount();
    } catch (e) {
      if (!mounted) return;
      SafeNavigation.showSnackBar(
        context,
        SnackBar(
          content: Text('Erreur lors de la suppression: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () {
                        if (context.canPop()) {
                          context.pop();
                        } else {
                          context.go(RouteNames.feed);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.arrow_back,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    const Text(
                      'Paramètres',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: _ProfileCard(),
            ),
            SliverToBoxAdapter(
              child: Selector<AuthProvider, bool>(
                selector: (_, p) => (p.userProfile?.isJournalist ?? false) && (p.userProfile?.role == 'journalist'),
                builder: (_, isJournalist, __) {
                  return _SectionCard(
                    title: isJournalist ? 'Compte journaliste' : 'Mon compte',
                    children: [
                      _SettingTile(
                        icon: Icons.badge_outlined,
                        title: isJournalist ? 'Profil professionnel' : 'Mon profil',
                        subtitle: isJournalist
                            ? context.read<AuthProvider>().userProfile?.organization ?? 'Journaliste indépendant'
                            : '@${context.read<AuthProvider>().userProfile?.username ?? 'utilisateur'}',
                        onTap: () {
                          final user = context.read<AuthProvider>().userProfile;
                          if (user != null) {
                            context.push(RouteNames.editProfile, extra: user);
                          }
                        },
                      ),
                      if (isJournalist)
                        _SettingTile(
                          icon: Icons.analytics_outlined,
                          title: 'Statistiques',
                          subtitle: 'Performances du contenu',
                          onTap: () {
                            final id = context.read<AuthProvider>().userProfile?.id ?? '';
                            if (id.isNotEmpty) {
                              context.push(RouteNames.stats, extra: {'journalistId': id});
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Impossible de charger les statistiques', style: TextStyle(color: Colors.white)),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          },
                        ),
                      _SettingTile(
                        icon: Icons.bookmark_border,
                        title: 'Contenu enregistré',
                        subtitle: 'Articles, vidéos, podcasts',
                        onTap: () => context.push(RouteNames.savedContent),
                      ),
                    ],
                  );
                },
              ),
            ),
            SliverToBoxAdapter(
              child: _SectionCard(
                title: 'Sécurité',
                children: [
                  _SettingTile(
                    icon: Icons.lock_outline,
                    title: 'Mot de passe',
                    subtitle: 'Modifier le mot de passe',
                    onTap: () => context.push('/change-password'),
                  ),
                ],
              ),
            ),
            SliverToBoxAdapter(
              child: _SectionCard(
                title: 'Notifications',
                children: [
                  _SettingTileSwitcher(
                    icon: Icons.notifications_active_outlined,
                    title: 'Notifications',
                    subtitle: 'Activer/désactiver',
                    value: notifEnabled,
                    onChanged: (v) {
                      HapticFeedback.selectionClick();
                      setState(() => notifEnabled = v);
                    },
                  ),
                ],
              ),
            ),
            SliverToBoxAdapter(
              child: _SectionCard(
                title: 'Aide et support',
                children: [
                  _SettingTile(
                    icon: Icons.help_outline,
                    title: "Centre d'aide",
                    isExternal: true,
                    onTap: () => _launchURL('https://help.thot-app.com'),
                  ),
                  _SettingTile(
                    icon: Icons.bug_report_outlined,
                    title: 'Signaler un problème',
                    onTap: () => context.push(RouteNames.reportProblem),
                  ),
                  _SettingTile(
                    icon: Icons.description_outlined,
                    title: "Conditions d'utilisation",
                    onTap: () => context.push(RouteNames.termsOfService),
                  ),
                  _SettingTile(
                    icon: Icons.privacy_tip_outlined,
                    title: 'Politique de confidentialité',
                    onTap: () => context.push(RouteNames.privacyPolicy),
                  ),
                ],
              ),
            ),
            SliverToBoxAdapter(
              child: _SectionCard(
                title: 'À propos',
                children: [
                  _SettingTile(
                    icon: Icons.info_outline,
                    title: "Version de l'application",
                    subtitle: '1.0.0',
                    onTap: () => context.push(RouteNames.about),
                  ),
                ],
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        'ZONE SENSIBLE',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withOpacity(0.1)),
                      ),
                      child: Column(
                        children: [
                          _SettingTile(
                            icon: Icons.logout,
                            title: 'Se déconnecter',
                            subtitle: 'Fermer la session',
                            isDanger: true,
                            onTap: _handleLogout,
                          ),
                          Divider(height: 1, color: Colors.white.withOpacity(0.1)),
                          _SettingTile(
                            icon: Icons.delete_forever,
                            title: 'Supprimer le compte',
                            subtitle: 'Action irréversible',
                            isDanger: true,
                            onTap: _confirmDeleteAccount,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
class _ProfileCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final user = context.select<AuthProvider, dynamic>((p) => p.userProfile);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.1),
                border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
              ),
              child: Center(
                child: Text(
                  (user?.username?.isNotEmpty == true ? user!.username![0] : 'U').toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user?.displayName ?? 'Utilisateur',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user?.email ?? '',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () {
                if (user != null) {
                  context.push(RouteNames.editProfile, extra: user);
                }
              },
              icon: Icon(Icons.edit_outlined, color: Colors.white.withOpacity(0.7)),
            ),
          ],
        ),
      ),
    );
  }
}
class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _SectionCard({required this.title, required this.children});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(
              title.toUpperCase(),
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.2,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Column(
              children: _intersperseDividers(children),
            ),
          ),
        ],
      ),
    );
  }
  List<Widget> _intersperseDividers(List<Widget> tiles) {
    final out = <Widget>[];
    for (var i = 0; i < tiles.length; i++) {
      out.add(tiles[i]);
      if (i != tiles.length - 1) {
        out.add(Divider(height: 1, color: Colors.white.withOpacity(0.1)));
      }
    }
    return out;
  }
}
class _SettingTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final bool isExternal;
  final bool isDanger;
  const _SettingTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.isExternal = false,
    this.isDanger = false,
  });
  @override
  Widget build(BuildContext context) {
    final iconColor = isDanger ? Colors.red : Colors.white.withOpacity(0.7);
    final titleColor = isDanger ? Colors.red : Colors.white;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Icon(icon, color: iconColor, size: 24),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: titleColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle!,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                isExternal ? Icons.open_in_new : Icons.chevron_right,
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
class _SettingTileSwitcher extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;
  const _SettingTileSwitcher({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.value,
    this.onChanged,
  });
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Icon(icon, color: Colors.white.withOpacity(0.7), size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 14,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.white,
            activeTrackColor: Colors.white.withOpacity(0.3),
            inactiveThumbColor: Colors.white.withOpacity(0.5),
            inactiveTrackColor: Colors.white.withOpacity(0.1),
          ),
        ],
      ),
    );
  }
}