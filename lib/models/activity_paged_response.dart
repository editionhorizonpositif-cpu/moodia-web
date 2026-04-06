class ActivityPagedResponse<T> {
  final List<T> content;
  final int pageNumber;
  final int pageSize;
  final int totalElements;
  final int totalPages;
  final bool first;
  final bool last;
  final bool empty;

  ActivityPagedResponse({
    required this.content,
    required this.pageNumber,
    required this.pageSize,
    required this.totalElements,
    required this.totalPages,
    required this.first,
    required this.last,
    required this.empty,
  });

  factory ActivityPagedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    // SAFE PARSING - Gère les valeurs null
    int _safeParseInt(dynamic value, {int defaultValue = 0}) {
      if (value == null) return defaultValue;
      if (value is int) return value;
      if (value is num) return value.toInt();
      try {
        return int.parse(value.toString());
      } catch (e) {
        return defaultValue;
      }
    }

    bool _safeParseBool(dynamic value, {bool defaultValue = false}) {
      if (value == null) return defaultValue;
      if (value is bool) return value;
      return value.toString().toLowerCase() == 'true';
    }

    // Parse le content
    List<T> contentList = [];
    if (json['content'] != null && json['content'] is List) {
      contentList = (json['content'] as List)
          .map((item) => fromJson(item as Map<String, dynamic>))
          .toList();
    }

    return ActivityPagedResponse(
      content: contentList,
      pageNumber: _safeParseInt(json['pageNumber'] ?? json['number']),
      pageSize: _safeParseInt(json['pageSize'] ?? json['size']),
      totalElements: _safeParseInt(json['totalElements']),
      totalPages: _safeParseInt(json['totalPages']),
      first: _safeParseBool(json['first']),
      last: _safeParseBool(json['last']),
      empty: _safeParseBool(json['empty'], defaultValue: contentList.isEmpty),
    );
  }
}
