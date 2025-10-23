import 'dart:typed_data';
import 'package:image/image.dart' as img;

/// Utilitaires de transformation d'images
/// Fonctions isolables pour rotation et flip

Uint8List decodeNormalizeIsolate(Uint8List bytes) {
  final decoded = img.decodeImage(bytes);
  if (decoded == null) throw StateError('decodeImage returned null');
  final baked = img.bakeOrientation(decoded);
  return Uint8List.fromList(img.encodePng(baked));
}

Uint8List rotateRightSync(Uint8List bytes) {
  final decoded = img.decodeImage(bytes);
  if (decoded == null) throw StateError('decode null');
  final rotated = img.copyRotate(decoded, angle: 90);
  return Uint8List.fromList(img.encodePng(rotated));
}

Uint8List rotateLeftSync(Uint8List bytes) {
  final decoded = img.decodeImage(bytes);
  if (decoded == null) throw StateError('decode null');
  final rotated = img.copyRotate(decoded, angle: -90);
  return Uint8List.fromList(img.encodePng(rotated));
}

Uint8List flipHorizontalSync(Uint8List bytes) {
  final decoded = img.decodeImage(bytes);
  if (decoded == null) throw StateError('decode null');
  final flipped = img.flipHorizontal(decoded);
  return Uint8List.fromList(img.encodePng(flipped));
}

Uint8List flipVerticalSync(Uint8List bytes) {
  final decoded = img.decodeImage(bytes);
  if (decoded == null) throw StateError('decode null');
  final flipped = img.flipVertical(decoded);
  return Uint8List.fromList(img.encodePng(flipped));
}
