import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class PrivacyPage extends StatelessWidget {
  const PrivacyPage({super.key});

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
          'Confidentialité',
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
            _buildSection(
              title: 'Interprétation et définitions',
              icon: Icons.gavel,
              child: _buildDefinitions(),
            ),
            _buildSection(
              title: 'Collecte et utilisation de vos données',
              icon: Icons.data_usage,
              child: _buildCollectionSection(),
            ),
            _buildSection(
              title: 'Conservation de vos données',
              icon: Icons.access_time,
              child: _buildRetentionSection(),
            ),
            _buildSection(
              title: 'Transfert de vos données',
              icon: Icons.public,
              child: const Text(
                'Vos données peuvent être transférées et traitées dans des pays où les lois sur la protection des données diffèrent. '
                'Nous mettons en place des garanties appropriées pour tout transfert international.',
                style: TextStyle(
                  fontSize: 15,
                  color: textSecondary,
                  height: 1.5,
                ),
              ),
            ),
            _buildSection(
              title: 'Suppression de vos données',
              icon: Icons.delete_outline,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Vous pouvez demander la suppression de vos données via les paramètres du compte ou par contact.',
                    style: TextStyle(fontSize: 15, color: textSecondary),
                  ),
                  const SizedBox(height: 8),
                  _buildBulletPoint(
                    'Nous pouvons conserver certaines données si requis par la loi.',
                  ),
                ],
              ),
            ),
            _buildSection(
              title: 'Divulgation de vos données',
              icon: Icons.share,
              child: Column(
                children: [
                  _buildBulletPoint(
                    'En cas de fusion ou acquisition, vos données peuvent être transférées.',
                  ),
                  _buildBulletPoint(
                    'Nous pouvons divulguer vos données si la loi l’exige.',
                  ),
                  _buildBulletPoint(
                    'Pour protéger nos droits ou votre sécurité.',
                  ),
                ],
              ),
            ),
            _buildSection(
              title: 'Sécurité de vos données',
              icon: Icons.security,
              child: const Text(
                'Nous utilisons des mesures de sécurité raisonnables, mais aucune transmission Internet n’est totalement sécurisée.',
                style: TextStyle(fontSize: 15, color: textSecondary),
              ),
            ),
            _buildSection(
              title: 'Confidentialité des enfants',
              icon: Icons.child_care,
              child: const Text(
                'Notre Service n’est pas destiné aux moins de 16 ans. Si vous pensez qu’un enfant nous a fourni des données, contactez-nous.',
                style: TextStyle(fontSize: 15, color: textSecondary),
              ),
            ),
            _buildSection(
              title: 'Liens vers d’autres sites',
              icon: Icons.link,
              child: const Text(
                'Nous ne sommes pas responsables des pratiques de confidentialité des sites tiers.',
                style: TextStyle(fontSize: 15, color: textSecondary),
              ),
            ),
            _buildSection(
              title: 'Modifications de cette politique',
              icon: Icons.update,
              child: const Text(
                'Nous vous informerons de tout changement par email ou via notre Service.',
                style: TextStyle(fontSize: 15, color: textSecondary),
              ),
            ),
            _buildSection(
              title: 'Nous contacter',
              icon: Icons.contact_mail,
              child: _buildContactSection(),
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
                child: Icon(Icons.privacy_tip, color: primaryColor, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  'Votre vie privée est notre priorité',
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
            'Cette politique décrit comment nous collectons, utilisons et protégeons vos données personnelles lorsque vous utilisez Moodia.',
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
          'Compte',
          'Compte unique créé pour vous permettre d’accéder à notre Service.',
        ),
        _buildDefinitionItem(
          'Affilié',
          'Entité contrôlant, contrôlée par ou sous contrôle commun avec la Société.',
        ),
        _buildDefinitionItem(
          'Application',
          'Moodia, le programme logiciel fourni par la Société.',
        ),
        _buildDefinitionItem('Société', 'Moodia (ci-après "Nous", "Notre").'),
        _buildDefinitionItem('Pays', 'France.'),
        _buildDefinitionItem(
          'Appareil',
          'Tout appareil pouvant accéder au Service (ordinateur, mobile, tablette).',
        ),
        _buildDefinitionItem(
          'Données personnelles',
          'Toute information se rapportant à une personne identifiée ou identifiable.',
        ),
        _buildDefinitionItem('Service', 'L’Application.'),
        _buildDefinitionItem(
          'Prestataire de services',
          'Toute personne physique ou morale qui traite les données pour le compte de la Société.',
        ),
        _buildDefinitionItem(
          'Données d’utilisation',
          'Données collectées automatiquement (ex : adresse IP, pages visitées, durée).',
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

  Widget _buildCollectionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSubTitle('Types de données collectées'),
        const SizedBox(height: 8),
        _buildBulletPoint(
          'Données personnelles : email, prénom, nom, numéro de téléphone, adresse, code postal, ville.',
        ),
        _buildBulletPoint(
          'Données d’utilisation : adresse IP, type de navigateur, pages visitées, date et heure, identifiants uniques.',
        ),
        const SizedBox(height: 12),
        _buildSubTitle('Utilisation de vos données personnelles'),
        const SizedBox(height: 8),
        _buildBulletPoint('Fournir et maintenir notre Service.'),
        _buildBulletPoint('Gérer votre compte.'),
        _buildBulletPoint('Vous contacter (email, notifications push).'),
        _buildBulletPoint(
          'Vous envoyer des informations promotionnelles (sauf opposition).',
        ),
        _buildBulletPoint('Gérer vos demandes.'),
        _buildBulletPoint(
          'Pour d’autres finalités : analyse, amélioration du Service.',
        ),
        const SizedBox(height: 12),
        _buildSubTitle('Partage de vos données'),
        const SizedBox(height: 8),
        _buildBulletPoint('Avec des prestataires de services.'),
        _buildBulletPoint(
          'Lors de transactions commerciales (fusion, acquisition).',
        ),
        _buildBulletPoint('Avec votre consentement.'),
      ],
    );
  }

  Widget _buildRetentionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Nous conservons vos données uniquement le temps nécessaire :',
          style: TextStyle(fontSize: 15, color: textSecondary),
        ),
        const SizedBox(height: 12),
        _buildBulletPoint(
          'Compte utilisateur : jusqu’à 24 mois après sa fermeture.',
        ),
        _buildBulletPoint(
          'Support client : jusqu’à 24 mois après la clôture du ticket.',
        ),
        _buildBulletPoint(
          'Données d’utilisation : jusqu’à 24 mois pour analyse.',
        ),
        _buildBulletPoint('Journaux serveur : jusqu’à 24 mois pour sécurité.'),
        const SizedBox(height: 8),
        const Text(
          'Nous pouvons conserver certaines données plus longtemps si requis par la loi ou pour des réclamations légales.',
          style: TextStyle(
            fontSize: 14,
            color: textSecondary,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  Widget _buildContactSection() {
    return Column(
      children: [
        GestureDetector(
          onTap: () => _launchEmail('contact.moodia.xyz'),
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
                    'contact.moodia.xyz',
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
          onTap: () => _launchUrl('https://app.moodia.xyz/contact'),
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
                    'https://app.moodia.xyz/contact',
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

  Widget _buildSubTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: textPrimary,
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
