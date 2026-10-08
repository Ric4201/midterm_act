import 'package:flutter_test/flutter_test.dart';
import 'package:midterm_act/models/quote.dart';

void main() {
  group('Quote Model Tests', () {
    test('Quote.fromJson correctly deserializes valid JSON', () {
      final json = {
        'id': 42,
        'quote': 'The only way to do great work is to love what you do.',
        'author': 'Steve Jobs',
      };

      final quote = Quote.fromJson(json);

      expect(quote.id, 42);
      expect(quote.quote, 'The only way to do great work is to love what you do.');
      expect(quote.author, 'Steve Jobs');
    });

    test('QuoteListResponse.fromJson correctly parses quote list', () {
      final json = {
        'quotes': [
          {'id': 1, 'quote': 'Stay hungry, stay foolish.', 'author': 'Steve Jobs'},
          {'id': 2, 'quote': 'Simplicity is the soul of efficiency.', 'author': 'Austin Freeman'},
        ],
        'total': 2,
        'skip': 0,
        'limit': 2,
      };

      final response = QuoteListResponse.fromJson(json);

      expect(response.quotes.length, 2);
      expect(response.total, 2);
      expect(response.quotes[0].id, 1);
      expect(response.quotes[1].author, 'Austin Freeman');
    });

    test('Quote.fromJson handles null or missing fields gracefully', () {
      final json = <String, dynamic>{};

      final quote = Quote.fromJson(json);

      expect(quote.id, 0);
      expect(quote.quote, 'No quote content');
      expect(quote.author, 'Unknown Author');
    });
  });
}
