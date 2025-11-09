import 'package:flutter/material.dart';
import '../../../../../core/themes/app_colors.dart';
import '../../../../../core/themes/web_theme.dart';
import '../../../../../shared/widgets/web/web_scaffold.dart';
import 'package:thot/core/infrastructure/dependency_injection.dart';
import '../../../../../features/admin/data/repositories/admin_repository_impl.dart';
import '../../../../../features/profile/domain/entities/user_profile.dart';
import '../../../../../features/media/utils/url_helper.dart';
import '../../../../../features/admin/presentation/shared/widgets/status_badge.dart';
class AdminUsersScreenWeb extends StatefulWidget {
  final String currentRoute;
  final Function(String route) onNavigate;
  const AdminUsersScreenWeb({
    super.key,
    required this.currentRoute,
    required this.onNavigate,
  });
  @override
  State<AdminUsersScreenWeb> createState() => _AdminUsersScreenWebState();
}
class _AdminUsersScreenWebState extends State<AdminUsersScreenWeb>
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
        if (a.isBanned && !b.isBanned) return 1;
        if (!a.isBanned && b.isBanned) return -1;
        return (a.name ?? a.username).compareTo(b.name ?? b.username);
      });
      if (!mounted) return;
      setState(() {
        _users = users;
        _totalPages = result['totalPages'] ?? 1;
        _hasMore = _currentPage < _totalPages;
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
  Future<void> _banUser(UserProfile user) async {
    try {
      await _adminRepository.banUser(user.id, reason: 'Banned by admin');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Utilisateur banni avec succès')),
      );
      _loadUsers(refresh: true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: ${e.toString()}')),
      );
    }
  }
  Future<void> _unbanUser(UserProfile user) async {
    try {
      await _adminRepository.unbanUser(user.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Utilisateur débanni avec succès')),
      );
      _loadUsers(refresh: true);
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
                  Icon(Icons.group, size: 32, color: colorScheme.primary),
                  const SizedBox(width: WebTheme.md),
                  Text(
                    'Gestion des Utilisateurs',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: WebTheme.xl),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Rechercher un utilisateur...',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: colorScheme.surfaceContainerHighest,
                      ),
                      onChanged: (value) {
                        setState(() => _searchQuery = value);
                        _loadUsers(refresh: true);
                      },
                    ),
                  ),
                  const SizedBox(width: WebTheme.md),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedRole,
                      decoration: InputDecoration(
                        labelText: 'Rôle',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: colorScheme.surfaceContainerHighest,
                      ),
                      items: const [
                        DropdownMenuItem(value: null, child: Text('Tous')),
                        DropdownMenuItem(
                            value: 'reader', child: Text('Lecteur')),
                        DropdownMenuItem(
                            value: 'journalist', child: Text('Journaliste')),
                        DropdownMenuItem(value: 'admin', child: Text('Admin')),
                      ],
                      onChanged: (value) {
                        setState(() => _selectedRole = value);
                        _loadUsers(refresh: true);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: WebTheme.xl),
              TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'Tous'),
                  Tab(text: 'Actifs'),
                  Tab(text: 'Bannis'),
                ],
              ),
              const SizedBox(height: WebTheme.lg),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _buildUsersTable(colorScheme),
              ),
              if (!_isLoading && _users.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: WebTheme.lg),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: _currentPage > 1
                            ? () {
                                setState(() => _currentPage--);
                                _loadUsers();
                              }
                            : null,
                        icon: Icon(Icons.arrow_back),
                      ),
                      const SizedBox(width: WebTheme.md),
                      Text(
                        'Page $_currentPage / $_totalPages',
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(width: WebTheme.md),
                      IconButton(
                        onPressed: _hasMore
                            ? () {
                                setState(() => _currentPage++);
                                _loadUsers();
                              }
                            : null,
                        icon: Icon(Icons.arrow_forward),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildUsersTable(ColorScheme colorScheme) {
    if (_users.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.group, size: 64, color: colorScheme.outline),
            const SizedBox(height: WebTheme.md),
            Text(
              'Aucun utilisateur trouvé',
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
              child: const Row(
                children: [
                  SizedBox(width: 80),
                  Expanded(flex: 2, child: Text('Utilisateur')),
                  Expanded(flex: 2, child: Text('Email')),
                  Expanded(child: Text('Rôle')),
                  Expanded(child: Text('Statut')),
                  SizedBox(width: 150, child: Text('Actions')),
                ],
              ),
            ),
            ...(_users.map((user) => _buildUserRow(user, colorScheme))),
          ],
        ),
      ),
    );
  }
  Widget _buildUserRow(UserProfile user, ColorScheme colorScheme) {
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
              backgroundImage: user.profilePicture != null
                  ? NetworkImage(UrlHelper.getImageUrl(user.profilePicture!))
                  : null,
              child: user.profilePicture == null
                  ? Icon(Icons.person)
                  : null,
            ),
          ),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        user.name ?? user.username,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (user.isVerified)
                      Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: Icon(Icons.verified,
                            size: 16, color: AppColors.blue),
                      ),
                  ],
                ),
                if (user.username.isNotEmpty && user.name != user.username)
                  Text(
                    '@${user.username}',
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
              user.email,
              style: const TextStyle(fontSize: 13),
            ),
          ),
          Expanded(
            child: RoleChip(role: user.role),
          ),
          Expanded(
            child: UserStatusBadge(isBanned: user.isBanned),
          ),
          SizedBox(
            width: 150,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (user.role != 'admin')
                  if (user.isBanned)
                    Tooltip(
                      message: 'Débannir',
                      child: IconButton(
                        icon: Icon(Icons.check_circle, size: 20),
                        color: AppColors.success,
                        onPressed: () => _unbanUser(user),
                      ),
                    )
                  else
                    Tooltip(
                      message: 'Bannir',
                      child: IconButton(
                        icon: Icon(Icons.block, size: 20),
                        color: AppColors.error,
                        onPressed: () => _showBanDialog(user),
                      ),
                    ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  void _showBanDialog(UserProfile user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bannir l\'utilisateur'),
        content: Text(
          'Êtes-vous sûr de vouloir bannir ${user.name ?? user.username} ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              _banUser(user);
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Bannir'),
          ),
        ],
      ),
    );
  }
}