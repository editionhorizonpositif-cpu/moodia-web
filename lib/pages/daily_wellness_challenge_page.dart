import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';

class DailyWellnessChallengePage extends StatefulWidget {
  const DailyWellnessChallengePage({super.key});

  @override
  State<DailyWellnessChallengePage> createState() =>
      _DailyWellnessChallengePageState();
}

class _DailyWellnessChallengePageState
    extends State<DailyWellnessChallengePage> {
  String _challenge = "";
  bool _isCompleted = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadChallenge();
  }

  Future<void> _loadChallenge() async {
    try {
      final String response = await rootBundle.loadString(
        'assets/data/wellness_challenges.json',
      );
      final List<dynamic> data = json.decode(response);
      final randomIndex = DateTime.now().day % data.length;
      setState(() {
        _challenge = data[randomIndex];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _challenge = "Impossible de charger le défi du jour.";
        _isLoading = false;
      });
    }
  }

  void _markCompleted() {
    setState(() {
      _isCompleted = true;
    });

    // Animation Lottie pendant 2 secondes
    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        _isCompleted = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    const Color backgroundColor = Color(0xFFF0F4F5);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text(
          "Défi Bien-être du jour",
          style: TextStyle(fontFamily: 'OpenSans'),
        ),
        backgroundColor: Colors.teal.shade400,
      ),
      body:
          _isLoading
              ? Center(
                child: Lottie.asset('assets/lotties/loading.json', width: 150),
              )
              : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Lottie.asset('assets/lotties/wellness.json', width: 200),
                    const SizedBox(height: 20),
                    Text(
                      "Ton défi du jour",
                      style: const TextStyle(
                        fontFamily: 'OpenSans',
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal,
                      ),
                    ),
                    const SizedBox(height: 15),
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      color: Colors.white,
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Text(
                          _challenge,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontFamily: 'OpenSans',
                            fontSize: 18,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.check_circle),
                      label: const Text(
                        "J'ai relevé le défi !",
                        style: TextStyle(fontFamily: 'OpenSans', fontSize: 16),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal.shade400,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                      onPressed: _markCompleted,
                    ),
                    const SizedBox(height: 30),
                    if (_isCompleted)
                      Lottie.asset('assets/lotties/success.json', width: 150),
                  ],
                ),
              ),
    );
  }
}
