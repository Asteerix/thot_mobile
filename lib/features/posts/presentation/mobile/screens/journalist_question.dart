import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:thot/core/navigation/app_router.dart';
import 'package:thot/core/navigation/route_names.dart';
import 'package:thot/shared/utils/responsive.dart';
import 'package:thot/shared/utils/responsive_utils.dart';
import 'package:thot/shared/widgets/logo.dart';
class JournalistQuestion extends StatefulWidget {
  const JournalistQuestion({super.key});
  @override
  State<JournalistQuestion> createState() => _JournalistQuestionState();
}
class _JournalistQuestionState extends State<JournalistQuestion> {
  bool? _isJournalist;
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final maxWidth =
        ResponsiveUtils.isWebOrTablet(context) ? 440.0 : double.infinity;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          AppRouter.replaceAllTo(context, RouteNames.welcome);
        }
      },
      child: Scaffold(
        extendBodyBehindAppBar: true,
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            tooltip: 'Retour',
            icon: Icon(Icons.arrow_back),
            onPressed: () {
              HapticFeedback.selectionClick();
              AppRouter.replaceAllTo(context, RouteNames.welcome);
            },
          ),
        ),
        body: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Theme.of(context).colorScheme.onSurface,
                    cs.primary.withOpacity(0.25),
                    Theme.of(context).colorScheme.onSurface,
                  ],
                ),
              ),
            ),
            SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        const SizedBox(height: 24),
                        const Hero(tag: 'appLogo', child: Logo()),
                        const Spacer(),
                        _FrostedCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'Êtes-vous journaliste ou représentez-vous un média ?',
                                textAlign: TextAlign.center,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(
                                      color: cs.onSurface,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                              const SizedBox(height: 20),
                              Semantics(
                                label: 'Choix journaliste',
                                child: SegmentedButton<bool>(
                                  segments: const <ButtonSegment<bool>>[
                                    ButtonSegment<bool>(
                                      value: true,
                                      label: Text('Oui'),
                                      icon: Icon(Icons.check_circle),
                                    ),
                                    ButtonSegment<bool>(
                                      value: false,
                                      label: Text('Non'),
                                      icon: Icon(Icons.radio_button_unchecked),
                                    ),
                                  ],
                                  selected: _isJournalist != null
                                      ? <bool>{_isJournalist!}
                                      : const <bool>{},
                                  onSelectionChanged: (selection) {
                                    HapticFeedback.lightImpact();
                                    setState(
                                        () => _isJournalist = selection.first);
                                  },
                                  style: ButtonStyle(
                                    visualDensity: VisualDensity.comfortable,
                                    minimumSize: WidgetStateProperty.all(
                                      const Size.fromHeight(56),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              AnimatedOpacity(
                                opacity: _isJournalist == null ? 0.5 : 1,
                                duration: const Duration(milliseconds: 200),
                                child: FilledButton.icon(
                                  onPressed: _isJournalist == null
                                      ? null
                                      : () {
                                          HapticFeedback.selectionClick();
                                          AppRouter.navigateTo(
                                            context,
                                            RouteNames.register,
                                            arguments: {
                                              'isJournalist': _isJournalist
                                            },
                                          );
                                        },
                                  icon: Icon(Icons.arrow_forward),
                                  label: const Text('Continuer'),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16, top: 8),
                          child: SizedBox(
                            height: 4,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(2),
                              child: LinearProgressIndicator(
                                value: 0.33,
                                backgroundColor:
                                    cs.surfaceContainer.withOpacity(0.3),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Shortcuts(
              shortcuts: <LogicalKeySet, Intent>{
                LogicalKeySet(LogicalKeyboardKey.keyO):
                    const _SelectBoolIntent(true),
                LogicalKeySet(LogicalKeyboardKey.keyN):
                    const _SelectBoolIntent(false),
                LogicalKeySet(LogicalKeyboardKey.enter): const ActivateIntent(),
              },
              child: Actions(
                actions: <Type, Action<Intent>>{
                  _SelectBoolIntent: CallbackAction<_SelectBoolIntent>(
                    onInvoke: (intent) {
                      setState(() => _isJournalist = intent.value);
                      return null;
                    },
                  ),
                },
                child: const SizedBox.shrink(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
class _FrostedCard extends StatelessWidget {
  const _FrostedCard({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: cs.surface.withOpacity(0.65),
            border: Border.all(color: cs.surfaceContainer),
          ),
          child: child,
        ),
      ),
    );
  }
}
class _SelectBoolIntent extends Intent {
  const _SelectBoolIntent(this.value);
  final bool value;
}