import 'package:thot/core/presentation/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:thot/core/di/service_locator.dart';
import 'package:thot/features/admin/providers/admin_repository_impl.dart';
import 'package:thot/features/app/profile/models/user_profile.dart';
import 'package:thot/shared/media/utils/url_helper.dart';
import 'package:thot/shared/utils/responsive_utils.dart';
import 'package:thot/core/utils/safe_navigation.dart';
import 'package:thot/core/config/spacing_constants.dart';
import 'package:thot/shared/utils/color_utils.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});
  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen>
    with SingleTickerProviderStateMixin {
  late final AdminRepositoryImpl _adminRepository;
  late TabController _tabController;
  List<UserProfile> _users = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String? _selectedRole;
  String? _selectedStatus;
  final TextEditingController _searchController = TextEditingController();
  int _currentPage = 1;
  int _totalPages = 1;
  bool _hasMore = true;
  @override
  void initState() {
    super.initState();
    _adminRepository = ServiceLocator.instance.adminRepository;
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          _selectedStatus = _getStatusForTab(_tabController.index);
          _loadUsers(refresh: true);
        });
      }
    });
    _loadUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  String? _getStatusForTab(int index) {
    switch (index) {
      case 0:
        return null;
      case 1:
        return 'active';
      case 2:
        return 'banned';
      default:
        return null;
    }
  }

  Future<void> _loadUsers({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _currentPage = 1;
        _users.clear();
      });
    }
    setState(() => _isLoading = true);
    try {
      final result = await _adminRepository.getUsers(
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
        role: _selectedRole,
        status: _selectedStatus,
        page: _currentPage,
        limit: 20,
      );
      final usersList = result['users'] ?? result['data']?['users'] ?? [];
      var users = (usersList as List<dynamic>)
          .map((u) => UserProfile.fromJson(u is Map<String, dynamic> ? u : {}))
          .toList();
      users.sort((a, b) {
        if (a.role == 'admin' && b.role != 'admin') return -1;
        if (b.role == 'admin' && a.role != 'admin') return 1;
        if (a.status != 'banned' && b.status == 'banned') return -1;
        if (b.status != 'banned' && a.status == 'banned') return 1;
        return (a.name ?? a.username).compareTo(b.name ?? b.username);
      });
      if (!mounted) return;
      setState(() {
        if (refresh) {
          _users = users;
        } else {
          _users.addAll(users);
        }
        _totalPages = result['totalPages'] ??
            result['data']?['pagination']?['totalPages'] ??
            1;
        _hasMore = _currentPage < _totalPages;
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
              title: Text('Gestion des utilisateurs'),
              centerTitle: true,
              elevation: 0,
              bottom: TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(
                    text: 'Tous',
                    icon: Icon(Icons.group),
                  ),
                  Tab(
                    text: 'Actifs',
                    icon: Icon(Icons.check_circle),
                  ),
                  Tab(
                    text: 'Bannis',
                    icon: Icon(Icons.block),
                  ),
                ],
              ),
            )
          : null,
      body: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: Theme.of(context).brightness == Brightness.light
                    ? [
                        AppColors.blue.withOpacity(0.1),
                        AppColors.blue.withOpacity(0.05),
                        Colors.transparent,
                      ]
                    : [
                        Theme.of(context).colorScheme.onSurface,
                        Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest
                            .withOpacity(0.8),
                        Colors.transparent,
                      ],
              ),
            ),
            child: Column(
              children: [
                Container(
                  padding: EdgeInsets.all(
                      ResponsiveUtils.getAdaptivePadding(context)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.admin_panel_settings,
                            size: ResponsiveUtils.getAdaptiveIconSize(context,
                                small: 24, medium: 28, large: 32),
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          SizedBox(width: SpacingConstants.space12),
                          Text(
                            'Gestion des utilisateurs',
                            style: TextStyle(
                              fontSize: ResponsiveUtils.getAdaptiveFontSize(
                                  context, 20),
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: SpacingConstants.space16),
                      Container(
                        decoration: BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(context).brightness ==
                                      Brightness.light
                                  ? Colors.black.withOpacity(0.1)
                                  : Colors.black.withOpacity(0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _searchController,
                          style: TextStyle(
                            fontSize: ResponsiveUtils.getAdaptiveFontSize(
                                context, 16),
                          ),
                          decoration: InputDecoration(
                            hintText: 'Rechercher un utilisateur...',
                            hintStyle: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant
                                  .withOpacity(0.6),
                            ),
                            prefixIcon: Icon(
                              Icons.search,
                              color: Theme.of(context).colorScheme.primary,
                              size:
                                  ResponsiveUtils.getAdaptiveIconSize(context),
                            ),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: Container(
                                      padding: EdgeInsets.all(
                                          SpacingConstants.space4),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .error
                                            .withOpacity(0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.close,
                                        size:
                                            ResponsiveUtils.getAdaptiveIconSize(
                                                context,
                                                small: 16,
                                                medium: 18,
                                                large: 20),
                                        color:
                                            Theme.of(context).colorScheme.error,
                                      ),
                                    ),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() => _searchQuery = '');
                                      _loadUsers(refresh: true);
                                    },
                                  )
                                : null,
                            filled: true,
                            fillColor:
                                Theme.of(context).brightness == Brightness.light
                                    ? Colors.white
                                    : Theme.of(context)
                                        .colorScheme
                                        .surfaceContainerHighest,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: Theme.of(context).brightness ==
                                        Brightness.light
                                    ? Theme.of(context)
                                        .colorScheme
                                        .surfaceContainerLowest
                                    : Theme.of(context)
                                        .colorScheme
                                        .surfaceContainerHighest,
                                width: 1,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: Theme.of(context).colorScheme.primary,
                                width: 2,
                              ),
                            ),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: SpacingConstants.space20,
                              vertical: SpacingConstants.space16,
                            ),
                          ),
                          onChanged: (value) {
                            setState(() => _searchQuery = value);
                            _loadUsers(refresh: true);
                          },
                        ),
                      ),
                      SizedBox(height: SpacingConstants.space16),
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: SpacingConstants.space12,
                              vertical: SpacingConstants.space8,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.group,
                                  size: ResponsiveUtils.getAdaptiveIconSize(
                                      context,
                                      small: 16,
                                      medium: 18,
                                      large: 20),
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                SizedBox(width: SpacingConstants.space8),
                                Text(
                                  '${_users.length} utilisateur${_users.length > 1 ? 's' : ''}',
                                  style: TextStyle(
                                    fontSize:
                                        ResponsiveUtils.getAdaptiveFontSize(
                                            context, 14),
                                    fontWeight: FontWeight.w600,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: SpacingConstants.space12),
                          Expanded(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  _buildFilterButton(
                                    icon: Icons.tune,
                                    label: _selectedRole ?? 'Filtrer par rôle',
                                    isActive: _selectedRole != null,
                                    onTap: _showRoleFilter,
                                  ),
                                  if (_selectedRole != null) ...[
                                    SizedBox(width: SpacingConstants.space8),
                                    _buildResetButton(),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  height: 1,
                  margin: EdgeInsets.symmetric(
                      horizontal: SpacingConstants.space16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        Theme.of(context).dividerColor.withOpacity(0.3),
                        Theme.of(context).dividerColor.withOpacity(0.3),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading && _users.isEmpty
                ? Center(child: CircularProgressIndicator())
                : _users.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.group,
                                size: ResponsiveUtils.getAdaptiveIconSize(
                                    context,
                                    small: 48,
                                    medium: 56,
                                    large: 64),
                                color: Theme.of(context).colorScheme.outline),
                            SizedBox(height: SpacingConstants.space16),
                            Text(
                              'Aucun utilisateur trouvé',
                              style: TextStyle(
                                  fontSize: ResponsiveUtils.getAdaptiveFontSize(
                                      context, 16),
                                  color: Theme.of(context).colorScheme.outline),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () => _loadUsers(refresh: true),
                        child: ListView.builder(
                          padding: const EdgeInsets.only(bottom: 80),
                          itemCount: _users.length + (_hasMore ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == _users.length) {
                              if (!_isLoading) {
                                _currentPage++;
                                _loadUsers();
                              }
                              return Center(
                                child: Padding(
                                  padding:
                                      EdgeInsets.all(SpacingConstants.space16),
                                  child: const CircularProgressIndicator(),
                                ),
                              );
                            }
                            final user = _users[index];
                            return Card(
                              margin: EdgeInsets.symmetric(
                                horizontal:
                                    ResponsiveUtils.getAdaptivePadding(context),
                                vertical: SpacingConstants.space4,
                              ),
                              elevation: user.role == 'admin' ? 3 : 1,
                              child: InkWell(
                                onTap: () => _showUserDetails(user),
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    border: user.role == 'admin'
                                        ? Border.all(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .error
                                                .withOpacity(0.5),
                                            width: 2)
                                        : null,
                                  ),
                                  child: Padding(
                                    padding: EdgeInsets.all(
                                        ResponsiveUtils.getAdaptiveCardPadding(
                                            context)),
                                    child: Row(
                                      children: [
                                        Stack(
                                          children: [
                                            CircleAvatar(
                                              radius: ResponsiveUtils
                                                  .getAdaptiveAvatarRadius(
                                                      context),
                                              backgroundImage: user.avatarUrl !=
                                                      null
                                                  ? NetworkImage(UrlHelper
                                                          .buildMediaUrl(
                                                              user.avatarUrl) ??
                                                      'https://via.placeholder.com/150')
                                                  : null,
                                              child: user.avatarUrl == null
                                                  ? Icon(Icons.person)
                                                  : null,
                                            ),
                                            if (user.status != 'active' &&
                                                user.status != null)
                                              Positioned(
                                                right: 0,
                                                bottom: 0,
                                                child: Container(
                                                  width: ResponsiveUtils
                                                      .getAdaptiveIconSize(
                                                          context,
                                                          small: 14,
                                                          medium: 16,
                                                          large: 18),
                                                  height: ResponsiveUtils
                                                      .getAdaptiveIconSize(
                                                          context,
                                                          small: 14,
                                                          medium: 16,
                                                          large: 18),
                                                  decoration: BoxDecoration(
                                                    color: user.status ==
                                                            'suspended'
                                                        ? Colors.red
                                                        : user.status ==
                                                                'banned'
                                                            ? Colors.red[900]
                                                            : Theme.of(context)
                                                                .colorScheme
                                                                .outline,
                                                    shape: BoxShape.circle,
                                                    border: Border.all(
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .surface,
                                                      width: 2,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                        SizedBox(
                                            width: SpacingConstants.space12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      user.name ??
                                                          user.username,
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: ResponsiveUtils
                                                            .getAdaptiveFontSize(
                                                                context, 16),
                                                        decoration:
                                                            user.status ==
                                                                    'banned'
                                                                ? TextDecoration
                                                                    .lineThrough
                                                                : TextDecoration
                                                                    .none,
                                                      ),
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  SizedBox(
                                                      width: SpacingConstants
                                                          .space8),
                                                  if (user.role == 'admin')
                                                    Container(
                                                      padding:
                                                          EdgeInsets.symmetric(
                                                              horizontal:
                                                                  SpacingConstants
                                                                      .space8,
                                                              vertical: 2),
                                                      decoration: BoxDecoration(
                                                        color: Theme.of(context)
                                                            .colorScheme
                                                            .error,
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(4),
                                                      ),
                                                      child: Text(
                                                        'ADMIN',
                                                        style: TextStyle(
                                                          color:
                                                              Theme.of(context)
                                                                  .colorScheme
                                                                  .surface,
                                                          fontSize: ResponsiveUtils
                                                              .getAdaptiveFontSize(
                                                                  context, 11),
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                    ),
                                                  if (user.isVerified)
                                                    Icon(Icons.verified,
                                                        size: ResponsiveUtils
                                                            .getAdaptiveIconSize(
                                                                context,
                                                                small: 16,
                                                                medium: 18,
                                                                large: 20),
                                                        color: Theme.of(context)
                                                            .colorScheme
                                                            .primary),
                                                ],
                                              ),
                                              SizedBox(height: 2),
                                              Text(
                                                user.email,
                                                style: TextStyle(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .outline,
                                                  fontSize: ResponsiveUtils
                                                      .getAdaptiveFontSize(
                                                          context, 14),
                                                ),
                                              ),
                                              SizedBox(
                                                  height:
                                                      SpacingConstants.space4),
                                              Row(
                                                children: [
                                                  _buildRoleChip(user.role),
                                                  SizedBox(
                                                      width: SpacingConstants
                                                          .space8),
                                                  if (user.status == 'banned')
                                                    Container(
                                                      padding:
                                                          EdgeInsets.symmetric(
                                                              horizontal:
                                                                  SpacingConstants
                                                                      .space8,
                                                              vertical: 2),
                                                      decoration: BoxDecoration(
                                                        color: ColorUtils
                                                            .getSafeAccentColor(
                                                                context,
                                                                Theme.of(
                                                                        context)
                                                                    .colorScheme
                                                                    .error),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(4),
                                                      ),
                                                      child: Text(
                                                        'BANNI',
                                                        style: TextStyle(
                                                          color:
                                                              Theme.of(context)
                                                                  .colorScheme
                                                                  .error,
                                                          fontSize: ResponsiveUtils
                                                              .getAdaptiveFontSize(
                                                                  context, 10),
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                    ),
                                                ],
                                              ),
                                              SizedBox(height: 2),
                                              Text(
                                                '${user.followersCount} abonnés • Status: ${user.status ?? "null"}',
                                                style: TextStyle(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .outline,
                                                  fontSize: ResponsiveUtils
                                                      .getAdaptiveFontSize(
                                                          context, 12),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        IconButton(
                                          onPressed: () =>
                                              _showUserActions(user),
                                          icon: Icon(Icons.more_vert),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleChip(String? role) {
    Color color;
    String label;
    IconData icon;
    switch (role) {
      case 'admin':
        color = Theme.of(context).colorScheme.error;
        label = 'Admin';
        icon = Icons.security;
        break;
      case 'journalist':
        color = Theme.of(context).colorScheme.primary;
        label = 'Journaliste';
        icon = Icons.article;
        break;
      case 'user':
      default:
        color = Theme.of(context).colorScheme.onSurfaceVariant;
        label = 'Utilisateur';
        icon = Icons.person;
    }
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: SpacingConstants.space12,
          vertical: SpacingConstants.space4),
      decoration: BoxDecoration(
        color: ColorUtils.getSafeAccentColor(context, color),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon,
              size: ResponsiveUtils.getAdaptiveIconSize(context,
                  small: 12, medium: 14, large: 16),
              color: color),
          SizedBox(width: SpacingConstants.space4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 13),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String label;
    switch (status) {
      case 'suspended':
        color = Theme.of(context).colorScheme.error;
        label = 'Suspendu';
        break;
      case 'inactive':
        color = Theme.of(context).colorScheme.onSurfaceVariant;
        label = 'Inactif';
        break;
      case 'banned':
        color = Theme.of(context).colorScheme.error;
        label = 'Banni';
        break;
      default:
        color = AppColors.success;
        label = 'Actif';
    }
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: SpacingConstants.space8, vertical: 2),
      decoration: BoxDecoration(
        color: ColorUtils.getSafeAccentColor(context, color),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 12),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  void _showRoleFilter() {
    SafeNavigation.showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(SpacingConstants.space16),
              child: Text(
                'Filtrer par rôle',
                style: TextStyle(
                  fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 18),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ListTile(
              title: const Text('Tous les rôles'),
              onTap: () {
                SafeNavigation.pop(context);
                setState(() => _selectedRole = null);
                _loadUsers(refresh: true);
              },
              selected: _selectedRole == null,
            ),
            ListTile(
              title: const Text('Administrateurs'),
              onTap: () {
                SafeNavigation.pop(context);
                setState(() => _selectedRole = 'admin');
                _loadUsers(refresh: true);
              },
              selected: _selectedRole == 'admin',
            ),
            ListTile(
              title: const Text('Utilisateurs'),
              onTap: () {
                SafeNavigation.pop(context);
                setState(() => _selectedRole = 'user');
                _loadUsers(refresh: true);
              },
              selected: _selectedRole == 'user',
            ),
            SizedBox(height: SpacingConstants.space8),
          ],
        ),
      ),
    );
  }

  void _showUserActions(UserProfile user) {
    SafeNavigation.showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: Icon(Icons.info),
              title: const Text('Voir les détails'),
              onTap: () {
                SafeNavigation.pop(context);
                _showUserDetails(user);
              },
            ),
            const Divider(),
            if (user.email != 'lucas@admin.com')
              ListTile(
                leading: Icon(
                  user.status == 'banned' ? Icons.lock_open : Icons.gavel,
                  color: user.status == 'banned'
                      ? AppColors.success
                      : AppColors.red,
                ),
                title: Text(user.status == 'banned' ? 'Débannir' : 'Bannir'),
                onTap: () {
                  SafeNavigation.pop(context);
                  if (user.status == 'banned') {
                    _unbanUser(user);
                  } else {
                    _banUser(user);
                  }
                },
              ),
            if (user.role != 'admin')
              ListTile(
                leading: Icon(Icons.security, color: AppColors.blue),
                title: const Text('Promouvoir Admin'),
                onTap: () {
                  SafeNavigation.pop(context);
                  _promoteToAdmin(user);
                },
              ),
            if (user.role == 'admin' && user.email != 'lucas@admin.com')
              ListTile(
                leading: Icon(Icons.person, color: AppColors.orange),
                title: const Text('Rétrograder en User'),
                onTap: () {
                  SafeNavigation.pop(context);
                  _demoteToUser(user);
                },
              ),
            SizedBox(height: SpacingConstants.space8),
          ],
        ),
      ),
    );
  }

  void _showUserDetails(UserProfile user) {
    SafeNavigation.showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: ResponsiveUtils.isMobile(context) ? 0.5 : 0.4,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: EdgeInsets.all(ResponsiveUtils.getAdaptivePadding(context)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: EdgeInsets.only(bottom: SpacingConstants.space20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.outline,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  CircleAvatar(
                    radius:
                        ResponsiveUtils.getAdaptiveAvatarRadius(context) * 1.5,
                    backgroundImage: user.avatarUrl != null
                        ? NetworkImage(
                            UrlHelper.buildMediaUrl(user.avatarUrl) ??
                                'https://via.placeholder.com/150')
                        : null,
                    child: user.avatarUrl == null
                        ? Icon(Icons.person,
                            size: ResponsiveUtils.getAdaptiveIconSize(context,
                                small: 32, medium: 36, large: 40))
                        : null,
                  ),
                  SizedBox(width: SpacingConstants.space16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.name ?? user.username,
                          style: TextStyle(
                            fontSize: ResponsiveUtils.getAdaptiveFontSize(
                                context, 20),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: SpacingConstants.space4),
                        Row(
                          children: [
                            _buildRoleChip(user.role),
                            SizedBox(width: SpacingConstants.space8),
                            if (user.status != null && user.status != 'active')
                              _buildStatusChip(user.status!),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: SpacingConstants.space24),
              _buildDetailSection('Informations', [
                _DetailItem(Icons.person, 'Nom', user.name ?? user.username),
                if (user.username.isNotEmpty && user.name != user.username)
                  _DetailItem(Icons.alternate_email, 'Nom d\'utilisateur',
                      user.username),
                _DetailItem(Icons.mail, 'Email', user.email),
                if (user.bio != null) _DetailItem(Icons.info, 'Bio', user.bio!),
                if (user.status != null)
                  _DetailItem(
                      Icons.info, 'Statut', _getStatusLabel(user.status!)),
              ]),
              SizedBox(height: SpacingConstants.space24),
              _buildDetailSection('Activité', [
                _DetailItem(Icons.article, 'Articles publiés',
                    user.postsCount.toString()),
                _DetailItem(
                    Icons.group, 'Abonnés', user.followersCount.toString()),
                _DetailItem(Icons.person_add, 'Abonnements',
                    user.followingCount.toString()),
              ]),
              SizedBox(height: SpacingConstants.space24),
              if (user.email != 'lucas@admin.com')
                ElevatedButton.icon(
                  onPressed: () {
                    SafeNavigation.pop(context);
                    if (user.status == 'banned') {
                      _unbanUser(user);
                    } else {
                      _banUser(user);
                    }
                  },
                  icon: Icon(
                    user.status == 'banned' ? Icons.lock_open : Icons.gavel,
                  ),
                  label: Text(
                    user.status == 'banned' ? 'Débannir' : 'Bannir',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: user.status == 'banned'
                        ? AppColors.success
                        : AppColors.red,
                    minimumSize: const Size.fromHeight(48),
                  ),
                ),
              SizedBox(height: SpacingConstants.space8),
              if (user.role != 'admin')
                ElevatedButton.icon(
                  onPressed: () {
                    SafeNavigation.pop(context);
                    _promoteToAdmin(user);
                  },
                  icon: Icon(Icons.security),
                  label: Text('Promouvoir Admin'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    minimumSize: const Size.fromHeight(48),
                  ),
                ),
              if (user.role == 'admin' && user.email != 'lucas@admin.com')
                ElevatedButton.icon(
                  onPressed: () {
                    SafeNavigation.pop(context);
                    _demoteToUser(user);
                  },
                  icon: Icon(Icons.person),
                  label: Text('Rétrograder en Utilisateur'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.secondary,
                    minimumSize: const Size.fromHeight(48),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailSection(String title, List<_DetailItem> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 18),
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: SpacingConstants.space12),
        ...items.map((item) => Padding(
              padding: EdgeInsets.only(bottom: SpacingConstants.space12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(item.icon,
                      size: ResponsiveUtils.getAdaptiveIconSize(context),
                      color: Theme.of(context).colorScheme.outline),
                  SizedBox(width: SpacingConstants.space12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.label,
                          style: TextStyle(
                            fontSize: ResponsiveUtils.getAdaptiveFontSize(
                                context, 12),
                            color: Theme.of(context).colorScheme.outline,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          item.value,
                          style: TextStyle(
                            fontSize: ResponsiveUtils.getAdaptiveFontSize(
                                context, 14),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )),
      ],
    );
  }

  Future<void> _banUser(UserProfile user) async {
    final TextEditingController reasonController = TextEditingController();
    final TextEditingController notesController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Bannir l\'utilisateur'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
                'Voulez-vous bannir définitivement ${user.name ?? user.username} ?'),
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
            child: Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => SafeNavigation.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Bannir'),
          ),
        ],
      ),
    );
    if (confirmed == true && reasonController.text.isNotEmpty) {
      try {
        await _adminRepository.banUser(
          user.id,
          const Duration(days: 30),
        );
        if (!mounted) return;
        SafeNavigation.showSnackBar(
          context,
          SnackBar(
            content: Text('Utilisateur banni'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
        _loadUsers(refresh: true);
      } catch (e) {
        if (!mounted) return;
        SafeNavigation.showSnackBar(
          context,
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
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

  Future<void> _unbanUser(UserProfile user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Débannir l\'utilisateur'),
        content: Text('Voulez-vous débannir ${user.name ?? user.username} ?'),
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
        await _adminRepository.unbanUser(user.id);
        if (!mounted) return;
        SafeNavigation.showSnackBar(
          context,
          const SnackBar(
              content: Text('Utilisateur débanni'),
              backgroundColor: AppColors.success),
        );
        _loadUsers(refresh: true);
      } catch (e) {
        if (!mounted) return;
        SafeNavigation.showSnackBar(
          context,
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _promoteToAdmin(UserProfile user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Promouvoir en Admin'),
        content: Text(
            'Voulez-vous promouvoir ${user.name ?? user.username} en administrateur ?'),
        actions: [
          TextButton(
            onPressed: () => SafeNavigation.pop(context, false),
            child: Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => SafeNavigation.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
            child: const Text('Promouvoir'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        await _adminRepository.updateUserRole(user.id, role: 'admin');
        if (!mounted) return;
        SafeNavigation.showSnackBar(
          context,
          const SnackBar(
              content: Text('Utilisateur promu administrateur'),
              backgroundColor: AppColors.success),
        );
        _loadUsers(refresh: true);
      } catch (e) {
        if (!mounted) return;
        SafeNavigation.showSnackBar(
          context,
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _demoteToUser(UserProfile user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Rétrograder en Utilisateur'),
        content: Text(
            'Voulez-vous rétrograder ${user.name ?? user.username} en simple utilisateur ?'),
        actions: [
          TextButton(
            onPressed: () => SafeNavigation.pop(context, false),
            child: Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => SafeNavigation.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.secondary,
            ),
            child: const Text('Rétrograder'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        await _adminRepository.updateUserRole(user.id, role: 'user');
        if (!mounted) return;
        SafeNavigation.showSnackBar(
          context,
          const SnackBar(
            content: Text('Administrateur rétrogradé en utilisateur'),
            backgroundColor: AppColors.orange,
          ),
        );
        _loadUsers(refresh: true);
      } catch (e) {
        if (!mounted) return;
        SafeNavigation.showSnackBar(
          context,
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'suspended':
        return 'Suspendu';
      case 'inactive':
        return 'Inactif';
      case 'banned':
        return 'Banni';
      case 'active':
      default:
        return 'Actif';
    }
  }

  Widget _buildFilterButton({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: SpacingConstants.space16,
            vertical: SpacingConstants.space12 * 0.8,
          ),
          decoration: BoxDecoration(
            gradient: isActive
                ? LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary.withOpacity(0.2),
                      Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    ],
                  )
                : null,
            color: !isActive
                ? Theme.of(context).brightness == Brightness.light
                    ? Colors.white
                    : Theme.of(context).colorScheme.surfaceContainerHighest
                : null,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isActive
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).brightness == Brightness.light
                      ? Theme.of(context).colorScheme.outline
                      : Theme.of(context).colorScheme.outline,
              width: isActive ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isActive
                    ? Theme.of(context).colorScheme.primary.withOpacity(0.2)
                    : Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: ResponsiveUtils.getAdaptiveIconSize(context,
                    small: 18, medium: 20, large: 22),
                color: isActive
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              SizedBox(width: SpacingConstants.space8),
              Text(
                label,
                style: TextStyle(
                  fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 14),
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                  color: isActive
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurface,
                ),
              ),
              SizedBox(width: SpacingConstants.space8),
              Icon(
                Icons.keyboard_arrow_down,
                size: ResponsiveUtils.getAdaptiveIconSize(context,
                    small: 20, medium: 22, large: 24),
                color: isActive
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResetButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedRole = null;
          });
          _loadUsers(refresh: true);
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: SpacingConstants.space16,
            vertical: SpacingConstants.space12 * 0.8,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.error.withOpacity(0.15),
                Theme.of(context).colorScheme.error.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Theme.of(context).colorScheme.error.withOpacity(0.4),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.refresh,
                size: ResponsiveUtils.getAdaptiveIconSize(context,
                    small: 18, medium: 20, large: 22),
                color: Theme.of(context).colorScheme.error,
              ),
              SizedBox(width: SpacingConstants.space8),
              Text(
                'Réinitialiser',
                style: TextStyle(
                  fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 14),
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailItem {
  final IconData icon;
  final String label;
  final String value;
  _DetailItem(this.icon, this.label, this.value);
}
