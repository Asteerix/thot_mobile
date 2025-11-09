import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../core/themes/web_theme.dart';
import '../../../../../shared/widgets/web/responsive_layout.dart';
import '../../../application/providers/auth_provider.dart';
import '../../../../../core/navigation/route_names.dart';
import '../../../../../core/navigation/app_router.dart';
import '../../../data/repositories/auth_repository_impl.dart'
    show AuthException;
import '../../shared/widgets/auth_text_field.dart';
import '../../shared/widgets/auth_error_message.dart';
import '../../shared/widgets/auth_loading_button.dart';
import '../../../domain/validators/auth_validators.dart';
class LoginScreenWeb extends StatefulWidget {
  const LoginScreenWeb({super.key});
  @override
  State<LoginScreenWeb> createState() => _LoginScreenWebState();
}
class _LoginScreenWebState extends State<LoginScreenWeb> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  @override
  void initState() {
    super.initState();
    _checkAuthState();
  }
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
  void _checkAuthState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final authProvider = context.read<AuthProvider>();
      if (authProvider.isAuthenticated) {
        _handlePostLoginNavigation(authProvider);
      }
    });
  }
  void _handlePostLoginNavigation(AuthProvider authProvider) {
    if (authProvider.isAdmin) {
      AppRouter.replaceAllTo(context, RouteNames.adminDashboard);
    } else {
      AppRouter.replaceAllTo(context, RouteNames.feed);
    }
  }
  Future<void> _handleLogin() async {
    if (_formKey.currentState?.validate() != true) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final authProvider = context.read<AuthProvider>();
      await authProvider.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      if (!mounted) return;
      _handlePostLoginNavigation(authProvider);
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.message;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'An unexpected error occurred. Please try again.';
        _isLoading = false;
      });
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: ResponsiveLayout(
        builder: (context, deviceType) {
          if (deviceType == DeviceType.mobile) {
            return _buildLoginForm(context);
          }
          return Center(
            child: SingleChildScrollView(
              child: Container(
                constraints:
                    const BoxConstraints(maxWidth: WebTheme.maxFormWidth),
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
                    child: _buildLoginForm(context),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
  Widget _buildLoginForm(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Image.asset(
              'assets/logo.jpeg',
              width: 200,
              height: 100,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: WebTheme.sm),
          Center(
            child: Text(
              'Welcome back',
              style: TextStyle(
                fontSize: 18,
                color: Colors.white.withOpacity(0.7),
              ),
            ),
          ),
          const SizedBox(height: WebTheme.xl),
          if (_errorMessage != null)
            AuthErrorMessage(
              message: _errorMessage!,
              onDismiss: () => setState(() => _errorMessage = null),
            ),
          AuthTextField(
            controller: _emailController,
            labelText: 'Email',
            prefixIcon: Icons.mail,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            enabled: !_isLoading,
            validator: AuthValidators.emailValidator,
          ),
          const SizedBox(height: WebTheme.lg),
          AuthTextField(
            controller: _passwordController,
            labelText: 'Mot de passe',
            prefixIcon: Icons.lock,
            obscureText: true,
            showPasswordToggle: true,
            textInputAction: TextInputAction.done,
            enabled: !_isLoading,
            onFieldSubmitted: (_) => _handleLogin(),
            validator: AuthValidators.passwordValidator,
          ),
          const SizedBox(height: WebTheme.md),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _isLoading
                  ? null
                  : () {
                    },
              child: Text(
                'Forgot password?',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(height: WebTheme.lg),
          AuthLoadingButton(
            onPressed: _handleLogin,
            text: 'Se connecter',
            isLoading: _isLoading,
            height: WebTheme.buttonHeightLarge,
          ),
          const SizedBox(height: WebTheme.xl),
          Row(
            children: [
              Expanded(child: Divider(color: Colors.white.withOpacity(0.3))),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: WebTheme.md),
                child: Text(
                  'OR',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 12,
                  ),
                ),
              ),
              Expanded(child: Divider(color: Colors.white.withOpacity(0.3))),
            ],
          ),
          const SizedBox(height: WebTheme.xl),
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Don't have an account? ",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
                TextButton(
                  onPressed: _isLoading
                      ? null
                      : () {
                          AppRouter.navigateTo(context, RouteNames.register);
                        },
                  child: const Text(
                    'Sign Up',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
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
}