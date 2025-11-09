import 'package:thot/core/themes/app_colors.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:thot/features/media/domain/config/media_config.dart';
import 'package:thot/features/media/infrastructure/media_processor.dart';
import 'video_player_preview.dart';
import 'audio_player_preview.dart';
import 'package:thot/core/utils/safe_navigation.dart';
class MediaPicker extends StatefulWidget {
  final MediaType type;
  final Function(File file) onMediaSelected;
  final String? initialImageUrl;
  final double height;
  final double width;
  const MediaPicker({
    super.key,
    required this.type,
    required this.onMediaSelected,
    this.initialImageUrl,
    this.height = 200,
    this.width = double.infinity,
  });
  @override
  State<MediaPicker> createState() => _MediaPickerState();
}
class _MediaPickerState extends State<MediaPicker> {
  File? _selectedFile;
  bool _isLoading = false;
  Future<bool> _validateVideo(File file) async {
    final videoController = VideoPlayerController.file(file);
    await videoController.initialize();
    final aspectRatio =
        videoController.value.size.width / videoController.value.size.height;
    final duration = videoController.value.duration;
    await videoController.dispose();
    final isShort = widget.type == MediaType.short;
    final maxDuration =
        widget.type.maxVideoDuration ?? MediaConfig.videoMaxDuration;
    if (duration.inSeconds > maxDuration) {
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isShort
              ? 'Le short ne doit pas dépasser 60 secondes'
              : 'La vidéo ne doit pas dépasser 5 minutes'),
          backgroundColor: AppColors.error,
        ),
      );
      return false;
    }
    if (isShort) {
      if (aspectRatio > 0.65) {
        if (!mounted) return false;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Le short doit être en format portrait (9:16). Pour les vidéos en format paysage, utilisez la section "Vidéo".'),
            backgroundColor: AppColors.error,
            duration: Duration(seconds: 5),
          ),
        );
        return false;
      }
    } else {
      if (aspectRatio < 1.0) {
        if (!mounted) return false;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Cette section est réservée aux vidéos en format paysage (16:9). Pour les vidéos en format portrait, utilisez la section "Short".'),
            backgroundColor: AppColors.error,
            duration: Duration(seconds: 5),
          ),
        );
        return false;
      }
    }
    return true;
  }
  Future<void> _pickMedia(ImageSource source) async {
    try {
      setState(() => _isLoading = true);
      final picker = ImagePicker();
      XFile? pickedFile;
      if (widget.type.isAudioContent) {
        final result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['mp3', 'wav', 'm4a', 'aac'],
          allowMultiple: false,
        );
        if (result != null) {
          pickedFile = XFile(result.files.first.path!);
        }
      } else if (widget.type.isVideoContent) {
        pickedFile = await picker.pickVideo(
          source: source,
          maxDuration: Duration(
            seconds:
                widget.type.maxVideoDuration ?? MediaConfig.videoMaxDuration,
          ),
        );
      } else {
        pickedFile = await picker.pickImage(
          source: source,
          imageQuality: MediaConfig.jpegQuality,
        );
      }
      if (pickedFile == null) return;
      File? processedFile;
      if (widget.type.isVideoContent) {
        final file = File(pickedFile.path);
        if (!await _validateVideo(file)) {
          return;
        }
        processedFile =
            await MediaProcessor.processVideo(pickedFile, widget.type);
        if (processedFile != null) {
          setState(() => _selectedFile = processedFile);
          widget.onMediaSelected(processedFile);
        }
      } else if (widget.type.isAudioContent) {
        processedFile =
            await MediaProcessor.processAudio(pickedFile, widget.type);
        if (processedFile != null) {
          setState(() => _selectedFile = processedFile);
          widget.onMediaSelected(processedFile);
        }
      } else {
        processedFile =
            await MediaProcessor.processImage(pickedFile, widget.type, context);
        if (processedFile != null) {
          setState(() => _selectedFile = processedFile);
          widget.onMediaSelected(processedFile);
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }
  void _showMediaPicker() {
    final isVideo = widget.type.isVideoContent;
    final isAudio = widget.type.isAudioContent;
    final aspectRatioText = switch (widget.type) {
      MediaType.question => 'paysage (16:9)',
      MediaType.short => 'portrait (9:16)',
      _ => 'carré (1:1)',
    };
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.4,
        minChildSize: 0.3,
        maxChildSize: 0.6,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        isVideo
                            ? Icons.videocam
                            : isAudio
                                ? Icons.music_note
                                : Icons.add_photo_alternate,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isVideo
                                ? 'Sélectionner une vidéo'
                                : isAudio
                                    ? 'Sélectionner un fichier audio'
                                    : 'Sélectionner une image',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (!isAudio) ...[
                            const SizedBox(height: 4),
                            Text(
                              isVideo
                                  ? 'Durée max: ${widget.type.maxVideoDuration ?? 300}s'
                                  : 'Format: $aspectRatioText',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.6),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                if (!isAudio) ...[
                  _MediaOption(
                    icon: isVideo ? Icons.videocam : Icons.camera_alt,
                    title: isVideo ? 'Enregistrer une vidéo' : 'Prendre une photo',
                    onTap: () {
                      SafeNavigation.pop(context);
                      _pickMedia(ImageSource.camera);
                    },
                  ),
                  const SizedBox(height: 12),
                  _MediaOption(
                    icon: isVideo ? Icons.videocam : Icons.image,
                    title: isVideo ? 'Choisir une vidéo' : 'Choisir une photo',
                    onTap: () {
                      SafeNavigation.pop(context);
                      _pickMedia(ImageSource.gallery);
                    },
                  ),
                ] else
                  _MediaOption(
                    icon: Icons.music_note,
                    title: 'Choisir un fichier audio',
                    onTap: () {
                      SafeNavigation.pop(context);
                      _pickMedia(ImageSource.gallery);
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _showMediaPicker,
      child: Container(
        height: widget.height,
        width: widget.width,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withOpacity(0.3),
            width: 2,
          ),
        ),
        child: _isLoading
            ? Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Colors.white.withOpacity(0.7),
                  ),
                ),
              )
            : _selectedFile != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: widget.type.isVideoContent
                        ? VideoPlayerPreview(
                            videoFile: _selectedFile!,
                            height: widget.height,
                            autoPlay: true,
                          )
                        : widget.type.isAudioContent
                            ? AudioPlayerPreview(
                                audioFile: _selectedFile!,
                                height: widget.height,
                              )
                            : Container(
                                height: widget.height,
                                width: widget.width,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(14),
                                  image: DecorationImage(
                                    image: FileImage(_selectedFile!),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                  )
                : widget.initialImageUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.network(
                          widget.initialImageUrl!,
                          height: widget.height,
                          width: widget.width,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes !=
                                        null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                    : null,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white.withOpacity(0.7),
                                ),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) => Icon(
                            Icons.error_outline,
                            color: Colors.white.withOpacity(0.5),
                          ),
                        ),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                                width: 2,
                              ),
                            ),
                            child: Icon(
                              widget.type.isVideoContent
                                  ? Icons.videocam
                                  : widget.type.isAudioContent
                                      ? Icons.music_note
                                      : Icons.add_photo_alternate,
                              size: 32,
                              color: Colors.white.withOpacity(0.7),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            widget.type.isVideoContent
                                ? 'Ajouter une vidéo'
                                : widget.type.isAudioContent
                                    ? 'Ajouter un fichier audio'
                                    : 'Ajouter une image',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
      ),
    );
  }
}
class _MediaOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  const _MediaOption({
    required this.icon,
    required this.title,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Colors.white.withOpacity(0.5),
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}