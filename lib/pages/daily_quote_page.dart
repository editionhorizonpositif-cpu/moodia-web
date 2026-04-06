import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:moodia/models/quote.dart';
import 'package:moodia/services/api_service.dart';

class DailyQuotePage extends StatefulWidget {
  const DailyQuotePage({super.key});

  @override
  State<DailyQuotePage> createState() => _DailyQuotePageState();
}

class _DailyQuotePageState extends State<DailyQuotePage> {
  final ApiService _apiService = ApiService();
  Quote? _quote;
  bool _isLoading = true;
  final String _quoteKey = 'daily_quote';
  final String _quoteDateKey = 'daily_quote_date';
  final String _historyKey = 'quote_history';

  @override
  void initState() {
    super.initState();
    _loadDailyQuote();
  }

  /// Charge la citation du jour ou en sélectionne une nouvelle
  Future<void> _loadDailyQuote() async {
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final savedDate = prefs.getString(_quoteDateKey);

    if (savedDate == today && prefs.containsKey(_quoteKey)) {
      // Charger la citation du jour déjà sauvegardée
      final quoteJson = jsonDecode(prefs.getString(_quoteKey)!);
      setState(() {
        _quote = Quote.fromJson(quoteJson);
        _isLoading = false;
      });
    } else {
      await _fetchNewQuote();
    }
  }

  /// Récupère une nouvelle citation aléatoire qui n'est pas dans l'historique
  Future<void> _fetchNewQuote() async {
    try {
      final quotes = await _apiService.getQuotes();
      final prefs = await SharedPreferences.getInstance();

      // Charger l'historique des 5 dernières citations
      List<int> history = [];
      if (prefs.containsKey(_historyKey)) {
        history = List<int>.from(jsonDecode(prefs.getString(_historyKey)!));
      }

      // Filtrer les citations pour exclure celles de l'historique
      final availableQuotes =
          quotes.where((q) => !history.contains(q.id)).toList();

      // Si toutes les citations sont épuisées, on réinitialise l'historique
      if (availableQuotes.isEmpty) {
        history.clear();
        availableQuotes.addAll(quotes);
      }

      // Sélectionner une citation aléatoire
      final randomQuote =
          availableQuotes[Random().nextInt(availableQuotes.length)];

      // Mettre à jour l'historique (max 5 dernières)
      history.insert(0, randomQuote.id!);
      if (history.length > 10) {
        history = history.sublist(0, 10);
      }

      await prefs.setString(_historyKey, jsonEncode(history));

      // Sauvegarder la citation et la date
      await prefs.setString(_quoteKey, jsonEncode(randomQuote.toJson()));
      await prefs.setString(
        _quoteDateKey,
        DateTime.now().toIso8601String().substring(0, 10),
      );

      setState(() {
        _quote = randomQuote;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _quote = Quote(
          id: -1,
          text: 'Impossible de charger la citation du jour.',
          author: 'Erreur',
          category: 'Erreur',
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color backgroundColor = Color(0xFFF0F4F5);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text(
          "Citation inspirante",
          style: TextStyle(fontFamily: 'OpenSans'),
        ),
        backgroundColor: Colors.deepPurple,
      ),
      body: Center(
        child:
            _isLoading
                ? const CircularProgressIndicator()
                : _quote == null
                ? const Text(
                  "Aucune citation disponible",
                  style: TextStyle(fontFamily: 'OpenSans', fontSize: 16),
                )
                : Padding(
                  padding: const EdgeInsets.all(24),
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 5,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.format_quote,
                            size: 40,
                            color: Colors.deepPurple,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "\"${_quote!.text}\"",
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontFamily: 'OpenSans',
                              fontSize: 18,
                              fontStyle: FontStyle.italic,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            "- ${_quote!.author}",
                            style: const TextStyle(
                              fontFamily: 'OpenSans',
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
      ),
    );
  }
}
