import 'package:thot/core/presentation/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:thot/core/config/app_config.dart';
import 'package:thot/core/routing/app_router.dart';
import 'package:thot/core/routing/route_names.dart';
import 'package:thot/features/app/profile/models/user_profile.dart';
import 'package:thot/features/app/profile/widgets/badges.dart';
import 'package:thot/features/app/profile/widgets/profile_avatar.dart';
import 'package:thot/features/app/profile/widgets/profile_cover.dart';
import 'package:url_launcher/url_launcher.dart';
import 'profile_logger.dart';
class ProfileHeader extends StatefulWidget {
  final UserProfile userProfile;
  final VoidCallback onLoadProfile;
  final bool isCurrentUser;
  final bool isProcessingFollow;
  final Function(UserProfile) onFollowToggle;
  const ProfileHeader({
    super.key,
    required this.userProfile,
    required this.onLoadProfile,
    required this.isCurrentUser,
    required this.isProcessingFollow,
    required this.onFollowToggle,
  });
  @override
  State<ProfileHeader> createState() => _ProfileHeaderState();
}
class _ProfileHeaderState extends State<ProfileHeader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  @override
  void initState() {
    super.initState();
    ProfileLogger.i(
        'ProfileHeader initState - userProfile_id: ${widget.userProfile.id}, userProfile_name: ${widget.userProfile.name}, userProfile_username: ${widget.userProfile.username}, userProfile_type: ${widget.userProfile.type}, userProfile_isJournalist: ${widget.userProfile.isJournalist}, userProfile_avatarUrl: ${widget.userProfile.avatarUrl}, userProfile_coverUrl: ${widget.userProfile.coverUrl}, isCurrentUser: ${widget.isCurrentUser}');
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _controller.forward();
  }
  void _navigateToEditProfile() {
    AppRouter.navigateTo(
      context,
      RouteNames.editProfile,
      arguments: widget.userProfile,
    );

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        widget.onLoadProfile();
      }
    });
  }

  Widget buildActionButtonsRow() {
    if (widget.isCurrentUser) {
      if (widget.userProfile.type == UserType.journalist) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  'Éditer',
                  Icons.edit,
                  onPressed: _navigateToEditProfile,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildActionButton(
                  'Statistiques',
                  Icons.bar_chart,
                  onPressed: _showStatisticsComingSoon,
                ),
              ),
            ],
          ),
        );
      } else {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: _buildActionButton(
            'Éditer',
            Icons.edit,
            onPressed: _navigateToEditProfile,
          ),
        );
      }
    }

    if (widget.userProfile.type == UserType.journalist) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: GestureDetector(
          onTap: widget.isProcessingFollow
              ? null
              : () {
                  ProfileLogger.d(
                    'Follow button tapped - userId: ${widget.userProfile.id}, currentState: ${widget.userProfile.isFollowing}',
                  );
                  widget.onFollowToggle(widget.userProfile);
                },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 40,
            decoration: BoxDecoration(
              color: widget.userProfile.isFollowing
                  ? Colors.grey[900]
                  : Theme.of(context).primaryColor,
              border: widget.userProfile.isFollowing
                  ? Border.all(color: Colors.grey[700]!, width: 1)
                  : null,
              borderRadius: BorderRadius.circular(20),
              gradient: widget.userProfile.isFollowing
                  ? null
                  : LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Theme.of(context).primaryColor,
                        Theme.of(context).primaryColor.withOpacity(0.8),
                      ],
                    ),
              boxShadow: widget.userProfile.isFollowing
                  ? null
                  : [
                      BoxShadow(
                        color: Theme.of(context).primaryColor.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
            ),
            child: widget.isProcessingFollow
                ? Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          widget.userProfile.isFollowing
                              ? Colors.grey[400]!
                              : Colors.white,
                        ),
                      ),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        widget.userProfile.isFollowing ? Icons.check : Icons.add,
                        color: widget.userProfile.isFollowing
                            ? Colors.grey[400]
                            : Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        widget.userProfile.isFollowing ? 'Abonné' : 'Suivre',
                        style: TextStyle(
                          color: widget.userProfile.isFollowing
                              ? Colors.grey[400]
                              : Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }
  Future<void> _launchUrl(String urlString) async {
    try {
      final url = Uri.parse(
          urlString.startsWith('http') ? urlString : 'https://$urlString');
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Impossible d\'ouvrir ce lien'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
  Widget _buildProfileSection() {
    return Container(
      width: double.infinity,
      color: Colors.black,
      child: Column(
        children: [
          SizedBox(
            height: 240,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: ProfileCover(
                    coverUrl: widget.userProfile.coverUrl,
                    isCurrentUser: widget.isCurrentUser,
                    onImageUpdated: widget.onLoadProfile,
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: 80,
                  child: Container(
                    color: Colors.black,
                  ),
                ),
                Positioned(
                  left: 16,
                  bottom: 25,
                  child: ProfileAvatar(
                    avatarUrl: widget.userProfile.avatarUrl,
                    userId: widget.userProfile.id,
                    isCurrentUser: widget.isCurrentUser,
                    onImageUpdated: widget.onLoadProfile,
                    role: widget.userProfile.type == UserType.journalist
                        ? 'journalist'
                        : 'regular',
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      widget.userProfile.name ?? '',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        height: 1.2,
                      ),
                    ),
                    if (widget.userProfile.isVerified &&
                        widget.userProfile.type == UserType.journalist) ...[
                      const SizedBox(width: 6),
                      const VerificationBadge(size: 20),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                if (widget.userProfile.type == UserType.journalist)
                  Text(
                    widget.userProfile.journalistRole ?? 'Journalist',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[300],
                      height: 1.3,
                    ),
                  ),
                const SizedBox(height: 8),
                if (widget.userProfile.organization != null)
                  Row(
                    children: [
                      Icon(Icons.business, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        widget.userProfile.organization!,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                if (widget.userProfile.location != null &&
                    widget.userProfile.location!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      children: [
                        Icon(Icons.location_on,
                            size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          widget.userProfile.location!,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),
                if (widget.userProfile.bio?.isNotEmpty ?? false) ...[
                  Text(
                    widget.userProfile.bio!,
                    style: TextStyle(
                      color: Colors.grey[300],
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                if (widget.userProfile.type == UserType.journalist) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            context.push('/followers/${widget.userProfile.id}');
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.1),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  '${widget.userProfile.followersCount}',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Abonnés',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.white.withOpacity(0.7),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            context.push('/following/${widget.userProfile.id}');
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.1),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  '${widget.userProfile.followingCount}',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Abonnements',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.white.withOpacity(0.7),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildFormations(),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildActionButtons() {
    if (widget.isCurrentUser) {
      if (widget.userProfile.type == UserType.journalist) {
        return Row(
          children: [
            Expanded(
              child: _buildActionButton(
                'Éditer',
                Icons.edit,
                onPressed: _navigateToEditProfile,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildActionButton(
                'Statistiques',
                Icons.bar_chart,
                onPressed: _showStatisticsComingSoon,
              ),
            ),
          ],
        );
      } else {
        return _buildActionButton(
          'Éditer',
          Icons.edit,
          onPressed: _navigateToEditProfile,
        );
      }
    }
    if (widget.userProfile.type == UserType.journalist) {
      return GestureDetector(
        onTap: widget.isProcessingFollow
            ? null
            : () {
                ProfileLogger.d(
                  'Follow button tapped - userId: ${widget.userProfile.id}, currentState: ${widget.userProfile.isFollowing}',
                );
                widget.onFollowToggle(widget.userProfile);
              },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 40,
          decoration: BoxDecoration(
            color: widget.userProfile.isFollowing
                ? Colors.grey[900]
                : Theme.of(context).primaryColor,
            border: widget.userProfile.isFollowing
                ? Border.all(color: Colors.grey[700]!, width: 1)
                : null,
            borderRadius: BorderRadius.circular(20),
            gradient: widget.userProfile.isFollowing
                ? null
                : LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Theme.of(context).primaryColor,
                      Theme.of(context).primaryColor.withOpacity(0.8),
                    ],
                  ),
            boxShadow: widget.userProfile.isFollowing
                ? null
                : [
                    BoxShadow(
                      color: Theme.of(context).primaryColor.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: widget.isProcessingFollow
              ? Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        widget.userProfile.isFollowing
                            ? Colors.grey[400]!
                            : Colors.white,
                      ),
                    ),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      widget.userProfile.isFollowing ? Icons.check : Icons.add,
                      color: widget.userProfile.isFollowing
                          ? Colors.grey[400]
                          : Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.userProfile.isFollowing ? 'Abonné' : 'Suivre',
                      style: TextStyle(
                        color: widget.userProfile.isFollowing
                            ? Colors.grey[400]
                            : Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
        ),
      );
    }
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: widget.isProcessingFollow
                ? null
                : () {
                    ProfileLogger.d(
                      'Follow button tapped - userId: ${widget.userProfile.id}, currentState: ${widget.userProfile.isFollowing}',
                    );
                    widget.onFollowToggle(widget.userProfile);
                  },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 40,
              decoration: BoxDecoration(
                color: widget.userProfile.isFollowing
                    ? Colors.grey[900]
                    : Theme.of(context).primaryColor,
                border: widget.userProfile.isFollowing
                    ? Border.all(color: Colors.grey[700]!, width: 1)
                    : null,
                borderRadius: BorderRadius.circular(20),
                gradient: widget.userProfile.isFollowing
                    ? null
                    : LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Theme.of(context).primaryColor,
                          Theme.of(context).primaryColor.withOpacity(0.8),
                        ],
                      ),
                boxShadow: widget.userProfile.isFollowing
                    ? null
                    : [
                        BoxShadow(
                          color:
                              Theme.of(context).primaryColor.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
              ),
              child: widget.isProcessingFollow
                  ? Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            widget.userProfile.isFollowing
                                ? Colors.grey[400]!
                                : Colors.white,
                          ),
                        ),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          widget.userProfile.isFollowing
                              ? Icons.check
                              : Icons.add,
                          color: widget.userProfile.isFollowing
                              ? Colors.grey[400]
                              : Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          widget.userProfile.isFollowing ? 'Abonné' : 'Suivre',
                          style: TextStyle(
                            color: widget.userProfile.isFollowing
                                ? Colors.grey[400]
                                : Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ],
    );
  }
  Widget _buildActionButton(
    String label,
    IconData icon, {
    required VoidCallback onPressed,
  }) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: Colors.black,
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showStatisticsComingSoon() {
    if (!mounted) return;
    context.push(
      RouteNames.stats,
      extra: {'journalistId': widget.userProfile.id},
    );
  }
  Widget _buildFormations() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: Colors.grey[850]!),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.school,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Formation',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (widget.userProfile.formations?.isEmpty ?? true)
                const Text(
                  'Aucune formation ajoutée',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: widget.userProfile.formations!.map((formation) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            formation.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            '${formation.institution} · ${formation.year}',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 14,
                            ),
                          ),
                          if (formation.description?.isNotEmpty ?? false)
                            Text(
                              formation.description!,
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 14,
                              ),
                            ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: Colors.grey[850]!),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.work,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Expérience',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (widget.userProfile.experience?.isEmpty ?? true)
                const Text(
                  'Aucune expérience ajoutée',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: widget.userProfile.experience!.map((experience) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            experience.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            '${experience.company}${experience.location != null ? ' · ${experience.location}' : ''}',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            experience.current
                                ? 'Actuel'
                                : experience.endDate?.year.toString() ?? 'N/A',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
            ],
          ),
        ),
        if (widget.userProfile.socialLinks?.isNotEmpty ?? false)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.grey[850]!),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.userProfile.socialLinks?['website']?.isNotEmpty ??
                    false)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: GestureDetector(
                      onTap: () => _launchUrl(
                          widget.userProfile.socialLinks!['website']!),
                      child: const Icon(
                        Icons.language,
                        color: Colors.grey,
                        size: 24,
                      ),
                    ),
                  ),
                if (widget.userProfile.socialLinks?['linkedin']?.isNotEmpty ??
                    false)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: GestureDetector(
                      onTap: () => _launchUrl(
                          'https://linkedin.com/in/${widget.userProfile.socialLinks!['linkedin']}'),
                      child: const Icon(
                        Icons.work,
                        color: Colors.grey,
                        size: 24,
                      ),
                    ),
                  ),
                if (widget.userProfile.socialLinks?['twitter']?.isNotEmpty ??
                    false)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: GestureDetector(
                      onTap: () => _launchUrl(
                          'https://twitter.com/${widget.userProfile.socialLinks!['twitter']}'),
                      child: const Icon(
                        Icons.alternate_email,
                        color: Colors.grey,
                        size: 24,
                      ),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: _buildProfileSection(),
      ),
    );
  }
  @override
  void didUpdateWidget(ProfileHeader oldWidget) {
    super.didUpdateWidget(oldWidget);
  }
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}