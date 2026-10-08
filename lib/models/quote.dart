/// Model classes for CC 105 Activity: Future, Stream & REST API Integration
///
/// Uses typed Dart objects with factory `fromJson` constructors as required.
library;

class Quote {
  final int id;
  final String quote;
  final String author;

  const Quote({
    required this.id,
    required this.quote,
    required this.author,
  });

  /// Factory constructor to deserialize JSON map into a typed [Quote] instance.
  factory Quote.fromJson(Map<String, dynamic> json) {
    return Quote(
      id: json['id'] as int? ?? 0,
      quote: (json['quote'] as String?)?.trim() ?? 'No quote content',
      author: (json['author'] as String?)?.trim() ?? 'Unknown Author',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'quote': quote,
      'author': author,
    };
  }

  @override
  String toString() => 'Quote(id: $id, author: $author, quote: "$quote")';
}

/// Response wrapper for the paginated quotes endpoint (`/quotes?limit=15`).
class QuoteListResponse {
  final List<Quote> quotes;
  final int total;
  final int skip;
  final int limit;

  const QuoteListResponse({
    required this.quotes,
    required this.total,
    required this.skip,
    required this.limit,
  });

  /// Factory constructor to parse list response.
  factory QuoteListResponse.fromJson(Map<String, dynamic> json) {
    final rawList = json['quotes'] as List<dynamic>? ?? [];
    final parsedQuotes = rawList
        .map((item) => Quote.fromJson(item as Map<String, dynamic>))
        .toList();

    return QuoteListResponse(
      quotes: parsedQuotes,
      total: json['total'] as int? ?? 0,
      skip: json['skip'] as int? ?? 0,
      limit: json['limit'] as int? ?? 0,
    );
  }
}
