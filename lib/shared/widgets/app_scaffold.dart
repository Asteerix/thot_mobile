// ============================================================================
// FICHIER INUTILISÉ - Aucune référence dans la codebase
// ============================================================================
// Date d'analyse: 2025-10-03
// Raison: AppScaffold n'est jamais importé ni utilisé dans mobile/lib/
// Le fichier widgets.dart l'exporte mais aucun fichier n'importe AppScaffold
// L'application utilise bottom_nav_bar.dart à la place pour la navigation
//
// Ce fichier contient une implémentation alternative de scaffold avec:
// - Navigation Material 3 responsive (NavigationBar + NavigationRail)
// - IndexedStack pour préserver l'état des onglets
// - Effets de flou (BackdropFilter) pour la barre de navigation
// - Support badges de notification
// - FAB conditionnel pour journalistes
//
// Si vous souhaitez utiliser ce scaffold à l'avenir:
// 1. Vérifier la compatibilité avec l'architecture actuelle
// 2. Remplacer ou fusionner avec bottom_nav_bar.dart
// 3. Décommenter le code ci-dessous
// ============================================================================

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum AppTab { home, shorts, explore, profile }

/// Scaffold applicatif avec navigation M3 responsive.
/// - Mobile: NavigationBar floutée + FAB centré optionnel.
/// - Large screen (≥700px): NavigationRail latérale.
/// - Conserve l'état de chaque onglet via IndexedStack.
/// - Gère badges, haptique, re-tap = scroll-to-top.
class AppScaffold extends StatefulWidget {
  final bool isJournalist;
  final bool isAuthenticated;
  final AppTab initialTab;

  /// Vues par onglet. Fournir les 4; la logique d'accès masque selon l'état.
  final Map<AppTab, Widget> pages;

  /// Compteurs par onglet (ex: notifications).
  final Map<AppTab, int> badges;

  const AppScaffold({
    super.key,
    required this.pages,
    this.isJournalist = false,
    this.isAuthenticated = true,
    this.initialTab = AppTab.home,
    this.badges = const {},
  });

  @override
  State<AppScaffold> createState() => _AppScaffoldState();
}

class _AppScaffoldState extends State<AppScaffold> {
  late AppTab _current;

  @override
  void initState() {
    super.initState();
    _current = widget.initialTab;
  }

  @override
  Widget build(BuildContext context) {
    final destinations = _buildDestinations(context);
    final pages = _buildPages(destinations.tabs);

    final body = IndexedStack(
      index: destinations.tabs.indexOf(_current),
      children: pages,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final useRail = constraints.maxWidth >= 700;

        if (useRail) {
          return Scaffold(
            body: Row(
              children: [
                _Rail(
                  selected: _current,
                  onSelected: _onSelect,
                  destinations: destinations,
                ),
                const VerticalDivider(width: 1),
                Expanded(child: body),
              ],
            ),
            floatingActionButton: _fabIfJournalist(context),
            floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
          );
        }

        return Scaffold(
          body: body,
          floatingActionButton: _fabIfJournalist(context),
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerDocked,
          bottomNavigationBar: _FrostedNavigationBar(
            selectedIndex: destinations.tabs.indexOf(_current),
            destinations: destinations,
            onSelected: (i) => _onSelect(destinations.tabs[i]),
          ),
        );
      },
    );
  }

  void _onSelect(AppTab tab) {
    if (tab == _current) {
      // Re-tap = scroll to top si un PrimaryScrollController est disponible.
      final controller = PrimaryScrollController.maybeOf(context);
      controller?.animateTo(0,
          duration: const Duration(milliseconds: 280), curve: Curves.easeOut);
      return;
    }
    HapticFeedback.selectionClick();
    setState(() => _current = tab);
  }

  Widget? _fabIfJournalist(BuildContext context) {
    if (!widget.isJournalist) return null;
    return FloatingActionButton(
      onPressed: () {
        // Navigation vers l'écran de création de contenu à implémenter
      },
      tooltip: 'Nouveau contenu',
      child: Icon(Icons.add),
    );
  }

  /// Détermine les onglets visibles selon l'authentification.
  _Destinations _buildDestinations(BuildContext context) {
    // Produit: non-auth = uniquement Accueil + Explorer.
    final tabs = <AppTab>[
      AppTab.home,
      if (widget.isAuthenticated) AppTab.shorts,
      AppTab.explore,
      if (widget.isAuthenticated) AppTab.profile,
    ];

    final items = tabs.map((t) {
      final pair = _iconsFor(t);
      final count = widget.badges[t] ?? 0;
      return NavigationDestination(
        icon: _CountBadge(count: count, child: pair.$1),
        selectedIcon: _CountBadge(count: count, child: pair.$2),
        label: _labelFor(t),
        tooltip: _labelFor(t),
      );
    }).toList();

    return _Destinations(tabs: tabs, widgets: items);
  }

  /// Aligne les pages sur les onglets visibles.
  List<Widget> _buildPages(List<AppTab> tabs) {
    return tabs.map((t) => _keepAlive(widget.pages[t]!)).toList();
  }

  // Icônes cohérentes, outlined/filled pour états.
  (Widget, Widget) _iconsFor(AppTab t) {
    switch (t) {
      case AppTab.home:
        return (Icon(Icons.home), Icon(Icons.home));
      case AppTab.shorts:
        return (
          Icon(Icons.play_circle),
          Icon(Icons.play_circle)
        );
      case AppTab.explore:
        return (Icon(Icons.search), Icon(Icons.search));
      case AppTab.profile:
        return (Icon(Icons.person), Icon(Icons.person));
    }
  }

  String _labelFor(AppTab t) {
    switch (t) {
      case AppTab.home:
        return 'Accueil';
      case AppTab.shorts:
        return 'Shorts';
      case AppTab.explore:
        return 'Explorer';
      case AppTab.profile:
        return 'Profil';
    }
  }

  Widget _keepAlive(Widget child) => _KeepAlive(child: child);
}

