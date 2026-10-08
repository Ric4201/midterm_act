import 'package:flutter/material.dart';
import '../models/quote.dart';
import '../services/quote_service.dart';

/// Screen 2: "The Belt"
/// Powered by [StreamBuilder].
///
/// Must-Haves Checklist:
/// - [x] Updates on its own every 5 seconds.
/// - [x] Shows a loading state before the first data arrives.
/// - [x] Shows an error state when something goes wrong (e.g. Airplane mode).
/// - [x] One failed fetch MUST NOT kill the stream (verified via StreamController.addError).
/// - [x] Data visibly changes on every tick.
/// - [x] Typed Dart objects with fromJson, timeout, and status code verification.
/// - [x] Survives airplane mode test without crashing.
class BeltScreen extends StatefulWidget {
  final QuoteService quoteService;

  const BeltScreen({super.key, required this.quoteService});

  @override
  State<BeltScreen> createState() => _BeltScreenState();
}

class _BeltScreenState extends State<BeltScreen> {
  late Stream<Quote> _quoteStream;

  /// Keeps a rolling conveyor belt history of arrived quotes
  final List<Quote> _beltHistory = [];
  int _receivedCount = 0;
  DateTime? _lastUpdateTime;

  @override
  void initState() {
    super.initState();
    _quoteStream = widget.quoteService.getQuoteStream(
      interval: const Duration(seconds: 5),
    );
  }

