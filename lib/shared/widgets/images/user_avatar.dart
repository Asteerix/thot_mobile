import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class UserAvatar extends StatelessWidget {
  final String? avatarUrl;
  final String? name;
  final bool isJournalist;
  final double radius;

  const UserAvatar({
    super.key,
    this.avatarUrl,
    this.name,
    this.isJournalist = false,
    this.radius = 24,
  });

  String get _defaultAsset {
    return isJournalist
        ? 'assets/images/defaults/default_journalist_avatar.png'
        : 'assets/images/defaults/default_user_avatar.png';
  }

  bool get _hasValidUrl {
    if (avatarUrl == null || avatarUrl!.isEmpty) return false;
    if (avatarUrl!.contains('localhost')) return false;
    if (avatarUrl!.startsWith('http://localhost')) return false;
    if (avatarUrl!.startsWith('https://localhost')) return false;
    if (avatarUrl!.contains('/defaults/default_')) return false;
    return avatarUrl!.startsWith('http://') || avatarUrl!.startsWith('https://');
  }

  String get _initial {
    if (name != null && name!.isNotEmpty) {
      return name![0].toUpperCase();
    }
    return '?';
  }

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.grey[800],
      child: _hasValidUrl
          ? ClipOval(
              child: CachedNetworkImage(
                imageUrl: avatarUrl!,
                width: radius * 2,
                height: radius * 2,
                fit: BoxFit.cover,
                placeholder: (context, url) => Center(
                  child: SizedBox(
                    width: radius * 0.5,
                    height: radius * 0.5,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white.withOpacity(0.5),
                    ),
                  ),
                ),
                errorWidget: (context, url, error) => ClipOval(
                  child: Image.asset(
                    _defaultAsset,
                    width: radius * 2,
                    height: radius * 2,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Center(
                      child: Text(
                        _initial,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: radius * 0.75,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            )
          : ClipOval(
              child: Image.asset(
                _defaultAsset,
                width: radius * 2,
                height: radius * 2,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Center(
                  child: Text(
                    _initial,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: radius * 0.75,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}
