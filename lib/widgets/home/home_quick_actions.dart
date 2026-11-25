import 'package:petal/widgets/home/surprise_watchlist_button.dart';
import 'package:petal/widgets/ios/ios_controls.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

class HomeQuickActions extends StatelessWidget {
  const HomeQuickActions({super.key, required this.showSurprise});

  final bool showSurprise;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
    child: Align(
      alignment: AlignmentDirectional.centerStart,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 8,
        children: [
          if (showSurprise)
            const Flexible(flex: 3, child: SurpriseWatchlistButton()),
          Flexible(
            flex: 2,
            child: PetalButton.secondary(
              onPressed: () => showOverlay(
                context,
                DialogConfiguration(),
                builder: (dialogContext) => AlertDialog(
                  title: const Text('Chat with AI'),
                  content: const Text('AI chat isn’t available in Petal yet.'),
                  actions: [
                    PetalButton.secondary(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              ),
              child: const Text('Chat with AI', textAlign: TextAlign.center),
            ),
          ),
        ],
      ),
    ),
  );
}