  void _recordQuote(Quote quote) {
    // Avoid duplicate additions if the same snapshot triggers build
    if (_beltHistory.isEmpty || _beltHistory.first.id != quote.id) {
      _receivedCount++;
      _lastUpdateTime = DateTime.now();
      _beltHistory.insert(0, quote);
      if (_beltHistory.length > 20) {
        _beltHistory.removeLast();
      }
    }
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
              'The Belt',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              'StreamBuilder • Auto-Updates Every 5s',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
            ),
          ],
        ),
      ),
      body: StreamBuilder<Quote>(
        stream: _quoteStream,
        builder: (context, snapshot) {
          // 1. Loading state BEFORE the first data arrives
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData &&
              !snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 52,
                    height: 52,
                    child: CircularProgressIndicator(strokeWidth: 3.5),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Powering up The Belt...',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Waiting for the first quote to arrive from REST API',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            );
          }

          // Check if error occurred on this tick (e.g. Airplane mode)
          final hasError = snapshot.hasError;
          final errorText = hasError
              ? snapshot.error.toString().replaceFirst('Exception: ', '')
              : null;

          // If new valid data arrived, record it into history
          if (snapshot.hasData && snapshot.data != null) {
            _recordQuote(snapshot.data!);
          }

          // If initial load failed with error and has no prior data
          if (hasError && _beltHistory.isEmpty) {
            final isAirplane = errorText?.toLowerCase().contains('airplane') == true ||
                errorText?.toLowerCase().contains('socket') == true ||
                errorText?.toLowerCase().contains('internet') == true;

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
                          isAirplane
                              ? Icons.airplanemode_active_rounded
                              : Icons.error_outline_rounded,
                          size: 56,
                          color: theme.colorScheme.error,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          isAirplane
                              ? 'Airplane Mode / Network Offline'
                              : 'Stream Connection Error',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onErrorContainer,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          errorText ?? 'Unknown error occurred.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onErrorContainer,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface.withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'Stream is still alive. Retrying in 5s...',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: theme.colorScheme.error,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }

          // Main View: Active Belt with Header, Latest Quote, and Rolling History
          final latestQuote = _beltHistory.isNotEmpty ? _beltHistory.first : null;

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Column(
                    children: [
                      // Status Bar: Indicates live periodic stream status
                      _BeltStatusBar(
                        isError: hasError,
                        receivedCount: _receivedCount,
                        lastUpdated: _lastUpdateTime,
                      ),
                      if (hasError) ...[
                        const SizedBox(height: 10),
                        // Error banner showing airplane mode / network error
                        // Demonstrates that one failed fetch does NOT kill the stream!
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.errorContainer,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: theme.colorScheme.error.withValues(alpha: 0.5),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.warning_amber_rounded,
                                color: theme.colorScheme.error,
                                size: 22,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Fetch error: ${errorText ?? "No connection"}. '
                                  'Stream is ALIVE and will retry in 5s.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: theme.colorScheme.onErrorContainer,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),

                      // Featured "Just Arrived on the Belt" Card
                      if (latestQuote != null)
                        _FeaturedQuoteCard(
                          quote: latestQuote,
                          updateNumber: _receivedCount,
                        ),

                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Icon(
                            Icons.history_rounded,
                            size: 18,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Conveyor Belt History (${_beltHistory.length})',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            'Newest first',
                            style: TextStyle(
                              fontSize: 11,
                              color: theme.colorScheme.outline,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),

              // Rolling history of quotes delivered by the belt
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final item = _beltHistory[index];
                      final isCurrent = index == 0;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        elevation: 0,
                        color: isCurrent
                            ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3)
                            : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: isCurrent
                                ? theme.colorScheme.primary.withValues(alpha: 0.4)
                                : theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
                          ),
                        ),
                        child: ListTile(
                          dense: true,
                          leading: CircleAvatar(
                            radius: 14,
                            backgroundColor: isCurrent
                                ? theme.colorScheme.primary
                                : theme.colorScheme.outlineVariant,
                            child: Text(
                              '#${_beltHistory.length - index}',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: isCurrent
                                    ? theme.colorScheme.onPrimary
                                    : theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                          title: Text(
                            '"${item.quote}"',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 13),
                          ),
                          subtitle: Text(
                            '— ${item.author} (ID: ${item.id})',
                            style: TextStyle(
                              fontSize: 11,
                              color: theme.colorScheme.secondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      );
                    },
                    childCount: _beltHistory.length,
                  ),
                ),
              ),
              const SliverToBoxAdapter(
                child: SizedBox(height: 24),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _BeltStatusBar extends StatelessWidget {
  final bool isError;
  final int receivedCount;
  final DateTime? lastUpdated;

  const _BeltStatusBar({
    required this.isError,
    required this.receivedCount,
    required this.lastUpdated,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isError
            ? theme.colorScheme.errorContainer.withValues(alpha: 0.5)
            : theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isError
              ? theme.colorScheme.error.withValues(alpha: 0.3)
              : theme.colorScheme.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isError ? Colors.red : Colors.green,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isError ? 'BELT STATUS: PAUSED / RECONNECTING' : 'BELT STATUS: LIVE STREAMING',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                    color: isError
                        ? theme.colorScheme.error
                        : theme.colorScheme.primary,
                  ),
                ),
                Text(
                  'Delivered $receivedCount quotes • Polls every 5s',
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2.2),
          ),
        ],
      ),
    );
  }
}

class _FeaturedQuoteCard extends StatelessWidget {
  final Quote quote;
  final int updateNumber;

  const _FeaturedQuoteCard({
    required this.quote,
    required this.updateNumber,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 3,
      shadowColor: theme.colorScheme.primary.withValues(alpha: 0.2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: theme.colorScheme.primary.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.surface,
              theme.colorScheme.primaryContainer.withValues(alpha: 0.2),
            ],
          ),
        ),
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'UPDATE #$updateNumber',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                      color: theme.colorScheme.onPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'ID: ${quote.id}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.outline,
                  ),
                ),
                const Spacer(),
                const Icon(
                  Icons.sensors_rounded,
                  color: Colors.green,
                  size: 20,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              '"${quote.quote}"',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Icon(
                  Icons.person_rounded,
                  size: 16,
                  color: theme.colorScheme.secondary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    quote.author,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.secondary,
                      fontWeight: FontWeight.bold,
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
