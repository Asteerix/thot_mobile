import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
class PrivacyPolicyScreen extends StatefulWidget {
  const PrivacyPolicyScreen({super.key});
  @override
  State<PrivacyPolicyScreen> createState() => _PrivacyPolicyScreenState();
}
class _PrivacyPolicyScreenState extends State<PrivacyPolicyScreen> {
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
  Widget _buildQuickCard(String title, String subtitle, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white.withOpacity(0.9), size: 28),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
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
                        'Politique de confidentialité',
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
                              Icons.lock_outline,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Votre vie privée compte',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Transparence et protection de vos données',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.5),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.3,
                      children: [
                        _buildQuickCard(
                          'RGPD',
                          'Conforme',
                          Icons.verified_user,
                        ),
                        _buildQuickCard(
                          'Données',
                          'Chiffrées',
                          Icons.lock,
                        ),
                        _buildQuickCard(
                          'Contrôle',
                          'Total',
                          Icons.admin_panel_settings,
                        ),
                        _buildQuickCard(
                          'Transparence',
                          'Garantie',
                          Icons.visibility,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(20),
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
                            Icons.shield_outlined,
                            color: Colors.white.withOpacity(0.9),
                            size: 28,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Vos données vous appartiennent',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Nous ne vendons jamais vos informations',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.6),
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    _buildSection(
                      '1. Données collectées',
                      'Nous collectons uniquement les données nécessaires au fonctionnement du service : informations de compte (email, nom d\'utilisateur), contenu que vous publiez, préférences et paramètres.',
                      Icons.folder_outlined,
                    ),
                    _buildSection(
                      '2. Utilisation des données',
                      'Vos données servent à personnaliser votre expérience, afficher du contenu pertinent, permettre les interactions sociales et assurer la sécurité de la plateforme.',
                      Icons.analytics_outlined,
                    ),
                    _buildSection(
                      '3. Protection et sécurité',
                      'Toutes les données sensibles sont chiffrées. Nous utilisons les dernières technologies de sécurité et effectuons des audits réguliers pour protéger vos informations.',
                      Icons.security,
                    ),
                    _buildSection(
                      '4. Vos droits RGPD',
                      'Vous avez le droit d\'accéder, modifier, exporter ou supprimer vos données à tout moment. Vous pouvez aussi vous opposer à certains traitements.',
                      Icons.gavel,
                    ),
                    _buildSection(
                      '5. Cookies',
                      'Nous utilisons des cookies essentiels pour le fonctionnement du site. Les cookies analytiques sont optionnels et vous pouvez les refuser.',
                      Icons.cookie_outlined,
                    ),
                    _buildSection(
                      '6. Partage des données',
                      'Nous ne partageons vos données qu\'avec votre consentement ou pour respecter des obligations légales. Jamais de vente à des tiers.',
                      Icons.share_outlined,
                    ),
                    _buildSection(
                      '7. Conservation',
                      'Les données sont conservées tant que votre compte est actif. Après suppression, elles sont effacées sous 30 jours, sauf obligation légale.',
                      Icons.schedule,
                    ),
                    _buildSection(
                      '8. Mineurs',
                      'Thot n\'est pas destiné aux moins de 13 ans. Nous ne collectons pas sciemment de données d\'enfants.',
                      Icons.child_care,
                    ),
                    _buildSection(
                      '9. Contact DPO',
                      'Pour toute question sur vos données : dpo@thot.app\nDélégué à la protection des données disponible 24/7',
                      Icons.support_agent,
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