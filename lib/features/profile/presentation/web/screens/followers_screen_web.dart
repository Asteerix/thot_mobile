import 'package:flutter/material.dart';
import '../../../../../core/themes/web_theme.dart';
import '../../../../../shared/widgets/web/web_scaffold.dart';
import '../../../../../shared/widgets/web/responsive_layout.dart';
class FollowersScreenWeb extends StatefulWidget {
  final String userId;
  final String currentRoute;
  final Function(String route) onNavigate;
  final FollowersTab initialTab;
  const FollowersScreenWeb({
    super.key,
    required this.userId,
    required this.currentRoute,
    required this.onNavigate,
    this.initialTab = FollowersTab.followers,
  });
  @override
  State<FollowersScreenWeb> createState() => _FollowersScreenWebState();
}
enum FollowersTab { followers, following }
class _FollowersScreenWebState extends State<FollowersScreenWeb>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  bool _isLoading = false;
  String _searchQuery = '';
  String _sortBy = 'recent';
  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTab == FollowersTab.followers ? 0 : 1,
    );
    _loadUsers();
  }
  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }
  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    try {
      await Future.delayed(const Duration(seconds: 1));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  void _handleSearch(String query) {
    setState(() => _searchQuery = query);
  }
  Future<void> _toggleFollow(String userId) async {
  }
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return WebScaffold(
      currentRoute: widget.currentRoute,
      onNavigate: widget.onNavigate,
      body: ResponsiveLayout(
        builder: (context, deviceType) {
          if (deviceType == DeviceType.mobile) {
            return _buildMobileLayout(context, colorScheme);
          }
          return _buildDesktopLayout(context, colorScheme, deviceType);
        },
      ),
    );
  }
  Widget _buildMobileLayout(BuildContext context, ColorScheme colorScheme) {
    return Column(
      children: [
        _buildHeader(context, colorScheme),
        _buildSearchBar(context, colorScheme),
        _buildTabs(context, colorScheme),
        Expanded(
          child: _buildTabContent(context, colorScheme, DeviceType.mobile),
        ),
      ],
    );
  }
  Widget _buildDesktopLayout(
    BuildContext context,
    ColorScheme colorScheme,
    DeviceType deviceType,
  ) {
    final isLargeScreen = deviceType == DeviceType.largeDesktop;
    final maxWidth = isLargeScreen ? 1400.0 : WebTheme.maxContentWidth;
    return Center(
      child: Container(
        constraints: BoxConstraints(maxWidth: maxWidth),
        padding: EdgeInsets.all(
          isLargeScreen ? WebTheme.xxxl : WebTheme.xxl,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context, colorScheme),
            const SizedBox(height: WebTheme.xl),
            Row(
              children: [
                Expanded(child: _buildSearchBar(context, colorScheme)),
                const SizedBox(width: WebTheme.lg),
                _buildSortDropdown(context, colorScheme),
              ],
            ),
            const SizedBox(height: WebTheme.xl),
            _buildTabs(context, colorScheme),
            const SizedBox(height: WebTheme.lg),
            Expanded(
              child: _buildTabContent(context, colorScheme, deviceType),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildHeader(BuildContext context, ColorScheme colorScheme) {
    return Row(
      children: [
        IconButton(
          onPressed: () => widget.onNavigate('/profile'),
          icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
        ),
        const SizedBox(width: WebTheme.md),
        Text(
          'Followers & Following',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
  Widget _buildSearchBar(BuildContext context, ColorScheme colorScheme) {
    return Container(
      height: WebTheme.inputHeight,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(WebTheme.borderRadiusSmall),
        border: Border.all(color: colorScheme.outline.withOpacity(0.3)),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: _handleSearch,
        decoration: InputDecoration(
          hintText: 'Search users...',
          hintStyle: TextStyle(
            color: colorScheme.onSurface.withOpacity(0.4),
          ),
          prefixIcon: Icon(Icons.search, color: colorScheme.primary),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear, color: colorScheme.onSurface),
                  onPressed: () {
                    _searchController.clear();
                    _handleSearch('');
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: WebTheme.md,
            vertical: WebTheme.md,
          ),
        ),
        style: TextStyle(color: colorScheme.onSurface),
      ),
    );
  }
  Widget _buildSortDropdown(BuildContext context, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: WebTheme.md),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(WebTheme.borderRadiusSmall),
        border: Border.all(color: colorScheme.outline.withOpacity(0.3)),
      ),
      child: DropdownButton<String>(
        value: _sortBy,
        underline: const SizedBox.shrink(),
        icon: Icon(Icons.arrow_drop_down, color: colorScheme.onSurface),
        dropdownColor: colorScheme.surface,
        style: TextStyle(color: colorScheme.onSurface),
        items: [
          DropdownMenuItem(
            value: 'recent',
            child: Text('Most Recent',
                style: TextStyle(color: colorScheme.onSurface)),
          ),
          DropdownMenuItem(
            value: 'oldest',
            child: Text('Oldest First',
                style: TextStyle(color: colorScheme.onSurface)),
          ),
          DropdownMenuItem(
            value: 'alphabetical',
            child: Text('A-Z', style: TextStyle(color: colorScheme.onSurface)),
          ),
        ],
        onChanged: (value) {
          if (value != null) {
            setState(() => _sortBy = value);
          }
        },
      ),
    );
  }
  Widget _buildTabs(BuildContext context, ColorScheme colorScheme) {
    return TabBar(
      controller: _tabController,
      labelColor: colorScheme.primary,
      unselectedLabelColor: colorScheme.onSurface.withOpacity(0.6),
      indicatorColor: colorScheme.primary,
      tabs: const [
        Tab(text: 'Followers'),
        Tab(text: 'Following'),
      ],
    );
  }
  Widget _buildTabContent(
    BuildContext context,
    ColorScheme colorScheme,
    DeviceType deviceType,
  ) {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(color: colorScheme.primary),
      );
    }
    return TabBarView(
      controller: _tabController,
      children: [
        _buildUserGrid(context, colorScheme, deviceType, _mockFollowers),
        _buildUserGrid(context, colorScheme, deviceType, _mockFollowing),
      ],
    );
  }
  Widget _buildUserGrid(
    BuildContext context,
    ColorScheme colorScheme,
    DeviceType deviceType,
    List<UserItem> users,
  ) {
    final filteredUsers = users.where((user) {
      if (_searchQuery.isEmpty) return true;
      final displayName = user.name.toLowerCase();
      final username = user.username?.toLowerCase() ?? '';
      final query = _searchQuery.toLowerCase();
      return displayName.contains(query) || username.contains(query);
    }).toList();
    if (filteredUsers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 64,
              color: colorScheme.onSurface.withOpacity(0.3),
            ),
            const SizedBox(height: WebTheme.md),
            Text(
              _searchQuery.isEmpty ? 'No users found' : 'No results',
              style: TextStyle(
                fontSize: 18,
                color: colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      );
    }
    return ResponsiveGrid(
      mobileColumns: 1,
      tabletColumns: 2,
      desktopColumns: deviceType == DeviceType.largeDesktop ? 4 : 3,
      childAspectRatio: 1.2,
      children: filteredUsers.map((user) {
        return _buildUserCard(context, colorScheme, user);
      }).toList(),
    );
  }
  Widget _buildUserCard(
    BuildContext context,
    ColorScheme colorScheme,
    UserItem user,
  ) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(WebTheme.borderRadiusMedium),
        side: BorderSide(color: colorScheme.outline.withOpacity(0.2)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(WebTheme.borderRadiusMedium),
        onTap: () => widget.onNavigate('/profile/${user.id}'),
        child: Padding(
          padding: const EdgeInsets.all(WebTheme.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: WebTheme.avatarSizeMedium / 2,
                backgroundColor: colorScheme.primaryContainer,
                child: Icon(
                  Icons.person,
                  size: 32,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(height: WebTheme.md),
              Text(
                user.name,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
              if (user.username.isNotEmpty)
                Text(
                  '@${user.username}',
                  style: TextStyle(
                    fontSize: 14,
                    color: colorScheme.onSurface.withOpacity(0.6),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              const SizedBox(height: WebTheme.md),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _toggleFollow(user.id),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: user.isFollowing
                        ? colorScheme.surface
                        : colorScheme.primary,
                    foregroundColor: user.isFollowing
                        ? colorScheme.onSurface
                        : colorScheme.onPrimary,
                    side: user.isFollowing
                        ? BorderSide(color: colorScheme.outline)
                        : null,
                    padding: const EdgeInsets.symmetric(
                      vertical: WebTheme.sm,
                    ),
                  ),
                  child: Text(user.isFollowing ? 'Unfollow' : 'Follow'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  final List<UserItem> _mockFollowers = [
    UserItem(
        id: '1',
        name: 'Alice Johnson',
        username: 'alice_j',
        isFollowing: false),
    UserItem(
        id: '2', name: 'Bob Smith', username: 'bobsmith', isFollowing: true),
    UserItem(
        id: '3', name: 'Carol White', username: 'carol_w', isFollowing: false),
    UserItem(
        id: '4', name: 'David Brown', username: 'dave_b', isFollowing: true),
    UserItem(
        id: '5', name: 'Eva Green', username: 'eva_green', isFollowing: false),
    UserItem(
        id: '6',
        name: 'Frank Miller',
        username: 'frankmiller',
        isFollowing: true),
  ];
  final List<UserItem> _mockFollowing = [
    UserItem(
        id: '7',
        name: 'George Wilson',
        username: 'george_w',
        isFollowing: true),
    UserItem(
        id: '8', name: 'Hannah Lee', username: 'hannah_lee', isFollowing: true),
    UserItem(id: '9', name: 'Ian Moore', username: 'ian_m', isFollowing: true),
    UserItem(
        id: '10', name: 'Julia Taylor', username: 'julia_t', isFollowing: true),
  ];
}
class UserItem {
  final String id;
  final String name;
  final String username;
  final bool isFollowing;
  UserItem({
    required this.id,
    required this.name,
    required this.username,
    required this.isFollowing,
  });
}