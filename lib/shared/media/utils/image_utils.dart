import 'package:flutter/painting.dart';
import 'package:thot/shared/media/utils/url_helper.dart';
import 'package:cached_network_image/cached_network_image.dart';
class ImageUtils {
  static String validateImageUrl(String? url) {
    if (url == null || url.isEmpty) {
      return '';
    }
    if (url.startsWith('file://')) {
      return '';
    }
    if (url == 'file://') {
      return '';
    }
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }
    return UrlHelper.buildMediaUrl(url) ?? '';
  }
  static bool isValidImageUrl(String? url) {
    if (url == null || url.isEmpty) {
      return false;
    }
    if (url == 'file://') {
      return false;
    }
    if (url.startsWith('file://')) {
      return false;
    }
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return true;
    }
    if (url.startsWith('file:///')) {
      return true;
    }
    if (!url.contains('://')) {
      return true;
    }
    return false;
  }
  static String getSafeImageUrl(String? url) {
    if (!isValidImageUrl(url)) {
      return '';
    }
    return validateImageUrl(url);
  }
  static String constructFullUrl(String? relativePath) {
    if (relativePath == null || relativePath.isEmpty) {
      return '';
    }
    if (relativePath.startsWith('http://') || relativePath.startsWith('https://')) {
      return relativePath;
    }
    return UrlHelper.buildMediaUrl(relativePath) ?? '';
  }
  static String getAvatarUrl(String? avatarPath) {
    if (avatarPath == null || avatarPath.isEmpty) {
      return '';
    }
    if (avatarPath == 'file://' ||
        avatarPath == 'null' ||
        avatarPath == 'undefined') {
      return '';
    }
    final url = getSafeImageUrl(avatarPath);
    if (url.isNotEmpty) {
      try {
        final uri = Uri.parse(url);
        return uri.toString();
      } catch (e) {
        try {
          final parts = url.split('/');
          final encodedParts = parts.map((part) {
            if (part.contains(':') || part.isEmpty) return part;
            return Uri.encodeComponent(part);
          }).toList();
          return encodedParts.join('/');
        } catch (e2) {
          return '';
        }
      }
    }
    return url;
  }
  static String getCoverUrl(String? coverPath) {
    if (coverPath == null || coverPath.isEmpty) {
      return '';
    }
    if (coverPath == 'file://' ||
        coverPath == 'null' ||
        coverPath == 'undefined') {
      return '';
    }
    final url = getSafeImageUrl(coverPath);
    if (url.isNotEmpty) {
      try {
        final uri = Uri.parse(url);
        return uri.toString();
      } catch (e) {
        try {
          final parts = url.split('/');
          final encodedParts = parts.map((part) {
            if (part.contains(':') || part.isEmpty) return part;
            return Uri.encodeComponent(part);
          }).toList();
          return encodedParts.join('/');
        } catch (e2) {
          return '';
        }
      }
    }
    return url;
  }
  static List<String> validateMediaUrls(List<String>? urls) {
    if (urls == null || urls.isEmpty) {
      return [];
    }
    return urls
        .map((url) => getSafeImageUrl(url))
        .where((url) => url.isNotEmpty)
        .toList();
  }
  static String processImageUrl(String? url) {
    return validateImageUrl(url);
  }
  static bool isValidNetworkUrl(String? url) {
    if (url == null || url.isEmpty) {
      return false;
    }
    String processedUrl = validateImageUrl(url);
    if (processedUrl.isEmpty) {
      return false;
    }
    return processedUrl.startsWith('http://') ||
        processedUrl.startsWith('https://');
  }
  static void debugInvalidUrl(String? url, String context) {
    if (url != null &&
        (url == 'file://' || url.startsWith('file://'))) {
      // Debug invalid URLs
    }
  }
  static Future<void> evictFromCache(String? imageUrl) async {
    if (imageUrl == null || imageUrl.isEmpty) return;
    final processedUrl = validateImageUrl(imageUrl);
    if (processedUrl.isEmpty) return;
    await CachedNetworkImage.evictFromCache(processedUrl);
  }
  static Future<void> clearAllCache() async {
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
  }
  static String getCacheBustingUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    final processedUrl = validateImageUrl(url);
    if (processedUrl.isEmpty) return '';
    final separator = processedUrl.contains('?') ? '&' : '?';
    return '$processedUrl${separator}t=${DateTime.now().millisecondsSinceEpoch}';
  }
}