import 'package:thot/core/themes/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:animations/animations.dart';
import 'package:provider/provider.dart';
import 'package:thot/features/authentication/data/repositories/auth_repository_impl.dart';
import 'package:thot/core/infrastructure/dependency_injection.dart';
import 'package:thot/features/authentication/application/providers/auth_provider.dart';
import 'package:thot/core/utils/safe_navigation.dart';
import 'package:thot/core/extensions/context_extensions.dart';
import 'package:thot/features/profile/domain/entities/user_profile.dart';
import 'package:thot/features/authentication/presentation/mobile/screens/welcome_screen.dart';
import 'package:thot/shared/utils/responsive.dart';
import 'package:thot/shared/utils/responsive_utils.dart';
import 'package:thot/shared/widgets/logo.dart';
import 'package:thot/core/navigation/route_names.dart';
class CapitalizeFirstLetterFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }
    final capitalizedText =
        newValue.text[0].toUpperCase() + newValue.text.substring(1);
    return TextEditingValue(
      text: capitalizedText,
      selection: newValue.selection,
    );
  }
}
class RegistrationForm extends StatefulWidget {
  final bool isJournalist;
  const RegistrationForm({
    super.key,
    required this.isJournalist,
  });
  @override
  State<RegistrationForm> createState() => _RegistrationFormState();
}
class _RegistrationFormState extends State<RegistrationForm>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _authService = ServiceLocator.instance.authRepository;
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _pressCardController = TextEditingController();
  final _organizationController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _emailConfirmController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordConfirmController = TextEditingController();
  late AnimationController _shakeController;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _shakeAnimation;
  bool _obscurePassword = true;
  bool _obscurePasswordConfirm = true;
  bool _acceptedTerms = false;
  bool _isLoading = false;
  int _currentStep = 0;
  bool _hasMinLength = false;
  bool _hasUpperCase = false;
  bool _hasLowerCase = false;
  bool _hasDigit = false;
  bool _hasSpecialChar = false;
  double _passwordStrength = 0.0;
  final Map<String, FocusNode> _focusNodes = {};
  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      duration: Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));
    _shakeAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0.1, 0),
    ).animate(CurvedAnimation(
      parent: _shakeController,
      curve: Curves.elasticIn,
    ));
    _initFocusNodes();
    _passwordController.addListener(_updatePasswordStrength);
    if (widget.isJournalist) {
      _organizationController.text = 'indépendant';
    }
    _fadeController.forward();
  }
  void _initFocusNodes() {
    final fields = widget.isJournalist
        ? [
            'firstName',
            'lastName',
            'pressCard',
            'organization',
            'email',
            'emailConfirm',
            'password',
            'passwordConfirm'
          ]
        : ['username', 'email', 'emailConfirm', 'password', 'passwordConfirm'];
    for (final field in fields) {
      _focusNodes[field] = FocusNode();
    }
  }
  void _updatePasswordStrength() {
    final password = _passwordController.text;
    setState(() {
      _hasMinLength = password.length >= 8;
      _hasUpperCase = RegExp(r'[A-Z]').hasMatch(password);
      _hasLowerCase = RegExp(r'[a-z]').hasMatch(password);
      _hasDigit = RegExp(r'[0-9]').hasMatch(password);
      _hasSpecialChar = RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password);
      int strength = 0;
      if (_hasMinLength) strength++;
      if (_hasUpperCase) strength++;
      if (_hasLowerCase) strength++;
      if (_hasDigit) strength++;
      if (_hasSpecialChar) strength++;
      _passwordStrength = strength / 5.0;
    });
  }
  void _showError(String message) {
    if (!mounted) return;
    HapticFeedback.mediumImpact();
    _shakeController.forward().then((_) {
      _shakeController.reverse();
    });
    context.safeShowSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline,
                color: Theme.of(context).colorScheme.onSurface),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(fontFamily: 'Tailwind'),
              ),
            ),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        duration: Duration(seconds: 4),
      ),
    );
  }
  void _showSuccess(String message) {
    if (!mounted) return;
    HapticFeedback.lightImpact();
    context.safeShowSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle,
                color: Theme.of(context).colorScheme.onSurface),
            const SizedBox(width: 12),
            Text(
              message,
              style: const TextStyle(fontFamily: 'Tailwind'),
            ),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Le mot de passe est requis';
    }
    if (!_hasMinLength) {
      return 'Le mot de passe doit contenir au moins 8 caractères';
    }
    if (!_hasUpperCase) {
      return 'Le mot de passe doit contenir au moins une majuscule';
    }
    if (!_hasLowerCase) {
      return 'Le mot de passe doit contenir au moins une minuscule';
    }
    if (!_hasDigit) {
      return 'Le mot de passe doit contenir au moins un chiffre';
    }
    if (!_hasSpecialChar) {
      return 'Le mot de passe doit contenir au moins un caractère spécial';
    }
    return null;
  }
  bool _canProceedToNextStep() {
    if (_currentStep == 0) {
      if (widget.isJournalist) {
        bool isValid = _firstNameController.text.trim().isNotEmpty &&
            _lastNameController.text.trim().isNotEmpty &&
            _organizationController.text.trim().isNotEmpty;
        if (_pressCardController.text.trim().isNotEmpty) {
          final pressCard = _pressCardController.text.trim();
          isValid = isValid &&
              RegExp(r'^[0-9]+$').hasMatch(pressCard) &&
              pressCard.length >= 4 &&
              pressCard.length <= 20;
        }
        return isValid;
      } else {
        return _usernameController.text.trim().isNotEmpty &&
            _usernameController.text.trim().length >= 3 &&
            _usernameController.text.trim().length <= 30 &&
            !RegExp(r'[!@#$%^&*(),?":{}|<>]').hasMatch(_usernameController.text) &&
            !_usernameController.text.trim().contains(' ');
      }
    } else if (_currentStep == 1) {
      final emailValid = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
          .hasMatch(_emailController.text.trim());
      return emailValid &&
          _emailController.text.trim() == _emailConfirmController.text.trim();
    }
    return false;
  }
  void _nextStep() {
    if (_canProceedToNextStep()) {
      setState(() {
        _currentStep++;
      });
      HapticFeedback.lightImpact();
    } else {
      _showError('Veuillez remplir tous les champs requis correctement');
    }
  }
  void _previousStep() {
    setState(() {
      _currentStep--;
    });
    HapticFeedback.selectionClick();
  }
  Future<void> _handleRegistration() async {
    final isValid = _formKey.currentState!.validate();
    if (!isValid) {
      _shakeController.forward().then((_) {
        _shakeController.reverse();
      });
      return;
    }
    if (!_acceptedTerms) {
      _showError('Veuillez accepter les conditions d\'utilisation');
      return;
    }
    setState(() {
      _isLoading = true;
    });
    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text;
      if (widget.isJournalist) {
        if (_firstNameController.text.isEmpty ||
            _lastNameController.text.isEmpty) {
          throw AuthException('Le prénom et le nom sont requis');
        }
        final name =
            '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}';
        final pressCard = _pressCardController.text.trim().isEmpty
            ? null
            : _pressCardController.text.trim();
        final organization = _organizationController.text.trim();
        final profile = await _authService.register(
          username: name,
          email: email,
          password: password,
          type: UserType.journalist,
          name: name,
          organization: organization,
          pressCard: pressCard,
        );
        if (!mounted) return;
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        authProvider.setUserProfile(profile);
        await authProvider.login(email: email, password: password);
      } else {
        if (_usernameController.text.isEmpty) {
          throw AuthException('Le nom d\'utilisateur est requis');
        }
        final username = _usernameController.text.trim();
        final profile = await _authService.register(
          username: username,
          email: email,
          password: password,
          type: UserType.regular,
        );
        if (!mounted) return;
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        authProvider.setUserProfile(profile);
        await authProvider.login(email: email, password: password);
      }
      if (!mounted) return;
      _showSuccess('Inscription réussie !');
      context.go('/feed');
    } on AuthException catch (e) {
      if (!mounted) return;
      String errorMessage = e.message;
      if (e.code == 'email_exists') {
        errorMessage = 'Cet email est déjà utilisé';
      } else if (e.code == 'username_exists') {
        errorMessage = 'Ce nom d\'utilisateur est déjà utilisé';
      } else if (e.code == 'invalid_email') {
        errorMessage = 'Email invalide';
      } else if (e.code == 'password_too_weak') {
        errorMessage = 'Le mot de passe est trop faible';
      }
      _showError(errorMessage);
    } catch (e) {
      if (!mounted) return;
      _showError('Une erreur est survenue lors de l\'inscription');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : cs.surface,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [AppColors.darkBackground, AppColors.darkSurface]
                : [cs.surface, cs.surfaceContainerHighest],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Center(
                child: Container(
                  width: ResponsiveUtils.isWebOrTablet(context)
                      ? 600
                      : double.infinity,
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(cs),
                      const SizedBox(height: 32),
                      _buildFormCard(cs, isDark),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
  Widget _buildHeader(ColorScheme cs) {
    return Column(
      children: [
        Semantics(
          button: true,
          label: 'Retour',
          child: IconButton(
            icon: Icon(Icons.arrow_back, color: cs.onSurface),
            onPressed: () {
              HapticFeedback.selectionClick();
              if (Navigator.of(context).canPop()) {
                SafeNavigation.pop(context);
              } else {
                context.go(RouteNames.modeSelection);
              }
            },
            style: IconButton.styleFrom(
              backgroundColor: cs.surfaceContainerHighest,
              padding: EdgeInsets.all(12),
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Hero(
          tag: 'logo',
          child: Logo(),
        ),
      ],
    );
  }
  Widget _buildFormCard(ColorScheme cs, bool isDark) {
    return SlideTransition(
      position: _shakeAnimation,
      child: Container(
        width: double.infinity,
        margin: EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: cs.surfaceContainer,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: isDark ? 0.3 : 0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            _buildStepIndicator(cs),
            _buildFormContent(cs),
          ],
        ),
      ),
    );
  }
  Widget _buildStepIndicator(ColorScheme cs) {
    final steps = widget.isJournalist
        ? ['Identité', 'Email', 'Sécurité']
        : ['Profil', 'Email', 'Sécurité'];
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: cs.outline.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          Text(
            widget.isJournalist ? 'Inscription Journaliste' : 'Inscription',
            style: TextStyle(
              color: cs.onSurface,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              fontFamily: 'Tailwind',
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: List.generate(steps.length, (index) {
              final isActive = index == _currentStep;
              final isCompleted = index < _currentStep;
              return Expanded(
                child: Semantics(
                  label:
                      '${steps[index]}, étape ${index + 1} sur ${steps.length}',
                  selected: isActive,
                  child: Column(
                    children: [
                      AnimatedContainer(
                        duration: Duration(milliseconds: 300),
                        height: 4,
                        margin: EdgeInsets.symmetric(
                          horizontal: index == 1 ? 4 : 0,
                        ),
                        decoration: BoxDecoration(
                          color: isActive
                              ? cs.primary
                              : isCompleted
                                  ? cs.primary.withOpacity(0.5)
                                  : cs.outline.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        steps[index],
                        style: TextStyle(
                          color: isActive
                              ? cs.primary
                              : isCompleted
                                  ? cs.onSurfaceVariant
                                  : cs.outline,
                          fontSize: 12,
                          fontWeight:
                              isActive ? FontWeight.bold : FontWeight.normal,
                          fontFamily: 'Tailwind',
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
  Widget _buildFormContent(ColorScheme cs) {
    return Padding(
      padding: EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: PageTransitionSwitcher(
          duration: Duration(milliseconds: 300),
          transitionBuilder: (child, primaryAnimation, secondaryAnimation) {
            return SharedAxisTransition(
              animation: primaryAnimation,
              secondaryAnimation: secondaryAnimation,
              transitionType: SharedAxisTransitionType.horizontal,
              child: child,
            );
          },
          child: _buildCurrentStep(cs),
        ),
      ),
    );
  }
  Widget _buildCurrentStep(ColorScheme cs) {
    switch (_currentStep) {
      case 0:
        return _buildIdentityStep(cs);
      case 1:
        return _buildEmailStep(cs);
      case 2:
        return _buildSecurityStep(cs);
      default:
        return const SizedBox();
    }
  }
  Widget _buildIdentityStep(ColorScheme cs) {
    return Column(
      key: const ValueKey(0),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.isJournalist) ...[
          _buildModernTextField(
            label: 'Prénom',
            controller: _firstNameController,
            focusNode: _focusNodes['firstName'],
            nextFocusNode: _focusNodes['lastName'],
            icon: Icons.person,
            cs: cs,
            inputFormatters: [CapitalizeFirstLetterFormatter()],
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Le prénom est requis';
              }
              if (value.trim().length < 2) {
                return 'Minimum 2 caractères';
              }
              if (value.trim().length > 50) {
                return 'Maximum 50 caractères';
              }
              if (RegExp(r'[0-9]').hasMatch(value)) {
                return 'Le prénom ne peut pas contenir de chiffres';
              }
              if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(value)) {
                return 'Caractères spéciaux non autorisés';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          _buildModernTextField(
            label: 'Nom',
            controller: _lastNameController,
            focusNode: _focusNodes['lastName'],
            nextFocusNode: _focusNodes['pressCard'],
            icon: Icons.person,
            cs: cs,
            inputFormatters: [CapitalizeFirstLetterFormatter()],
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Le nom est requis';
              }
              if (value.trim().length < 2) {
                return 'Minimum 2 caractères';
              }
              if (value.trim().length > 50) {
                return 'Maximum 50 caractères';
              }
              if (RegExp(r'[0-9]').hasMatch(value)) {
                return 'Le nom ne peut pas contenir de chiffres';
              }
              if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(value)) {
                return 'Caractères spéciaux non autorisés';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          _buildModernTextField(
            label: 'Carte de presse (optionnel)',
            controller: _pressCardController,
            focusNode: _focusNodes['pressCard'],
            nextFocusNode: _focusNodes['organization'],
            icon: Icons.verified,
            keyboardType: TextInputType.number,
            cs: cs,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return null;
              }
              if (!RegExp(r'^[0-9]+$').hasMatch(value.trim())) {
                return 'Seulement des chiffres';
              }
              if (value.trim().length < 4) {
                return 'Minimum 4 chiffres';
              }
              if (value.trim().length > 20) {
                return 'Maximum 20 chiffres';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          _buildModernTextField(
            label: 'Organisation',
            controller: _organizationController,
            focusNode: _focusNodes['organization'],
            icon: Icons.business,
            cs: cs,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'L\'organisation est requise';
              }
              if (value.trim().length < 2) {
                return 'Minimum 2 caractères';
              }
              if (value.trim().length > 100) {
                return 'Maximum 100 caractères';
              }
              return null;
            },
          ),
        ] else ...[
          _buildModernTextField(
            label: 'Nom d\'utilisateur',
            controller: _usernameController,
            focusNode: _focusNodes['username'],
            icon: Icons.person,
            cs: cs,
            helperText: 'Lettres, chiffres et underscore uniquement',
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Le nom d\'utilisateur est requis';
              }
              if (value.trim().length < 3) {
                return 'Minimum 3 caractères';
              }
              if (value.trim().length > 30) {
                return 'Maximum 30 caractères';
              }
              if (RegExp(r'[!@#$%^&*(),?":{}|<>]').hasMatch(value)) {
                return 'Caractères spéciaux non autorisés';
              }
              if (value.trim().contains(' ')) {
                return 'Pas d\'espaces autorisés';
              }
              return null;
            },
          ),
        ],
        const SizedBox(height: 32),
        _buildNavigationButtons(cs),
      ],
    );
  }
  Widget _buildEmailStep(ColorScheme cs) {
    return Column(
      key: const ValueKey(1),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildModernTextField(
          label: 'Adresse email',
          controller: _emailController,
          focusNode: _focusNodes['email'],
          nextFocusNode: _focusNodes['emailConfirm'],
          icon: Icons.mail,
          keyboardType: TextInputType.emailAddress,
          cs: cs,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'L\'email est requis';
            }
            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
              return 'Email invalide';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        _buildModernTextField(
          label: 'Confirmer l\'email',
          controller: _emailConfirmController,
          focusNode: _focusNodes['emailConfirm'],
          icon: Icons.mail,
          keyboardType: TextInputType.emailAddress,
          cs: cs,
          validator: (value) {
            if (value != _emailController.text) {
              return 'Les emails ne correspondent pas';
            }
            return null;
          },
        ),
        const SizedBox(height: 32),
        _buildNavigationButtons(cs),
      ],
    );
  }
  Widget _buildSecurityStep(ColorScheme cs) {
    return Column(
      key: const ValueKey(2),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPasswordField(
          label: 'Mot de passe',
          controller: _passwordController,
          focusNode: _focusNodes['password'],
          nextFocusNode: _focusNodes['passwordConfirm'],
          obscure: _obscurePassword,
          cs: cs,
          onToggleObscure: () {
            setState(() {
              _obscurePassword = !_obscurePassword;
            });
          },
        ),
        const SizedBox(height: 8),
        _buildPasswordStrengthIndicator(cs),
        const SizedBox(height: 16),
        _buildPasswordField(
          label: 'Confirmer le mot de passe',
          controller: _passwordConfirmController,
          focusNode: _focusNodes['passwordConfirm'],
          obscure: _obscurePasswordConfirm,
          cs: cs,
          isConfirm: true,
          onToggleObscure: () {
            setState(() {
              _obscurePasswordConfirm = !_obscurePasswordConfirm;
            });
          },
        ),
        const SizedBox(height: 24),
        _buildTermsAndConditions(cs),
        const SizedBox(height: 32),
        _buildSubmitButton(cs),
        const SizedBox(height: 16),
        _buildNavigationButtons(cs, isLastStep: true),
      ],
    );
  }
  Widget _buildModernTextField({
    required String label,
    required TextEditingController controller,
    FocusNode? focusNode,
    FocusNode? nextFocusNode,
    required IconData icon,
    required ColorScheme cs,
    String? helperText,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return Semantics(
      textField: true,
      label: label,
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        style: TextStyle(
          color: cs.onSurface,
          fontFamily: 'Tailwind',
          fontSize: 16,
        ),
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        textInputAction:
            nextFocusNode != null ? TextInputAction.next : TextInputAction.done,
        onFieldSubmitted: (_) {
          if (nextFocusNode != null) {
            FocusScope.of(context).requestFocus(nextFocusNode);
          }
        },
        decoration: InputDecoration(
          labelText: label,
          helperText: helperText,
          helperStyle: TextStyle(
            color: cs.onSurfaceVariant,
            fontSize: 12,
          ),
          labelStyle: TextStyle(
            color: cs.onSurfaceVariant,
            fontFamily: 'Tailwind',
          ),
          prefixIcon: Icon(icon, color: cs.onSurfaceVariant),
          filled: true,
          fillColor: cs.surfaceContainerHighest,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: cs.primary, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: cs.error, width: 1),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: cs.error, width: 2),
          ),
          contentPadding: EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
        ),
        validator: validator ??
            (value) {
              if (value == null || value.isEmpty) {
                return 'Ce champ est requis';
              }
              return null;
            },
      ),
    );
  }
  Widget _buildPasswordField({
    required String label,
    required TextEditingController controller,
    FocusNode? focusNode,
    FocusNode? nextFocusNode,
    required bool obscure,
    required ColorScheme cs,
    required VoidCallback onToggleObscure,
    bool isConfirm = false,
  }) {
    return Semantics(
      textField: true,
      label: label,
      obscured: obscure,
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        obscureText: obscure,
        style: TextStyle(
          color: cs.onSurface,
          fontFamily: 'Tailwind',
          fontSize: 16,
        ),
        textInputAction:
            nextFocusNode != null ? TextInputAction.next : TextInputAction.done,
        onFieldSubmitted: (_) {
          if (nextFocusNode != null) {
            FocusScope.of(context).requestFocus(nextFocusNode);
          }
        },
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: cs.onSurfaceVariant,
            fontFamily: 'Tailwind',
          ),
          prefixIcon: Icon(Icons.lock, color: cs.onSurfaceVariant),
          suffixIcon: IconButton(
            icon: Icon(
              obscure ? Icons.visibility_off : Icons.visibility,
              color: cs.onSurfaceVariant,
            ),
            onPressed: onToggleObscure,
          ),
          filled: true,
          fillColor: cs.surfaceContainerHighest,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: cs.primary, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: cs.error, width: 1),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: cs.error, width: 2),
          ),
          contentPadding: EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
        ),
        validator: (value) {
          if (isConfirm) {
            if (value != _passwordController.text) {
              return 'Les mots de passe ne correspondent pas';
            }
            return null;
          }
          return _validatePassword(value);
        },
      ),
    );
  }
  Widget _buildPasswordStrengthIndicator(ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedContainer(
          duration: Duration(milliseconds: 300),
          height: 4,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(2),
            gradient: LinearGradient(
              colors: [
                _passwordStrength >= 0.2
                    ? (_passwordStrength >= 0.6
                        ? (_passwordStrength >= 0.8
                            ? Colors.green
                            : AppColors.orange)
                        : AppColors.red)
                    : cs.outline.withOpacity(0.3),
                cs.outline.withOpacity(0.3),
              ],
              stops: [_passwordStrength, _passwordStrength],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            _buildStrengthChip('8+ caractères', _hasMinLength, cs),
            _buildStrengthChip('Majuscule', _hasUpperCase, cs),
            _buildStrengthChip('Minuscule', _hasLowerCase, cs),
            _buildStrengthChip('Chiffre', _hasDigit, cs),
            _buildStrengthChip('Spécial', _hasSpecialChar, cs),
          ],
        ),
      ],
    );
  }
  Widget _buildStrengthChip(String label, bool satisfied, ColorScheme cs) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 200),
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: satisfied ? cs.primaryContainer : cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            satisfied ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 12,
            color: satisfied ? cs.primary : cs.outline,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: satisfied ? cs.onPrimaryContainer : cs.onSurfaceVariant,
              fontFamily: 'Tailwind',
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildTermsAndConditions(ColorScheme cs) {
    return Semantics(
      checked: _acceptedTerms,
      label:
          'J\'accepte les conditions d\'utilisation et la politique de confidentialité',
      onTap: () {
        setState(() {
          _acceptedTerms = !_acceptedTerms;
        });
        HapticFeedback.selectionClick();
      },
      child: InkWell(
        onTap: () {
          setState(() {
            _acceptedTerms = !_acceptedTerms;
          });
          HapticFeedback.selectionClick();
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _acceptedTerms ? cs.primary : cs.outline.withOpacity(0.3),
              width: _acceptedTerms ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: Duration(milliseconds: 200),
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: _acceptedTerms ? cs.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: _acceptedTerms ? cs.primary : Colors.white,
                    width: 2,
                  ),
                ),
                child: _acceptedTerms
                    ? Icon(Icons.check, size: 16, color: cs.onPrimary)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Wrap(
                  children: [
                    Text(
                      'J\'accepte les ',
                      style: TextStyle(
                        color: cs.onSurface,
                        fontFamily: 'Tailwind',
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.pushNamed(RouteNames.terms),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'conditions',
                        style: TextStyle(
                          color: cs.primary,
                          fontFamily: 'Tailwind',
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                    Text(
                      ' et la ',
                      style: TextStyle(
                        color: cs.onSurface,
                        fontFamily: 'Tailwind',
                      ),
                    ),
                    TextButton(
                      onPressed: () =>
                          context.pushNamed(RouteNames.privacyPolicy),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'confidentialité',
                        style: TextStyle(
                          color: cs.primary,
                          fontFamily: 'Tailwind',
                          decoration: TextDecoration.underline,
                        ),
                      ),
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
  Widget _buildNavigationButtons(ColorScheme cs, {bool isLastStep = false}) {
    return Row(
      children: [
        if (_currentStep > 0) ...[
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _previousStep,
              icon: Icon(Icons.arrow_back),
              label: const Text('Retour'),
              style: OutlinedButton.styleFrom(
                foregroundColor: cs.onSurface,
                side: BorderSide(color: cs.outline),
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
        ],
        if (!isLastStep)
          Expanded(
            child: FilledButton.icon(
              onPressed: _canProceedToNextStep() ? _nextStep : null,
              icon: Icon(Icons.arrow_forward),
              label: const Text('Continuer'),
              style: FilledButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
      ],
    );
  }
  Widget _buildSubmitButton(ColorScheme cs) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: FilledButton(
        onPressed: _isLoading ? null : _handleRegistration,
        style: FilledButton.styleFrom(
          backgroundColor: cs.primary,
          foregroundColor: cs.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: _isLoading
            ? SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(cs.onPrimary),
                ),
              )
            : const Text(
                'S\'inscrire',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Tailwind',
                  letterSpacing: 0.5,
                ),
              ),
      ),
    );
  }
  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _pressCardController.dispose();
    _organizationController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _emailConfirmController.dispose();
    _passwordController.dispose();
    _passwordConfirmController.dispose();
    _shakeController.dispose();
    _fadeController.dispose();
    for (final node in _focusNodes.values) {
      node.dispose();
    }
    super.dispose();
  }
}