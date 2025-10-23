import 'package:thot/core/themes/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:thot/shared/utils/responsive_utils.dart';
import 'package:thot/shared/utils/responsive.dart';
import 'package:thot/shared/widgets/logo.dart';
import 'package:thot/core/utils/safe_navigation.dart';
class VerificationPendingScreen extends StatelessWidget {
  const VerificationPendingScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => SafeNavigation.pop(context),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: Container(
            width:
                ResponsiveUtils.isWebOrTablet(context) ? 400 : double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Logo(),
                const SizedBox(height: 60),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 20,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.hourglass_empty,
                        size: 48,
                        color: AppColors.warning,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Vérification en cours',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.surface,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Tailwind',
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Votre compte est en cours de vérification. Une fois vérifié, vous pourrez publier du contenu.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 16,
                          fontFamily: 'Tailwind',
                        ),
                      ),
                    ],
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