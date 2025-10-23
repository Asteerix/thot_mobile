import 'package:flutter/material.dart';
import '../../../../../core/themes/app_colors.dart';
import '../../../../../core/themes/web_theme.dart';
import '../../../../../shared/widgets/web/web_scaffold.dart';
import '../../../../../shared/widgets/web/responsive_layout.dart';
import 'package:thot/core/infrastructure/dependency_injection.dart';
import '../../../../../features/admin/data/repositories/admin_repository_impl.dart';
import '../../../../../features/profile/domain/entities/user_profile.dart';
import '../../../../../features/media/utils/url_helper.dart';
class AdminJournalistsScreenWeb extends StatefulWidget {
  final String currentRoute;
  final Function(String route) onNavigate;
  const AdminJournalistsScreenWeb({
    super.key,
    required this.currentRoute,
    required this.onNavigate,
  });
  @override
  State<AdminJournalistsScreenWeb> createState() =>
      _AdminJournalistsScreenWebState();
}
class _AdminJournalistsScreenWebState extends State<AdminJournalistsScreenWeb>
    with SingleTickerProviderStateMixin {
  late final AdminRepositoryImpl _adminRepository;
  late TabController _tabController;
  List<UserProfile> _allJournalists = [];
  List<UserProfile> _pendingJournalists = [];
  List<UserProfile> _verifiedJournalists = [];
  bool _isLoading = true;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  @override
  void initState() {
    super.initState();
    _adminRepository = ServiceLocator.instance.adminRepository;
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
    _loadJournalists();
  }
  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }
  Future<void> _loadJournalists() async {
    setState(() => _isLoading = true);
    try {
      final result = await _adminRepository.getJournalists(
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
        status: null,
      );
      final journalistsList =
          result['data']?['journalists'] ?? result['journalists'] ?? [];
      final journalists = (journalistsList as List<dynamic>)
          .map((j) => UserProfile.fromJson(j is Map<String, dynamic> ? j : {}))
          .toList();
      journalists.sort((a, b) {
        if (a.pressCard != null &&
            a.pressCard!.isNotEmpty &&
            (b.pressCard == null || b.pressCard!.isEmpty)) {
          return -1;
        }
        if (b.pressCard != null &&
            b.pressCard!.isNotEmpty &&
            (a.pressCard == null || a.pressCard!.isEmpty)) {
          return 1;
        }
        return (a.name ?? a.username).compareTo(b.name ?? b.username);
      });
      if (!mounted) return;
      setState(() {
        _allJournalists = journalists;
        _pendingJournalists = journalists.where((j) => !j.isVerified).toList();
        _verifiedJournalists = journalists.where((j) => j.isVerified).toList();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: ${e.toString()}')),
      );
    }
  }
  Future<void> _verifyJournalist(UserProfile journalist) async {
    try {
      await _adminRepository.verifyJournalist(journalist.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Journaliste vérifié avec succès')),
      );
      _loadJournalists();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: ${e.toString()}')),
      );
    }
  }
  Future<void> _unverifyJournalist(UserProfile journalist) async {
    try {
      await _adminRepository.unverifyJournalist(journalist.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vérification retirée avec succès')),
      );
      _loadJournalists();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: ${e.toString()}')),
      );
    }
  }
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return WebScaffold(
      currentRoute: widget.currentRoute,
      onNavigate: widget.onNavigate,
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: WebTheme.maxContentWidth),
          padding: const EdgeInsets.all(WebTheme.xxl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.badge, size: 32, color: colorScheme.primary),
                  const SizedBox(width: WebTheme.md),
                  Text(
                    'Gestion des Journalistes',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: WebTheme.xl),
              SizedBox(
                width: 400,
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Rechercher un journaliste...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: colorScheme.surfaceContainerHighest,
                  ),
                  onChanged: (value) {
                    setState(() => _searchQuery = value);
                    _loadJournalists();
                  },
                ),
              ),
              const SizedBox(height: WebTheme.xl),
              TabBar(
                controller: _tabController,
                tabs: [
                  Tab(
                    text:
                        'Tous (${_allJournalists.length})',
                  ),
                  Tab(
                    text:
                        'En attente (${_pendingJournalists.length})',
                  ),
                  Tab(
                    text:
                        'Vérifiés (${_verifiedJournalists.length})',
                  ),
                ],
              ),
              const SizedBox(height: WebTheme.lg),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : TabBarView(
                        controller: _tabController,
                        children: [
                          _buildJournalistsList(_allJournalists, colorScheme),
                          _buildJournalistsList(
                              _pendingJournalists, colorScheme),
                          _buildJournalistsList(
                              _verifiedJournalists, colorScheme),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildJournalistsList(
      List<UserProfile> journalists, ColorScheme colorScheme) {
    if (journalists.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.badge_outlined, size: 64, color: colorScheme.outline),
            const SizedBox(height: WebTheme.md),
            Text(
              'Aucun journaliste trouvé',
              style: TextStyle(
                fontSize: 18,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }
    return SingleChildScrollView(
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: colorScheme.outlineVariant),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(WebTheme.md),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 80),
                  const Expanded(flex: 3, child: Text('Journaliste')),
                  const Expanded(flex: 2, child: Text('Email')),
                  const Expanded(flex: 2, child: Text('Carte de presse')),
                  const Expanded(flex: 1, child: Text('Statut')),
                  const SizedBox(width: 200, child: Text('Actions')),
                ],
              ),
            ),
            ...journalists.map((journalist) =>
                _buildJournalistRow(journalist, colorScheme)),
          ],
        ),
      ),
    );
  }
  Widget _buildJournalistRow(UserProfile journalist, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(WebTheme.md),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: colorScheme.outlineVariant, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: CircleAvatar(
              radius: 24,
              backgroundImage: journalist.profilePicture != null
                  ? NetworkImage(
                      UrlHelper.getImageUrl(journalist.profilePicture!))
                  : null,
              child: journalist.profilePicture == null
                  ? const Icon(Icons.person)
                  : null,
            ),
          ),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  journalist.name ?? journalist.username,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  '@${journalist.username}',
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              journalist.email,
              style: const TextStyle(fontSize: 13),
            ),
          ),
          Expanded(
            flex: 2,
            child: journalist.pressCard?.isNotEmpty == true
                ? Row(
                    children: [
                      Icon(Icons.check_circle,
                          size: 16, color: AppColors.success),
                      const SizedBox(width: 4),
                      const Text('Fournie', style: TextStyle(fontSize: 13)),
                    ],
                  )
                : Row(
                    children: [
                      Icon(Icons.warning, size: 16, color: AppColors.orange),
                      const SizedBox(width: 4),
                      const Text('Manquante', style: TextStyle(fontSize: 13)),
                    ],
                  ),
          ),
          Expanded(
            flex: 1,
            child: journalist.isVerified
                ? Chip(
                    label: const Text('Vérifié'),
                    backgroundColor: AppColors.success.withOpacity(0.1),
                    labelStyle: TextStyle(
                      color: AppColors.success,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                  )
                : Chip(
                    label: const Text('En attente'),
                    backgroundColor: AppColors.orange.withOpacity(0.1),
                    labelStyle: TextStyle(
                      color: AppColors.orange,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                  ),
          ),
          SizedBox(
            width: 200,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (journalist.pressCard?.isNotEmpty == true)
                  Tooltip(
                    message: 'Voir la carte de presse',
                    child: IconButton(
                      icon: const Icon(Icons.image, size: 20),
                      onPressed: () {
                        _showPressCardDialog(journalist);
                      },
                    ),
                  ),
                if (journalist.isVerified)
                  Tooltip(
                    message: 'Retirer la vérification',
                    child: IconButton(
                      icon: const Icon(Icons.cancel, size: 20),
                      color: AppColors.error,
                      onPressed: () => _unverifyJournalist(journalist),
                    ),
                  )
                else
                  Tooltip(
                    message: 'Vérifier',
                    child: IconButton(
                      icon: const Icon(Icons.check_circle, size: 20),
                      color: AppColors.success,
                      onPressed: () => _verifyJournalist(journalist),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  void _showPressCardDialog(UserProfile journalist) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
          padding: const EdgeInsets.all(WebTheme.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Carte de presse - ${journalist.name ?? journalist.username}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: WebTheme.lg),
              Expanded(
                child: Image.network(
                  UrlHelper.getImageUrl(journalist.pressCard!),
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const Center(
                    child: Text('Erreur lors du chargement de l\'image'),
                  ),
                ),
              ),
              const SizedBox(height: WebTheme.lg),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Fermer'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}