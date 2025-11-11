import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'package:thot/features/authentication/application/providers/auth_provider.dart';
import 'package:thot/core/infrastructure/dependency_injection.dart';
import 'package:thot/core/utils/safe_navigation.dart';

final _logger = Logger();

class EditJournalistCardScreen extends StatefulWidget {
  const EditJournalistCardScreen({super.key});

  @override
  State<EditJournalistCardScreen> createState() => _EditJournalistCardScreenState();
}

class _EditJournalistCardScreenState extends State<EditJournalistCardScreen> {
  final _formKey = GlobalKey<FormState>();
  final _cardNumberController = TextEditingController();
  bool _isLoading = false;
  bool _isSaving = false;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentCard();
  }

  @override
  void dispose() {
    _cardNumberController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentCard() async {
    setState(() => _isLoading = true);
    try {
      final authProvider = context.read<AuthProvider>();
      final user = authProvider.userProfile;
      if (user?.pressCard != null && user!.pressCard!.isNotEmpty) {
        _cardNumberController.text = user.pressCard!;
      }
    } catch (e) {
      _logger.e('Error loading journalist card', error: e);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveCard() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSaving = true);
    try {
      final apiService = ServiceLocator.instance.apiService;
      final response = await apiService.put(
        '/api/users/journalist-card',
        data: {'pressCard': _cardNumberController.text.trim()},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final authProvider = context.read<AuthProvider>();
        await authProvider.refreshProfile();

        if (mounted) {
          SafeNavigation.showSnackBar(
            context,
            const SnackBar(
              content: Text('Carte de presse enregistrée avec succès', style: TextStyle(color: Colors.white)),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw Exception('Erreur lors de la sauvegarde: ${response.statusCode}');
      }
    } catch (e) {
      _logger.e('Error saving journalist card', error: e);
      if (mounted) {
        SafeNavigation.showSnackBar(
          context,
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

  Future<void> _deleteCard() async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black87,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.black,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.red.withOpacity(0.1),
                  border: Border.all(color: Colors.red.withOpacity(0.5), width: 2),
                ),
                child: const Icon(Icons.warning, color: Colors.red, size: 28),
              ),
              const SizedBox(height: 24),
              const Text(
                'Supprimer la carte',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Êtes-vous sûr de vouloir supprimer votre numéro de carte de presse ? Vous ne serez plus vérifié.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(color: Colors.white.withOpacity(0.3)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Annuler',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(ctx).pop(true),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Supprimer',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed == true) {
      setState(() => _isDeleting = true);
      try {
        final apiService = ServiceLocator.instance.apiService;
        final response = await apiService.delete('/api/users/journalist-card');

        if (response.statusCode == 200 || response.statusCode == 204) {
          final authProvider = context.read<AuthProvider>();
          await authProvider.refreshProfile();

          if (mounted) {
            SafeNavigation.showSnackBar(
              context,
              const SnackBar(
                content: Text('Carte de presse supprimée', style: TextStyle(color: Colors.white)),
                backgroundColor: Colors.green,
              ),
            );
            _cardNumberController.clear();
          }
        } else {
          throw Exception('Erreur lors de la suppression: ${response.statusCode}');
        }
      } catch (e) {
        _logger.e('Error deleting journalist card', error: e);
        if (mounted) {
          SafeNavigation.showSnackBar(
            context,
            SnackBar(
              content: Text('Erreur: ${e.toString()}', style: const TextStyle(color: Colors.white)),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isDeleting = false);
        }
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
                      child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Text(
                      'Carte de presse',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'NUMÉRO DE CARTE',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.5),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _cardNumberController,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                decoration: InputDecoration(
                                  hintText: 'Ex: 123456789',
                                  hintStyle: TextStyle(
                                    color: Colors.white.withOpacity(0.3),
                                  ),
                                  filled: true,
                                  fillColor: Colors.white.withOpacity(0.05),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: Colors.white.withOpacity(0.3),
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: Colors.white.withOpacity(0.3),
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                  ),
                                  errorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: Colors.red,
                                    ),
                                  ),
                                  focusedErrorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: Colors.red,
                                      width: 2,
                                    ),
                                  ),
                                  prefixIcon: const Icon(
                                    Icons.badge,
                                    color: Colors.white,
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Veuillez entrer un numéro de carte';
                                  }
                                  if (value.length < 4) {
                                    return 'Le numéro doit contenir au moins 4 chiffres';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 32),
                              _buildActionButtons(),
                              const SizedBox(height: 32),
                              _buildInfoSection(),
                            ],
                          ),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    final hasCard = _cardNumberController.text.isNotEmpty;

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isSaving ? null : _saveCard,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                    ),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.save, size: 20),
                      SizedBox(width: 12),
                      Text(
                        'Enregistrer',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
          ),
        ),
        if (hasCard) ...[
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _isDeleting ? null : _deleteCard,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isDeleting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                      ),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.delete, size: 20),
                        SizedBox(width: 12),
                        Text(
                          'Supprimer',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildInfoSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info, color: Colors.green[300], size: 20),
              const SizedBox(width: 12),
              const Text(
                'Informations importantes',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoItem('Entrez le numéro de votre carte de presse professionnelle.'),
          const SizedBox(height: 8),
          _buildInfoItem('Le numéro doit contenir au moins 4 chiffres.'),
          const SizedBox(height: 8),
          _buildInfoItem('Une fois validé, vous aurez le badge vérifié vert.'),
          const SizedBox(height: 8),
          _buildInfoItem('Seuls les chiffres sont acceptés (0-9).'),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 6,
          height: 6,
          margin: const EdgeInsets.only(top: 7),
          decoration: BoxDecoration(
            color: Colors.green[300],
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}
