import 'package:thot/core/presentation/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:thot/features/app/content/shared/models/post.dart';

class PoliticalOrientationUtils {
  static IconData getIconData(PoliticalOrientation? view) {
    return switch (view) {
      PoliticalOrientation.extremelyConservative =>
        Icons.keyboard_double_arrow_left,
      PoliticalOrientation.conservative => Icons.chevron_left,
      PoliticalOrientation.neutral => Icons.remove,
      PoliticalOrientation.progressive => Icons.chevron_right,
      PoliticalOrientation.extremelyProgressive =>
        Icons.keyboard_double_arrow_right,
      null => Icons.public,
    };
  }

  static Icon getIcon(PoliticalOrientation? view) {
    return Icon(
      getIconData(view),
      size: 24,
      color: Colors.white,
    );
  }

  static String getLabel(PoliticalOrientation? view) {
    return switch (view) {
      PoliticalOrientation.extremelyProgressive => 'Très progressiste',
      PoliticalOrientation.progressive => 'Progressiste',
      PoliticalOrientation.extremelyConservative => 'Très conservateur',
      PoliticalOrientation.conservative => 'Conservateur',
      PoliticalOrientation.neutral => 'Neutre',
      null => 'Non spécifié',
    };
  }

  static Color getColor(PoliticalOrientation? view) {
    return switch (view) {
      PoliticalOrientation.extremelyProgressive =>
        AppColors.extremelyProgressive,
      PoliticalOrientation.progressive => AppColors.progressive,
      PoliticalOrientation.extremelyConservative =>
        AppColors.extremelyConservative,
      PoliticalOrientation.conservative => AppColors.conservative,
      PoliticalOrientation.neutral => AppColors.neutral,
      null => AppColors.neutral,
    };
  }
}
