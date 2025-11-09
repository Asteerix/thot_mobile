import 'package:flutter/material.dart';
import 'package:thot/core/themes/app_colors.dart';
import 'package:thot/core/themes/web_theme.dart';

class MediaUploaderDesktop extends StatefulWidget {
  final Function(List<String> paths) onMediaSelected;
  final List<String> acceptedTypes;
  final int maxFiles;
  final bool allowMultiple;

  const MediaUploaderDesktop({
    super.key,
    required this.onMediaSelected,
    this.acceptedTypes = const ['image/*', 'video/*'],
    this.maxFiles = 10,
    this.allowMultiple = true,
  });

  @override
  State<MediaUploaderDesktop> createState() => _MediaUploaderDesktopState();
}

class _MediaUploaderDesktopState extends State<MediaUploaderDesktop> {
  final List<String> _selectedPaths = [];
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        border: Border.all(
          color: _isDragging ? AppColors.primary : Colors.grey.shade300,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(12),
        color: _isDragging ? AppColors.primary.withOpacity(0.1) : Colors.white,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.cloudUpload,
            size: 64,
            color: _isDragging ? AppColors.primary : Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Drag and drop media files here',
            style: WebTheme.headingStyle.copyWith(
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'or',
            style: TextStyle(color: Colors.grey.shade500),
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: _selectFiles,
            icon: Icon(Icons.paperclip),
            label: const Text('Browse Files'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
          if (_selectedPaths.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              '${_selectedPaths.length} file(s) selected',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ],
      ),
    );
  }

  void _selectFiles() async {
    // This is a placeholder - actual file selection would use file_picker package
    // or HTML input element for web
    widget.onMediaSelected(_selectedPaths);
  }
}
