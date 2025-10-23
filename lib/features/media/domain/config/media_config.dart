import 'dart:math' as math;
class Resolution {
  final int width;
  final int height;
  const Resolution(this.width, this.height);
  double get aspectRatio => width / height;
  Resolution scaleToFit({int? maxWidth, int? maxHeight}) {
    if (maxWidth == null && maxHeight == null) return this;
    final double w = width.toDouble();
    final double h = height.toDouble();
    if (maxWidth != null && maxHeight != null) {
      final fw = maxWidth / w;
      final fh = maxHeight / h;
      final f = math.min(fw, fh);
      return Resolution((w * f).round(), (h * f).round());
    }
    if (maxWidth != null) {
      final newHeight = (maxWidth / aspectRatio).round();
      return Resolution(maxWidth, math.max(newHeight, 1));
    }
    final newWidth = (maxHeight! * aspectRatio).round();
    return Resolution(math.max(newWidth, 1), maxHeight);
  }
  static Resolution fromWidth(double aspectRatio, int width) =>
      Resolution(width, (width / aspectRatio).round());
  static Resolution fromHeight(double aspectRatio, int height) =>
      Resolution((height * aspectRatio).round(), height);
  @override
  String toString() => '${width}x$height';
}
class Quality {
  final int? videoHeight;
  final int? videoBitrate;
  final int? videoFrameRate;
  final int? audioBitrate;
  final int? audioSampleRate;
  final int? jpegQuality;
  const Quality({
    this.videoHeight,
    this.videoBitrate,
    this.videoFrameRate,
    this.audioBitrate,
    this.audioSampleRate,
    this.jpegQuality,
  });
}
class MediaSpec {
  final double aspectRatio;
  final Duration? maxDuration;
  final int maxFileSize;
  final bool isAudio;
  final bool isVideo;
  final bool isImage;
  final Resolution? recommendedResolution;
  final Quality? quality;
  final List<String> allowedExtensions;
  const MediaSpec({
    required this.aspectRatio,
    this.maxDuration,
    required this.maxFileSize,
    required this.isAudio,
    required this.isVideo,
    required this.isImage,
    this.recommendedResolution,
    this.quality,
    this.allowedExtensions = const [],
  });
}
class MediaConfig {
  static const int _kB = 1024;
  static const int _mb = 1024 * _kB;
  static const double questionAspectRatio = 16 / 9;
  static const double shortAspectRatio = 9 / 16;
  static const double articleAspectRatio = 1 / 1;
  static const double videoAspectRatio = 16 / 9;
  static const int shortMaxDuration = 60;
  static const int videoMaxDuration = 300;
  static const Duration shortMax = Duration(seconds: shortMaxDuration);
  static const Duration videoMax = Duration(seconds: videoMaxDuration);
  static const int videoHeight = 480;
  static const int videoBitrate = 1500000;
  static const int videoFrameRate = 30;
  static const int audioBitrate = 192000;
  static const int audioSampleRate = 44100;
  static const int maxImageSize = 10 * _mb;
  static const int maxShortVideoSize = 500 * _mb;
  static const int maxVideoSize = 500 * _mb;
  static const int maxAudioSize = 100 * _mb;
  static const int jpegQuality = 85;
  static const Resolution res1080pLandscape = Resolution(1920, 1080);
  static const Resolution res1080pPortrait = Resolution(1080, 1920);
  static const Resolution res1080Square = Resolution(1080, 1080);
  static const List<String> _imageExt = ['jpg', 'jpeg', 'png', 'webp'];
  static const List<String> _videoExt = ['mp4', 'mov', 'm4v', 'webm'];
  static const List<String> _audioExt = ['mp3', 'aac', 'm4a', 'wav', 'flac'];
  static const Map<MediaType, MediaSpec> specByType = {
    MediaType.question: MediaSpec(
      aspectRatio: questionAspectRatio,
      maxDuration: null,
      maxFileSize: maxImageSize,
      isAudio: false,
      isVideo: false,
      isImage: true,
      recommendedResolution: res1080pLandscape,
      quality: Quality(jpegQuality: jpegQuality),
      allowedExtensions: _imageExt,
    ),
    MediaType.short: MediaSpec(
      aspectRatio: shortAspectRatio,
      maxDuration: shortMax,
      maxFileSize: maxShortVideoSize,
      isAudio: false,
      isVideo: true,
      isImage: false,
      recommendedResolution: res1080pPortrait,
      quality: Quality(
        videoHeight: 1080,
        videoBitrate: 6000000,
        videoFrameRate: 30,
        audioBitrate: audioBitrate,
        audioSampleRate: audioSampleRate,
      ),
      allowedExtensions: _videoExt,
    ),
    MediaType.article: MediaSpec(
      aspectRatio: articleAspectRatio,
      maxDuration: null,
      maxFileSize: maxImageSize,
      isAudio: false,
      isVideo: false,
      isImage: true,
      recommendedResolution: res1080Square,
      quality: Quality(jpegQuality: jpegQuality),
      allowedExtensions: _imageExt,
    ),
    MediaType.video: MediaSpec(
      aspectRatio: videoAspectRatio,
      maxDuration: videoMax,
      maxFileSize: maxVideoSize,
      isAudio: false,
      isVideo: true,
      isImage: false,
      recommendedResolution: res1080pLandscape,
      quality: Quality(
        videoHeight: 1080,
        videoBitrate: 8000000,
        videoFrameRate: 30,
        audioBitrate: audioBitrate,
        audioSampleRate: audioSampleRate,
      ),
      allowedExtensions: _videoExt,
    ),
    MediaType.podcast: MediaSpec(
      aspectRatio: articleAspectRatio,
      maxDuration: null,
      maxFileSize: maxAudioSize,
      isAudio: true,
      isVideo: false,
      isImage: false,
      recommendedResolution: null,
      quality: Quality(
        audioBitrate: audioBitrate,
        audioSampleRate: audioSampleRate,
      ),
      allowedExtensions: _audioExt,
    ),
    MediaType.shortThumbnail: MediaSpec(
      aspectRatio: shortAspectRatio,
      maxDuration: null,
      maxFileSize: maxImageSize,
      isAudio: false,
      isVideo: false,
      isImage: true,
      recommendedResolution: res1080pPortrait,
      quality: Quality(jpegQuality: jpegQuality),
      allowedExtensions: _imageExt,
    ),
  };
  static String formatBytes(int bytes, {int decimals = 1}) {
    if (bytes < _kB) return '$bytes B';
    if (bytes < _mb) return '${(bytes / _kB).toStringAsFixed(decimals)} KB';
    return '${(bytes / _mb).toStringAsFixed(decimals)} MB';
  }
  static String formatDuration(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    return h > 0 ? '${two(h)}:${two(m)}:${two(s)}' : '${two(m)}:${two(s)}';
  }
  static List<String> validateUpload({
    required MediaType type,
    int? fileSizeBytes,
    Duration? duration,
    int? width,
    int? height,
    String? extension,
    double aspectTolerance = 0.01,
  }) {
    final spec = specByType[type]!;
    final issues = <String>[];
    if (fileSizeBytes != null && fileSizeBytes > spec.maxFileSize) {
      issues.add(
        'Taille trop élevée: ${formatBytes(fileSizeBytes)} > '
        '${formatBytes(spec.maxFileSize)}',
      );
    }
    if (duration != null &&
        spec.maxDuration != null &&
        duration > spec.maxDuration!) {
      issues.add(
        'Durée trop longue: ${formatDuration(duration)} > '
        '${formatDuration(spec.maxDuration!)}',
      );
    }
    if (width != null && height != null) {
      final actual = width / height;
      final delta = (actual - spec.aspectRatio).abs() / spec.aspectRatio;
      if (delta > aspectTolerance) {
        issues.add(
          'Mauvais ratio: ${actual.toStringAsFixed(3)} attendu ~ '
          '${spec.aspectRatio.toStringAsFixed(3)} (±${(aspectTolerance * 100).toStringAsFixed(1)}%)',
        );
      }
    }
    if (extension != null && spec.allowedExtensions.isNotEmpty) {
      final ext = extension.toLowerCase();
      if (!spec.allowedExtensions.contains(ext)) {
        issues.add(
          'Extension non prise en charge: .$ext '
          '(autorisées: ${spec.allowedExtensions.map((e) => '.$e').join(', ')})',
        );
      }
    }
    return issues;
  }
  static Resolution recommendedResolutionFor(
    MediaType type, {
    int? maxWidth,
    int? maxHeight,
  }) {
    final spec = specByType[type]!;
    final base = spec.recommendedResolution ??
        (spec.aspectRatio >= 1
            ? Resolution.fromWidth(spec.aspectRatio, 1920)
            : Resolution.fromHeight(spec.aspectRatio, 1920));
    return base.scaleToFit(maxWidth: maxWidth, maxHeight: maxHeight);
  }
  static Resolution fromWidth(MediaType type, int width) =>
      Resolution.fromWidth(specByType[type]!.aspectRatio, width);
  static Resolution fromHeight(MediaType type, int height) =>
      Resolution.fromHeight(specByType[type]!.aspectRatio, height);
  @Deprecated('Utilisez MediaConfig.specByType[type]?.quality.videoHeight')
  static const int legacyVideoHeight = videoHeight;
  @Deprecated('Utilisez MediaConfig.specByType[type]?.quality.videoBitrate')
  static const int legacyVideoBitrate = videoBitrate;
  @Deprecated('Utilisez MediaConfig.specByType[type]?.quality.videoFrameRate')
  static const int legacyVideoFrameRate = videoFrameRate;
}
enum MediaType { question, short, article, video, podcast, shortThumbnail }
extension MediaTypeExtension on MediaType {
  double get aspectRatio => MediaConfig.specByType[this]!.aspectRatio;
  int? get maxVideoDuration {
    switch (this) {
      case MediaType.short:
        return MediaConfig.shortMaxDuration;
      case MediaType.video:
        return MediaConfig.videoMaxDuration;
      default:
        return null;
    }
  }
  Duration? get maxDuration => MediaConfig.specByType[this]!.maxDuration;
  int get maxFileSize => MediaConfig.specByType[this]!.maxFileSize;
  bool get isAudioContent => MediaConfig.specByType[this]!.isAudio;
  bool get isVideoContent => MediaConfig.specByType[this]!.isVideo;
  bool get isImageContent => MediaConfig.specByType[this]!.isImage;
  List<String> get allowedExtensions =>
      MediaConfig.specByType[this]!.allowedExtensions;
  Resolution? get recommendedResolution =>
      MediaConfig.specByType[this]!.recommendedResolution;
  Quality? get quality => MediaConfig.specByType[this]!.quality;
}