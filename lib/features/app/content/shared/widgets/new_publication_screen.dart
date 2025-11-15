import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:thot/core/utils/safe_navigation.dart';
import 'package:thot/core/routing/route_names.dart';

@immutable
class PublicationFormat {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  const PublicationFormat({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
  });
}

@immutable
class ContentSubType {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  const ContentSubType({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
  });
}

@immutable
class Domain {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  const Domain({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
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
  PublicationFormat? _selectedFormat;
  Domain? _selectedDomain;
  ContentSubType? _selectedSubType;
  String _searchQuery = '';
  int _currentStep = 0;
  static const _formats = <PublicationFormat>[
    PublicationFormat(
      id: 'publications',
      title: 'Publications',
      description: 'Créez un article, une vidéo ou un podcast',
      icon: Icons.article,
    ),
    PublicationFormat(
      id: 'shorts',
      title: 'Shorts',
      description: 'Partagez du contenu court et impactant',
      icon: Icons.play_circle_filled,
    ),
    PublicationFormat(
      id: 'questions',
      title: 'Questions',
      description: 'Posez une question à la communauté',
      icon: Icons.help_outline,
    ),
  ];
  static const _subTypes = <ContentSubType>[
    ContentSubType(
      id: 'article',
      title: 'Article',
      description: 'Rédigez un article détaillé',
      icon: Icons.article,
    ),
    ContentSubType(
      id: 'video',
      title: 'Vidéo',
      description: 'Créez une vidéo explicative',
      icon: Icons.videocam,
    ),
    ContentSubType(
      id: 'podcast',
      title: 'Podcast',
      description: 'Enregistrez un podcast audio',
      icon: Icons.podcasts,
    ),
  ];
  static const _domains = <Domain>[
    Domain(
      id: 'politique',
      title: 'Politique',
      description: 'Actualités politiques et gouvernementales',
      icon: Icons.account_balance,
    ),
    Domain(
      id: 'economie',
      title: 'Économie',
      description: 'Marchés, finances et entreprises',
      icon: Icons.trending_up,
    ),
    Domain(
      id: 'science',
      title: 'Science',
      description: 'Découvertes et innovations scientifiques',
      icon: Icons.science,
    ),
    Domain(
      id: 'international',
      title: 'International',
      description: 'Actualités du monde entier',
      icon: Icons.public,
    ),
    Domain(
      id: 'juridique',
      title: 'Juridique',
      description: 'Droit, justice et législation',
      icon: Icons.gavel,
    ),
    Domain(
      id: 'philosophie',
      title: 'Philosophie',
      description: 'Idées et réflexions philosophiques',
      icon: Icons.psychology,
    ),
    Domain(
      id: 'societe',
      title: 'Société',
      description: 'Questions sociales et sociétales',
      icon: Icons.group,
    ),
    Domain(
      id: 'psychologie',
      title: 'Psychologie',
      description: 'Comportement humain et mental',
      icon: Icons.psychology,
    ),
    Domain(
      id: 'sport',
      title: 'Sport',
      description: 'Actualités sportives et résultats',
      icon: Icons.emoji_events,
    ),
    Domain(
      id: 'technologie',
      title: 'Technologie',
      description: 'Innovation et nouvelles technologies',
      icon: Icons.laptop,
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

  void _onFormatSelected(PublicationFormat format) {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedFormat = format;
    });
  }

  void _onSubTypeSelected(ContentSubType subType) {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedSubType = subType;
    });
  }

