import 'package:flutter/material.dart';

class YogaSessionPage extends StatefulWidget {
  const YogaSessionPage({super.key});

  @override
  State<YogaSessionPage> createState() => _YogaSessionPageState();
}

class _YogaSessionPageState extends State<YogaSessionPage> {
  int _currentPose = 0;
  final List<YogaPose> _poses = [
    YogaPose(
      name: 'Montagne (Tadasana)',
      duration: '30 secondes',
      description: 'Debout, pieds joints, épaules relâchées',
      benefits: 'Améliore la posture et la stabilité',
      image: '🧍',
    ),
    YogaPose(
      name: 'Chien tête en bas (Adho Mukha Svanasana)',
      duration: '1 minute',
      description: 'Formez un V inversé avec votre corps',
      benefits: 'Étire tout le corps et calme l\'esprit',
      image: '⬇️',
    ),
    YogaPose(
      name: 'Guerrier II (Virabhadrasana II)',
      duration: '45 secondes chaque côté',
      description: 'Pieds écartés, bras tendus, regard vers l\'avant',
      benefits: 'Renforce les jambes et améliore la concentration',
      image: '⚔️',
    ),
    YogaPose(
      name: 'Enfant (Balasana)',
      duration: '1 minute',
      description: 'À genoux, front au sol, bras le long du corps',
      benefits: 'Détend le dos et calme le système nerveux',
      image: '🧘',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final currentPose = _poses[_currentPose];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Session Yoga',
          style: TextStyle(color: Colors.white, fontFamily: 'OpenSans'),
        ),
        backgroundColor: const Color(0xFF81C784),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        color: const Color(0xFFF8FBFC),
        child: Column(
          children: [
            // Progression
            Padding(
              padding: const EdgeInsets.all(20),
              child: LinearProgressIndicator(
                value: (_currentPose + 1) / _poses.length,
                backgroundColor: Colors.grey.shade200,
                color: const Color(0xFF81C784),
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Pose actuelle
                    Container(
                      height: 200,
                      decoration: BoxDecoration(
                        color: const Color(0xFF81C784).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Center(
                        child: Text(
                          currentPose.image,
                          style: const TextStyle(fontSize: 100),
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Nom de la pose
                    Text(
                      currentPose.name,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF2C3E50),
                        fontFamily: 'OpenSans',
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 10),

                    // Durée
                    Text(
                      'Durée: ${currentPose.duration}',
                      style: const TextStyle(
                        fontSize: 18,
                        color: Color(0xFF7DBBC3),
                        fontFamily: 'OpenSans',
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Description
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Instructions',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF2C3E50),
                                fontFamily: 'OpenSans',
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              currentPose.description,
                              style: const TextStyle(
                                fontSize: 16,
                                color: Color(0xFF5D6D7E),
                                fontFamily: 'OpenSans',
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Bienfaits
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Bienfaits',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF2C3E50),
                                fontFamily: 'OpenSans',
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              currentPose.benefits,
                              style: const TextStyle(
                                fontSize: 16,
                                color: Color(0xFF5D6D7E),
                                fontFamily: 'OpenSans',
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Liste des poses
                    const Text(
                      'Séquence complète',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF2C3E50),
                        fontFamily: 'OpenSans',
                      ),
                    ),

                    const SizedBox(height: 15),

                    ..._poses.asMap().entries.map((entry) {
                      final index = entry.key;
                      final pose = entry.value;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: index == _currentPose
                              ? const Color(0xFF81C784).withOpacity(0.1)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: index == _currentPose
                                ? const Color(0xFF81C784)
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Row(
                          children: [
                            Text(
                              pose.image,
                              style: const TextStyle(fontSize: 30),
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    pose.name,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: index == _currentPose
                                          ? const Color(0xFF2C3E50)
                                          : const Color(0xFF5D6D7E),
                                      fontFamily: 'OpenSans',
                                    ),
                                  ),
                                  Text(
                                    pose.duration,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF7DBBC3),
                                      fontFamily: 'OpenSans',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (index < _currentPose)
                              const Icon(
                                Icons.check_circle,
                                color: Color(0xFF81C784),
                              ),
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
            ),

            // Contrôles
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Colors.grey, width: 0.5)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (_currentPose > 0)
                    ElevatedButton(
                      onPressed: () {
                        setState(() => _currentPose--);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF81C784),
                        side: const BorderSide(color: Color(0xFF81C784)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 30,
                          vertical: 15,
                        ),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.arrow_back),
                          SizedBox(width: 8),
                          Text('Précédent'),
                        ],
                      ),
                    )
                  else
                    const SizedBox(width: 140),

                  ElevatedButton(
                    onPressed: () {
                      if (_currentPose < _poses.length - 1) {
                        setState(() => _currentPose++);
                      } else {
                        // Session terminée
                        Navigator.pop(context);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF81C784),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 30,
                        vertical: 15,
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(
                          _currentPose < _poses.length - 1
                              ? 'Suivant'
                              : 'Terminer',
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          _currentPose < _poses.length - 1
                              ? Icons.arrow_forward
                              : Icons.check,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class YogaPose {
  final String name;
  final String duration;
  final String description;
  final String benefits;
  final String image;

  YogaPose({
    required this.name,
    required this.duration,
    required this.description,
    required this.benefits,
    required this.image,
  });
}
