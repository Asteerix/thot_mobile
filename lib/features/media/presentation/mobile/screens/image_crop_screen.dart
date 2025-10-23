import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:crop_your_image/crop_your_image.dart';
import 'package:thot/core/themes/app_colors.dart';
import 'package:thot/core/constants/app_constants.dart';
import 'package:thot/features/media/domain/config/media_config.dart';
import 'package:thot/core/utils/safe_navigation.dart';
import 'package:thot/core/monitoring/logger_service.dart';
import 'package:thot/shared/widgets/media/crop_handle.dart';
import 'package:thot/shared/widgets/media/crop_grid_painter.dart';
import 'package:thot/shared/widgets/media/aspect_preset_chip.dart';
import 'package:thot/shared/widgets/media/image_tool_button.dart';
import 'package:thot/shared/widgets/media/crop_error_screen.dart';
import 'package:thot/shared/widgets/media/image_transform_utils.dart';
enum AspectPreset { free, square, post45, landscape169, portrait916 }
class ImageCropScreen extends StatefulWidget {
  final Uint8List imageBytes;
  final MediaType type;
  const ImageCropScreen({
    super.key,
    required this.imageBytes,
    required this.type,
  });
  @override
  State<ImageCropScreen> createState() => _ImageCropScreenState();
}
class _ImageCropScreenState extends State<ImageCropScreen> {
  final _cropController = CropController();
  final _logger = LoggerService.instance;
  Uint8List? _imageBytes;
  bool _isCropping = false;
  bool _hasError = false;
  String _errorMessage = 'Impossible de traiter cette image';
  AspectPreset _preset = AspectPreset.free;
  double? _currentAspect;
  Key _cropKey = UniqueKey();
  @override
  void initState() {
    super.initState();
    _preset = _presetFromMediaType(widget.type);
    _currentAspect = _aspectFromPreset(_preset);
    _decodeAndNormalize();
  }
  Future<void> _decodeAndNormalize() async {
    try {
      if (widget.imageBytes.isEmpty) {
        _setError('Image vide');
        return;
      }
      final normalized = await compute(decodeNormalizeIsolate, widget.imageBytes);
      if (!mounted) return;
      setState(() => _imageBytes = normalized);
    } catch (e, st) {
      _logger.error('Error preparing image for crop', e, st);
      _setError('Erreur de décodage');
    }
  }
  void _setError(String msg) {
    setState(() {
      _hasError = true;
      _errorMessage = msg;
    });
  }
  Future<void> _rotateRight() => _applyTransform(rotateRightSync);
  Future<void> _rotateLeft() => _applyTransform(rotateLeftSync);
  Future<void> _flipH() => _applyTransform(flipHorizontalSync);
  Future<void> _flipV() => _applyTransform(flipVerticalSync);
  Future<void> _applyTransform(Uint8List Function(Uint8List) transformer) async {
    final src = _imageBytes;
    if (src == null) return;
    HapticFeedback.selectionClick();
    setState(() => _imageBytes = null);
    try {
      final result = await compute(transformer, src);
      if (!mounted) return;
      setState(() {
        _imageBytes = result;
        _cropKey = UniqueKey();
      });
    } catch (e, st) {
      _logger.error('Transform error', e, st);
      _setError('Échec de transformation');
    }
  }
  void _onCrop() {
    if (_isCropping) return;
    HapticFeedback.mediumImpact();
    setState(() => _isCropping = true);
    _cropController.crop();
  }
  void _onCancel() {
    if (_isCropping) return;
    SafeNavigation.pop(context);
  }
  void _onSkip() {
    if (_isCropping) return;
    SafeNavigation.pop(context, widget.imageBytes);
  }
  void _onCropped(CropResult result) {
    HapticFeedback.lightImpact();
    switch (result) {
      case CropSuccess(croppedImage: final data):
        SafeNavigation.pop(context, data);
      case CropFailure(cause: final error):
        LoggerService.instance.error('Crop failed', error);
        SafeNavigation.pop(context, widget.imageBytes);
    }
  }
  void _onCropReady() {
    if (!mounted) return;
    setState(() => _isCropping = false);
  }
  void _onPreset(AspectPreset p) {
    if (_preset == p || _isCropping) return;
    HapticFeedback.selectionClick();
    setState(() {
      _preset = p;
      _currentAspect = _aspectFromPreset(p);
      _cropKey = UniqueKey();
    });
  }
  Future<void> _onResetFrame() async {
    if (_isCropping) return;
    HapticFeedback.selectionClick();
    setState(() => _cropKey = UniqueKey());
  }
  AspectPreset _presetFromMediaType(MediaType t) {
    return switch (t) {
      MediaType.question => AspectPreset.landscape169,
      MediaType.short => AspectPreset.portrait916,
      MediaType.shortThumbnail => AspectPreset.portrait916,
      _ => AspectPreset.square,
    };
  }
  double? _aspectFromPreset(AspectPreset p) {
    return switch (p) {
      AspectPreset.free => null,
      AspectPreset.square => 1.0,
      AspectPreset.post45 => 4 / 5,
      AspectPreset.landscape169 => 16 / 9,
      AspectPreset.portrait916 => 9 / 16,
    };
  }
  String _presetLabel(AspectPreset p) {
    return switch (p) {
      AspectPreset.free => 'Libre',
      AspectPreset.square => '1:1',
      AspectPreset.post45 => '4:5',
      AspectPreset.landscape169 => '16:9',
      AspectPreset.portrait916 => '9:16',
    };
  }
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (_hasError) {
      return CropErrorScreen(
        message: _errorMessage,
        onCancel: _onCancel,
        onUseOriginal: _onSkip,
      );
    }
    final bytes = _imageBytes;
    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : Colors.black,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkSurface : Colors.black87,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: Colors.white),
          onPressed: _isCropping ? null : _onCancel,
        ),
        title: Text(
          'Recadrer',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _isCropping ? null : _onSkip,
            child: Text(
              'Ignorer',
              style: TextStyle(
                color: _isCropping ? Colors.white.withOpacity(0.3) : AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: PopScope(
        canPop: !_isCropping,
        child: Column(
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (bytes == null)
                    Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                      ),
                    )
                  else
                    Crop(
                      key: _cropKey,
                      image: bytes,
                      controller: _cropController,
                      aspectRatio: _currentAspect,
                      onCropped: _onCropped,
                      onStatusChanged: (s) {
                        if (s == CropStatus.ready) _onCropReady();
                      },
                      withCircleUi: false,
                      baseColor: AppColors.primary,
                      maskColor: Colors.black.withOpacity(0.7),
                      interactive: !_isCropping,
                      cornerDotBuilder: (_, __) => const CropHandle(),
                    ),
                  const IgnorePointer(
                    child: CustomPaint(
                      painter: CropGridPainter(),
                      size: Size.infinite,
                    ),
                  ),
                  if (_isCropping)
                    Container(
                      color: Colors.black.withOpacity(0.6),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Traitement...',
                              style: TextStyle(color: Colors.white, fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            SafeArea(
              top: false,
              child: Container(
                padding: EdgeInsets.all(UIConstants.paddingM),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : Colors.black87,
                  border: Border(
                    top: BorderSide(
                      color: isDark ? AppColors.darkBorder : Colors.white.withOpacity(0.1),
                    ),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      height: 36,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: AspectPreset.values.length,
                        separatorBuilder: (_, __) => SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final p = AspectPreset.values[index];
                          final selected = p == _preset;
                          return AspectPresetChip(
                            label: _presetLabel(p),
                            selected: selected,
                            enabled: !_isCropping,
                            onTap: () => _onPreset(p),
                          );
                        },
                      ),
                    ),
                    SizedBox(height: 12),
                    Row(
                      children: [
                        ImageToolButton(
                          icon: Icons.rotate_left,
                          tooltip: 'Rotation -90°',
                          enabled: !_isCropping && bytes != null,
                          onPressed: _rotateLeft,
                        ),
                        ImageToolButton(
                          icon: Icons.rotate_right,
                          tooltip: 'Rotation +90°',
                          enabled: !_isCropping && bytes != null,
                          onPressed: _rotateRight,
                        ),
                        ImageToolButton(
                          icon: Icons.flip,
                          tooltip: 'Miroir H',
                          enabled: !_isCropping && bytes != null,
                          onPressed: _flipH,
                        ),
                        ImageToolButton(
                          icon: Icons.flip_camera_android,
                          tooltip: 'Miroir V',
                          enabled: !_isCropping && bytes != null,
                          onPressed: _flipV,
                        ),
                        ImageToolButton(
                          icon: Icons.refresh,
                          tooltip: 'Réinitialiser',
                          enabled: !_isCropping && bytes != null,
                          onPressed: _onResetFrame,
                        ),
                        const Spacer(),
                      ],
                    ),
                    SizedBox(height: 12),
                    Container(
                      height: 50,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: !_isCropping && bytes != null
                            ? LinearGradient(
                                colors: [AppColors.primary, AppColors.primaryDark],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : null,
                        color: _isCropping || bytes == null ? (isDark ? AppColors.darkCard : Colors.grey[800]) : null,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: !_isCropping && bytes != null ? _onCrop : null,
                          borderRadius: BorderRadius.circular(12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.check_rounded,
                                size: 20,
                                color: !_isCropping && bytes != null ? Colors.white : Colors.white.withOpacity(0.3),
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Valider',
                                style: TextStyle(
                                  color: !_isCropping && bytes != null ? Colors.white : Colors.white.withOpacity(0.3),
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}