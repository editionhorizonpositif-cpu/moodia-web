/*import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/challenge_provider.dart';
import '../models/challenge.dart';
import '../widgets/challenge_card.dart';
import '../routes/route.dart'; // Importer vos routes

class ChallengesSection extends StatelessWidget {
  const ChallengesSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ChallengeProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (provider.featuredChallenges.isEmpty &&
            provider.userActiveChallenges.isEmpty &&
            provider.challenges.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          children: [
            if (provider.featuredChallenges.isNotEmpty)
              _buildFeaturedChallenges(context, provider),

            if (provider.userActiveChallenges.isNotEmpty)
              _buildActiveChallenges(context, provider),

            _buildRecommendations(context, provider),
          ],
        );
      },
    );
  }

  Widget _buildFeaturedChallenges(
    BuildContext context,
    ChallengeProvider provider,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '🌟 Défis en vedette',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, AppRoutes.challenges);
                },
                child: const Text(
                  'Voir tout',
                  style: TextStyle(color: Color(0xFF7DBBC3)),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: provider.featuredChallenges.length,
            itemBuilder: (context, index) {
              final challenge = provider.featuredChallenges[index];
              return Container(
                width: 260,
                margin: const EdgeInsets.only(right: 12),
                child: ChallengeCard(
                  challenge: challenge,
                  variant: ChallengeCardVariant.featured,
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      AppRoutes.challengeDetail,
                      arguments: challenge.id,
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildActiveChallenges(
    BuildContext context,
    ChallengeProvider provider,
  ) {
    final inProgress = provider.userActiveChallenges;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '🔥 Mes défis en cours',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, AppRoutes.userChallenges);
                },
                child: const Text(
                  'Voir tout',
                  style: TextStyle(color: Color(0xFF7DBBC3)),
                ),
              ),
            ],
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: inProgress.length > 2 ? 2 : inProgress.length,
          itemBuilder: (context, index) {
            final challenge = inProgress[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ChallengeCard(
                challenge: challenge,
                variant: ChallengeCardVariant.compact,
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    AppRoutes.challengeDetail,
                    arguments: challenge.id,
                  );
                },
              ),
            );
          },
        ),
        if (inProgress.length > 2)
          Padding(
            padding: const EdgeInsets.all(8),
            child: Center(
              child: TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, AppRoutes.userChallenges);
                },
                child: Text(
                  '+ ${inProgress.length - 2} autres défis',
                  style: const TextStyle(color: Color(0xFF7DBBC3)),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildRecommendations(
    BuildContext context,
    ChallengeProvider provider,
  ) {
    final recommendations = provider.challenges
        .where(
          (c) => c.isActive && c.hasJoined != true && c.remainingSlots != 0,
        )
        .take(3)
        .toList();

    if (recommendations.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF7DBBC3).withOpacity(0.8),
            const Color(0xFF5A9AA3),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.lightbulb, color: Colors.white, size: 28),
              SizedBox(width: 8),
              Text(
                'Pour vous',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Des défis adaptés à vos besoins',
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 20),
          ...recommendations.map(
            (challenge) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: ChallengeCard(
                challenge: challenge,
                variant: ChallengeCardVariant.compact,
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    AppRoutes.challengeDetail,
                    arguments: challenge.id,
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: TextButton(
              onPressed: () {
                Navigator.pushNamed(context, AppRoutes.challenges);
              },
              style: TextButton.styleFrom(foregroundColor: Colors.white),
              child: const Text('Voir plus de défis'),
            ),
          ),
        ],
      ),
    );
  }
}*/
