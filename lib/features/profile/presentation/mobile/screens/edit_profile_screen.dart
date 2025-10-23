import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:logger/logger.dart';
import 'package:thot/features/profile/domain/entities/user_profile.dart'
    show UserProfile;
import 'package:thot/features/profile/domain/entities/user_profile.dart'
    show Experience, Formation;
import 'package:thot/features/profile/domain/repositories/profile_repository.dart';
import 'package:thot/features/profile/data/repositories/profile_repository_impl.dart';
import 'package:thot/features/media/infrastructure/upload_service.dart';
import 'package:thot/features/media/utils/url_helper.dart';
import 'package:thot/core/infrastructure/dependency_injection.dart';
import 'package:thot/core/utils/safe_navigation.dart';
final _logger = Logger();
class EditProfileScreen extends StatefulWidget {
  final UserProfile userProfile;
  final ProfileRepository profileRepository;
  EditProfileScreen({
    super.key,
    required this.userProfile,
    ProfileRepository? profileRepository,
  }) : profileRepository = profileRepository ??
            ProfileRepositoryImpl(ServiceLocator.instance.apiService);
  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}
class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _fullNameController;
  late TextEditingController _bioController;
  late TextEditingController _locationController;
  late TextEditingController _journalistRoleController;
  late TextEditingController _organizationController;
  late TextEditingController _websiteController;
  late TextEditingController _linkedinController;
  late TextEditingController _twitterController;
  String? _selectedAvatarPath;
  String? _selectedCoverPath;
  bool _isSaving = false;
  UserProfile? _currentProfile;
  List<Experience> _experiences = [];
  List<Formation> _formations = [];
  final _imagePicker = ImagePicker();
  @override
  void initState() {
    super.initState();
    _currentProfile = widget.userProfile;
    _fullNameController =
        TextEditingController(text: _currentProfile?.name ?? '');
    _bioController = TextEditingController(text: _currentProfile?.bio);
    _locationController =
        TextEditingController(text: _currentProfile?.location);
    _journalistRoleController =
        TextEditingController(text: _currentProfile?.journalistRole);
    _organizationController =
        TextEditingController(text: _currentProfile?.organization);
    _websiteController = TextEditingController(
        text: _currentProfile?.socialLinks?['website'] ?? '');
    _linkedinController = TextEditingController(
        text: _currentProfile?.socialLinks?['linkedin'] ?? '');
    _twitterController = TextEditingController(
        text: _currentProfile?.socialLinks?['twitter'] ?? '');
    _experiences = List.from(_currentProfile?.experience ?? []);
    _formations = List.from(_currentProfile?.formations ?? []);
  }
  @override
  void dispose() {
    _fullNameController.dispose();
    _bioController.dispose();
    _locationController.dispose();
    _journalistRoleController.dispose();
    _organizationController.dispose();
    _websiteController.dispose();
    _linkedinController.dispose();
    _twitterController.dispose();
    super.dispose();
  }
  Future<void> _pickAvatar() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );
      if (image != null) {
        setState(() {
          _selectedAvatarPath = image.path;
        });
      }
    } catch (e) {
      _logger.e('Error picking avatar', error: e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors de la sélection de l\'avatar', style: TextStyle(color: Colors.white)),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  Future<void> _pickCover() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 400,
        imageQuality: 85,
      );
      if (image != null) {
        setState(() {
          _selectedCoverPath = image.path;
        });
      }
    } catch (e) {
      _logger.e('Error picking cover', error: e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors de la sélection de la couverture', style: TextStyle(color: Colors.white)),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  ImageProvider _getAvatarProvider() {
    if (_selectedAvatarPath != null) {
      return FileImage(File(_selectedAvatarPath!));
    }
    if (_currentProfile?.avatarUrl != null) {
      final absoluteUrl = UrlHelper.toAbsoluteUrl(_currentProfile!.avatarUrl);
      if (absoluteUrl != null) {
        return NetworkImage(absoluteUrl);
      }
    }
    return const AssetImage('assets/images/defaults/default_user_avatar.png');
  }
  ImageProvider _getCoverProvider() {
    if (_selectedCoverPath != null) {
      return FileImage(File(_selectedCoverPath!));
    }
    if (_currentProfile?.coverUrl != null) {
      final absoluteUrl = UrlHelper.toAbsoluteUrl(_currentProfile!.coverUrl);
      if (absoluteUrl != null) {
        return NetworkImage(absoluteUrl);
      }
    }
    return const AssetImage('assets/images/defaults/default_cover.png');
  }
  Future<void> _saveProfile() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    try {
      final uploadService = UploadService();
      String? avatarUrl;
      String? coverUrl;
      if (_selectedAvatarPath != null) {
        final result = await uploadService.uploadImage(
          File(_selectedAvatarPath!),
          type: 'profile',
        );
        avatarUrl = result['url'] as String?;
      }
      if (_selectedCoverPath != null) {
        final result = await uploadService.uploadImage(
          File(_selectedCoverPath!),
          type: 'cover',
        );
        coverUrl = result['url'] as String?;
      }
      final isJournalist = _currentProfile!.isJournalist;
      final updatedProfile = UserProfile(
        id: _currentProfile!.id,
        username: _currentProfile!.username,
        name: _fullNameController.text.trim(),
        email: _currentProfile!.email,
        type: _currentProfile!.type,
        role: _currentProfile!.role,
        bio: _bioController.text.isNotEmpty
            ? _bioController.text.trim()
            : _currentProfile?.bio,
        location: _locationController.text.isNotEmpty
            ? _locationController.text.trim()
            : _currentProfile?.location,
        avatarUrl: avatarUrl ?? _currentProfile?.avatarUrl,
        coverUrl: coverUrl ?? _currentProfile?.coverUrl,
        journalistRole:
            isJournalist && _journalistRoleController.text.isNotEmpty
                ? _journalistRoleController.text.trim()
                : _currentProfile?.journalistRole,
        organization: isJournalist && _organizationController.text.isNotEmpty
            ? _organizationController.text.trim()
            : _currentProfile?.organization,
        socialLinks: isJournalist
            ? {
                if (_websiteController.text.isNotEmpty)
                  'website': _websiteController.text.trim(),
                if (_linkedinController.text.isNotEmpty)
                  'linkedin': _linkedinController.text.trim(),
                if (_twitterController.text.isNotEmpty)
                  'twitter': _twitterController.text.trim(),
              }
            : _currentProfile?.socialLinks,
        followersCount: _currentProfile?.followersCount ?? 0,
        followingCount: _currentProfile?.followingCount ?? 0,
        postsCount: _currentProfile?.postsCount ?? 0,
        isFollowing: _currentProfile?.isFollowing ?? false,
        isVerified: _currentProfile?.isVerified ?? false,
        isPrivate: _currentProfile?.isPrivate ?? false,
        isBlocked: _currentProfile?.isBlocked ?? false,
        commentsCount: _currentProfile?.commentsCount ?? 0,
        reactionsCount: _currentProfile?.reactionsCount ?? 0,
        notificationCount: _currentProfile?.notificationCount ?? 0,
        highlightedStories: _currentProfile?.highlightedStories ?? [],
        politicalViews: _currentProfile?.politicalViews ?? {},
        preferences: _currentProfile?.preferences,
        status: _currentProfile?.status,
        banReason: _currentProfile?.banReason,
        bannedAt: _currentProfile?.bannedAt,
        bannedBy: _currentProfile?.bannedBy,
        unbannedAt: _currentProfile?.unbannedAt,
        unbannedBy: _currentProfile?.unbannedBy,
        suspensionReason: _currentProfile?.suspensionReason,
        suspendedAt: _currentProfile?.suspendedAt,
        suspendedBy: _currentProfile?.suspendedBy,
        suspendedUntil: _currentProfile?.suspendedUntil,
        lastActive: _currentProfile?.lastActive,
        pressCard: _currentProfile?.pressCard,
        formations: _formations,
        experience: _experiences,
        specialties: _currentProfile?.specialties,
        questions: _currentProfile?.questions,
        createdAt: _currentProfile!.createdAt,
        updatedAt: DateTime.now(),
      );
      final result =
          await widget.profileRepository.updateProfile(updatedProfile);
      if (mounted) {
        result.fold(
          (error) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Erreur: ${error.message}', style: const TextStyle(color: Colors.white)),
                backgroundColor: Colors.red,
              ),
            );
          },
          (profile) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Profil mis à jour avec succès', style: TextStyle(color: Colors.white)),
                backgroundColor: Colors.green,
              ),
            );
            SafeNavigation.pop(context, profile);
          },
        );
      }
    } catch (e) {
      _logger.e('Error saving profile', error: e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}', style: const TextStyle(color: Colors.white)),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => SafeNavigation.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.close, color: Colors.white, size: 20),
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Text(
                      'Modifier le profil',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (_isSaving)
                    const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  else
                    GestureDetector(
                      onTap: _saveProfile,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Enregistrer',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCoverAvatarSection(),
                    const SizedBox(height: 80),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionTitle('INFORMATIONS GÉNÉRALES'),
                          const SizedBox(height: 20),
                          _buildTextField(
                            controller: _fullNameController,
                            label: 'Nom complet',
                            icon: Icons.person_outline,
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _bioController,
                            label: 'Bio',
                            icon: Icons.edit_outlined,
                            maxLines: 4,
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _locationController,
                            label: 'Localisation',
                            icon: Icons.location_on_outlined,
                          ),
                          if (_currentProfile?.isJournalist == true) ...[
                            const SizedBox(height: 40),
                            _buildSectionTitle('INFORMATIONS PROFESSIONNELLES'),
                            const SizedBox(height: 20),
                            _buildTextField(
                              controller: _organizationController,
                              label: 'Organisation',
                              icon: Icons.business_outlined,
                            ),
                            const SizedBox(height: 16),
                            _buildTextField(
                              controller: _journalistRoleController,
                              label: 'Fonction',
                              icon: Icons.work_outline,
                            ),
                            const SizedBox(height: 40),
                            _buildSectionTitle('RÉSEAUX SOCIAUX'),
                            const SizedBox(height: 20),
                            _buildTextField(
                              controller: _websiteController,
                              label: 'Site web',
                              icon: Icons.language,
                            ),
                            const SizedBox(height: 16),
                            _buildTextField(
                              controller: _linkedinController,
                              label: 'LinkedIn',
                              icon: Icons.link,
                            ),
                            const SizedBox(height: 16),
                            _buildTextField(
                              controller: _twitterController,
                              label: 'Twitter/X',
                              icon: Icons.alternate_email,
                            ),
                            const SizedBox(height: 40),
                            _buildSectionTitle('EXPÉRIENCES'),
                            const SizedBox(height: 20),
                            _buildExperiencesList(),
                            const SizedBox(height: 40),
                            _buildSectionTitle('FORMATIONS'),
                            const SizedBox(height: 20),
                            _buildFormationsList(),
                          ],
                          const SizedBox(height: 40),
                        ],
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
  Widget _buildCoverAvatarSection() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        GestureDetector(
          onTap: _pickCover,
          child: Container(
            width: double.infinity,
            height: 180,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (_selectedCoverPath != null || _currentProfile?.coverUrl != null)
                  Image(
                    image: _getCoverProvider(),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => _buildCoverPlaceholder(),
                  )
                else
                  _buildCoverPlaceholder(),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.3),
                      ],
                    ),
                  ),
                ),
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white.withOpacity(0.3)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.photo_camera_outlined, color: Colors.white, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Modifier la couverture',
                          style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          left: 20,
          bottom: -60,
          child: GestureDetector(
            onTap: _pickAvatar,
            child: Stack(
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.1),
                    border: Border.all(color: Colors.white.withOpacity(0.3), width: 3),
                  ),
                  child: ClipOval(
                    child: Image(
                      image: _getAvatarProvider(),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.white.withOpacity(0.1),
                          child: const Icon(Icons.person, size: 60, color: Colors.white),
                        );
                      },
                    ),
                  ),
                ),
                Positioned(
                  bottom: 4,
                  right: 4,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.black, width: 2),
                    ),
                    child: const Icon(Icons.add_a_photo, color: Colors.black, size: 18),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
  Widget _buildCoverPlaceholder() {
    return Container(
      color: Colors.white.withOpacity(0.05),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.photo_outlined, size: 48, color: Colors.white.withOpacity(0.5)),
            const SizedBox(height: 8),
            Text(
              'Aucune photo de couverture',
              style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        color: Colors.white.withOpacity(0.5),
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.2,
      ),
    );
  }
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white, fontSize: 16),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
        prefixIcon: Icon(icon, color: Colors.white.withOpacity(0.7)),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white, width: 2),
        ),
      ),
    );
  }
  Widget _buildExperiencesList() {
    return Column(
      children: [
        ..._experiences.asMap().entries.map((entry) {
          final index = entry.key;
          final exp = entry.value;
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exp.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${exp.company}${exp.location != null ? ' • ${exp.location}' : ''}',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${exp.startDate.year} - ${exp.current ? 'Présent' : exp.endDate?.year ?? ''}',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () {
                    setState(() {
                      _experiences.removeAt(index);
                    });
                  },
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () => _showAddExperienceBottomSheet(),
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text('Ajouter une expérience', style: TextStyle(color: Colors.white)),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            side: BorderSide(color: Colors.white.withOpacity(0.3)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }
  Widget _buildFormationsList() {
    return Column(
      children: [
        ..._formations.asMap().entries.map((entry) {
          final index = entry.key;
          final form = entry.value;
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        form.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        form.institution,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${form.year}',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () {
                    setState(() {
                      _formations.removeAt(index);
                    });
                  },
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () => _showAddFormationBottomSheet(),
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text('Ajouter une formation', style: TextStyle(color: Colors.white)),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            side: BorderSide(color: Colors.white.withOpacity(0.3)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }
  Future<void> _showAddExperienceBottomSheet() async {
    final result = await showModalBottomSheet<Experience?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.black,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => const _ExperienceBottomSheet(),
    );
    if (result != null && mounted) {
      setState(() {
        _experiences.add(result);
      });
    }
  }
  Future<void> _showAddFormationBottomSheet() async {
    final result = await showModalBottomSheet<Formation?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.black,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => const _FormationBottomSheet(),
    );
    if (result != null && mounted) {
      setState(() {
        _formations.add(result);
      });
    }
  }
}
class _ExperienceBottomSheet extends StatefulWidget {
  const _ExperienceBottomSheet();
  @override
  State<_ExperienceBottomSheet> createState() => _ExperienceBottomSheetState();
}
class _ExperienceBottomSheetState extends State<_ExperienceBottomSheet> {
  late TextEditingController _titleController;
  late TextEditingController _companyController;
  late TextEditingController _locationController;
  late TextEditingController _descriptionController;
  DateTime _startDate = DateTime.now();
  DateTime? _endDate;
  bool _isCurrent = false;
  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _companyController = TextEditingController();
    _locationController = TextEditingController();
    _descriptionController = TextEditingController();
  }
  @override
  void dispose() {
    _titleController.dispose();
    _companyController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
  Widget _buildTextField(TextEditingController controller, String label, {int maxLines = 1}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white, fontSize: 16),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white, width: 2),
        ),
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        top: 24,
        left: 24,
        right: 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Nouvelle expérience',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.close, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildTextField(_titleController, 'Poste'),
            const SizedBox(height: 16),
            _buildTextField(_companyController, 'Entreprise'),
            const SizedBox(height: 16),
            _buildTextField(_locationController, 'Lieu (optionnel)'),
            const SizedBox(height: 16),
            _buildTextField(_descriptionController, 'Description (optionnel)', maxLines: 3),
            const SizedBox(height: 8),
            CheckboxListTile(
              title: const Text('Poste actuel', style: TextStyle(color: Colors.white)),
              value: _isCurrent,
              onChanged: (value) => setState(() => _isCurrent = value ?? false),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
              checkColor: Colors.black,
              activeColor: Colors.white,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(color: Colors.white.withOpacity(0.3)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Annuler', style: TextStyle(color: Colors.white, fontSize: 16)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      if (_titleController.text.trim().isEmpty || _companyController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Veuillez remplir tous les champs obligatoires', style: TextStyle(color: Colors.white)),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }
                      final experience = Experience(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        title: _titleController.text.trim(),
                        company: _companyController.text.trim(),
                        location: _locationController.text.trim().isEmpty ? null : _locationController.text.trim(),
                        startDate: _startDate,
                        endDate: _isCurrent ? null : _endDate,
                        current: _isCurrent,
                        description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
                      );
                      Navigator.pop(context, experience);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Ajouter', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
class _FormationBottomSheet extends StatefulWidget {
  const _FormationBottomSheet();
  @override
  State<_FormationBottomSheet> createState() => _FormationBottomSheetState();
}
class _FormationBottomSheetState extends State<_FormationBottomSheet> {
  late TextEditingController _titleController;
  late TextEditingController _institutionController;
  late TextEditingController _yearController;
  late TextEditingController _descriptionController;
  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _institutionController = TextEditingController();
    _yearController = TextEditingController(text: DateTime.now().year.toString());
    _descriptionController = TextEditingController();
  }
  @override
  void dispose() {
    _titleController.dispose();
    _institutionController.dispose();
    _yearController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
  Widget _buildTextField(TextEditingController controller, String label, {int maxLines = 1, TextInputType? keyboardType}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white, fontSize: 16),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white, width: 2),
        ),
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        top: 24,
        left: 24,
        right: 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Nouvelle formation',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.close, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildTextField(_titleController, 'Diplôme'),
            const SizedBox(height: 16),
            _buildTextField(_institutionController, 'École / Université'),
            const SizedBox(height: 16),
            _buildTextField(_yearController, 'Année', keyboardType: TextInputType.number),
            const SizedBox(height: 16),
            _buildTextField(_descriptionController, 'Description (optionnel)', maxLines: 3),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(color: Colors.white.withOpacity(0.3)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Annuler', style: TextStyle(color: Colors.white, fontSize: 16)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      if (_titleController.text.trim().isEmpty || _institutionController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Veuillez remplir tous les champs obligatoires', style: TextStyle(color: Colors.white)),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }
                      final year = int.tryParse(_yearController.text.trim());
                      if (year == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('L\'année doit être un nombre valide', style: TextStyle(color: Colors.white)),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }
                      final formation = Formation(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        title: _titleController.text.trim(),
                        institution: _institutionController.text.trim(),
                        year: year,
                        description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
                      );
                      Navigator.pop(context, formation);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Ajouter', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}