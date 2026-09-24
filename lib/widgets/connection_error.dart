import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

class ConnectionException implements Exception {
  final String message;

  const ConnectionException([this.message = 'Connection failed']);

  @override
  String toString() => message;
}

class ConnectionErrorView extends StatelessWidget {
  final Object? error;
  final VoidCallback? onRetry;
  final String? title;
  final String? message;

  const ConnectionErrorView({
    super.key,
    this.error,
    this.onRetry,
    this.title,
    this.message,
  });

  String get _title => title ?? "Can't reach the network";

  String get _message {
    if (message != null) return message!;
    final raw = error?.toString() ?? '';
    if (raw.toLowerCase().contains('socket') ||
        raw.toLowerCase().contains('failed host') ||
        raw.toLowerCase().contains('connection') ||
        raw.toLowerCase().contains('timed out') ||
        raw.toLowerCase().contains('network')) {
      return 'This network blocked or dropped the request. Try again on another connection, or retry after the ship Wi-Fi portal is signed in.';
    }
    return 'Something went wrong while loading. Check your connection and try again.';
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(LucideIcons.wifiOff, size: 40, color: Theme.of(context).colorScheme.mutedForeground),
              const SizedBox(height: 16),
              Text(
                _title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                _message,
                textAlign: TextAlign.center,
                style: TextStyle(color: Theme.of(context).colorScheme.mutedForeground),
              ),
              if (onRetry != null) ...[
                const SizedBox(height: 20),
                Button.primary(
                  onPressed: onRetry,
                  leading: const Icon(LucideIcons.refreshCw),
                  child: const Text('Try again'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
