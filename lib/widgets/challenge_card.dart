/*import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/challenge.dart';
import 'challenge_difficulty_indicator.dart';
import 'challenge_status_badge.dart';
import 'challenge_progress_bar.dart';

enum ChallengeCardVariant { standard, featured, user, compact }

class ChallengeCard extends StatelessWidget {
  final Challenge challenge;
  final ChallengeCardVariant variant;
  final VoidCallback? onTap;
  final VoidCallback? onJoinTap;

  const ChallengeCard({
    super.key,
    required this.challenge,
    this.variant = ChallengeCardVariant.standard,
    this.onTap,
    this.onJoinTap,
  });

  @override
  Widget build(BuildContext context) {
    switch (variant) {
      case ChallengeCardVariant.featured:
        return _buildFeaturedCard(context);
      case ChallengeCardVariant.user:
        return _buildUserCard(context);
      case ChallengeCardVariant.compact:
        return _buildCompactCard(context);
      case ChallengeCardVariant.standard:
      default:
        return _buildStandardCard(context);
    }
  }

  Widget _buildStandardCard(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image ou en-tête
              _buildCardHeader(),

              // Contenu
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Titre et catégorie
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                challenge.title,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2C3E50),
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                challenge.categoryName,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        ChallengeDifficultyIndicator(
                          difficulty: challenge.difficultyLevel,
                          size: 32,
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Description courte
                    Text(
                      challenge.description,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[700],
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 16),

                    // Métriques
                    _buildMetricsRow(),

                    const SizedBox(height: 12),

                    // Bouton d'action si nécessaire
                    if (onJoinTap != null && challenge.canJoin())
                      _buildJoinButton(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeaturedCard(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(
                  int.parse(
                    '0xFF${challenge.colorCode?.substring(1) ?? '7DBBC3'}',
                  ),
                ),
                Color(
                  int.parse(
                    '0xFF${challenge.colorCode?.substring(1) ?? '7DBBC3'}',
                  ),
                ).withOpacity(0.8),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Badge vedette
              const Positioned(
                top: 12,
                right: 12,
                child: Icon(Icons.star, color: Colors.amber, size: 24),
              ),

              // Contenu
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Titre
                    Text(
                      challenge.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 8),

                    // Description
                    Text(
                      challenge.description,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.white70,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const Spacer(),

                    // Métriques en blanc
                    Row(
                      children: [
                        _buildMetricChip(
                          icon: Icons.people,
                          value: '${challenge.currentParticipants}',
                          label: 'participants',
                          light: true,
                        ),
                        const SizedBox(width: 8),
                        _buildMetricChip(
                          icon: Icons.emoji_events,
                          value: '${challenge.pointsReward ?? 0}',
                          label: 'pts',
                          light: true,
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // Bouton rejoindre
                    if (challenge.canJoin())
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: onJoinTap,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF2C3E50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Rejoindre'),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserCard(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              // En-tête avec statut
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: challenge.participationStatus == 'COMPLETED'
                      ? Colors.green.withOpacity(0.1)
                      : challenge.participationStatus == 'ABANDONED'
                      ? Colors.red.withOpacity(0.1)
                      : const Color(0xFF7DBBC3).withOpacity(0.1),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    ChallengeStatusBadge(
                      status: challenge.participationStatus ?? 'JOINED',
                    ),
                    const Spacer(),
                    if (challenge.endsAt != null)
                      Text(
                        'Fin: ${DateFormat('dd/MM/yy').format(challenge.endsAt!)}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                  ],
                ),
              ),

              // Contenu
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Titre
                    Text(
                      challenge.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2C3E50),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Progression
                    if (challenge.userProgress != null)
                      ChallengeProgressBar(
                        progress: challenge.userProgress! as double,
                        height: 8,
                        showPercentage: true,
                      ),

                    const SizedBox(height: 12),

                    // Stats utilisateur
                    Row(
                      children: [
                        _buildUserStat(
                          icon: Icons.flash_on,
                          value: '${challenge.userProgress ?? 0}%',
                          label: 'Progression',
                        ),
                        const SizedBox(width: 16),
                        _buildUserStat(
                          icon: Icons.local_fire_department,
                          value: '${challenge.streakDays ?? 0}',
                          label: 'jours',
                        ),
                        const SizedBox(width: 16),
                        _buildUserStat(
                          icon: Icons.access_time,
                          value: _getRemainingDays(),
                          label: 'restants',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactCard(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Row(
            children: [
              // Icône
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Color(
                    int.parse(
                      '0xFF${challenge.colorCode?.substring(1) ?? '7DBBC3'}',
                    ),
                  ).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.emoji_events,
                  color: Color(
                    int.parse(
                      '0xFF${challenge.colorCode?.substring(1) ?? '7DBBC3'}',
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // Infos
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      challenge.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2C3E50),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.people, size: 14, color: Colors.grey[500]),
                        const SizedBox(width: 4),
                        Text(
                          '${challenge.currentParticipants} participants',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(width: 8),
                        ChallengeDifficultyIndicator(
                          difficulty: challenge.difficultyLevel,
                          size: 20,
                          showLabel: false,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Points
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF7DBBC3).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${challenge.pointsReward ?? 0} pts',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF7DBBC3),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardHeader() {
    if (challenge.imageUrl != null) {
      return ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        child: Image.network(
          challenge.imageUrl!,
          height: 120,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildHeaderPlaceholder();
          },
        ),
      );
    }
    return _buildHeaderPlaceholder();
  }

  Widget _buildHeaderPlaceholder() {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: Color(
          int.parse('0xFF${challenge.colorCode?.substring(1) ?? '7DBBC3'}'),
        ).withOpacity(0.2),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Center(
        child: Icon(
          Icons.emoji_events,
          size: 48,
          color: Color(
            int.parse('0xFF${challenge.colorCode?.substring(1) ?? '7DBBC3'}'),
          ),
        ),
      ),
    );
  }

  Widget _buildMetricsRow() {
    return Row(
      children: [
        _buildMetric(
          icon: Icons.people,
          value: '${challenge.currentParticipants}',
          label: 'participants',
        ),
        const SizedBox(width: 16),
        _buildMetric(
          icon: Icons.access_time,
          value: challenge.durationMinutes != null
              ? '${challenge.durationMinutes}min'
              : challenge.duration?.value != null
              ? '${challenge.duration!.value} ${challenge.duration!.unit?.toLowerCase()}'
              : 'Flexible',
          label: 'durée',
        ),
        const SizedBox(width: 16),
        _buildMetric(
          icon: Icons.emoji_events,
          value: '${challenge.pointsReward ?? 0}',
          label: 'points',
        ),
      ],
    );
  }

  Widget _buildMetric({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Expanded(
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[500]),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2C3E50),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  label,
                  style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricChip({
    required IconData icon,
    required String value,
    required String label,
    bool light = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: light ? Colors.white.withOpacity(0.2) : Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: light ? Colors.white : Colors.grey[700]),
          const SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: light ? Colors.white : const Color(0xFF2C3E50),
            ),
          ),
          const SizedBox(width: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: light ? Colors.white70 : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserStat({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF7DBBC3)),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C3E50),
            ),
          ),
          Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildJoinButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onJoinTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF7DBBC3),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text('Rejoindre ce défi'),
      ),
    );
  }

  String _getRemainingDays() {
    if (challenge.endsAt == null) return '∞';

    final now = DateTime.now();
    final days = challenge.endsAt!.difference(now).inDays;

    if (days < 0) return '0';
    if (days == 0) return 'Aujourd\'hui';
    return days.toString();
  }
}*/
