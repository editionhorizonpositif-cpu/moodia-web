// lib/models/paged_response.dart
import 'dart:convert';

class PagedResponse<T> {
  final List<T> content;
  final int page;
  final int size;
  final int totalElements;
  final int totalPages;
  final bool last;
  final bool first;
  final bool empty;

  PagedResponse({
    required this.content,
    required this.page,
    required this.size,
    required this.totalElements,
    required this.totalPages,
    required this.last,
    required this.first,
    required this.empty,
  });

  factory PagedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    return PagedResponse<T>(
      content: (json['content'] as List<dynamic>)
          .map((item) => fromJson(item as Map<String, dynamic>))
          .toList(),
      page: json['number'] as int,
      size: json['size'] as int,
      totalElements: json['totalElements'] as int,
      totalPages: json['totalPages'] as int,
      last: json['last'] as bool,
      first: json['first'] as bool,
      empty: json['empty'] as bool,
    );
  }

  Map<String, dynamic> toJson(T Function(T) toJson) {
    return {
      'content': content.map(toJson).toList(),
      'number': page,
      'size': size,
      'totalElements': totalElements,
      'totalPages': totalPages,
      'last': last,
      'first': first,
      'empty': empty,
    };
  }

  bool hasNext() => !last;
  bool hasPrevious() => !first;
}
