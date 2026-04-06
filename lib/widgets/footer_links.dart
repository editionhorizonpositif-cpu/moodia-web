// lib/widgets/footer_links_compact.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:moodia/routes/route.dart';

class FooterLinksCompact extends StatelessWidget {
  const FooterLinksCompact({super.key});

  bool get _isDesktop => kIsWeb;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = const Color(0xFF7DBBC3);
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth > 900;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        vertical: isLargeScreen ? 32 : 24,
        horizontal: isLargeScreen ? 32 : 16,
      ),
      color: isDark ? Colors.grey[900] : Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Logo
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: isLargeScreen ? 40 : 32,
                height: isLargeScreen ? 40 : 32,
                decoration: BoxDecoration(
                  color: primaryColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Image.asset(
                    'assets/images/moodia_logo.png',
                    height: 50,
                    width: 50,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 50,
                        width: 50,
                        color: Colors.blue,
                        child: const Center(
                          child: Text(
                            'M',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Moodia',
                style: TextStyle(
                  fontSize: isLargeScreen ? 18 : 16,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : const Color(0xFF2C3E50),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Liens légaux
          Wrap(
            alignment: WrapAlignment.center,
            spacing: isLargeScreen ? 20 : 12,
            runSpacing: 8,
            children: [
              _buildTextLink(
                context,
                'Confidentialité',
                AppRoutes.privacy,
                isLargeScreen,
              ),
              _buildTextLink(
                context,
                'Conditions',
                AppRoutes.terms,
                isLargeScreen,
              ),
              _buildTextLink(
                context,
                'Préférences',
                AppRoutes.preferences,
                isLargeScreen,
              ),
              _buildTextLink(context, 'Aide', AppRoutes.help, isLargeScreen),
            ],
          ),

          const SizedBox(height: 20),

          // Icônes sociales
          Wrap(
            alignment: WrapAlignment.center,
            spacing: isLargeScreen ? 16 : 12,
            runSpacing: 12,
            children: [
              _buildSocialIcon(
                FontAwesomeIcons.facebook,
                const Color(0xFF1877F2),
                'Facebook',
                'https://www.facebook.com/moodiaofficiel',
                isLargeScreen,
              ),
              _buildSocialIcon(
                FontAwesomeIcons.whatsapp,
                const Color(0xFF25D366),
                'WhatsApp',
                'https://wa.me/+237640718108',
                isLargeScreen,
              ),
              _buildSocialIcon(
                FontAwesomeIcons.linkedin,
                const Color(0xFF0077B5),
                'LinkedIn',
                'https://linkedin.com/company/moodiaofficiel',
                isLargeScreen,
              ),
              _buildSocialIcon(
                FontAwesomeIcons.pinterest,
                const Color(0xFFE60023),
                'Pinterest',
                'https://fr.pinterest.com/moodiaofficiel',
                isLargeScreen,
              ),
              _buildSocialIcon(
                FontAwesomeIcons.xTwitter,
                const Color(0xFF000000),
                'X',
                'https://twitter.com/Moodia337122',
                isLargeScreen,
              ),
              _buildSocialIcon(
                FontAwesomeIcons.tiktok,
                const Color(0xFF000000),
                'TikTok',
                'https://www.tiktok.com/@moodiaofficiel',
                isLargeScreen,
              ),
              _buildSocialIcon(
                FontAwesomeIcons.youtube,
                const Color(0xFFFF0000),
                'YouTube',
                'https://www.youtube.com/@moodiaofficiel',
                isLargeScreen,
              ),
              _buildSocialIcon(
                FontAwesomeIcons.telegram,
                const Color(0xFF0088CC),
                'Telegram',
                'https://t.me/moodia_officiel',
                isLargeScreen,
              ),
              _buildSocialIcon(
                FontAwesomeIcons.instagram,
                const Color(0xFFE4405F),
                'Instagram',
                'https://www.instagram.com/moodiaofficiel',
                isLargeScreen,
              ),
              _buildSocialIcon(
                FontAwesomeIcons.bluesky,
                const Color(0xFF0082FC),
                'Bluesky',
                'https://bsky.app/profile/moodia.xyz',
                isLargeScreen,
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Copyright
          Text(
            '© ${DateTime.now().year} Moodia. Tous droits réservés.',
            style: TextStyle(
              fontSize: isLargeScreen ? 13 : 11,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextLink(
    BuildContext context,
    String text,
    String route,
    bool isLargeScreen,
  ) {
    return TextButton(
      onPressed: () => Navigator.pushNamed(context, route),
      style: TextButton.styleFrom(
        padding: EdgeInsets.symmetric(
          horizontal: isLargeScreen ? 12 : 8,
          vertical: isLargeScreen ? 8 : 6,
        ),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: isLargeScreen ? 14 : 12,
          color: Colors.grey[600],
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildSocialIcon(
    IconData icon,
    Color color,
    String label,
    String url,
    bool isLargeScreen,
  ) {
    final size = isLargeScreen ? 44.0 : 40.0;

    if (_isDesktop) {
      return MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Tooltip(
          message: label,
          child: GestureDetector(
            onTap: () => _launchUrl(url),
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(color: color.withOpacity(0.2), width: 1),
              ),
              child: Icon(icon, size: size * 0.45, color: color),
            ),
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: () => _launchUrl(url),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          shape: BoxShape.circle,
          border: Border.all(color: color.withOpacity(0.2), width: 1),
        ),
        child: Icon(icon, size: size * 0.45, color: color),
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