  void _onDomainSelected(Domain domain) {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedDomain = domain;
    });
  }

  void _onBack() {
    HapticFeedback.lightImpact();
    if (_currentStep == 2) {
      setState(() {
        if (_selectedFormat?.id == 'publications' && _selectedSubType != null) {
          _currentStep = 1;
          _selectedDomain = null;
        } else {
          _currentStep = 0;
          _selectedFormat = null;
          _selectedSubType = null;
          _selectedDomain = null;
        }
      });
    } else if (_currentStep == 1) {
      setState(() {
        _currentStep = 0;
        _selectedFormat = null;
        _selectedSubType = null;
      });
    } else {
      Navigator.of(context).pop();
    }
  }

  void _onContinue() {
    HapticFeedback.mediumImpact();

    if (_currentStep == 0 && _selectedFormat != null) {
      // Si questions ou shorts, passer direct à step 2 (domaine)
      if (_selectedFormat!.id == 'questions' || _selectedFormat!.id == 'shorts') {
        setState(() => _currentStep = 2);
      } else {
        setState(() => _currentStep = 1);
      }
      return;
    }

    if (_currentStep == 1 && _selectedSubType != null) {
      setState(() => _currentStep = 2);
      return;
    }

    if (_currentStep == 2 && _selectedDomain != null) {
      _navigateToCreation();
      return;
    }

    if (_selectedFormat == null) {
      SafeNavigation.showSnackBar(
        context,
        const SnackBar(
          content: Text('Veuillez sélectionner un format'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (_selectedFormat!.id == 'publications' && _selectedSubType == null) {
      SafeNavigation.showSnackBar(
        context,
        const SnackBar(
          content: Text('Veuillez sélectionner un type de publication'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
  }

  void _navigateToCreation() {
    if (_selectedFormat == null || _selectedDomain == null) return;
    if (_selectedFormat!.id == 'publications' && _selectedSubType == null) return;

    final String formatId;
    if (_selectedFormat!.id == 'publications') {
      formatId = _selectedSubType!.id;
    } else if (_selectedFormat!.id == 'shorts') {
      formatId = 'short';
    } else {
      formatId = 'question';
    }
    final domain = _selectedDomain!.id;

    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('🚀 NAVIGATE TO CREATION');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('📍 Format: ${_selectedFormat!.id}');
    print('📍 Format ID: $formatId');
    print('📍 Domain: $domain');
    print('📍 Route: /new-content/$formatId/$domain/${widget.journalistId}');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    context.push('/new-content/$formatId/$domain/${widget.journalistId}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: _onBack,
        ),
        title: const Text(
          'Nouveau contenu',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Column(
        children: [
          _buildProgressIndicator(),
          Expanded(
            child: _buildCurrentStep(),
          ),
          _buildBottomButton(),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    final totalSteps = _selectedFormat?.id == 'publications' ? 3 : 2;
    final currentStep = _currentStep + 1;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: Colors.black,
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withOpacity(0.1),
          ),
        ),
      ),
      child: Row(
        children: List.generate(totalSteps, (index) {
          final stepNumber = index + 1;
          final isCompleted = stepNumber < currentStep;
          final isCurrent = stepNumber == currentStep;
          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 4.0,
                    decoration: BoxDecoration(
                      color: isCompleted || isCurrent
                          ? Colors.white
                          : Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(2.0),
                    ),
                  ),
                ),
                if (index < totalSteps - 1) const SizedBox(width: 8.0),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildCurrentStep() {
    if (_currentStep == 0) {
      return _buildFormatSelection();
    } else if (_currentStep == 1) {
      if (_selectedFormat?.id == 'publications') {
        return _buildSubTypeSelection();
      } else {
        return _buildDomainSelection();
      }
    } else {
      return _buildDomainSelection();
    }
  }

  Widget _buildFormatSelection() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Format',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8.0),
          Text(
            'Choisissez le format de votre publication',
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 24.0),
          ..._formats.map((format) => Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: _FormatCard(
                  format: format,
                  isSelected: _selectedFormat?.id == format.id,
                  onTap: () => _onFormatSelected(format),
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildSubTypeSelection() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Type de publication',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8.0),
          Text(
            'Choisissez le type de contenu que vous souhaitez créer',
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 24.0),
          ..._subTypes.map((subType) => Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: _SubTypeCard(
                  subType: subType,
                  isSelected: _selectedSubType?.id == subType.id,
                  onTap: () => _onSubTypeSelected(subType),
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildDomainSelection() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Colors.black,
            border: Border(
              bottom: BorderSide(
                color: Colors.white.withOpacity(0.1),
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Domaine',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8.0),
              Text(
                'Choisissez le domaine de votre publication',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 16.0),
              TextField(
                controller: _searchController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Rechercher un domaine...',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
                  prefixIcon:
                      Icon(Icons.search, color: Colors.white.withOpacity(0.4)),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.03),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: BorderSide(
                      color: Colors.white.withOpacity(0.1),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: BorderSide(
                      color: Colors.white.withOpacity(0.1),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: const BorderSide(color: Colors.white, width: 2),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _filteredDomains.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32.0),
                    child: Text(
                      'Aucun domaine trouvé',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 14,
                      ),
                    ),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16.0),
                  children: _filteredDomains
                      .map((domain) => Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: _DomainCard(
                              domain: domain,
                              isSelected: _selectedDomain?.id == domain.id,
                              onTap: () => _onDomainSelected(domain),
                            ),
                          ))
                      .toList(),
                ),
        ),
      ],
    );
  }

  Widget _buildBottomButton() {
    final bool canContinue;
    if (_currentStep == 0) {
      canContinue = _selectedFormat != null;
    } else if (_currentStep == 1) {
      if (_selectedFormat?.id == 'publications') {
        canContinue = _selectedSubType != null;
      } else {
        canContinue = _selectedDomain != null;
      }
    } else {
      canContinue = _selectedDomain != null;
    }
    final bool isFinalStep = _currentStep == 2 ||
        (_currentStep == 1 && _selectedFormat?.id != 'publications');
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.black,
          border: Border(
            top: BorderSide(
              color: Colors.white.withOpacity(0.1),
            ),
          ),
        ),
        child: SizedBox(
          height: 50,
          width: double.infinity,
          child: ElevatedButton(
            onPressed: canContinue
                ? () {
                    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
                    print('🔘 CONTINUER BUTTON PRESSED');
                    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
                    print('📍 Current step: $_currentStep');
                    print('📍 Selected format: ${_selectedFormat?.id}');
                    print('📍 Selected subtype: ${_selectedSubType?.id}');
                    print('📍 Selected domain: ${_selectedDomain?.id}');
                    print('📍 Can continue: $canContinue');
                    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
                    _onContinue();
                  }
                : () {
                    print('❌ Button disabled - canContinue: $canContinue');
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: canContinue ? Colors.white : Colors.grey[800],
              foregroundColor: canContinue ? Colors.black : Colors.grey[500],
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
              disabledBackgroundColor: Colors.grey[800],
              disabledForegroundColor: Colors.grey[500],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isFinalStep ? Icons.check : Icons.arrow_forward,
                  size: 20,
                  color: canContinue ? Colors.black : Colors.grey[500],
                ),
                const SizedBox(width: 8.0),
                const Text(
                  'Continuer',
                  style: TextStyle(
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
}

class _FormatCard extends StatelessWidget {
  final PublicationFormat format;
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
      borderRadius: BorderRadius.circular(16.0),
      child: Container(
        padding: const EdgeInsets.all(20.0),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(
            color: isSelected ? Colors.white : Colors.white.withOpacity(0.1),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.white.withOpacity(0.08),
                    blurRadius: 8.0,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white
                    : Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16.0),
              ),
              child: Icon(
                format.icon,
                color: isSelected ? Colors.black : Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 16.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    format.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4.0),
                  Text(
                    format.description,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: Colors.white, size: 24)
            else
              Icon(Icons.circle_outlined,
                  color: Colors.white.withOpacity(0.2), size: 24),
          ],
        ),
      ),
    );
  }
}

class _SubTypeCard extends StatelessWidget {
  final ContentSubType subType;
  final bool isSelected;
  final VoidCallback onTap;
  const _SubTypeCard({
    required this.subType,
    required this.isSelected,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16.0),
      child: Container(
        padding: const EdgeInsets.all(20.0),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(
            color: isSelected ? Colors.white : Colors.white.withOpacity(0.1),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.white.withOpacity(0.08),
                    blurRadius: 8.0,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white
                    : Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16.0),
              ),
              child: Icon(
                subType.icon,
                color: isSelected ? Colors.black : Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 16.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    subType.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4.0),
                  Text(
                    subType.description,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: Colors.white, size: 24)
            else
              Icon(Icons.circle_outlined,
                  color: Colors.white.withOpacity(0.2), size: 24),
          ],
        ),
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
      borderRadius: BorderRadius.circular(16.0),
      child: Container(
        padding: const EdgeInsets.all(20.0),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(
            color: isSelected ? Colors.white : Colors.white.withOpacity(0.1),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.white.withOpacity(0.08),
                    blurRadius: 8.0,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white
                    : Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16.0),
              ),
              child: Icon(
                domain.icon,
                color: isSelected ? Colors.black : Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 16.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    domain.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4.0),
                  Text(
                    domain.description,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: Colors.white, size: 24)
            else
              Icon(Icons.circle_outlined,
                  color: Colors.white.withOpacity(0.2), size: 24),
          ],
        ),
      ),
    );
  }
}
