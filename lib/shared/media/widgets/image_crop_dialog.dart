import 'package:thot/core/presentation/theme/app_colors.dart';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:crop_your_image/crop_your_image.dart';
import 'package:thot/shared/media/config/media_config.dart';
import 'package:thot/core/utils/safe_navigation.dart';
class ImageCropDialog extends StatefulWidget {
  final Uint8List imageBytes;
  final MediaType type;
  final Function(Uint8List) onCropped;
  const ImageCropDialog({
    super.key,
    required this.imageBytes,
    required this.type,
    required this.onCropped,
  });
  @override
  State<ImageCropDialog> createState() => _ImageCropDialogState();
}
class _ImageCropDialogState extends State<ImageCropDialog> {
  final _cropController = CropController();
  String _aspectRatioText = '';
  bool _isCropping = false;
  @override
  void initState() {
    super.initState();
    _aspectRatioText = 'Paysage (16:9)';
  }
  void _handleCrop() {
    if (_isCropping) return;
    setState(() => _isCropping = true);
    _cropController.crop();
  }
  void _handleCancel() {
    SafeNavigation.pop(context);
  }
  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isCropping,
      child: Dialog(
        backgroundColor: Colors.grey[900],
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recadrer l\'image ($_aspectRatioText)',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: Colors.white),
                    onPressed: _isCropping ? null : _handleCancel,
                  ),
                ],
              ),
            ),
            Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.7,
                minHeight: MediaQuery.of(context).size.height * 0.5,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Crop(
                    image: widget.imageBytes,
                    controller: _cropController,
                    aspectRatio: widget.type.aspectRatio,
                    onCropped: (croppedData) {
                      if (mounted) {
                        widget.onCropped(croppedData);
                        SafeNavigation.pop(context, croppedData);
                      }
                    },
                    onStatusChanged: (status) {
                      if (status == CropStatus.ready) {
                        setState(() => _isCropping = false);
                      }
                    },
                    withCircleUi: false,
                    baseColor: Colors.black,
                    maskColor: Colors.black.withOpacity(0.6),
                    cornerDotBuilder: (size, edgeAlignment) =>
                        const SizedBox.shrink(),
                    interactive: !_isCropping,
                  ),
                  if (_isCropping)
                    Container(
                      color: Colors.black.withOpacity(0.5),
                      child: const Center(
                        child: CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isCropping ? null : _handleCancel,
                    child: Text(
                      'Annuler',
                      style: TextStyle(
                        color: _isCropping ? Colors.grey : Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: _isCropping ? null : _handleCrop,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.blue.withOpacity(0.5),
                      disabledForegroundColor: Colors.white,
                    ),
                    child: _isCropping
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text('Valider'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}