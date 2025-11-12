import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:thot/core/di/service_locator.dart';
import 'package:thot/core/utils/safe_navigation.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});
  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _currentFocus = FocusNode();
  final _newFocus = FocusNode();
  final _confirmFocus = FocusNode();
  final _authService = ServiceLocator.instance.authRepository;
  bool _isLoading = false;
  bool _isFormValid = false;
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  String? _serverError;
  bool get _lenOk => _newPasswordController.text.trim().length >= 8;
  bool get _upperOk =>
      RegExp(r'[A-ZÀ-Ö]').hasMatch(_newPasswordController.text);
  bool get _lowerOk =>
      RegExp(r'[a-zà-ö]').hasMatch(_newPasswordController.text);
  bool get _digitOk => RegExp(r'\d').hasMatch(_newPasswordController.text);
  bool get _symbolOk => RegExp(r'''[!@#\$%^&*(),.?":{}|<>_\-\\/\[\]=+;'"`~]''')
      .hasMatch(_newPasswordController.text);
  double get _strength {
    final checks = [_lenOk, _upperOk, _lowerOk, _digitOk, _symbolOk];
    final passed = checks.where((c) => c).length;
    final base = passed / checks.length;
    final bonus = _newPasswordController.text.length >= 12 ? 0.15 : 0;
    return (base + bonus).clamp(0.0, 1.0);
  }

  @override
  void initState() {
    super.initState();
    _newPasswordController.addListener(_revalidate);
    _confirmPasswordController.addListener(_revalidate);
    _currentPasswordController.addListener(_revalidate);
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _currentFocus.dispose();
    _newFocus.dispose();
    _confirmFocus.dispose();
    super.dispose();
  }

  void _revalidate() {
    final nowValid = _formKey.currentState?.validate() ?? false;
    if (nowValid != _isFormValid) {
      setState(() => _isFormValid = nowValid);
    } else {
      setState(() {});
    }
  }

  String? _validateCurrent(String? v) {
    if (v == null || v.isEmpty) return 'Mot de passe actuel requis';
    if (v.length < 6) return 'Longueur minimale: 6 caractères';
    return null;
  }

  String? _validateNew(String? v) {
    final value = v?.trim() ?? '';
    if (value.isEmpty) return 'Nouveau mot de passe requis';
    if (!_lenOk) return 'Au moins 8 caractères';
    if (!_upperOk) return 'Inclure une majuscule';
    if (!_lowerOk) return 'Inclure une minuscule';
    if (!_digitOk) return 'Inclure un chiffre';
    if (!_symbolOk) return 'Inclure un symbole';
    if (value == _currentPasswordController.text) {
      return "Le nouveau doit être différent de l'actuel";
    }
    return null;
  }

  String? _validateConfirm(String? v) {
    if (v == null || v.isEmpty) return 'Confirmation requise';
    if (v != _newPasswordController.text) {
      return 'Les deux mots de passe diffèrent';
    }
    return null;
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _isLoading = true;
      _serverError = null;
    });
    try {
      await _authService.changePassword(
        currentPassword: _currentPasswordController.text,
        newPassword: _newPasswordController.text.trim(),
      );
      if (!mounted) return;
      HapticFeedback.lightImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Mot de passe mis à jour'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.white.withOpacity(0.1),
        ),
      );
      SafeNavigation.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      HapticFeedback.selectionClick();
      setState(() {
        _serverError =
            'Échec de la modification. Vérifier le mot de passe actuel et la connexion.';
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: Colors.black,
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          backgroundColor: Colors.black,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => SafeNavigation.pop(context),
          ),
          title: const Text(
            'Changer le mot de passe',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 20,
            ),
          ),
        ),
        bottomNavigationBar: SafeArea(
          minimum: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: (_isLoading || !_isFormValid) ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                disabledBackgroundColor: Colors.white.withOpacity(0.3),
                disabledForegroundColor: Colors.black.withOpacity(0.5),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                      ),
                    )
                  : const Text(
                      'Mettre à jour',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
            ),
          ),
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              if (_serverError != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: _ErrorBanner(message: _serverError!),
                ),
              Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.1),
                        width: 1,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Form(
                        key: _formKey,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _PasswordField(
                              label: 'Mot de passe actuel',
                              controller: _currentPasswordController,
                              focusNode: _currentFocus,
                              nextFocus: _newFocus,
                              obscure: _obscureCurrent,
                              onToggleObscure: () => setState(
                                  () => _obscureCurrent = !_obscureCurrent),
                              validator: _validateCurrent,
                              autofillHints: const [AutofillHints.password],
                            ),
                            const SizedBox(height: 24),
                            _PasswordField(
                              label: 'Nouveau mot de passe',
                              controller: _newPasswordController,
                              focusNode: _newFocus,
                              nextFocus: _confirmFocus,
                              obscure: _obscureNew,
                              onToggleObscure: () =>
                                  setState(() => _obscureNew = !_obscureNew),
                              validator: _validateNew,
                              helper: _PasswordCriteria(
                                lenOk: _lenOk,
                                upperOk: _upperOk,
                                lowerOk: _lowerOk,
                                digitOk: _digitOk,
                                symbolOk: _symbolOk,
                              ),
                              strength: _strength,
                              autofillHints: const [AutofillHints.newPassword],
                            ),
                            const SizedBox(height: 24),
                            _PasswordField(
                              label: 'Confirmer le nouveau mot de passe',
                              controller: _confirmPasswordController,
                              focusNode: _confirmFocus,
                              obscure: _obscureConfirm,
                              onToggleObscure: () => setState(
                                  () => _obscureConfirm = !_obscureConfirm),
                              validator: _validateConfirm,
                              textInputAction: TextInputAction.done,
                              onSubmitted: (_) =>
                                  _isFormValid ? _submit() : null,
                              autofillHints: const [AutofillHints.newPassword],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PasswordField extends StatefulWidget {
  const _PasswordField({
    required this.label,
    required this.controller,
    required this.obscure,
    required this.onToggleObscure,
    required this.validator,
    this.focusNode,
    this.nextFocus,
    this.textInputAction = TextInputAction.next,
    this.onSubmitted,
    this.helper,
    this.strength,
    this.autofillHints = const [],
  });
  final String label;
  final TextEditingController controller;
  final bool obscure;
  final VoidCallback onToggleObscure;
  final String? Function(String?) validator;
  final FocusNode? focusNode;
  final FocusNode? nextFocus;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onSubmitted;
  final Widget? helper;
  final double? strength;
  final List<String> autofillHints;
  @override
  State<_PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<_PasswordField> {
  bool _peek = false;
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: widget.controller,
          focusNode: widget.focusNode,
          textInputAction: widget.textInputAction,
          onFieldSubmitted: (v) {
            widget.onSubmitted?.call(v);
            if (widget.nextFocus != null) {
              widget.nextFocus!.requestFocus();
            } else {
              FocusScope.of(context).unfocus();
            }
          },
          obscureText: (widget.obscure && !_peek),
          enableSuggestions: false,
          autocorrect: false,
          autofillHints: widget.autofillHints,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: widget.label,
            labelStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
            prefixIcon: Icon(
              Icons.lock,
              color: Colors.white.withOpacity(0.6),
            ),
            suffixIcon: GestureDetector(
              onLongPress: () => setState(() => _peek = true),
              onLongPressUp: () => setState(() => _peek = false),
              child: IconButton(
                tooltip: (widget.obscure && !_peek) ? 'Afficher' : 'Masquer',
                icon: Icon(
                  (widget.obscure && !_peek)
                      ? Icons.visibility
                      : Icons.visibility_off,
                  color: Colors.white.withOpacity(0.6),
                ),
                onPressed: widget.onToggleObscure,
              ),
            ),
            filled: true,
            fillColor: Colors.white.withOpacity(0.05),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.white, width: 1),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Colors.red.withOpacity(0.8),
                width: 1,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Colors.red.withOpacity(0.8),
                width: 1,
              ),
            ),
            errorStyle: TextStyle(
              color: Colors.red.withOpacity(0.9),
              fontSize: 12,
            ),
          ),
          validator: widget.validator,
        ),
        if (widget.strength != null) ...[
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: widget.strength!.clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: Colors.white.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation<Color>(
                widget.strength! < 0.4
                    ? Colors.red.withOpacity(0.8)
                    : (widget.strength! < 0.7
                        ? Colors.orange.withOpacity(0.8)
                        : Colors.green.withOpacity(0.8)),
              ),
            ),
          ),
        ],
        if (widget.helper != null) ...[
          const SizedBox(height: 12),
          widget.helper!,
        ],
      ],
    );
  }
}

