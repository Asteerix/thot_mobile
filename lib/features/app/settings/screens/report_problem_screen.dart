import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:thot/core/di/service_locator.dart';
import 'package:thot/core/services/logging/logger_service.dart';

class ReportProblemScreen extends StatefulWidget {
  const ReportProblemScreen({super.key});
  @override
  State<ReportProblemScreen> createState() => _ReportProblemScreenState();
}

class _ReportProblemScreenState extends State<ReportProblemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _messageController = TextEditingController();
  final _logger = LoggerService.instance;
  bool _isSubmitting = false;
  String? _selectedCategory;
  String? _selectedSubCategory;
  int _selectedPriority = 1;
  final List<File> _attachedImages = [];
  final ImagePicker _picker = ImagePicker();
  final Map<String, IconData> _categoryIcons = {
    'sécurité': Icons.shield,
    'fonctionnalité': Icons.build,
    'performance': Icons.speed,
    'interface': Icons.brush,
    'autre': Icons.more_horiz,
  };
  final List<Map<String, dynamic>> _priorities = [
    {'label': 'Faible', 'icon': Icons.flag},
    {'label': 'Moyenne', 'icon': Icons.flag},
    {'label': 'Élevée', 'icon': Icons.flag},
  ];
  bool get _canSubmit =>
      _selectedCategory != null &&
      _selectedSubCategory != null &&
      _messageController.text.trim().length >= 10;
  final Map<String, List<String>> _problemCategories = {
    'sécurité': [
      'Activité suspecte',
      'Problème de confidentialité',
      'Harcèlement ou abus',
      'Usurpation d\'identité',
      'Autre problème de sécurité',
    ],
    'fonctionnalité': [
      'L\'application se ferme de manière inattendue',
      'Problème de chargement des contenus',
      'Problème de lecture vidéo/audio',
      'Fonctionnalité qui ne fonctionne pas',
      'Autre problème technique',
    ],
    'performance': [
      'Application lente',
      'Temps de chargement long',
      'Consommation mémoire élevée',
      'Batterie qui se vide rapidement',
      'Autre problème de performance',
    ],
    'interface': [
      'Problème d\'affichage',
      'Élément manquant',
      'Mise en page cassée',
      'Problème de responsive',
      'Autre problème d\'interface',
    ],
    'autre': [
      'Suggestion d\'amélioration',
      'Question générale',
      'Problème non listé',
      'Feedback général',
    ],
  };
  @override
  void initState() {
    super.initState();
    _messageController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      if (image != null) {
        setState(() {
          if (_attachedImages.length < 3) {
            _attachedImages.add(File(image.path));
          } else {
            _showSnackBar('Maximum 3 images autorisées', isError: true);
          }
        });
      }
    } catch (e) {
      _logger.error('Error picking image', e);
      _showSnackBar('Erreur lors de la sélection de l\'image', isError: true);
    }
  }

  void _removeImage(int index) {
    HapticFeedback.lightImpact();
    setState(() {
      _attachedImages.removeAt(index);
    });
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError
            ? Colors.red.withOpacity(0.9)
            : Colors.white.withOpacity(0.1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_canSubmit) {
      _showSnackBar('Veuillez remplir tous les champs requis', isError: true);
      return;
    }
    setState(() => _isSubmitting = true);
    HapticFeedback.mediumImpact();
    try {
      final adminRepository = ServiceLocator.instance.adminRepository;
      await adminRepository.submitProblemReport(
        category: _selectedCategory!,
        subCategory: _selectedSubCategory!,
        message: _messageController.text.trim(),
      );
      if (mounted) {
        _showSnackBar('Votre signalement a été envoyé avec succès');
        HapticFeedback.lightImpact();
        context.pop();
      }
    } catch (e) {
      _logger.error('Error submitting report', e);
      if (mounted) {
        _showSnackBar('Erreur: ${e.toString()}', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            HapticFeedback.selectionClick();
            context.pop();
          },
        ),
        title: const Text(
          'Signaler un problème',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              _buildInfoCard(),
              const SizedBox(height: 32),
              _buildCategorySelector(),
              if (_selectedCategory != null) ...[
                const SizedBox(height: 24),
                _buildSubCategoryChips(),
              ],
              if (_selectedSubCategory != null) ...[
                const SizedBox(height: 32),
                _buildPrioritySelector(),
                const SizedBox(height: 32),
                _buildMessageField(),
                const SizedBox(height: 32),
                _buildAttachments(),
              ],
              const SizedBox(height: 40),
              _buildSubmitButton(),
              const SizedBox(height: 16),
              _buildCancelButton(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.info,
              color: Colors.white.withOpacity(0.9),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Information',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Votre signalement sera traité dans les plus brefs délais. Nous vous contacterons si nous avons besoin d\'informations supplémentaires.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Type de problème',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 2.5,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: _problemCategories.keys.length,
          itemBuilder: (context, index) {
            final category = _problemCategories.keys.elementAt(index);
            final isSelected = _selectedCategory == category;
            return InkWell(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() {
                  _selectedCategory = category;
                  _selectedSubCategory = null;
                });
              },
              borderRadius: BorderRadius.circular(12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withOpacity(0.15)
                      : Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? Colors.white
                        : Colors.white.withOpacity(0.1),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _categoryIcons[category],
                      color: Colors.white.withOpacity(isSelected ? 1 : 0.6),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        category[0].toUpperCase() + category.substring(1),
                        style: TextStyle(
                          color: Colors.white.withOpacity(isSelected ? 1 : 0.6),
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSubCategoryChips() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Problème spécifique',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _problemCategories[_selectedCategory]!.map((subCategory) {
            final isSelected = _selectedSubCategory == subCategory;
            return InkWell(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() {
                  _selectedSubCategory = isSelected ? null : subCategory;
                });
              },
              borderRadius: BorderRadius.circular(20),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withOpacity(0.2)
                      : Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? Colors.white.withOpacity(0.5)
                        : Colors.white.withOpacity(0.1),
                  ),
                ),
                child: Text(
                  subCategory,
                  style: TextStyle(
                    color: Colors.white.withOpacity(isSelected ? 1 : 0.7),
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                    fontSize: 14,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPrioritySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Priorité',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: List.generate(_priorities.length, (index) {
            final priority = _priorities[index];
            final isSelected = _selectedPriority == index;
            final priorityColor = index == 0
                ? Colors.green
                : (index == 1 ? Colors.orange : Colors.red);
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: index < _priorities.length - 1 ? 8 : 0,
                ),
                child: InkWell(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() {
                      _selectedPriority = index;
                    });
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? priorityColor.withOpacity(0.2)
                          : Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? priorityColor.withOpacity(0.8)
                            : Colors.white.withOpacity(0.1),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          priority['icon'],
                          color: isSelected
                              ? priorityColor
                              : Colors.white.withOpacity(0.6),
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          priority['label'],
                          style: TextStyle(
                            color: isSelected
                                ? priorityColor
                                : Colors.white.withOpacity(0.6),
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildMessageField() {
    final charCount = _messageController.text.trim().length;
    final isValid = charCount >= 10;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Description du problème',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Décrivez votre problème en détail (minimum 10 caractères)',
          style: TextStyle(
            color: Colors.white.withOpacity(0.5),
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _messageController,
          maxLines: 8,
          maxLength: 1000,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Expliquez votre problème ici...',
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
            filled: true,
            fillColor: Colors.white.withOpacity(0.05),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.white, width: 1),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.red.withOpacity(0.8)),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.red.withOpacity(0.8)),
            ),
            errorStyle: TextStyle(color: Colors.red.withOpacity(0.9)),
            counterText: '',
            contentPadding: const EdgeInsets.all(16),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Veuillez décrire votre problème';
            }
            if (value.trim().length < 10) {
              return 'La description doit contenir au moins 10 caractères';
            }
            return null;
          },
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '$charCount/1000 caractères',
              style: TextStyle(
                color: isValid
                    ? Colors.green.withOpacity(0.8)
                    : (charCount > 0
                        ? Colors.orange.withOpacity(0.8)
                        : Colors.white.withOpacity(0.5)),
                fontSize: 12,
              ),
            ),
            if (charCount > 0 && charCount < 10)
              Text(
                'Encore ${10 - charCount} caractères',
                style: TextStyle(
                  color: Colors.red.withOpacity(0.9),
                  fontSize: 12,
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildAttachments() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Pièces jointes',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '${_attachedImages.length}/3',
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 14,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Ajoutez des captures d\'écran pour mieux illustrer le problème',
          style: TextStyle(
            color: Colors.white.withOpacity(0.5),
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 100,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              ..._attachedImages.asMap().entries.map((entry) {
                final index = entry.key;
                final image = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Stack(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2),
                          ),
                          image: DecorationImage(
                            image: FileImage(image),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: InkWell(
                          onTap: () => _removeImage(index),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
              if (_attachedImages.length < 3)
                InkWell(
                  onTap: _pickImage,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                        width: 2,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_photo_alternate,
                          color: Colors.white.withOpacity(0.7),
                          size: 32,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Ajouter',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: (_isSubmitting || !_canSubmit) ? null : _submitReport,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          disabledBackgroundColor: Colors.white.withOpacity(0.3),
          disabledForegroundColor: Colors.black.withOpacity(0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        icon: _isSubmitting
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                ),
              )
            : Icon(Icons.send),
        label: Text(
          _isSubmitting ? 'Envoi en cours...' : 'Envoyer le signalement',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildCancelButton() {
    return Center(
      child: TextButton(
        onPressed: () {
          HapticFeedback.selectionClick();
          context.pop();
        },
        child: Text(
          'Annuler',
          style: TextStyle(
            color: Colors.white.withOpacity(0.6),
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}
