import 'package:flutter/material.dart';
import '../models/quote.dart';
import '../services/quote_service.dart';

/// Screen 1: "The Order"
/// Powered by [FutureBuilder].
///
/// Must-Haves Checklist:
/// - [x] Loads once when the screen opens (stored in `_quotesFuture` inside `initState`).
/// - [x] Shows a spinner while waiting.
/// - [x] Shows an error message and a Retry button when it fails.
/// - [x] Shows an "empty" message when there is no data to show.
/// - [x] Shows real API data as a list.
/// - [x] Survives airplane mode without crashing.
class OrderScreen extends StatefulWidget {
  final QuoteService quoteService;

  const OrderScreen({super.key, required this.quoteService});

  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  /// The Future is cached here so that calling [build] multiple times
  /// (e.g. during theme changes, screen rotations, etc.) will NEVER trigger
  /// accidental endless re-fetching.
  late Future<List<Quote>> _quotesFuture;

  @override
  void initState() {
    super.initState();
    _loadQuotes();
  }

  void _loadQuotes() {
    setState(() {
      _quotesFuture = widget.quoteService.fetchQuotes();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'The Order',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              'FutureBuilder • Fetched Once On Open',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Reload Quotes',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadQuotes,
          ),
        ],
      ),
      body: FutureBuilder<List<Quote>>(
        future: _quotesFuture,
        builder: (context, snapshot) {
          // 1. Loading State (Spinner while waiting)
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 48,
                    height: 48,
                    child: CircularProgressIndicator(strokeWidth: 3.5),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Fetching quotes from REST API...',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            );
          }

          // 2. Error State (Error message + Retry button)
          if (snapshot.hasError) {
            final errorText = snapshot.error.toString().replaceFirst('Exception: ', '');
            final isAirplaneOrNetwork = errorText.toLowerCase().contains('internet') ||
                errorText.toLowerCase().contains('airplane') ||
                errorText.toLowerCase().contains('socket') ||
                errorText.toLowerCase().contains('timed out');

            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Card(
                  elevation: 0,
                  color: theme.colorScheme.errorContainer.withValues(alpha: 0.7),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: theme.colorScheme.error.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24.0,
                      vertical: 32.0,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isAirplaneOrNetwork
                              ? Icons.airplanemode_active_rounded
                              : Icons.error_outline_rounded,
                          size: 56,
                          color: theme.colorScheme.error,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          isAirplaneOrNetwork
                              ? 'Airplane Mode / No Connection'
                              : 'Failed to Load Quotes',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onErrorContainer,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          errorText,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onErrorContainer,
                          ),
                        ),
                        const SizedBox(height: 24),
                        FilledButton.icon(
                          onPressed: _loadQuotes,
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('Retry Fetch'),
                          style: FilledButton.styleFrom(
                            backgroundColor: theme.colorScheme.error,
                            foregroundColor: theme.colorScheme.onError,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }

          // 3. Success State with Empty Check
          final quotes = snapshot.data ?? [];

          if (quotes.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.inbox_outlined,
                      size: 64,
                      color: theme.colorScheme.outline,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No Quotes Available',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'The API returned an empty list. Try refreshing.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 20),
                    OutlinedButton.icon(
                      onPressed: _loadQuotes,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Refresh'),
                    ),
                  ],
                ),
              ),
            );
          }

          // 4. Success State: Real API data as a List
          return RefreshIndicator(
            onRefresh: () async {
              _loadQuotes();
              await _quotesFuture;
            },
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: quotes.length,
              itemBuilder: (context, index) {
                final quote = quotes[index];
                return _QuoteCard(
                  quote: quote,
                  index: index + 1,
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _QuoteCard extends StatelessWidget {
  final Quote quote;
  final int index;

  const _QuoteCard({
    required this.quote,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '#$index • ID ${quote.id}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.format_quote_rounded,
                  color: theme.colorScheme.primary.withValues(alpha: 0.5),
                  size: 24,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              '"${quote.quote}"',
              style: theme.textTheme.bodyLarge?.copyWith(
                height: 1.35,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.person_outline_rounded,
                  size: 16,
                  color: theme.colorScheme.secondary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    quote.author,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.secondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
