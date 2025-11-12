import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:crop_your_image/crop_your_image.dart';
import 'package:thot/core/presentation/theme/app_colors.dart';
import 'package:thot/core/config/app_config.dart';
import 'package:thot/shared/media/config/media_config.dart';
import 'package:thot/core/utils/safe_navigation.dart';
import 'package:thot/core/services/logging/logger_service.dart';
import 'package:thot/shared/widgets/media/crop_handle.dart';
import 'package:thot/shared/widgets/media/crop_grid_painter.dart';
import 'package:thot/shared/widgets/media/aspect_preset_chip.dart';
import 'package:thot/shared/widgets/media/image_tool_button.dart';
import 'package:thot/shared/widgets/media/crop_error_screen.dart';

enum AspectPreset { free, square, post45, landscape169, portrait916 }

class ImageCropScreen extends StatefulWidget {
  const ImageCropScreen({
    super.key,
    required this.imageBytes,
    required this.type,
  });

  final Uint8List imageBytes;
  final MediaType type;

  @override
  State<ImageCropScreen> createState() => _ImageCropScreenState();
}

class _ImageCropScreenState extends State<ImageCropScreen> {
  final _cropController = CropController();
  final _logger = LoggerService.instance;

  bool _isCropping = false;
  bool _hasError = false;
  String _errorMessage = 'Impossible de traiter cette image';
  AspectPreset _preset = AspectPreset.free;
  double? _currentAspect;
  int _rotationCount = 0;
  bool _isFlippedH = false;
  bool _isFlippedV = false;

  @override
  void initState() {
    super.initState();
    _preset = _presetFromMediaType(widget.type);
    _currentAspect = _aspectFromPreset(_preset);
    _validateImage();
  }

  void _validateImage() {
    if (widget.imageBytes.isEmpty) {
      _setError('Image vide');
    }
  }

  void _setError(String msg) {
    if (!mounted) return;
    setState(() {
      _hasError = true;
      _errorMessage = msg;
    });
  }

  Future<void> _rotateRight() async {
    if (_isCropping) return;
    HapticFeedback.selectionClick();
    setState(() {
      _rotationCount = (_rotationCount + 1) % 4;
    });
  }

  Future<void> _rotateLeft() async {
    if (_isCropping) return;
    HapticFeedback.selectionClick();
    setState(() {
      _rotationCount = (_rotationCount - 1) % 4;
    });
  }

  Future<void> _flipH() async {
    if (_isCropping) return;
    HapticFeedback.selectionClick();
    setState(() {
      _isFlippedH = !_isFlippedH;
    });
  }

  Future<void> _flipV() async {
    if (_isCropping) return;
    HapticFeedback.selectionClick();
    setState(() {
      _isFlippedV = !_isFlippedV;
    });
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
        _logger.error('Crop failed', error);
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
    });
  }

  Future<void> _onResetFrame() async {
    if (_isCropping) return;
    HapticFeedback.selectionClick();
    setState(() {
      _rotationCount = 0;
      _isFlippedH = false;
      _isFlippedV = false;
    });
  }

  AspectPreset _presetFromMediaType(MediaType t) {
    return switch (t) {
      MediaType.question => AspectPreset.landscape169,
      MediaType.short => AspectPreset.portrait916,
      MediaType.shortThumbnail => AspectPreset.portrait916,
      _ => AspectPreset.square,
    };
  }

  List<AspectPreset> _getAllowedPresets(MediaType t) {
    switch (t) {
      case MediaType.question:
        return [AspectPreset.landscape169];
      case MediaType.short:
      case MediaType.shortThumbnail:
        return [AspectPreset.portrait916];
      case MediaType.video:
        return [AspectPreset.landscape169];
      case MediaType.article:
      case MediaType.podcast:
        return [AspectPreset.square, AspectPreset.landscape169];
      default:
        return [
          AspectPreset.square,
          AspectPreset.post45,
          AspectPreset.landscape169,
        ];
    }
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

  String _getMediaTypeLabel(MediaType t) {
    switch (t) {
      case MediaType.question:
        return '(16:9)';
      case MediaType.short:
      case MediaType.shortThumbnail:
        return '(9:16)';
      case MediaType.video:
        return '(16:9)';
      case MediaType.article:
      case MediaType.podcast:
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    if (_hasError) {
      return CropErrorScreen(
        message: _errorMessage,
        onCancel: _onCancel,
        onUseOriginal: _onSkip,
      );
    }

    final backgroundColor = isDark ? AppColors.darkBackground : Colors.black;
    final surfaceColor = isDark ? AppColors.darkSurface : Colors.black87;
    final borderColor =
        isDark ? AppColors.darkBorder : Colors.white.withOpacity(0.1);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: surfaceColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: _isCropping ? null : _onCancel,
        ),
        title: Text(
          'Recadrer ${_getMediaTypeLabel(widget.type)}',
          style: const TextStyle(
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
                color: _isCropping
                    ? Colors.white.withOpacity(0.3)
                    : AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: PopScope(
        canPop: !_isCropping,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..rotateZ(_rotationCount * 1.5708)
                      ..scale(_isFlippedH ? -1.0 : 1.0, _isFlippedV ? -1.0 : 1.0),
                    child: Crop(
                      image: widget.imageBytes,
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
                  ),
                  const IgnorePointer(
                    child: CustomPaint(
                      painter: CropGridPainter(),
                      size: Size.infinite,
                    ),
                  ),
                  _isCropping
                      ? Container(
                          color: Colors.black.withOpacity(0.6),
                          child: const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircularProgressIndicator(
                                  valueColor:
                                      AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'Traitement...',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ],
              ),
            ),
            SafeArea(
              top: false,
              child: Container(
                padding: EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: surfaceColor,
                  border: Border(
                    top: BorderSide(color: borderColor),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      height: 36,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _getAllowedPresets(widget.type).length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final allowedPresets =
                              _getAllowedPresets(widget.type);
                          final p = allowedPresets[index];
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
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        ImageToolButton(
                          icon: Icons.rotate_left,
                          tooltip: 'Rotation -90°',
                          enabled: !_isCropping,
                          onPressed: _rotateLeft,
                        ),
                        ImageToolButton(
                          icon: Icons.rotate_right,
                          tooltip: 'Rotation +90°',
                          enabled: !_isCropping,
                          onPressed: _rotateRight,
                        ),
                        ImageToolButton(
                          icon: Icons.flip,
                          tooltip: 'Miroir H',
                          enabled: !_isCropping,
                          onPressed: _flipH,
                        ),
                        ImageToolButton(
                          icon: Icons.flip,
                          tooltip: 'Miroir V',
                          enabled: !_isCropping,
                          onPressed: _flipV,
                        ),
                        ImageToolButton(
                          icon: Icons.refresh,
                          tooltip: 'Réinitialiser',
                          enabled: !_isCropping,
                          onPressed: _onResetFrame,
                        ),
                        const Spacer(),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: !_isCropping
                            ? const LinearGradient(
                                colors: [
                                  AppColors.primary,
                                  AppColors.primaryDark,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : null,
                        color: _isCropping
                            ? (isDark ? AppColors.darkCard : Colors.grey[800])
                            : null,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: !_isCropping ? _onCrop : null,
                          borderRadius: BorderRadius.circular(12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.check,
                                size: 20,
                                color: !_isCropping
                                    ? Colors.white
                                    : Colors.white.withOpacity(0.3),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Valider',
                                style: TextStyle(
                                  color: !_isCropping
                                      ? Colors.white
                                      : Colors.white.withOpacity(0.3),
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