/// NavigationBar M3 dans un conteneur « frosted » + séparation.
class _FrostedNavigationBar extends StatelessWidget {
  final int selectedIndex;
  final _Destinations destinations;
  final ValueChanged<int> onSelected;

  const _FrostedNavigationBar({
    required this.selectedIndex,
    required this.destinations,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final nav = NavigationBarTheme(
      data: NavigationBarThemeData(
        height: 80,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        indicatorShape: const StadiumBorder(),
        indicatorColor: theme.colorScheme.primary.withOpacity(0.12),
        // Laisse le parent gérer le fond (frosted + bordure)
        backgroundColor: Colors.transparent,
      ),
      child: NavigationBar(
        selectedIndex: selectedIndex,
        destinations: destinations.widgets,
        onDestinationSelected: onSelected,
      ),
    );

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.withOpacity(0.92),
            border: Border(
              top: BorderSide(color: theme.dividerColor.withOpacity(0.28)),
            ),
          ),
          child: SafeArea(top: false, child: nav),
        ),
      ),
    );
  }
}

/// NavigationRail pour grands écrans.
class _Rail extends StatelessWidget {
  final AppTab selected;
  final void Function(AppTab) onSelected;
  final _Destinations destinations;

  const _Rail({
    required this.selected,
    required this.onSelected,
    required this.destinations,
  });

  @override
  Widget build(BuildContext context) {
    final index = destinations.tabs.indexOf(selected);
    return NavigationRail(
      selectedIndex: index,
      onDestinationSelected: (i) => onSelected(destinations.tabs[i]),
      labelType: NavigationRailLabelType.selected,
      leading: const SizedBox(height: 8),
      trailing: const SizedBox(height: 8),
      destinations: destinations.widgets
          .map((d) => NavigationRailDestination(
                icon: d.icon,
                selectedIcon: d.selectedIcon,
                label: Text(d.label),
              ))
          .toList(),
    );
  }
}

/// Classe interne pour grouper destinations et onglets.
class _Destinations {
  final List<AppTab> tabs;
  final List<NavigationDestination> widgets;
  const _Destinations({required this.tabs, required this.widgets});
}

/// Badge numérique compact sans dépendance externe.
class _CountBadge extends StatelessWidget {
  final Widget child;
  final int count;
  const _CountBadge({required this.child, required this.count});

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return child;
    final color = Theme.of(context).colorScheme.error;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned(
          right: -6,
          top: -6,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Text(
              count > 99 ? '99+' : '$count',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 10,
                height: 1.2,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Garde la page en vie dans l'IndexedStack.
class _KeepAlive extends StatefulWidget {
  final Widget child;
  const _KeepAlive({required this.child});
  @override
  State<_KeepAlive> createState() => _KeepAliveState();
}

class _KeepAliveState extends State<_KeepAlive>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
