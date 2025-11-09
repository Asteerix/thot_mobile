import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:thot/features/authentication/application/providers/auth_provider.dart';
import 'package:thot/features/authentication/data/repositories/auth_repository_impl.dart';
import 'package:thot/core/infrastructure/dependency_injection.dart';
import 'package:thot/features/profile/domain/entities/user_profile.dart';
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
class RegistrationStepper extends StatefulWidget {
  final bool isJournalist;
  const RegistrationStepper({super.key, required this.isJournalist});
  @override
  State<RegistrationStepper> createState() => _RegistrationStepperState();
}
class _RegistrationStepperState extends State<RegistrationStepper>
    with TickerProviderStateMixin {
  final _identityFormKey = GlobalKey<FormState>();
  final _emailFormKey = GlobalKey<FormState>();
  final _passwordFormKey = GlobalKey<FormState>();
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
  final PageController _pageController = PageController();
  late AnimationController _slideController;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  bool _obscurePassword = true;
  bool _obscurePasswordConfirm = true;
  bool _acceptedTerms = false;
  bool _isLoading = false;
  int _currentStep = 0;
  bool _isCurrentStepValid = false;
  bool _hasStartedTypingUsername = false;
  bool _hasStartedTypingFirstName = false;
  bool _hasStartedTypingLastName = false;
  bool _hasStartedTypingOrganization = false;
  bool _hasStartedTypingPressCard = false;
  bool _hasStartedTypingEmail = false;
  bool _hasStartedTypingEmailConfirm = false;
  bool _hasStartedTypingPassword = false;
  bool _hasStartedTypingPasswordConfirm = false;
  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    _slideController.forward();
    _setupListeners();
  }
  void _setupListeners() {
    _usernameController.addListener(() {
      if (!_hasStartedTypingUsername && _usernameController.text.isNotEmpty) {
        setState(() => _hasStartedTypingUsername = true);
      }
      _validateCurrentStep();
    });
    _firstNameController.addListener(() {
      if (!_hasStartedTypingFirstName && _firstNameController.text.isNotEmpty) {
        setState(() => _hasStartedTypingFirstName = true);
      }
      _validateCurrentStep();
    });
    _lastNameController.addListener(() {
      if (!_hasStartedTypingLastName && _lastNameController.text.isNotEmpty) {
        setState(() => _hasStartedTypingLastName = true);
      }
      _validateCurrentStep();
    });
    _organizationController.addListener(() {
      if (!_hasStartedTypingOrganization && _organizationController.text.isNotEmpty) {
        setState(() => _hasStartedTypingOrganization = true);
      }
      _validateCurrentStep();
    });
    _pressCardController.addListener(() {
      if (!_hasStartedTypingPressCard && _pressCardController.text.isNotEmpty) {
        setState(() => _hasStartedTypingPressCard = true);
      }
      _validateCurrentStep();
    });
    _emailController.addListener(() {
      if (!_hasStartedTypingEmail && _emailController.text.isNotEmpty) {
        setState(() => _hasStartedTypingEmail = true);
      }
      _validateCurrentStep();
    });
    _emailConfirmController.addListener(() {
      if (!_hasStartedTypingEmailConfirm && _emailConfirmController.text.isNotEmpty) {
        setState(() => _hasStartedTypingEmailConfirm = true);
      }
      _validateCurrentStep();
    });
    _passwordController.addListener(() {
      if (!_hasStartedTypingPassword && _passwordController.text.isNotEmpty) {
        setState(() => _hasStartedTypingPassword = true);
      }
      _validateCurrentStep();
    });
    _passwordConfirmController.addListener(() {
      if (!_hasStartedTypingPasswordConfirm && _passwordConfirmController.text.isNotEmpty) {
        setState(() => _hasStartedTypingPasswordConfirm = true);
      }
      _validateCurrentStep();
    });
  }
  @override
  void dispose() {
    _slideController.dispose();
    _pulseController.dispose();
    _pageController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _pressCardController.dispose();
    _organizationController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _emailConfirmController.dispose();
    _passwordController.dispose();
    _passwordConfirmController.dispose();
    super.dispose();
  }
  void _validateCurrentStep() {
    if (!mounted) return;
    bool isValid = false;
    switch (_currentStep) {
      case 0:
        if (widget.isJournalist) {
          isValid = _firstNameController.text.trim().isNotEmpty &&
              _lastNameController.text.trim().isNotEmpty &&
              _organizationController.text.trim().isNotEmpty;
          if (_pressCardController.text.trim().isNotEmpty) {
            final pressCard = _pressCardController.text.trim();
            isValid = isValid &&
                RegExp(r'^[0-9]+$').hasMatch(pressCard) &&
                pressCard.length >= 4 &&
                pressCard.length <= 20;
          }
        } else {
          isValid = _usernameController.text.trim().length >= 3;
        }
        break;
      case 1:
        isValid = _emailController.text.trim().isNotEmpty &&
            _emailController.text.contains('@') &&
            _emailController.text.contains('.') &&
            _emailConfirmController.text.trim().isNotEmpty &&
            _emailController.text == _emailConfirmController.text;
        break;
      case 2:
        isValid = _passwordController.text.isNotEmpty &&
            _passwordController.text.length >= 8 &&
            _passwordConfirmController.text.isNotEmpty &&
            _passwordController.text == _passwordConfirmController.text;
        break;
      case 3:
        isValid = _acceptedTerms;
        break;
    }
    setState(() => _isCurrentStepValid = isValid);
  }
  void _showMessage(String message, bool isError) {
    if (!mounted) return;
    final snackBar = SnackBar(
      content: Row(
        children: [
          Icon(
            isError ? Icons.error_outline : Icons.check_circle,
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(message, style: const TextStyle(color: Colors.white))),
        ],
      ),
      backgroundColor: isError ? Colors.red : Colors.green,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      duration: Duration(seconds: isError ? 4 : 2),
    );
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
  Future<void> _handleRegistration() async {
    setState(() => _isLoading = true);
    try {
      String username = widget.isJournalist
          ? '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}'
          : _usernameController.text.trim();
      final profile = await _authService.register(
        username: username,
        email: _emailController.text.trim(),
        password: _passwordController.text,
        type: widget.isJournalist ? UserType.journalist : UserType.regular,
        pressCard: widget.isJournalist && _pressCardController.text.isNotEmpty
            ? _pressCardController.text.trim()
            : null,
        organization:
            widget.isJournalist ? _organizationController.text.trim() : null,
      );
      if (!mounted) return;
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      authProvider.setUserProfile(profile);
      await authProvider.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      if (!mounted) return;
      context.go('/feed');
    } on AuthException catch (e) {
      if (!mounted) return;
      _showMessage(e.message, true);
    } catch (e) {
      if (!mounted) return;
      _showMessage('Erreur inattendue', true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
  void _nextStep() {
    if (_currentStep < 3) {
      HapticFeedback.lightImpact();
      setState(() => _currentStep++);
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      _validateCurrentStep();
    }
  }
  void _previousStep() {
    if (_currentStep > 0) {
      HapticFeedback.lightImpact();
      setState(() => _currentStep--);
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      _validateCurrentStep();
    } else {
      context.go('/mode-selection');
    }
  }
  Widget _buildDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (index) {
        final isActive = index == _currentStep;
        final isPast = index < _currentStep;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 32 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive
                ? Colors.white
                : isPast
                    ? Colors.white.withOpacity(0.5)
                    : Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
  Widget _buildStepPage(int step) {
    Widget content;
    IconData icon;
    switch (step) {
      case 0:
        icon = widget.isJournalist ? Icons.verified : Icons.person;
        content = _buildIdentityStep();
        break;
      case 1:
        icon = Icons.mail;
        content = _buildEmailStep();
        break;
      case 2:
        icon = Icons.lock;
        content = _buildPasswordStep();
        break;
      case 3:
        icon = Icons.verified_user;
        content = _buildTermsStep();
        break;
      default:
        return SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          SizedBox(height: 40),
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _currentStep == step ? _pulseAnimation.value : 1.0,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.1),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 36,
                  ),
                ),
              );
            },
          ),
          SizedBox(height: 32),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: content,
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildIdentityStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Informations',
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 8),
        Text(
          widget.isJournalist
              ? 'Vos informations professionnelles'
              : 'Choisissez votre identité',
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 16,
          ),
        ),
        SizedBox(height: 40),
        Form(
          key: _identityFormKey,
          child: widget.isJournalist
              ? Column(
                  children: [
                    _buildTextField(
                      controller: _firstNameController,
                      label: 'Prénom',
                      icon: Icons.person,
                      hasStartedTyping: _hasStartedTypingFirstName,
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
                    SizedBox(height: 16),
                    _buildTextField(
                      controller: _lastNameController,
                      label: 'Nom',
                      icon: Icons.person,
                      hasStartedTyping: _hasStartedTypingLastName,
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
                    SizedBox(height: 16),
                    _buildTextField(
                      controller: _organizationController,
                      label: 'Organisation',
                      icon: Icons.business,
                      hasStartedTyping: _hasStartedTypingOrganization,
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
                    SizedBox(height: 16),
                    _buildTextField(
                      controller: _pressCardController,
                      label: 'Carte de presse (optionnel)',
                      icon: Icons.verified,
                      keyboardType: TextInputType.number,
                      hasStartedTyping: _hasStartedTypingPressCard,
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
                  ],
                )
              : Column(
                  children: [
                    _buildTextField(
                      controller: _usernameController,
                      label: 'Nom d\'utilisateur',
                      icon: Icons.person,
                      hasStartedTyping: _hasStartedTypingUsername,
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
                ),
        ),
      ],
    );
  }
  Widget _buildEmailStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Email',
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Pour sécuriser votre compte',
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 16,
          ),
        ),
        SizedBox(height: 40),
        Form(
          key: _emailFormKey,
          child: Column(
            children: [
              _buildTextField(
                controller: _emailController,
                label: 'Adresse email',
                icon: Icons.mail,
                keyboardType: TextInputType.emailAddress,
                hasStartedTyping: _hasStartedTypingEmail,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'L\'email est requis';
                  }
                  final trimmedValue = value.trim();
                  if (!trimmedValue.contains('@')) {
                    return 'Email invalide (manque @)';
                  }
                  if (!trimmedValue.contains('.')) {
                    return 'Email invalide (manque .)';
                  }
                  final emailRegex = RegExp(
                    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
                  );
                  if (!emailRegex.hasMatch(trimmedValue)) {
                    return 'Format d\'email invalide';
                  }
                  if (trimmedValue.length > 100) {
                    return 'Email trop long (max 100)';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              _buildTextField(
                controller: _emailConfirmController,
                label: 'Confirmer l\'email',
                icon: Icons.check_circle,
                keyboardType: TextInputType.emailAddress,
                hasStartedTyping: _hasStartedTypingEmailConfirm,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Confirmez votre email';
                  }
                  if (value.trim() != _emailController.text.trim()) {
                    return 'Les emails ne correspondent pas';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
  Widget _buildPasswordStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sécurité',
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Créez un mot de passe fort',
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 16,
          ),
        ),
        SizedBox(height: 40),
        Form(
          key: _passwordFormKey,
          child: Column(
            children: [
              _buildTextField(
                controller: _passwordController,
                label: 'Mot de passe',
                icon: Icons.lock,
                obscureText: _obscurePassword,
                hint: '8 caractères minimum',
                hasStartedTyping: _hasStartedTypingPassword,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Le mot de passe est requis';
                  }
                  if (value.length < 8) {
                    return 'Minimum 8 caractères';
                  }
                  if (value.length > 100) {
                    return 'Maximum 100 caractères';
                  }
                  if (!RegExp(r'[A-Z]').hasMatch(value)) {
                    return 'Doit contenir au moins une majuscule';
                  }
                  if (!RegExp(r'[a-z]').hasMatch(value)) {
                    return 'Doit contenir au moins une minuscule';
                  }
                  if (!RegExp(r'[0-9]').hasMatch(value)) {
                    return 'Doit contenir au moins un chiffre';
                  }
                  return null;
                },
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility : Icons.visibility_off,
                    color: Colors.white.withOpacity(0.7),
                  ),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              SizedBox(height: 16),
              _buildTextField(
                controller: _passwordConfirmController,
                label: 'Confirmer le mot de passe',
                icon: Icons.check_circle,
                obscureText: _obscurePasswordConfirm,
                hasStartedTyping: _hasStartedTypingPasswordConfirm,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Confirmez votre mot de passe';
                  }
                  if (value != _passwordController.text) {
                    return 'Les mots de passe ne correspondent pas';
                  }
                  return null;
                },
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePasswordConfirm
                        ? Icons.visibility
                        : Icons.visibility_off,
                    color: Colors.white.withOpacity(0.7),
                  ),
                  onPressed: () => setState(
                      () => _obscurePasswordConfirm = !_obscurePasswordConfirm),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  Widget _buildTermsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Finalisation',
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Acceptez les conditions',
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 16,
          ),
        ),
        SizedBox(height: 40),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
            ),
          ),
          child: CheckboxListTile(
            value: _acceptedTerms,
            onChanged: (value) {
              setState(() {
                _acceptedTerms = value ?? false;
                _validateCurrentStep();
              });
            },
            checkColor: Colors.black,
            activeColor: Colors.white,
            title: Text(
              'J\'accepte les conditions',
              style: TextStyle(color: Colors.white),
            ),
            subtitle: Text(
              'CGU et politique de confidentialité',
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 12,
              ),
            ),
          ),
        ),
        SizedBox(height: 16),
        Center(
          child: TextButton(
            onPressed: () {
              showModalBottomSheet(
                context: context,
                backgroundColor: Colors.black,
                isScrollControlled: true,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                builder: (context) => DraggableScrollableSheet(
                  initialChildSize: 0.5,
                  minChildSize: 0.3,
                  maxChildSize: 0.9,
                  expand: false,
                  builder: (context, scrollController) => Container(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 20),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        Text(
                          'Documents légaux',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 24),
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              Navigator.pop(context);
                              context.pushNamed(RouteNames.terms);
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.1),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.article,
                                    color: Colors.white.withOpacity(0.7),
                                  ),
                                  SizedBox(width: 16),
                                  Expanded(
                                    child: Text(
                                      'Conditions d\'utilisation',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                  Icon(
                                    Icons.chevron_right,
                                    color: Colors.white.withOpacity(0.7),
                                    size: 16,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 12),
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              Navigator.pop(context);
                              context.pushNamed(RouteNames.privacyPolicy);
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.1),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.verified_user,
                                    color: Colors.white.withOpacity(0.7),
                                  ),
                                  SizedBox(width: 16),
                                  Expanded(
                                    child: Text(
                                      'Politique de confidentialité',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                  Icon(
                                    Icons.chevron_right,
                                    color: Colors.white.withOpacity(0.7),
                                    size: 16,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const Spacer(),
                        SizedBox(
                          width: double.infinity,
                          child: TextButton(
                            onPressed: () => Navigator.pop(context),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'Fermer',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
            child: Text(
              'Lire les conditions',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ),
      ],
    );
  }
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    String? hint,
    TextInputType? keyboardType,
    Widget? suffixIcon,
    String? Function(String?)? validator,
    bool hasStartedTyping = false,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      style: const TextStyle(color: Colors.white, fontSize: 16),
      onChanged: (_) => _validateCurrentStep(),
      validator: validator,
      autovalidateMode: hasStartedTyping
          ? AutovalidateMode.always
          : AutovalidateMode.disabled,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
        prefixIcon: Icon(icon, color: Colors.white.withOpacity(0.7)),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        errorStyle: const TextStyle(color: Colors.red, fontSize: 12),
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: _previousStep,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                  const Spacer(),
                  _buildDots(),
                  const Spacer(),
                  const SizedBox(width: 36),
                ],
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: List.generate(4, _buildStepPage),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(24),
              child: SafeArea(
                top: false,
                child: _currentStep == 3
                    ? SizedBox(
                        width: double.infinity,
                        height: 60,
                        child: ElevatedButton(
                          onPressed: _acceptedTerms && !_isLoading
                              ? _handleRegistration
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                            disabledBackgroundColor: Colors.white.withOpacity(0.3),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            elevation: 0,
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.black),
                                )
                              : const Text(
                                  'Créer mon compte',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      )
                    : SizedBox(
                        width: double.infinity,
                        height: 60,
                        child: ElevatedButton(
                          onPressed: _isCurrentStepValid ? _nextStep : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                            disabledBackgroundColor: Colors.white.withOpacity(0.3),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Continuer',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}