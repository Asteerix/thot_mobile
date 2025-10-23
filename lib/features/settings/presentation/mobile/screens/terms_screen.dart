import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
class TermsScreen extends StatefulWidget {
  const TermsScreen({super.key});
  @override
  State<TermsScreen> createState() => _TermsScreenState();
}
class _TermsScreenState extends State<TermsScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _hasScrolled = false;
  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.offset > 50 && !_hasScrolled) {
        setState(() => _hasScrolled = true);
      } else if (_scrollController.offset <= 50 && _hasScrolled) {
        setState(() => _hasScrolled = false);
      }
    });
  }
  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
  Widget _buildSection(String title, String content, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
        ),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.white.withOpacity(0.9), size: 20),
          ),
          title: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          iconColor: Colors.white.withOpacity(0.7),
          collapsedIconColor: Colors.white.withOpacity(0.7),
          children: [
            Text(
              content,
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 14,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: 60,
              decoration: BoxDecoration(
                color: Colors.black,
                border: Border(
                  bottom: BorderSide(
                    color: _hasScrolled
                        ? Colors.white.withOpacity(0.1)
                        : Colors.transparent,
                  ),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        context.pop();
                      },
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                    ),
                    const Expanded(
                      child: Text(
                        'Conditions d\'utilisation',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.gavel,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Conditions d\'utilisation',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Dernière mise à jour: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.5),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.white.withOpacity(0.9),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              'En utilisant Thot, vous acceptez ces conditions',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    _buildSection(
                      '1. Acceptation des conditions',
                      'En accédant et en utilisant l\'application Thot, vous acceptez d\'être lié par ces conditions d\'utilisation. Si vous n\'acceptez pas ces conditions, veuillez ne pas utiliser notre service.',
                      Icons.check_circle_outline,
                    ),
                    _buildSection(
                      '2. Description du service',
                      'Thot est une plateforme de partage d\'informations vérifiées. Nous nous engageons à fournir un contenu de qualité, vérifié par des journalistes professionnels.',
                      Icons.description_outlined,
                    ),
                    _buildSection(
                      '3. Compte utilisateur',
                      'Vous êtes responsable de maintenir la confidentialité de votre compte et mot de passe. Vous acceptez la responsabilité de toutes les activités qui se produisent sous votre compte.',
                      Icons.person_outline,
                    ),
                    _buildSection(
                      '4. Contenu utilisateur',
                      'En publiant du contenu sur Thot, vous nous accordez une licence mondiale, non exclusive, libre de redevances pour utiliser, reproduire et distribuer ce contenu.',
                      Icons.article_outlined,
                    ),
                    _buildSection(
                      '5. Comportement interdit',
                      'Il est interdit de publier du contenu illégal, diffamatoire, harcelant ou violant les droits d\'autrui. Nous nous réservons le droit de supprimer tout contenu inapproprié.',
                      Icons.block_outlined,
                    ),
                    _buildSection(
                      '6. Propriété intellectuelle',
                      'Tout le contenu de Thot, y compris les textes, graphiques, logos et logiciels, est la propriété de Thot ou de ses concédants de licence.',
                      Icons.copyright_outlined,
                    ),
                    _buildSection(
                      '7. Limitation de responsabilité',
                      'Thot ne sera pas responsable des dommages indirects, accidentels, spéciaux ou consécutifs résultant de l\'utilisation ou de l\'impossibilité d\'utiliser le service.',
                      Icons.warning_outlined,
                    ),
                    _buildSection(
                      '8. Modifications',
                      'Nous nous réservons le droit de modifier ces conditions à tout moment. Les modifications entreront en vigueur dès leur publication sur l\'application.',
                      Icons.edit_outlined,
                    ),
                    _buildSection(
                      '9. Contact',
                      'Pour toute question concernant ces conditions, contactez-nous à legal@thot.app',
                      Icons.mail_outline,
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}