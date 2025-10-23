import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:thot/core/themes/app_colors.dart';
import 'package:thot/core/constants/app_constants.dart';
import 'package:thot/core/utils/safe_navigation.dart';
import 'package:thot/features/posts/presentation/mobile/screens/new_article_screen.dart';
import 'package:thot/features/posts/presentation/mobile/screens/new_video_screen.dart';
import 'package:thot/features/posts/presentation/mobile/screens/new_podcast_screen.dart';
@immutable
class Domain {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  const Domain({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}
@immutable
class ContentFormat {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  const ContentFormat({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}
class NewPublicationScreen extends StatefulWidget {
  final String journalistId;
  const NewPublicationScreen({super.key, required this.journalistId});
  @override
  State<NewPublicationScreen> createState() => _NewPublicationScreenState();
}
class _NewPublicationScreenState extends State<NewPublicationScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  Domain? _selectedDomain;
  ContentFormat? _selectedFormat;
  String _searchQuery = '';
  static const _domains = <Domain>[
    Domain(
      id: 'politique',
      title: 'Politique',
      description: 'Actualités politiques et gouvernementales',
      icon: Icons.account_balance,
      color: AppColors.blue,
    ),
    Domain(
      id: 'economie',
      title: 'Économie',
      description: 'Marchés, finances et entreprises',
      icon: Icons.trending_up,
      color: AppColors.success,
    ),
    Domain(
      id: 'science',
      title: 'Science',
      description: 'Découvertes et innovations scientifiques',
      icon: Icons.science,
      color: AppColors.purple,
    ),
    Domain(
      id: 'international',
      title: 'International',
      description: 'Actualités du monde entier',
      icon: Icons.public,
      color: AppColors.orange,
    ),
    Domain(
      id: 'juridique',
      title: 'Juridique',
      description: 'Droit, justice et législation',
      icon: Icons.gavel,
      color: AppColors.red,
    ),
    Domain(
      id: 'philosophie',
      title: 'Philosophie',
      description: 'Idées et réflexions philosophiques',
      icon: Icons.psychology,
      color: AppColors.purple,
    ),
    Domain(
      id: 'societe',
      title: 'Société',
      description: 'Questions sociales et sociétales',
      icon: Icons.groups,
      color: AppColors.success,
    ),
    Domain(
      id: 'psychologie',
      title: 'Psychologie',
      description: 'Comportement humain et mental',
      icon: Icons.self_improvement,
      color: AppColors.red,
    ),
    Domain(
      id: 'sport',
      title: 'Sport',
      description: 'Actualités sportives et résultats',
      icon: Icons.sports_soccer,
      color: AppColors.warning,
    ),
    Domain(
      id: 'technologie',
      title: 'Technologie',
      description: 'Innovation et nouvelles technologies',
      icon: Icons.computer,
      color: AppColors.blue,
    ),
  ];
  static const _formats = <ContentFormat>[
    ContentFormat(
      id: 'article',
      title: 'Article',
      description: 'Rédigez un article détaillé',
      icon: Icons.article_outlined,
      color: AppColors.blue,
    ),
    ContentFormat(
      id: 'video',
      title: 'Vidéo',
      description: 'Créez une vidéo explicative',
      icon: Icons.videocam_outlined,
      color: AppColors.red,
    ),
    ContentFormat(
      id: 'podcast',
      title: 'Podcast',
      description: 'Enregistrez un podcast audio',
      icon: Icons.podcasts_outlined,
      color: AppColors.purple,
    ),
  ];
  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }
  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }
  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }
  List<Domain> get _filteredDomains {
    if (_searchQuery.isEmpty) return _domains;
    return _domains
        .where((d) =>
            d.title.toLowerCase().contains(_searchQuery) ||
            d.description.toLowerCase().contains(_searchQuery))
        .toList();
  }
  void _onContinue() {
    if (_selectedDomain == null || _selectedFormat == null) {
      HapticFeedback.lightImpact();
      SafeNavigation.showSnackBar(
        context,
        SnackBar(
          content: Text('Veuillez sélectionner un domaine et un format'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    HapticFeedback.mediumImpact();
    final domain = _selectedDomain!.id;
    final journalistId = widget.journalistId;
    Widget screen;
    switch (_selectedFormat!.id) {
      case 'article':
        screen = NewArticleScreen(domain: domain, journalistId: journalistId);
        break;
      case 'video':
        screen = NewVideoScreen(domain: domain, journalistId: journalistId);
        break;
      case 'podcast':
        screen = NewPodcastScreen(domain: domain, journalistId: journalistId);
        break;
      default:
        return;
    }
    SafeNavigation.push(context, MaterialPageRoute(builder: (context) => screen));
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Nouvelle publication',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(UIConstants.paddingM),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Domaine',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Choisissez le domaine de votre publication',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 14,
                    ),
                  ),
                  SizedBox(height: 16),
                  TextField(
                    controller: _searchController,
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Rechercher un domaine...',
                      hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                      prefixIcon: Icon(Icons.search, color: Colors.white.withOpacity(0.5)),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.05),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  ..._filteredDomains.map((domain) => Padding(
                        padding: EdgeInsets.only(bottom: 12),
                        child: _DomainCard(
                          domain: domain,
                          isSelected: _selectedDomain?.id == domain.id,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() => _selectedDomain = domain);
                          },
                        ),
                      )),
                  if (_filteredDomains.isEmpty)
                    Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 32),
                        child: Text(
                          'Aucun domaine trouvé',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  SizedBox(height: 32),
                  Text(
                    'Format',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Choisissez le format de votre contenu',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 14,
                    ),
                  ),
                  SizedBox(height: 16),
                  ..._formats.map((format) => Padding(
                        padding: EdgeInsets.only(bottom: 12),
                        child: _FormatCard(
                          format: format,
                          isSelected: _selectedFormat?.id == format.id,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() => _selectedFormat = format);
                          },
                        ),
                      )),
                  SizedBox(height: 100),
                ],
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Container(
              padding: EdgeInsets.all(UIConstants.paddingM),
              decoration: BoxDecoration(
                color: Colors.black,
                border: Border(
                  top: BorderSide(
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
              ),
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  color: _selectedDomain != null && _selectedFormat != null
                      ? Colors.white
                      : Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: _selectedDomain == null || _selectedFormat == null
                      ? Border.all(
                          color: Colors.white.withOpacity(0.1),
                        )
                      : null,
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _selectedDomain != null && _selectedFormat != null
                        ? _onContinue
                        : null,
                    borderRadius: BorderRadius.circular(12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.arrow_forward_rounded,
                          size: 20,
                          color: _selectedDomain != null && _selectedFormat != null
                              ? Colors.black
                              : Colors.white.withOpacity(0.3),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Continuer',
                          style: TextStyle(
                            color: _selectedDomain != null && _selectedFormat != null
                                ? Colors.black
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
            ),
          ),
        ],
      ),
    );
  }
}
class _DomainCard extends StatelessWidget {
  final Domain domain;
  final bool isSelected;
  final VoidCallback onTap;
  const _DomainCard({
    required this.domain,
    required this.isSelected,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? domain.color
                : Colors.white.withOpacity(0.1),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isSelected
                    ? domain.color.withOpacity(0.15)
                    : Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                domain.icon,
                color: isSelected ? domain.color : Colors.white,
                size: 24
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    domain.title,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    domain.description,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: domain.color, size: 24),
          ],
        ),
      ),
    );
  }
}
class _FormatCard extends StatelessWidget {
  final ContentFormat format;
  final bool isSelected;
  final VoidCallback onTap;
  const _FormatCard({
    required this.format,
    required this.isSelected,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? format.color
                : Colors.white.withOpacity(0.1),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isSelected
                    ? format.color.withOpacity(0.15)
                    : Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                format.icon,
                color: isSelected ? format.color : Colors.white,
                size: 24
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    format.title,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    format.description,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: format.color, size: 24),
          ],
        ),
      ),
    );
  }
}