// lib/models/quote.dart

class Quote {
  final int? id;
  final String text;
  final String author;
  final String category;

  Quote({
    this.id,
    required this.text,
    required this.author,
    required this.category,
  });

  // Fonction pour créer un objet Account à partir d'un JSON
  factory Quote.fromJson(Map<String, dynamic> json) {
    return Quote(
      id: json['id'] as int?,
      text: json['text'] ?? '',
      author: json['author'] ?? '',
      category: json['category'] ?? '',
    );
  }

  // Fonction pour convertir l'objet en JSON
  Map<String, dynamic> toJson() {
    final map = {
      'id': id,
      'text': text,
      'author': author,
      'category': category,
    };

    print("🟦 Quote JSON: $map");
    return map;
  }
}
