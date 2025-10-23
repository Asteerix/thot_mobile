import 'package:flutter/material.dart';
import 'package:thot/core/themes/app_colors.dart';
import 'package:thot/core/themes/web_theme.dart';
class VideoEditorDesktop extends StatefulWidget {
  final String videoPath;
  final Function(String editedPath) onVideoEdited;
  const VideoEditorDesktop({
    super.key,
    required this.videoPath,
    required this.onVideoEdited,
  });
  @override
  State<VideoEditorDesktop> createState() => _VideoEditorDesktopState();
}
class _VideoEditorDesktopState extends State<VideoEditorDesktop> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      constraints: BoxConstraints(
        maxWidth: WebTheme.maxContentWidth,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
        borderRadius: BorderRadius.circular(WebTheme.borderRadiusMedium),
      ),
      child: Column(
        children: [
          Container(
            height: 400,
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(WebTheme.borderRadiusMedium),
              ),
            ),
            child: Center(
              child: Icon(
                Icons.play_circle,
                size: 64,
                color: AppColors.primary,
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(WebTheme.spacingMedium),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Timeline',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: WebTheme.spacingSmall),
                RangeSlider(
                  values: const RangeValues(0, 100),
                  min: 0,
                  max: 100,
                  divisions: 100,
                  activeColor: AppColors.primary,
                  inactiveColor: AppColors.textSecondary.withOpacity(0.3),
                  onChanged: (RangeValues values) {
                  },
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(WebTheme.spacingMedium),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'Annuler',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
                SizedBox(width: WebTheme.spacingSmall),
                ElevatedButton(
                  onPressed: () {
                    widget.onVideoEdited(widget.videoPath);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.textOnPrimary,
                  ),
                  child: const Text('Appliquer'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}