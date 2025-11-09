import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../../../core/themes/web_theme.dart';
import '../../../../../core/navigation/route_names.dart';
import '../../../../../core/navigation/app_router.dart';
import '../../mobile/screens/mode_selection_screen.dart' show ProfileType;
class ModeSelectionScreenWeb extends StatefulWidget {
  const ModeSelectionScreenWeb({super.key});
  @override
  State<ModeSelectionScreenWeb> createState() => _ModeSelectionScreenWebState();
}
class _ModeSelectionScreenWebState extends State<ModeSelectionScreenWeb> {
  ProfileType _selectedType = ProfileType.journalist;
  void _selectType(ProfileType type) {
    setState(() {
      _selectedType = type;
    });
  }
  void _continueToRegistration() {
    if (_selectedType == ProfileType.journalist) {
      context.go(RouteNames.registrationStepper);
    } else {
      context.go(RouteNames.register);
    }
  }
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 800),
            padding: const EdgeInsets.all(WebTheme.xxl),
            child: Card(
              elevation: 8,
              color: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(WebTheme.borderRadiusLarge),
                side: BorderSide(
                  color: Colors.white.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(WebTheme.cardPaddingLarge),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        onPressed: () =>
                            AppRouter.replaceAllTo(context, RouteNames.welcome),
                        icon: Icon(Icons.arrow_back, color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: WebTheme.lg),
                    Text(
                      'Qui êtes-vous ?',
                      style: theme.textTheme.displaySmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: WebTheme.md),
                    Text(
                      'Choisissez votre mode d\'utilisation',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                      const SizedBox(height: WebTheme.xxl),
                      Row(
                        children: [
                          Expanded(
                            child: _OptionCard(
                              icon: FontAwesomeIcons.editPointed,
                              title: 'Journaliste',
                              description: 'Je publie du contenu',
                              isSelected: _selectedType == ProfileType.journalist,
                              onTap: () => _selectType(ProfileType.journalist),
                            ),
                          ),
                          const SizedBox(width: WebTheme.xl),
                          Expanded(
                            child: _OptionCard(
                              icon: FontAwesomeIcons.visibility,
                              title: 'Lecteur',
                              description: 'Je consulte du contenu',
                              isSelected: _selectedType == ProfileType.reader,
                              onTap: () => _selectType(ProfileType.reader),
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: WebTheme.xxl),
                    SizedBox(
                      width: double.infinity,
                      height: WebTheme.buttonHeightLarge,
                      child: ElevatedButton(
                        onPressed: _continueToRegistration,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                                WebTheme.borderRadiusMedium),
                          ),
                          elevation: 2,
                        ),
                        child: Text(
                          'Continuer',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: WebTheme.lg),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
class _OptionCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String description;
  final bool isSelected;
  final VoidCallback onTap;
  const _OptionCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.isSelected,
    required this.onTap,
  });
  @override
  State<_OptionCard> createState() => _OptionCardState();
}
class _OptionCardState extends State<_OptionCard> {
  bool _isHovered = false;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 280,
          padding: const EdgeInsets.all(WebTheme.xl),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? Colors.white.withOpacity(0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(WebTheme.borderRadiusLarge),
            border: Border.all(
              color: widget.isSelected
                  ? Colors.white
                  : _isHovered
                      ? Colors.white.withOpacity(0.5)
                      : Colors.white.withOpacity(0.3),
              width: widget.isSelected ? 3 : 2,
            ),
            boxShadow: widget.isSelected || _isHovered
                ? [
                    BoxShadow(
                      color: Colors.white.withOpacity(0.1),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: widget.isSelected
                      ? Colors.white.withOpacity(0.15)
                      : Colors.white.withOpacity(0.05),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  widget.icon,
                  color: Colors.white,
                  size: 48,
                ),
              ),
              const SizedBox(height: WebTheme.lg),
              Text(
                widget.title,
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: WebTheme.sm),
              Text(
                widget.description,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}