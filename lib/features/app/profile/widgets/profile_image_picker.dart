import 'package:thot/core/presentation/theme/app_colors.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:thot/features/public/auth/shared/providers/auth_provider.dart';
import 'package:thot/core/services/realtime/event_bus.dart';
import 'package:thot/shared/media/services/upload_service.dart';
import 'package:thot/core/utils/safe_navigation.dart';
import 'file_handler.dart';
import 'profile_logger.dart';
class ProfileImagePicker extends StatefulWidget {
  final String? currentImageUrl;
  final bool isProfile;
  final VoidCallback onImageUpdated;
  final Widget? child;
  const ProfileImagePicker({
    super.key,
    this.currentImageUrl,
    required this.isProfile,
    required this.onImageUpdated,
    this.child,
  });
  @override
  State<ProfileImagePicker> createState() => _ProfileImagePickerState();
}
class _ProfileImagePickerState extends State<ProfileImagePicker> {
  final _imagePicker = ImagePicker();
  bool _isUploading = false;
  Future<bool> _checkAndRequestPermissions() async {
    ProfileLogger.i('Checking photo permissions...');
    try {
      final status = await Permission.photos.status;
      if (status.isDenied) {
        final result = await Permission.photos.request();
        if (result.isPermanentlyDenied) {
          if (!context.mounted) return false;
          ProfileLogger.w('Photo permissions permanently denied');
          SafeNavigation.showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Permission requise'),
              content: const Text(
                  'L\'accès à la galerie photo est nécessaire pour modifier votre photo. Veuillez l\'activer dans les paramètres.'),
              actions: [
                TextButton(
                  onPressed: () {
                    if (context.mounted) {
                      SafeNavigation.pop(context);
                    }
                  },
                  child: const Text('Annuler'),
                ),
                TextButton(
                  onPressed: () => openAppSettings(),
                  child: const Text('Paramètres'),
                ),
              ],
            ),
          );
          return false;
        }
        return result.isGranted;
      }
      ProfileLogger.i('Photo permissions granted');
      return status.isGranted;
    } catch (e) {
      ProfileLogger.e('Error checking permissions', error: e);
      return false;
    }
  }
  Future<void> pickAndUploadImage() async {
    if (_isUploading) return;
    try {
      ProfileLogger.i('Starting image pick process...');
      final hasPermission = await _checkAndRequestPermissions();
      if (!hasPermission) {
        ProfileLogger.w('Permission denied for photo access');
        return;
      }
      final image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
      );
      if (image == null) {
        ProfileLogger.i('No image selected');
        return;
      }
      ProfileLogger.i('Image selected, preparing for upload');
      setState(() => _isUploading = true);
      final fileData = await FileHandler.handleImageFile(
        image,
        isProfile: widget.isProfile,
      );
      ProfileLogger.i('Got file data for upload');
      ProfileLogger.i('Uploading image to server...');
      final uploadService = UploadService();
      final uploadResult = await uploadService.uploadImage(
        File(fileData.path!),
        type: widget.isProfile ? 'profile' : 'cover',
      );
      if (uploadResult['url'] != null && mounted) {
        ProfileLogger.i('Image upload successful');
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        if (authProvider.userProfile?.id != null) {
          EventBus()
              .fire(ProfileUpdatedEvent(userId: authProvider.userProfile!.id));
        }
        widget.onImageUpdated();
      } else {
        throw Exception('Failed to upload image');
      }
    } catch (e) {
      ProfileLogger.e('Image upload error', error: e);
      String errorMessage = 'Failed to upload image';
      if (e.toString().contains('LIMIT_FILE_SIZE')) {
        errorMessage = 'Image size too large. Please choose a smaller image.';
      } else if (e.toString().contains('Invalid file type')) {
        errorMessage = 'Invalid file type. Please choose a JPEG or PNG image.';
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 3),
          action: SnackBarAction(
            label: 'OK',
            textColor: Colors.white,
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            },
          ),
        ),
      );
    } finally {
      setState(() => _isUploading = false);
    }
  }
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: pickAndUploadImage,
        child: Stack(
          children: [
            if (widget.child != null) widget.child!,
            if (_isUploading)
              Container(
                color: Colors.black.withOpacity(0.5),
                child: const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}