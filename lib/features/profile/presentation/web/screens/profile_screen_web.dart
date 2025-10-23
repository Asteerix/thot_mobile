import 'package:flutter/material.dart';
import '../../../../../core/themes/web_theme.dart';
import '../../../../../shared/widgets/web/web_scaffold.dart';
import '../../../../../shared/widgets/web/responsive_layout.dart';
class ProfileScreenWeb extends StatefulWidget {
  final String userId;
  final String currentRoute;
  final Function(String route) onNavigate;
  const ProfileScreenWeb({
    super.key,
    required this.userId,
    required this.currentRoute,
    required this.onNavigate,
  });
  @override
  State<ProfileScreenWeb> createState() => _ProfileScreenWebState();
}
class _ProfileScreenWebState extends State<ProfileScreenWeb>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
          return _buildDesktopLayout(context, colorScheme);
        },
      ),
    );
  }
  Widget _buildMobileLayout(BuildContext context, ColorScheme colorScheme) {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildProfileHeader(context, colorScheme, false),
          _buildProfileContent(context, colorScheme),
        ],
      ),
    );
  }
  Widget _buildDesktopLayout(BuildContext context, ColorScheme colorScheme) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: WebTheme.maxContentWidth),
        padding: const EdgeInsets.all(WebTheme.xxl),
        child: Column(
          children: [
            _buildProfileHeader(context, colorScheme, true),
            const SizedBox(height: WebTheme.xl),
            Expanded(child: _buildProfileContent(context, colorScheme)),
          ],
        ),
      ),
    );
  }
  Widget _buildProfileHeader(
    BuildContext context,
    ColorScheme colorScheme,
    bool isDesktop,
  ) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(WebTheme.borderRadiusMedium),
        side: BorderSide(color: colorScheme.outline.withOpacity(0.2)),
      ),
      child: Padding(
        padding: EdgeInsets.all(isDesktop ? WebTheme.xl : WebTheme.lg),
        child: Column(
          children: [
            Container(
              height: isDesktop ? 200 : 120,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius:
                    BorderRadius.circular(WebTheme.borderRadiusMedium),
              ),
            ),
            const SizedBox(height: WebTheme.lg),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: isDesktop
                      ? WebTheme.avatarSizeLarge / 2
                      : WebTheme.avatarSizeMedium / 2,
                  backgroundColor: colorScheme.surface,
                  child: CircleAvatar(
                    radius: isDesktop
                        ? (WebTheme.avatarSizeLarge / 2) - 4
                        : (WebTheme.avatarSizeMedium / 2) - 4,
                    backgroundColor: colorScheme.primaryContainer,
                    child: Icon(
                      Icons.person,
                      size: isDesktop ? 48 : 32,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
                const SizedBox(width: WebTheme.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'John Doe',
                        style: TextStyle(
                          fontSize: isDesktop ? 28 : 24,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        '@johndoe',
                        style: TextStyle(
                          fontSize: 16,
                          color: colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                      const SizedBox(height: WebTheme.sm),
                      Text(
                        'Software developer passionate about web technologies and open source.',
                        style: TextStyle(
                          fontSize: 15,
                          color: colorScheme.onSurface.withOpacity(0.8),
                        ),
                      ),
                      const SizedBox(height: WebTheme.md),
                      Row(
                        children: [
                          _buildStatItem(context, '1.2K', 'Posts'),
                          const SizedBox(width: WebTheme.xl),
                          _buildStatItem(context, '5.4K', 'Followers'),
                          const SizedBox(width: WebTheme.xl),
                          _buildStatItem(context, '892', 'Following'),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.edit, size: 18),
                      label: const Text('Edit Profile'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                      ),
                    ),
                    const SizedBox(height: WebTheme.sm),
                    OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.share, size: 18),
                      label: const Text('Share'),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildStatItem(BuildContext context, String value, String label) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
      ],
    );
  }
  Widget _buildProfileContent(BuildContext context, ColorScheme colorScheme) {
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          labelColor: colorScheme.primary,
          unselectedLabelColor: colorScheme.onSurface.withOpacity(0.6),
          indicatorColor: colorScheme.primary,
          tabs: const [
            Tab(text: 'Posts'),
            Tab(text: 'Articles'),
            Tab(text: 'Shorts'),
            Tab(text: 'Likes'),
          ],
        ),
        const SizedBox(height: WebTheme.lg),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildPostsGrid(context, colorScheme),
              _buildPostsGrid(context, colorScheme),
              _buildPostsGrid(context, colorScheme),
              _buildPostsGrid(context, colorScheme),
            ],
          ),
        ),
      ],
    );
  }
  Widget _buildPostsGrid(BuildContext context, ColorScheme colorScheme) {
    return ResponsiveGrid(
      desktopColumns: 3,
      tabletColumns: 2,
      mobileColumns: 1,
      childAspectRatio: 1.5,
      children: List.generate(
        9,
        (index) => Card(
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(WebTheme.borderRadiusMedium),
          ),
          child: InkWell(
            onTap: () {},
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  'https://via.placeholder.com/400x300',
                  fit: BoxFit.cover,
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(WebTheme.md),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Theme.of(context).brightness == Brightness.dark
                              ? Colors.black.withOpacity(0.7)
                              : Colors.black.withOpacity(0.5),
                        ],
                      ),
                    ),
                    child: Text(
                      'Post Title ${index + 1}',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}