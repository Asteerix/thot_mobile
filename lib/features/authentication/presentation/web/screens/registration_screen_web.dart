import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../core/themes/web_theme.dart';
import '../../../../../shared/widgets/web/responsive_layout.dart';
import '../../../application/providers/auth_provider.dart';
import '../../../../../core/navigation/route_names.dart';
import '../../../../../core/navigation/app_router.dart';
class RegistrationScreenWeb extends StatefulWidget {
  const RegistrationScreenWeb({super.key});
  @override
  State<RegistrationScreenWeb> createState() => _RegistrationScreenWebState();
}
class _RegistrationScreenWebState extends State<RegistrationScreenWeb> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _usernameController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreedToTerms = false;
  String? _errorMessage;
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _usernameController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }
  Future<void> _handleRegister() async {
    if (_formKey.currentState?.validate() != true) return;
    if (!_agreedToTerms) {
      setState(() {
        _errorMessage = 'Please agree to the Terms and Conditions';
      });
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final authProvider = context.read<AuthProvider>();
      await authProvider.register(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        username: _usernameController.text.trim(),
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
      );
      if (!mounted) return;
      AppRouter.replaceAllTo(context, RouteNames.feed);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: Colors.black,
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
      child: Padding(
        padding: const EdgeInsets.all(WebTheme.lg),
        child: _buildRegistrationForm(context, colorScheme),
      ),
    );
  }
  Widget _buildDesktopLayout(BuildContext context, ColorScheme colorScheme) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: WebTheme.maxContentWidth),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(WebTheme.xxl),
                child: Card(
                  elevation: 4,
                  color: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(WebTheme.borderRadiusLarge),
                    side: BorderSide(
                      color: Colors.white.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(WebTheme.cardPaddingLarge),
                    child: _buildRegistrationForm(context, colorScheme),
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(WebTheme.xxl),
                child: _buildInfoSection(context, colorScheme),
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildRegistrationForm(BuildContext context, ColorScheme colorScheme) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Image.asset(
              'assets/logo.jpeg',
              width: 200,
              height: 100,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: WebTheme.lg),
          Text(
            'Create Account',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: WebTheme.sm),
          Text(
            'Join the THOT community',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: WebTheme.xl),
          if (_errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(WebTheme.md),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius:
                    BorderRadius.circular(WebTheme.borderRadiusMedium),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline,
                      color: Colors.red),
                  const SizedBox(width: WebTheme.sm),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: WebTheme.lg),
          ],
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _firstNameController,
                  enabled: !_isLoading,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'First Name',
                    labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                    prefixIcon: Icon(Icons.person_outline, color: Colors.white.withOpacity(0.7)),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.05),
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(WebTheme.borderRadiusMedium),
                      borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(WebTheme.borderRadiusMedium),
                      borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(WebTheme.borderRadiusMedium),
                      borderSide: const BorderSide(color: Colors.white, width: 2),
                    ),
                  ),
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Required' : null,
                ),
              ),
              const SizedBox(width: WebTheme.md),
              Expanded(
                child: TextFormField(
                  controller: _lastNameController,
                  enabled: !_isLoading,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Last Name',
                    labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                    prefixIcon: Icon(Icons.person_outline, color: Colors.white.withOpacity(0.7)),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.05),
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(WebTheme.borderRadiusMedium),
                      borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(WebTheme.borderRadiusMedium),
                      borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(WebTheme.borderRadiusMedium),
                      borderSide: const BorderSide(color: Colors.white, width: 2),
                    ),
                  ),
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Required' : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: WebTheme.lg),
          TextFormField(
            controller: _usernameController,
            enabled: !_isLoading,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Username',
              labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
              prefixIcon: Icon(Icons.alternate_email, color: Colors.white.withOpacity(0.7)),
              filled: true,
              fillColor: Colors.white.withOpacity(0.05),
              border: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(WebTheme.borderRadiusMedium),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(WebTheme.borderRadiusMedium),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(WebTheme.borderRadiusMedium),
                borderSide: const BorderSide(color: Colors.white, width: 2),
              ),
            ),
            validator: (value) {
              if (value?.isEmpty ?? true) return 'Required';
              if (value!.length < 3) return 'At least 3 characters';
              return null;
            },
          ),
          const SizedBox(height: WebTheme.lg),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            enabled: !_isLoading,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Email',
              labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
              prefixIcon: Icon(Icons.email_outlined, color: Colors.white.withOpacity(0.7)),
              filled: true,
              fillColor: Colors.white.withOpacity(0.05),
              border: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(WebTheme.borderRadiusMedium),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(WebTheme.borderRadiusMedium),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(WebTheme.borderRadiusMedium),
                borderSide: const BorderSide(color: Colors.white, width: 2),
              ),
            ),
            validator: (value) {
              if (value?.isEmpty ?? true) return 'Required';
              if (!value!.contains('@')) return 'Invalid email';
              return null;
            },
          ),
          const SizedBox(height: WebTheme.lg),
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            enabled: !_isLoading,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Password',
              labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
              prefixIcon: Icon(Icons.lock_outline, color: Colors.white.withOpacity(0.7)),
              suffixIcon: IconButton(
                icon: Icon(
                    _obscurePassword ? Icons.visibility : Icons.visibility_off,
                    color: Colors.white.withOpacity(0.7)),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
              filled: true,
              fillColor: Colors.white.withOpacity(0.05),
              border: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(WebTheme.borderRadiusMedium),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(WebTheme.borderRadiusMedium),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(WebTheme.borderRadiusMedium),
                borderSide: const BorderSide(color: Colors.white, width: 2),
              ),
            ),
            validator: (value) {
              if (value?.isEmpty ?? true) return 'Required';
              if (value!.length < 8) return 'At least 8 characters';
              return null;
            },
          ),
          const SizedBox(height: WebTheme.lg),
          TextFormField(
            controller: _confirmPasswordController,
            obscureText: _obscureConfirmPassword,
            enabled: !_isLoading,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Confirm Password',
              labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
              prefixIcon: Icon(Icons.lock_outline, color: Colors.white.withOpacity(0.7)),
              suffixIcon: IconButton(
                icon: Icon(_obscureConfirmPassword
                    ? Icons.visibility
                    : Icons.visibility_off,
                    color: Colors.white.withOpacity(0.7)),
                onPressed: () => setState(
                    () => _obscureConfirmPassword = !_obscureConfirmPassword),
              ),
              filled: true,
              fillColor: Colors.white.withOpacity(0.05),
              border: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(WebTheme.borderRadiusMedium),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(WebTheme.borderRadiusMedium),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(WebTheme.borderRadiusMedium),
                borderSide: const BorderSide(color: Colors.white, width: 2),
              ),
            ),
            validator: (value) {
              if (value != _passwordController.text) {
                return 'Passwords do not match';
              }
              return null;
            },
          ),
          const SizedBox(height: WebTheme.lg),
          CheckboxListTile(
            value: _agreedToTerms,
            onChanged: _isLoading
                ? null
                : (value) {
                    setState(() => _agreedToTerms = value ?? false);
                  },
            controlAffinity: ListTileControlAffinity.leading,
            checkColor: Colors.black,
            activeColor: Colors.white,
            side: BorderSide(color: Colors.white.withOpacity(0.5)),
            title: Text.rich(
              TextSpan(
                text: 'I agree to the ',
                style: TextStyle(color: Colors.white),
                children: [
                  TextSpan(
                    text: 'Terms and Conditions',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: WebTheme.xl),
          SizedBox(
            height: WebTheme.buttonHeightLarge,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleRegister,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(WebTheme.borderRadiusMedium),
                ),
              ),
              child: _isLoading
                  ? SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.black),
                      ),
                    )
                  : const Text(
                      'Create Account',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
            ),
          ),
          const SizedBox(height: WebTheme.lg),
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Already have an account? ',
                  style:
                      TextStyle(color: Colors.white.withOpacity(0.7)),
                ),
                TextButton(
                  onPressed: _isLoading
                      ? null
                      : () => AppRouter.navigateTo(context, RouteNames.login),
                  child: Text(
                    'Sign In',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildInfoSection(BuildContext context, ColorScheme colorScheme) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.menu_book, size: 64, color: Colors.white),
        const SizedBox(height: WebTheme.xl),
        Text(
          'Join THOT',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: WebTheme.md),
        Text(
          'Discover, share, and engage with knowledge.',
          style: TextStyle(
            fontSize: 16,
            color: Colors.white.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: WebTheme.xl),
        _buildInfoItem(
          context,
          Icons.article_outlined,
          'Share Articles',
          'Write and publish your thoughts',
        ),
        const SizedBox(height: WebTheme.lg),
        _buildInfoItem(
          context,
          Icons.video_library_outlined,
          'Post Shorts',
          'Quick videos and updates',
        ),
        const SizedBox(height: WebTheme.lg),
        _buildInfoItem(
          context,
          Icons.people_outline,
          'Connect',
          'Build your network of thinkers',
        ),
      ],
    );
  }
  Widget _buildInfoItem(
    BuildContext context,
    IconData icon,
    String title,
    String description,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(WebTheme.md),
          decoration: BoxDecoration(
            color: Colors.whiteContainer,
            borderRadius: BorderRadius.circular(WebTheme.borderRadiusMedium),
          ),
          child: Icon(icon, color: Colors.blackContainer),
        ),
        const SizedBox(width: WebTheme.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: WebTheme.xs),
              Text(
                description,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}