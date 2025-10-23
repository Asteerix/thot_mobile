import 'package:flutter/material.dart';
import 'package:thot/core/themes/app_colors.dart';

/// Poignée de recadrage pour l'éditeur d'images
/// Widget réutilisable pour les coins du cadre de crop
class CropHandle extends StatelessWidget {
  const CropHandle({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: AppColors.primary,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
    );
  }
}