class _PasswordCriteria extends StatelessWidget {
  const _PasswordCriteria({
    required this.lenOk,
    required this.upperOk,
    required this.lowerOk,
    required this.digitOk,
    required this.symbolOk,
  });
  final bool lenOk;
  final bool upperOk;
  final bool lowerOk;
  final bool digitOk;
  final bool symbolOk;
  @override
  Widget build(BuildContext context) {
    final items = <_CritItem>[
      _CritItem('≥ 8 caractères', lenOk),
      _CritItem('1 majuscule', upperOk),
      _CritItem('1 minuscule', lowerOk),
      _CritItem('1 chiffre', digitOk),
      _CritItem('1 symbole', symbolOk),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items.map((e) => _CritRow(item: e)).toList(),
    );
  }
}

class _CritItem {
  const _CritItem(this.label, this.ok);
  final String label;
  final bool ok;
}

class _CritRow extends StatelessWidget {
  const _CritRow({required this.item});
  final _CritItem item;
  @override
  Widget build(BuildContext context) {
    return AnimatedDefaultTextStyle(
      duration: const Duration(milliseconds: 150),
      style: TextStyle(
        color: item.ok ? Colors.white : Colors.white.withOpacity(0.4),
        fontSize: 12,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              item.ok ? Icons.check_circle : Icons.radio_button_unchecked,
              size: 16,
              color: item.ok ? Colors.white : Colors.white.withOpacity(0.4),
            ),
            const SizedBox(width: 8),
            Text(item.label),
          ],
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});
  final String message;
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.red.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.red.withOpacity(0.9),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: Colors.red.withOpacity(0.9),
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
