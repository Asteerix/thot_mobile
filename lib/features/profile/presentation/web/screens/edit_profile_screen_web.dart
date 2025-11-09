import 'package:flutter/material.dart';
import '../../../../../core/themes/web_theme.dart';
import '../../../../../shared/widgets/web/web_scaffold.dart';
import '../../../../../shared/widgets/web/responsive_layout.dart';
class EditProfileScreenWeb extends StatefulWidget {
  final String currentRoute;
  final Function(String route) onNavigate;
  const EditProfileScreenWeb({
    super.key,
    required this.currentRoute,
    required this.onNavigate,
  });
  @override
  State<EditProfileScreenWeb> createState() => _EditProfileScreenWebState();
}
class _EditProfileScreenWebState extends State<EditProfileScreenWeb> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  final _usernameController = TextEditingController();
  final _displayNameController = TextEditingController();
  final _bioController = TextEditingController();
  final _websiteController = TextEditingController();
  final _twitterController = TextEditingController();
  final _linkedinController = TextEditingController();
  final _githubController = TextEditingController();
  @override
  void initState() {
    super.initState();
    _loadUserData();
  }
  @override
  void dispose() {
    _usernameController.dispose();
    _displayNameController.dispose();
    _bioController.dispose();
    _websiteController.dispose();
    _twitterController.dispose();
    _linkedinController.dispose();
    _githubController.dispose();
    super.dispose();
  }
  void _loadUserData() {
    _usernameController.text = 'johndoe';
    _displayNameController.text = 'John Doe';
    _bioController.text =
        'Software developer passionate about web technologies and open source.';
    _websiteController.text = 'https://example.com';
    _twitterController.text = '@johndoe';
    _linkedinController.text = 'johndoe';
    _githubController.text = 'johndoe';
  }
  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
        widget.onNavigate('/profile');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(WebTheme.md),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(context, colorScheme),
            const SizedBox(height: WebTheme.lg),
            _buildAvatarSection(context, colorScheme),
            const SizedBox(height: WebTheme.lg),
            _buildPersonalInfoSection(context, colorScheme),
            const SizedBox(height: WebTheme.lg),
            _buildBioSection(context, colorScheme),
            const SizedBox(height: WebTheme.lg),
            _buildSocialMediaSection(context, colorScheme),
            const SizedBox(height: WebTheme.xl),
            _buildActionButtons(context, colorScheme),
          ],
        ),
      ),
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
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context, colorScheme),
                const SizedBox(height: WebTheme.xl),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: Column(
                        children: [
                          _buildAvatarSection(context, colorScheme),
                          const SizedBox(height: WebTheme.xl),
                          _buildPersonalInfoSection(context, colorScheme),
                          const SizedBox(height: WebTheme.xl),
                          _buildBioSection(context, colorScheme),
                          const SizedBox(height: WebTheme.xl),
                          _buildSocialMediaSection(context, colorScheme),
                        ],
                      ),
                    ),
                    if (isLargeScreen) ...[
                      const SizedBox(width: WebTheme.xxl),
                      Expanded(
                        flex: 1,
                        child: _buildPreviewSection(context, colorScheme),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: WebTheme.xl),
                _buildActionButtons(context, colorScheme),
              ],
            ),
          ),
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
          'Edit Profile',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
  Widget _buildAvatarSection(BuildContext context, ColorScheme colorScheme) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(WebTheme.borderRadiusMedium),
        side: BorderSide(color: colorScheme.outline.withOpacity(0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(WebTheme.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Profile Images',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: WebTheme.lg),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cover Photo',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: WebTheme.sm),
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius:
                        BorderRadius.circular(WebTheme.borderRadiusMedium),
                  ),
                  child: Center(
                    child: OutlinedButton.icon(
                      onPressed: () {
                      },
                      icon: Icon(Icons.cloud_upload),
                      label: const Text('Upload Cover Photo'),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: WebTheme.lg),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Profile Picture',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: WebTheme.sm),
                Row(
                  children: [
                    CircleAvatar(
                      radius: WebTheme.avatarSizeLarge / 2,
                      backgroundColor: colorScheme.primaryContainer,
                      child: Icon(
                        Icons.person,
                        size: 48,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(width: WebTheme.lg),
                    OutlinedButton.icon(
                      onPressed: () {
                      },
                      icon: Icon(Icons.cloud_upload),
                      label: const Text('Change Avatar'),
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
  Widget _buildPersonalInfoSection(
    BuildContext context,
    ColorScheme colorScheme,
  ) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(WebTheme.borderRadiusMedium),
        side: BorderSide(color: colorScheme.outline.withOpacity(0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(WebTheme.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Personal Information',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: WebTheme.lg),
            ResponsiveLayout(
              builder: (context, deviceType) {
                if (deviceType == DeviceType.mobile) {
                  return Column(
                    children: [
                      _buildTextField(
                        controller: _usernameController,
                        label: 'Username',
                        hint: 'Enter your username',
                        prefixIcon: Icons.alternate_email,
                        colorScheme: colorScheme,
                      ),
                      const SizedBox(height: WebTheme.md),
                      _buildTextField(
                        controller: _displayNameController,
                        label: 'Display Name',
                        hint: 'Enter your display name',
                        prefixIcon: Icons.person,
                        colorScheme: colorScheme,
                      ),
                    ],
                  );
                }
                return Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: _usernameController,
                        label: 'Username',
                        hint: 'Enter your username',
                        prefixIcon: Icons.alternate_email,
                        colorScheme: colorScheme,
                      ),
                    ),
                    const SizedBox(width: WebTheme.lg),
                    Expanded(
                      child: _buildTextField(
                        controller: _displayNameController,
                        label: 'Display Name',
                        hint: 'Enter your display name',
                        prefixIcon: Icons.person,
                        colorScheme: colorScheme,
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: WebTheme.md),
            _buildTextField(
              controller: _websiteController,
              label: 'Website',
              hint: 'https://example.com',
              prefixIcon: Icons.language,
              colorScheme: colorScheme,
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildBioSection(BuildContext context, ColorScheme colorScheme) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(WebTheme.borderRadiusMedium),
        side: BorderSide(color: colorScheme.outline.withOpacity(0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(WebTheme.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bio',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: WebTheme.lg),
            TextFormField(
              controller: _bioController,
              maxLines: 5,
              maxLength: 500,
              decoration: InputDecoration(
                hintText: 'Tell us about yourself...',
                hintStyle: TextStyle(
                  color: colorScheme.onSurface.withOpacity(0.4),
                ),
                filled: true,
                fillColor: colorScheme.surface,
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(WebTheme.borderRadiusSmall),
                  borderSide: BorderSide(
                    color: colorScheme.outline.withOpacity(0.3),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(WebTheme.borderRadiusSmall),
                  borderSide: BorderSide(
                    color: colorScheme.outline.withOpacity(0.3),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(WebTheme.borderRadiusSmall),
                  borderSide: BorderSide(color: colorScheme.primary, width: 2),
                ),
              ),
              style: TextStyle(color: colorScheme.onSurface),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildSocialMediaSection(
    BuildContext context,
    ColorScheme colorScheme,
  ) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(WebTheme.borderRadiusMedium),
        side: BorderSide(color: colorScheme.outline.withOpacity(0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(WebTheme.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Social Media',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: WebTheme.lg),
            ResponsiveLayout(
              builder: (context, deviceType) {
                if (deviceType == DeviceType.mobile) {
                  return Column(
                    children: [
                      _buildTextField(
                        controller: _twitterController,
                        label: 'Twitter',
                        hint: '@username',
                        prefixIcon: Icons.tag,
                        colorScheme: colorScheme,
                      ),
                      const SizedBox(height: WebTheme.md),
                      _buildTextField(
                        controller: _linkedinController,
                        label: 'LinkedIn',
                        hint: 'username',
                        prefixIcon: Icons.work,
                        colorScheme: colorScheme,
                      ),
                      const SizedBox(height: WebTheme.md),
                      _buildTextField(
                        controller: _githubController,
                        label: 'GitHub',
                        hint: 'username',
                        prefixIcon: Icons.code,
                        colorScheme: colorScheme,
                      ),
                    ],
                  );
                }
                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: _twitterController,
                            label: 'Twitter',
                            hint: '@username',
                            prefixIcon: Icons.tag,
                            colorScheme: colorScheme,
                          ),
                        ),
                        const SizedBox(width: WebTheme.lg),
                        Expanded(
                          child: _buildTextField(
                            controller: _linkedinController,
                            label: 'LinkedIn',
                            hint: 'username',
                            prefixIcon: Icons.work,
                            colorScheme: colorScheme,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: WebTheme.md),
                    _buildTextField(
                      controller: _githubController,
                      label: 'GitHub',
                      hint: 'username',
                      prefixIcon: Icons.code,
                      colorScheme: colorScheme,
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildPreviewSection(BuildContext context, ColorScheme colorScheme) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(WebTheme.borderRadiusMedium),
        side: BorderSide(color: colorScheme.outline.withOpacity(0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(WebTheme.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Preview',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: WebTheme.lg),
            Container(
              padding: const EdgeInsets.all(WebTheme.lg),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius:
                    BorderRadius.circular(WebTheme.borderRadiusMedium),
                border: Border.all(
                  color: colorScheme.outline.withOpacity(0.2),
                ),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: colorScheme.primaryContainer,
                    child: Icon(
                      Icons.person,
                      size: 40,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: WebTheme.md),
                  Text(
                    _displayNameController.text.isEmpty
                        ? 'Display Name'
                        : _displayNameController.text,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    _usernameController.text.isEmpty
                        ? '@username'
                        : '@${_usernameController.text}',
                    style: TextStyle(
                      fontSize: 14,
                      color: colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: WebTheme.md),
                  Text(
                    _bioController.text.isEmpty
                        ? 'Your bio will appear here'
                        : _bioController.text,
                    style: TextStyle(
                      fontSize: 14,
                      color: colorScheme.onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData prefixIcon,
    required ColorScheme colorScheme,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: WebTheme.sm),
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: colorScheme.onSurface.withOpacity(0.4),
            ),
            prefixIcon: Icon(prefixIcon, color: colorScheme.primary),
            filled: true,
            fillColor: colorScheme.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(WebTheme.borderRadiusSmall),
              borderSide: BorderSide(
                color: colorScheme.outline.withOpacity(0.3),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(WebTheme.borderRadiusSmall),
              borderSide: BorderSide(
                color: colorScheme.outline.withOpacity(0.3),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(WebTheme.borderRadiusSmall),
              borderSide: BorderSide(color: colorScheme.primary, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: WebTheme.md,
              vertical: WebTheme.md,
            ),
          ),
          style: TextStyle(color: colorScheme.onSurface),
        ),
      ],
    );
  }
  Widget _buildActionButtons(BuildContext context, ColorScheme colorScheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        OutlinedButton(
          onPressed: _isLoading ? null : () => widget.onNavigate('/profile'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(
              horizontal: WebTheme.buttonPaddingHorizontal,
              vertical: WebTheme.buttonPaddingVertical,
            ),
          ),
          child: const Text('Cancel'),
        ),
        const SizedBox(width: WebTheme.md),
        ElevatedButton(
          onPressed: _isLoading ? null : _saveProfile,
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
            padding: const EdgeInsets.symmetric(
              horizontal: WebTheme.buttonPaddingHorizontal,
              vertical: WebTheme.buttonPaddingVertical,
            ),
          ),
          child: _isLoading
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(colorScheme.onPrimary),
                  ),
                )
              : const Text('Save Changes'),
        ),
      ],
    );
  }
}