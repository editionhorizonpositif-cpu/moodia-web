// lib/pages/terms_page.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class TermsPage extends StatelessWidget {
  const TermsPage({super.key});

  static const Color primaryColor = Color(0xFF7DBBC3);
  static const Color secondaryColor = Color(0xFF4A90E2);
  static const Color textPrimary = Color(0xFF2C3E50);
  static const Color textSecondary = Color(0xFF5D6D7E);
  static const Color surfaceLight = Color(0xFFF8F9FA);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: surfaceLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(Icons.arrow_back, color: textPrimary, size: 20),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Conditions d\'utilisation',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [surfaceLight, Colors.white],
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _buildHeader(),
            const SizedBox(height: 24),

            // Interprétation et définitions
            _buildSection(
              title: 'Interprétation et définitions',
              icon: Icons.gavel,
              child: _buildDefinitions(),
            ),

            // Reconnaissance
            _buildSection(
              title: 'Reconnaissance',
              icon: Icons.check_circle_outline,
              child: const Text(
                'Ces conditions régissent votre utilisation de Moodia. En accédant à l’application, vous acceptez pleinement ces conditions. '
                'Si vous n’êtes pas d’accord, vous ne devez pas utiliser l’application.',
                style: TextStyle(
                  fontSize: 15,
                  color: textSecondary,
                  height: 1.5,
                ),
              ),
            ),

            // Liens vers d'autres sites
            _buildSection(
              title: 'Liens vers d’autres sites',
              icon: Icons.link,
              child: const Text(
                'Notre Service peut contenir des liens vers des sites tiers. Nous n’avons aucun contrôle sur leur contenu ou leurs pratiques, '
                'et déclinons toute responsabilité en cas de dommages liés à leur utilisation.',
                style: TextStyle(
                  fontSize: 15,
                  color: textSecondary,
                  height: 1.5,
                ),
              ),
            ),

            // Liens depuis les réseaux sociaux
            _buildSection(
              title: 'Liens depuis les réseaux sociaux',
              icon: Icons.share,
              child: const Text(
                'Nous pouvons afficher du contenu provenant de réseaux sociaux. Ces services tiers sont indépendants de Moodia ; '
                'leur utilisation est régie par leurs propres conditions.',
                style: TextStyle(
                  fontSize: 15,
                  color: textSecondary,
                  height: 1.5,
                ),
              ),
            ),

            // Résiliation
            _buildSection(
              title: 'Résiliation',
              icon: Icons.block,
              child: const Text(
                'Nous pouvons suspendre ou résilier votre accès à tout moment, sans préavis, en cas de non-respect des présentes conditions.',
                style: TextStyle(
                  fontSize: 15,
                  color: textSecondary,
                  height: 1.5,
                ),
              ),
            ),

            // Limitation de responsabilité
            _buildSection(
              title: 'Limitation de responsabilité',
              icon: Icons.warning_amber,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Dans toute la mesure permise par la loi, Moodia ne pourra être tenu responsable des dommages indirects, '
                    'perte de données, ou préjudices liés à l’utilisation de l’application. Notre responsabilité totale, '
                    'pour quelque réclamation que ce soit, est limitée au montant que vous avez payé pour utiliser le Service '
                    '(ou 100 USD si vous n’avez rien payé).',
                    style: TextStyle(
                      fontSize: 15,
                      color: textSecondary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildBulletPoint(
                    'L’application est fournie à des fins de bien-être et d’information uniquement.',
                  ),
                  _buildBulletPoint(
                    'Elle ne constitue en aucun cas un avis médical ou un substitut à un professionnel de santé.',
                  ),
                  _buildBulletPoint(
                    'Consultez toujours un professionnel qualifié pour toute question relative à votre santé.',
                  ),
                ],
              ),
            ),

            // Clause "AS IS"
            _buildSection(
              title: 'Exclusion de garanties',
              icon: Icons.info_outline,
              child: const Text(
                'Le Service est fourni "EN L’ÉTAT" et "SELON DISPONIBILITÉ", sans garantie d’aucune sorte, explicite ou implicite. '
                'Nous ne garantissons pas que le Service fonctionnera sans interruption, sans erreur, ou qu’il répondra à vos attentes.',
                style: TextStyle(
                  fontSize: 15,
                  color: textSecondary,
                  height: 1.5,
                ),
              ),
            ),

            // Droit applicable
            _buildSection(
              title: 'Droit applicable',
              icon: Icons.gavel,
              child: const Text(
                'Les présentes conditions sont régies par le droit français, sans égard aux conflits de règles de droit. '
                'Tout litige relatif à votre utilisation du Service sera soumis aux tribunaux compétents de Paris.',
                style: TextStyle(
                  fontSize: 15,
                  color: textSecondary,
                  height: 1.5,
                ),
              ),
            ),

            // Résolution des litiges
            _buildSection(
              title: 'Résolution des litiges',
              icon: Icons.handshake,
              child: const Text(
                'En cas de litige, nous vous invitons d’abord à nous contacter pour tenter une résolution informelle.',
                style: TextStyle(
                  fontSize: 15,
                  color: textSecondary,
                  height: 1.5,
                ),
              ),
            ),

            // Utilisateurs dans l'UE
            _buildSection(
              title: 'Utilisateurs dans l’Union européenne',
              icon: Icons.flag,
              child: const Text(
                'Si vous êtes un consommateur résidant dans l’UE, vous bénéficiez des dispositions impératives de la loi de votre pays.',
                style: TextStyle(
                  fontSize: 15,
                  color: textSecondary,
                  height: 1.5,
                ),
              ),
            ),

            // Divisibilité et renonciation
            _buildSection(
              title: 'Divisibilité et renonciation',
              icon: Icons.segment,
              child: const Text(
                'Si une disposition de ces conditions est jugée inapplicable, les autres restent en vigueur. '
                'Le fait de ne pas exiger l’application d’une disposition ne constitue pas une renonciation.',
                style: TextStyle(
                  fontSize: 15,
                  color: textSecondary,
                  height: 1.5,
                ),
              ),
            ),

            // Modifications des conditions
            _buildSection(
              title: 'Modifications des conditions',
              icon: Icons.update,
              child: const Text(
                'Nous pouvons modifier ces conditions à tout moment. Les modifications substantielles vous seront notifiées '
                '(par email ou via l’application) au moins 30 jours avant leur entrée en vigueur. '
                'Votre utilisation continue du Service après ces modifications vaut acceptation.',
                style: TextStyle(
                  fontSize: 15,
                  color: textSecondary,
                  height: 1.5,
                ),
              ),
            ),

            // Contact
            _buildSection(
              title: 'Nous contacter',
              icon: Icons.contact_mail,
              child: _buildContactSection(),
            ),

            const SizedBox(height: 30),
            Center(
              child: Text(
                'Conditions générées avec TermsFeed et adaptées à Moodia',
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            primaryColor.withOpacity(0.1),
            secondaryColor.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: primaryColor.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.description, color: primaryColor, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  'Conditions générales d’utilisation',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Ces conditions régissent votre utilisation de l’application Moodia. Veuillez les lire attentivement avant d’utiliser nos services.',
            style: TextStyle(fontSize: 15, color: textSecondary, height: 1.5),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.7),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.update, size: 16, color: primaryColor),
                const SizedBox(width: 6),
                Text(
                  'Dernière mise à jour : 6 mars 2026',
                  style: TextStyle(
                    fontSize: 13,
                    color: textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: primaryColor, size: 22),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildDefinitions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDefinitionItem(
          'Application',
          'Le logiciel Moodia, fourni par la Société.',
        ),
        _buildDefinitionItem(
          'Boutique d’applications',
          'Le service de distribution (Apple App Store ou Google Play) depuis lequel l’Application a été téléchargée.',
        ),
        _buildDefinitionItem(
          'Affilié',
          'Entité contrôlant, contrôlée par ou sous contrôle commun avec la Société.',
        ),
        _buildDefinitionItem('Pays', 'France.'),
        _buildDefinitionItem('Société', 'Moodia (ci-après "Nous", "Notre").'),
        _buildDefinitionItem(
          'Appareil',
          'Tout appareil permettant d’accéder au Service (ordinateur, mobile, tablette).',
        ),
        _buildDefinitionItem('Service', 'L’Application.'),
        _buildDefinitionItem(
          'Conditions',
          'Les présentes conditions générales d’utilisation.',
        ),
        _buildDefinitionItem(
          'Réseau social tiers',
          'Tout service ou contenu fourni par un tiers et accessible via le Service.',
        ),
        _buildDefinitionItem(
          'Vous',
          'La personne accédant ou utilisant le Service.',
        ),
      ],
    );
  }

  Widget _buildDefinitionItem(String term, String definition) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(
            fontSize: 15,
            color: textSecondary,
            height: 1.4,
          ),
          children: [
            TextSpan(
              text: '$term : ',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
            ),
            TextSpan(text: definition),
          ],
        ),
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, left: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('• ', style: TextStyle(fontSize: 16, color: primaryColor)),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 15,
                color: textSecondary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactSection() {
    return Column(
      children: [
        GestureDetector(
          onTap: () => _launchEmail('contact@moodia.xyz'),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.email, color: primaryColor, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'contact@moodia.xyz',
                    style: TextStyle(
                      fontSize: 16,
                      color: primaryColor,
                      fontWeight: FontWeight.w500,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => _launchUrl('https://app.moodia.xyz'),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: secondaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.language, color: secondaryColor, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'https://app.moodia.xyz',
                    style: TextStyle(
                      fontSize: 16,
                      color: secondaryColor,
                      fontWeight: FontWeight.w500,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _launchEmail(String email) async {
    final uri = Uri.parse('mailto:$email');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
