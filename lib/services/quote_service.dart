import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/quote.dart';

/// Service responsible for fetching Quotes from the DummyJSON Public REST API.
///
/// API Ground Rules respected:
/// - Free, returns JSON, no API key, no credit card required.
/// - Endpoints:
///     1. Order (List): `https://dummyjson.com/quotes?limit=15`
///     2. Belt (Stream): `https://dummyjson.com/quotes/random`
/// - Respects rate limits by fetching every 5 seconds for the stream.
/// - Validates status code (200) and enforces request timeouts.
/// - Survives the airplane mode test without crashing.
class QuoteService {
  static const String baseUrl = 'https://dummyjson.com/quotes';
  static const Duration timeoutDuration = Duration(seconds: 5);

  final http.Client _client;

  QuoteService({http.Client? client}) : _client = client ?? http.Client();

  /// Fetches a list of quotes once for Screen 1 (The Order).
  ///
  /// Checks status code, includes a timeout, and converts into typed Dart objects.
  /// Throws meaningful descriptive errors on failure (e.g. Airplane mode).
  Future<List<Quote>> fetchQuotes({int limit = 15}) async {
    final uri = Uri.parse('$baseUrl?limit=$limit');

    try {
      final response = await _client.get(uri).timeout(timeoutDuration);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data =
            jsonDecode(response.body) as Map<String, dynamic>;
        final quoteListResponse = QuoteListResponse.fromJson(data);
        return quoteListResponse.quotes;
      } else {
        throw HttpException(
          'Server returned status code ${response.statusCode}: ${response.reasonPhrase}',
        );
      }
    } on SocketException catch (_) {
      throw const SocketException(
        'No Internet connection. Did you turn on Airplane Mode?',
      );
    } on TimeoutException catch (_) {
      throw TimeoutException(
        'Request timed out. Server took more than ${timeoutDuration.inSeconds} seconds to respond.',
      );
    } on http.ClientException catch (e) {
      throw Exception('Network client error: ${e.message}');
    } on FormatException catch (_) {
      throw const FormatException('Invalid JSON format received from server.');
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  /// Fetches a single random quote for Screen 2 (The Belt).
  ///
  /// Checks status code, has a timeout, and parses into typed [Quote].
  Future<Quote> fetchRandomQuote() async {
    final uri = Uri.parse('$baseUrl/random');

    try {
      final response = await _client.get(uri).timeout(timeoutDuration);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data =
            jsonDecode(response.body) as Map<String, dynamic>;
        return Quote.fromJson(data);
      } else {
        throw HttpException(
          'Server returned status code ${response.statusCode}: ${response.reasonPhrase}',
        );
      }
    } on SocketException catch (_) {
      throw const SocketException(
        'No Internet connection (Airplane Mode active).',
      );
    } on TimeoutException catch (_) {
      throw TimeoutException('Request timed out while streaming quote.');
    } on http.ClientException catch (e) {
      throw Exception('Network client error: ${e.message}');
    } on FormatException catch (_) {
      throw const FormatException('Invalid JSON payload received.');
    } catch (e) {
      throw Exception('Streaming error: $e');
    }
  }

  /// Creates a continuous Stream of [Quote] objects for Screen 2 (The Belt).
  ///
  /// Key Requirement:
  /// - Ticks every [interval] (defaults to 5 seconds).
  /// - One failed fetch does NOT kill the stream.
  /// - Survives Airplane Mode toggling on and off:
  ///   When Airplane Mode is turned ON, an error is emitted to the stream via
  ///   [StreamController.addError]. The stream stays alive!
  ///   When Airplane Mode is turned OFF, subsequent ticks succeed and emit new data.
  Stream<Quote> getQuoteStream({
    Duration interval = const Duration(seconds: 5),
  }) {
    late StreamController<Quote> controller;
    Timer? periodicTimer;
    bool isFetching = false;

    Future<void> tick() async {
      if (controller.isClosed || isFetching) return;
      isFetching = true;
      try {
        final quote = await fetchRandomQuote();
        if (!controller.isClosed) {
          controller.add(quote);
        }
      } catch (error) {
        if (!controller.isClosed) {
          // Deliver error to StreamBuilder without closing/killing the stream!
          controller.addError(error);
        }
      } finally {
        isFetching = false;
      }
    }

    controller = StreamController<Quote>.broadcast(
      onListen: () {
        // Fetch immediately on initial listen so the user doesn't wait 5 seconds.
        tick();
        // Periodically tick every 5 seconds.
        periodicTimer = Timer.periodic(interval, (_) => tick());
      },
      onCancel: () {
        periodicTimer?.cancel();
      },
    );

    return controller.stream;
  }
}
