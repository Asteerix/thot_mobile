import 'package:thot/core/presentation/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:thot/core/di/service_locator.dart';
import 'package:thot/features/admin/providers/admin_repository_impl.dart';
import 'package:thot/features/app/profile/models/user_profile.dart';
import 'package:thot/shared/media/utils/url_helper.dart';
import 'package:thot/shared/utils/responsive_utils.dart';
import 'package:thot/features/app/profile/widgets/badges.dart';
import 'package:thot/core/utils/safe_navigation.dart';
import 'package:thot/core/config/spacing_constants.dart';

class AdminJournalistsScreen extends StatefulWidget {
  const AdminJournalistsScreen({super.key});
  @override
  State<AdminJournalistsScreen> createState() => _AdminJournalistsScreenState();
}

class _AdminJournalistsScreenState extends State<AdminJournalistsScreen>
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
      SafeNavigation.showSnackBar(
        context,
        SnackBar(content: Text('Erreur: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ResponsiveUtils.isMobile(context)
          ? AppBar(
              title: const Text('Gestion des journalistes'),
              centerTitle: true,
              elevation: 0,
              bottom: PreferredSize(
                preferredSize: Size.fromHeight(
                    ResponsiveUtils.getAdaptiveSpacing(context,
                        mobile: 100, tablet: 110, desktop: 120)),
                child: Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: ResponsiveUtils.getAdaptivePadding(context),
                        vertical: SpacingConstants.space8,
                      ),
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText:
                              'Rechercher par nom, email, organisation...',
                          prefixIcon: Icon(Icons.search),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: Icon(Icons.close),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _searchQuery = '');
                                    _loadJournalists();
                                  },
                                )
                              : null,
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: SpacingConstants.space16),
                        ),
                        onChanged: (value) {
                          setState(() => _searchQuery = value);
                          _loadJournalists();
                        },
                      ),
                    ),
                    TabBar(
                      controller: _tabController,
                      tabs: [
                        Tab(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.group,
                                  size: ResponsiveUtils.getAdaptiveIconSize(
                                      context,
                                      small: 16,
                                      medium: 18,
                                      large: 20)),
                              SizedBox(width: SpacingConstants.space4),
                              Text(
                                'Tous (${_allJournalists.length})',
                                style: TextStyle(
                                  fontSize: ResponsiveUtils.getAdaptiveFontSize(
                                      context, 14),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Tab(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.hourglass_empty,
                                  size: ResponsiveUtils.getAdaptiveIconSize(
                                      context,
                                      small: 16,
                                      medium: 18,
                                      large: 20),
                                  color: AppColors.orange),
                              SizedBox(width: SpacingConstants.space4),
                              Text(
                                'Attente (${_pendingJournalists.length})',
                                style: TextStyle(
                                  fontSize: ResponsiveUtils.getAdaptiveFontSize(
                                      context, 14),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Tab(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              VerificationBadge(
                                  size: ResponsiveUtils.getAdaptiveIconSize(
                                      context,
                                      small: 16,
                                      medium: 18,
                                      large: 20)),
                              SizedBox(width: SpacingConstants.space4),
                              Text(
                                'Vérifiés (${_verifiedJournalists.length})',
                                style: TextStyle(
                                  fontSize: ResponsiveUtils.getAdaptiveFontSize(
                                      context, 14),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            )
          : null,
      body: IndexedStack(
        index: _tabController.index,
        children: [
          _buildJournalistsList(_allJournalists),
          _buildJournalistsList(_pendingJournalists),
          _buildJournalistsList(_verifiedJournalists),
        ],
      ),
    );
  }

  Widget _buildJournalistsList(List<UserProfile> journalists) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (journalists.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_off,
                size: ResponsiveUtils.getAdaptiveIconSize(context,
                    small: 48, medium: 56, large: 64),
                color: Theme.of(context).colorScheme.outline),
            SizedBox(height: SpacingConstants.space16),
            Text(
              'Aucun journaliste trouvé',
              style: TextStyle(
                  fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 16),
                  color: Theme.of(context).colorScheme.outline),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadJournalists,
      child: ListView.builder(
        padding: EdgeInsets.only(
          top: SpacingConstants.space8,
          bottom: ResponsiveUtils.getAdaptiveSpacing(context,
              mobile: 80, tablet: 100, desktop: 120),
        ),
        itemCount: journalists.length,
        itemBuilder: (context, index) {
          final journalist = journalists[index];
          return Card(
            margin: EdgeInsets.symmetric(
              horizontal: ResponsiveUtils.getAdaptivePadding(context),
              vertical: SpacingConstants.space4,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(SpacingConstants.space12),
              side: journalist.pressCard != null &&
                      journalist.pressCard!.isNotEmpty
                  ? BorderSide(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withOpacity(0.3),
                      width: 2)
                  : BorderSide.none,
            ),
            child: InkWell(
              onTap: () => _showJournalistDetails(journalist),
              borderRadius: BorderRadius.circular(SpacingConstants.space12),
              child: Padding(
                padding: EdgeInsets.all(
                    ResponsiveUtils.getAdaptiveCardPadding(context)),
                child: Row(
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius:
                              ResponsiveUtils.getAdaptiveAvatarRadius(context),
                          backgroundImage: journalist.avatarUrl != null
                              ? NetworkImage(UrlHelper.buildMediaUrl(
                                      journalist.avatarUrl) ??
                                  'https://via.placeholder.com/150')
                              : null,
                          child: journalist.avatarUrl == null
                              ? Icon(Icons.person)
                              : null,
                        ),
                        if (journalist.pressCard != null &&
                            journalist.pressCard!.isNotEmpty)
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              padding:
                                  EdgeInsets.all(SpacingConstants.space4 / 2),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surface,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 2,
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.verified,
                                size: ResponsiveUtils.getAdaptiveIconSize(
                                    context,
                                    small: 16,
                                    medium: 18,
                                    large: 20),
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ),
                      ],
                    ),
                    SizedBox(width: SpacingConstants.space12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              if (journalist.role == 'admin') ...[
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: SpacingConstants.space8,
                                    vertical: SpacingConstants.space4 / 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.red,
                                    borderRadius: BorderRadius.circular(
                                        SpacingConstants.space4),
                                  ),
                                  child: Text(
                                    'ADMIN',
                                    style: TextStyle(
                                      color:
                                          Theme.of(context).colorScheme.surface,
                                      fontSize:
                                          ResponsiveUtils.getAdaptiveFontSize(
                                              context, 10),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                SizedBox(width: SpacingConstants.space8),
                              ],
                              Expanded(
                                child: Text(
                                  journalist.name ?? journalist.username,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize:
                                        ResponsiveUtils.getAdaptiveFontSize(
                                            context, 16),
                                    decoration: journalist.status == 'banned'
                                        ? TextDecoration.lineThrough
                                        : null,
                                    color: journalist.status == 'banned'
                                        ? Theme.of(context).colorScheme.outline
                                        : null,
                                  ),
                                ),
                              ),
                              if (journalist.isVerified)
                                VerificationBadge(
                                    size: ResponsiveUtils.getAdaptiveIconSize(
                                        context,
                                        small: 16,
                                        medium: 18,
                                        large: 20)),
                            ],
                          ),
                          SizedBox(height: SpacingConstants.space4),
                          Text(
                            journalist.email,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.outline,
                              fontSize: ResponsiveUtils.getAdaptiveFontSize(
                                  context, 14),
                            ),
                          ),
                          if (journalist.organization != null) ...[
                            SizedBox(height: SpacingConstants.space4 / 2),
                            Text(
                              journalist.organization!,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.outline,
                                fontSize: ResponsiveUtils.getAdaptiveFontSize(
                                    context, 13),
                              ),
                            ),
                          ],
                          if (journalist.pressCard != null &&
                              journalist.pressCard!.isNotEmpty) ...[
                            SizedBox(height: SpacingConstants.space4),
                            Row(
                              children: [
                                Icon(Icons.verified,
                                    size: ResponsiveUtils.getAdaptiveIconSize(
                                        context,
                                        small: 14,
                                        medium: 16,
                                        large: 18),
                                    color:
                                        Theme.of(context).colorScheme.outline),
                                SizedBox(width: SpacingConstants.space4),
                                Expanded(
                                  child: Text(
                                    journalist.pressCard!,
                                    style: TextStyle(
                                      fontSize:
                                          ResponsiveUtils.getAdaptiveFontSize(
                                              context, 12),
                                      color:
                                          Theme.of(context).colorScheme.outline,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                          if (journalist.status == 'banned') ...[
                            SizedBox(height: SpacingConstants.space4),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: SpacingConstants.space8,
                                vertical: SpacingConstants.space4 / 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(
                                    SpacingConstants.space12),
                                border: Border.all(
                                    color: AppColors.red.withOpacity(0.3)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.block,
                                      size: ResponsiveUtils.getAdaptiveIconSize(
                                          context,
                                          small: 12,
                                          medium: 14,
                                          large: 16),
                                      color: AppColors.red),
                                  SizedBox(width: SpacingConstants.space4),
                                  Text(
                                    'BANNI',
                                    style: TextStyle(
                                      color: AppColors.red,
                                      fontSize:
                                          ResponsiveUtils.getAdaptiveFontSize(
                                              context, 11),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Column(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: SpacingConstants.space12,
                            vertical: SpacingConstants.space8,
                          ),
                          decoration: BoxDecoration(
                            color: journalist.isVerified
                                ? AppColors.success.withOpacity(0.1)
                                : AppColors.orange.withOpacity(0.1),
                            borderRadius:
                                BorderRadius.circular(SpacingConstants.space20),
                          ),
                          child: Text(
                            journalist.isVerified ? 'Vérifié' : 'En attente',
                            style: TextStyle(
                              fontSize: ResponsiveUtils.getAdaptiveFontSize(
                                  context, 12),
                              color: journalist.isVerified
                                  ? Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? AppColors.success
                                      : AppColors.success
                                  : Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? AppColors.orange
                                      : AppColors.orange,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        SizedBox(height: SpacingConstants.space8),
                        IconButton(
                          onPressed: () => _showQuickActions(journalist),
                          icon: Icon(Icons.more_vert),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showQuickActions(UserProfile journalist) {
    SafeNavigation.showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
            top: Radius.circular(SpacingConstants.space20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: EdgeInsets.symmetric(vertical: SpacingConstants.space12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outline,
                borderRadius:
                    BorderRadius.circular(SpacingConstants.space4 / 2),
              ),
            ),
            ListTile(
              leading: Icon(Icons.info,
                  color: Theme.of(context).colorScheme.primary),
              title: const Text('Voir les détails'),
              onTap: () {
                SafeNavigation.pop(context);
                _showJournalistDetails(journalist);
              },
            ),
            const Divider(),
            ListTile(
              leading: Icon(
                journalist.status == 'banned' ? Icons.lock_open : Icons.gavel,
                color: journalist.status == 'banned'
                    ? AppColors.success
                    : AppColors.red,
              ),
              title:
                  Text(journalist.status == 'banned' ? 'Débannir' : 'Bannir'),
              onTap: () {
                SafeNavigation.pop(context);
                if (journalist.status == 'banned') {
                  _unbanJournalist(journalist);
                } else {
                  _banJournalist(journalist);
                }
              },
            ),
            if (journalist.role != 'admin')
              ListTile(
                leading: Icon(Icons.security,
                    color: Theme.of(context).colorScheme.primary),
                title: const Text('Promouvoir Admin'),
                onTap: () {
                  SafeNavigation.pop(context);
                  _promoteToAdmin(journalist);
                },
              ),
            if (journalist.role == 'admin')
              ListTile(
                leading: Icon(Icons.person, color: AppColors.orange),
                title: const Text('Rétrograder en Journaliste'),
                onTap: () {
                  SafeNavigation.pop(context);
                  _demoteToJournalist(journalist);
                },
              ),
            const Divider(),
            if (!journalist.isVerified)
              ListTile(
                leading: Icon(Icons.check_circle, color: AppColors.success),
                title: const Text('Vérifier le journaliste'),
                onTap: () {
                  SafeNavigation.pop(context);
                  _verifyJournalist(journalist);
                },
              ),
            if (journalist.isVerified)
              ListTile(
                leading:
                    Icon(Icons.remove_circle_outline, color: AppColors.orange),
                title: const Text('Retirer la vérification'),
                onTap: () {
                  SafeNavigation.pop(context);
                  _unverifyJournalist(journalist);
                },
              ),
            SizedBox(height: SpacingConstants.space8),
          ],
        ),
      ),
    );
  }

  Future<void> _verifyJournalist(UserProfile journalist) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Vérifier le journaliste'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                'Voulez-vous vérifier ${journalist.name ?? journalist.username} ?'),
            SizedBox(height: SpacingConstants.space8),
            if (journalist.pressCard != null)
              Text(
                'Carte de presse: ${journalist.pressCard}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => SafeNavigation.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => SafeNavigation.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
            child: const Text('Vérifier'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await _adminRepository.toggleJournalistVerification(
            journalist.id, true);
        if (!mounted) return;
        SafeNavigation.showSnackBar(
          context,
          const SnackBar(
              content: Text('Journaliste vérifié avec succès'),
              backgroundColor: AppColors.success),
        );
        _loadJournalists();
      } catch (e) {
        if (!mounted) return;
        SafeNavigation.showSnackBar(
          context,
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _unverifyJournalist(UserProfile journalist) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Retirer la vérification'),
        content: Text(
          'Voulez-vous retirer la vérification de ${journalist.name ?? journalist.username} ?',
        ),
        actions: [
          TextButton(
            onPressed: () => SafeNavigation.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => SafeNavigation.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.orange,
            ),
            child: const Text('Retirer'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await _adminRepository.toggleJournalistVerification(
            journalist.id, false);
        if (!mounted) return;
        SafeNavigation.showSnackBar(
          context,
          const SnackBar(
            content: Text('Vérification retirée'),
            backgroundColor: AppColors.orange,
          ),
        );
        _loadJournalists();
      } catch (e) {
        if (!mounted) return;
        SafeNavigation.showSnackBar(
          context,
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showJournalistDetails(UserProfile journalist) {
    SafeNavigation.showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: ResponsiveUtils.isMobile(context) ? 0.9 : 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: BorderRadius.vertical(
                top: Radius.circular(SpacingConstants.space24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                width: 50,
                height: 5,
                margin:
                    EdgeInsets.symmetric(vertical: SpacingConstants.space12),
                decoration: BoxDecoration(
                  color: Theme.of(context).dividerColor.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(SpacingConstants.space4),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: EdgeInsets.symmetric(
                      horizontal: SpacingConstants.space20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: EdgeInsets.all(SpacingConstants.space20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors:
                                Theme.of(context).brightness == Brightness.light
                                    ? [
                                        Theme.of(context)
                                            .colorScheme
                                            .primary
                                            .withOpacity(0.1),
                                        Theme.of(context)
                                            .colorScheme
                                            .primary
                                            .withOpacity(0.05),
                                      ]
                                    : [
                                        Theme.of(context)
                                            .colorScheme
                                            .primary
                                            .withOpacity(0.2),
                                        Theme.of(context)
                                            .colorScheme
                                            .primary
                                            .withOpacity(0.1),
                                      ],
                          ),
                          borderRadius:
                              BorderRadius.circular(SpacingConstants.space16),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Stack(
                                  children: [
                                    Hero(
                                      tag: 'journalist-${journalist.id}',
                                      child: CircleAvatar(
                                        radius:
                                            ResponsiveUtils.getAdaptiveSpacing(
                                                context,
                                                mobile: 40,
                                                tablet: 45,
                                                desktop: 50),
                                        backgroundImage: journalist.avatarUrl !=
                                                null
                                            ? NetworkImage(UrlHelper
                                                    .buildMediaUrl(
                                                        journalist.avatarUrl) ??
                                                'https://via.placeholder.com/150')
                                            : null,
                                        child: journalist.avatarUrl == null
                                            ? Icon(Icons.person,
                                                size: ResponsiveUtils
                                                    .getAdaptiveIconSize(
                                                        context,
                                                        small: 36,
                                                        medium: 40,
                                                        large: 44))
                                            : null,
                                      ),
                                    ),
                                    Positioned(
                                      bottom: 0,
                                      right: 0,
                                      child: Container(
                                        padding: EdgeInsets.all(
                                            SpacingConstants.space4),
                                        decoration: BoxDecoration(
                                          color: journalist.isVerified
                                              ? Colors.green
                                              : AppColors.orange,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Theme.of(context)
                                                .scaffoldBackgroundColor,
                                            width: 3,
                                          ),
                                        ),
                                        child: Icon(
                                          journalist.isVerified
                                              ? Icons.check
                                              : Icons.hourglass_empty,
                                          size: ResponsiveUtils
                                              .getAdaptiveIconSize(context,
                                                  small: 14,
                                                  medium: 16,
                                                  large: 18),
                                          color: Theme.of(context)
                                              .colorScheme
                                              .surface,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(width: SpacingConstants.space20),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        journalist.name ?? journalist.username,
                                        style: TextStyle(
                                          fontSize: ResponsiveUtils
                                              .getAdaptiveFontSize(context, 22),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(height: SpacingConstants.space4),
                                      Text(
                                        '@${journalist.username}',
                                        style: TextStyle(
                                          fontSize: ResponsiveUtils
                                              .getAdaptiveFontSize(context, 14),
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant,
                                        ),
                                      ),
                                      SizedBox(height: SpacingConstants.space8),
                                      Wrap(
                                        spacing: SpacingConstants.space8,
                                        runSpacing: SpacingConstants.space4,
                                        children: [
                                          _buildStatusBadge(
                                            label: journalist.isVerified
                                                ? 'Vérifié'
                                                : 'Non vérifié',
                                            color: journalist.isVerified
                                                ? Colors.green
                                                : AppColors.orange,
                                            icon: journalist.isVerified
                                                ? Icons.verified
                                                : Icons.hourglass_empty,
                                          ),
                                          if (journalist.role == 'admin')
                                            _buildStatusBadge(
                                              label: 'Admin',
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .error,
                                              icon: Icons.security,
                                            ),
                                          if (journalist.status == 'banned')
                                            _buildStatusBadge(
                                              label: 'Banni',
                                              color: AppColors.red,
                                              icon: Icons.block,
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            if (journalist.pressCard != null &&
                                journalist.pressCard!.isNotEmpty) ...[
                              SizedBox(height: SpacingConstants.space20),
                              Container(
                                width: double.infinity,
                                padding:
                                    EdgeInsets.all(SpacingConstants.space16),
                                decoration: BoxDecoration(
                                  color: AppColors.success.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(
                                      SpacingConstants.space12),
                                  border: Border.all(
                                    color: AppColors.success.withOpacity(0.3),
                                    width: 2,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: EdgeInsets.all(
                                          SpacingConstants.space12),
                                      decoration: BoxDecoration(
                                        color:
                                            AppColors.success.withOpacity(0.2),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.verified,
                                        color: AppColors.success,
                                        size:
                                            ResponsiveUtils.getAdaptiveIconSize(
                                                context,
                                                small: 24,
                                                medium: 28,
                                                large: 32),
                                      ),
                                    ),
                                    SizedBox(width: SpacingConstants.space16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Carte de presse',
                                            style: TextStyle(
                                              fontSize: ResponsiveUtils
                                                  .getAdaptiveFontSize(
                                                      context, 12),
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.success,
                                            ),
                                          ),
                                          SizedBox(
                                              height: SpacingConstants.space4),
                                          Text(
                                            journalist.pressCard!,
                                            style: TextStyle(
                                              fontSize: ResponsiveUtils
                                                  .getAdaptiveFontSize(
                                                      context, 16),
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.success,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Icon(
                                      Icons.verified_user,
                                      color: AppColors.success,
                                      size: ResponsiveUtils.getAdaptiveIconSize(
                                          context,
                                          small: 32,
                                          medium: 36,
                                          large: 40),
                                    ),
                                  ],
                                ),
                              ),
                            ] else ...[
                              SizedBox(height: SpacingConstants.space20),
                              Container(
                                width: double.infinity,
                                padding:
                                    EdgeInsets.all(SpacingConstants.space16),
                                decoration: BoxDecoration(
                                  color: AppColors.red.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(
                                      SpacingConstants.space12),
                                  border: Border.all(
                                    color: AppColors.red.withOpacity(0.3),
                                    width: 2,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: EdgeInsets.all(
                                          SpacingConstants.space12),
                                      decoration: BoxDecoration(
                                        color: AppColors.red.withOpacity(0.2),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.warning,
                                        color: AppColors.red,
                                        size:
                                            ResponsiveUtils.getAdaptiveIconSize(
                                                context,
                                                small: 24,
                                                medium: 28,
                                                large: 32),
                                      ),
                                    ),
                                    SizedBox(width: SpacingConstants.space16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Carte de presse',
                                            style: TextStyle(
                                              fontSize: ResponsiveUtils
                                                  .getAdaptiveFontSize(
                                                      context, 12),
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.red,
                                            ),
                                          ),
                                          SizedBox(
                                              height: SpacingConstants.space4),
                                          Text(
                                            'Non renseignée',
                                            style: TextStyle(
                                              fontSize: ResponsiveUtils
                                                  .getAdaptiveFontSize(
                                                      context, 16),
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.red,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      SizedBox(height: SpacingConstants.space24),
                      _buildDetailCard(
                        title: 'Informations personnelles',
                        icon: Icons.person,
                        children: [
                          _buildDetailRow(
                              'Email', journalist.email, Icons.mail),
                          if (journalist.organization != null)
                            _buildDetailRow('Organisation',
                                journalist.organization!, Icons.business),
                          if (journalist.bio != null)
                            _buildDetailRow(
                                'Biographie', journalist.bio!, Icons.info),
                          if (journalist.role != null)
                            _buildDetailRow(
                                'Rôle',
                                journalist.role == 'admin'
                                    ? 'Administrateur'
                                    : 'Journaliste',
                                Icons.shield),
                        ],
                      ),
                      SizedBox(height: SpacingConstants.space16),
                      _buildDetailCard(
                        title: 'Statistiques',
                        icon: Icons.bar_chart,
                        children: [
                          _buildStatRow('Articles publiés',
                              journalist.postsCount, Icons.article),
                          _buildStatRow('Abonnés', journalist.followersCount,
                              Icons.group),
                        ],
                      ),
                      SizedBox(height: SpacingConstants.space24),
                      Text(
                        'Actions administratives',
                        style: TextStyle(
                          fontSize:
                              ResponsiveUtils.getAdaptiveFontSize(context, 18),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: SpacingConstants.space12),
                      _buildActionButton(
                        onPressed: () {
                          SafeNavigation.pop(context);
                          if (journalist.isVerified) {
                            _unverifyJournalist(journalist);
                          } else {
                            _verifyJournalist(journalist);
                          }
                        },
                        icon: journalist.isVerified
                            ? Icons.remove_circle_outline
                            : Icons.check_circle,
                        label: journalist.isVerified
                            ? 'RETIRER LA VÉRIFICATION'
                            : 'VÉRIFIER LE JOURNALISTE',
                        color: journalist.isVerified
                            ? Colors.orange
                            : AppColors.success,
                        isImportant: true,
                      ),
                      SizedBox(height: SpacingConstants.space12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildActionButton(
                              onPressed: () {
                                SafeNavigation.pop(context);
                                if (journalist.status == 'banned') {
                                  _unbanJournalist(journalist);
                                } else {
                                  _banJournalist(journalist);
                                }
                              },
                              icon: journalist.status == 'banned'
                                  ? Icons.lock_open
                                  : Icons.gavel,
                              label: journalist.status == 'banned'
                                  ? 'Débannir'
                                  : 'Bannir',
                              color: journalist.status == 'banned'
                                  ? Colors.green
                                  : AppColors.red,
                            ),
                          ),
                          SizedBox(width: SpacingConstants.space12),
                          if (journalist.role != 'admin')
                            Expanded(
                              child: _buildActionButton(
                                onPressed: () {
                                  SafeNavigation.pop(context);
                                  _promoteToAdmin(journalist);
                                },
                                icon: Icons.security,
                                label: 'Admin',
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          if (journalist.role == 'admin')
                            Expanded(
                              child: _buildActionButton(
                                onPressed: () {
                                  SafeNavigation.pop(context);
                                  _demoteToJournalist(journalist);
                                },
                                icon: Icons.person,
                                label: 'Utilisateur',
                                color: AppColors.warning,
                              ),
                            ),
                        ],
                      ),
                      SizedBox(height: SpacingConstants.space32),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge({
    required String label,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: SpacingConstants.space12,
        vertical: SpacingConstants.space4,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(SpacingConstants.space20),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: ResponsiveUtils.getAdaptiveIconSize(context,
                small: 14, medium: 16, large: 18),
            color: color,
          ),
          SizedBox(width: SpacingConstants.space4),
          Text(
            label,
            style: TextStyle(
              fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 12),
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: EdgeInsets.all(SpacingConstants.space16),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.light
            ? Theme.of(context).colorScheme.surfaceContainerLowest
            : Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(SpacingConstants.space16),
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: ResponsiveUtils.getAdaptiveIconSize(context),
                color: Theme.of(context).colorScheme.primary,
              ),
              SizedBox(width: SpacingConstants.space8),
              Text(
                title,
                style: TextStyle(
                  fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 16),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: SpacingConstants.space16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Padding(
      padding: EdgeInsets.only(bottom: SpacingConstants.space12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: ResponsiveUtils.getAdaptiveIconSize(context,
                small: 18, medium: 20, large: 22),
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          SizedBox(width: SpacingConstants.space12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 12),
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                SizedBox(height: SpacingConstants.space4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 14),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, dynamic value, IconData icon) {
    return Padding(
      padding: EdgeInsets.only(bottom: SpacingConstants.space12),
      child: Row(
        children: [
          Icon(
            icon,
            size: ResponsiveUtils.getAdaptiveIconSize(context,
                small: 18, medium: 20, large: 22),
            color: Theme.of(context).colorScheme.primary,
          ),
          SizedBox(width: SpacingConstants.space12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 14),
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Text(
            value.toString(),
            style: TextStyle(
              fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 16),
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
    required Color color,
    bool isImportant = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(SpacingConstants.space12),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: SpacingConstants.space20,
            vertical: isImportant
                ? SpacingConstants.space16
                : SpacingConstants.space12,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                color.withValues(alpha: isImportant ? 0.9 : 0.15),
                color.withValues(alpha: isImportant ? 0.8 : 0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(SpacingConstants.space12),
            border: Border.all(
              color: color.withValues(alpha: isImportant ? 1 : 0.3),
              width: isImportant ? 2 : 1,
            ),
            boxShadow: isImportant
                ? [
                    BoxShadow(
                      color: color.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: ResponsiveUtils.getAdaptiveIconSize(context,
                    small: 20, medium: 22, large: 24),
                color:
                    isImportant ? Theme.of(context).colorScheme.surface : color,
              ),
              SizedBox(width: SpacingConstants.space8),
              Text(
                label,
                style: TextStyle(
                  fontSize: ResponsiveUtils.getAdaptiveFontSize(
                      context, isImportant ? 16 : 14),
                  fontWeight: FontWeight.bold,
                  color: isImportant
                      ? Theme.of(context).colorScheme.surface
                      : color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _banJournalist(UserProfile journalist) async {
    final TextEditingController reasonController = TextEditingController();
    final TextEditingController notesController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bannir le journaliste'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
                'Voulez-vous bannir définitivement ${journalist.name ?? journalist.username} ?'),
            SizedBox(height: SpacingConstants.space16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Raison du bannissement*',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            SizedBox(height: SpacingConstants.space12),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(
                labelText: 'Notes additionnelles (optionnel)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => SafeNavigation.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => SafeNavigation.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Bannir'),
          ),
        ],
      ),
    );
    if (confirmed == true && reasonController.text.isNotEmpty) {
      try {
        await _adminRepository.banUser(
          journalist.id,
          const Duration(days: 30),
        );
        if (!mounted) return;
        SafeNavigation.showSnackBar(
          context,
          const SnackBar(
            content: Text('Journaliste banni'),
            backgroundColor: AppColors.error,
          ),
        );
        _loadJournalists();
      } catch (e) {
        if (!mounted) return;
        SafeNavigation.showSnackBar(
          context,
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } else if (confirmed == true && reasonController.text.isEmpty) {
      if (!mounted) return;
      SafeNavigation.showSnackBar(
        context,
        const SnackBar(
          content: Text('Veuillez fournir une raison'),
          backgroundColor: AppColors.orange,
        ),
      );
    }
  }

  Future<void> _unbanJournalist(UserProfile journalist) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Débannir le journaliste'),
        content: Text(
            'Voulez-vous débannir ${journalist.name ?? journalist.username} ?'),
        actions: [
          TextButton(
            onPressed: () => SafeNavigation.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => SafeNavigation.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
            child: const Text('Débannir'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        await _adminRepository.unbanUser(journalist.id);
        if (!mounted) return;
        SafeNavigation.showSnackBar(
          context,
          const SnackBar(
              content: Text('Journaliste débanni'),
              backgroundColor: AppColors.success),
        );
        _loadJournalists();
      } catch (e) {
        if (!mounted) return;
        SafeNavigation.showSnackBar(
          context,
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _promoteToAdmin(UserProfile journalist) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Promouvoir en Admin'),
        content: Text(
            'Voulez-vous promouvoir ${journalist.name ?? journalist.username} en administrateur ?'),
        actions: [
          TextButton(
            onPressed: () => SafeNavigation.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => SafeNavigation.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.blue,
              foregroundColor: Colors.white,
            ),
            child: const Text('Promouvoir'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        await _adminRepository.updateUserRole(journalist.id, role: 'admin');
        if (!mounted) return;
        SafeNavigation.showSnackBar(
          context,
          const SnackBar(
              content: Text('Journaliste promu administrateur'),
              backgroundColor: AppColors.success),
        );
        _loadJournalists();
      } catch (e) {
        if (!mounted) return;
        SafeNavigation.showSnackBar(
          context,
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _demoteToJournalist(UserProfile journalist) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rétrograder en Journaliste'),
        content: Text(
            'Voulez-vous retirer les droits admin de ${journalist.name ?? journalist.username} ?'),
        actions: [
          TextButton(
            onPressed: () => SafeNavigation.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => SafeNavigation.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.orange,
            ),
            child: const Text('Rétrograder'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        await _adminRepository.updateUserRole(journalist.id,
            role: 'journalist');
        if (!mounted) return;
        SafeNavigation.showSnackBar(
          context,
          const SnackBar(
            content: Text('Droits admin retirés'),
            backgroundColor: AppColors.orange,
          ),
        );
        _loadJournalists();
      } catch (e) {
        if (!mounted) return;
        SafeNavigation.showSnackBar(
          context,
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}
