import 'package:petal/api/home_layout.dart';
import 'package:petal/widgets/back_button.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

class HomeCustomizationPage extends StatefulWidget {
  final bool popup;
  const HomeCustomizationPage({super.key, this.popup = false});
  @override
  State<HomeCustomizationPage> createState() => _HomeCustomizationPageState();
}

class _HomeCustomizationPageState extends State<HomeCustomizationPage> {
  @override
  void initState() {
    super.initState();
    HomeLayout.instance.load();
  }

  void _save(Future<void> action) {
    action.catchError((Object _) {
      if (mounted)
        showToast(
          context: context,
          builder: (_, _) => const Text('Could not save Home layout.'),
        );
    });
  }

  @override
  Widget build(BuildContext context) {
    final layout = HomeLayout.instance;
    return Scaffold(
      headers: widget.popup ? const [] : const [
        AppBar(leading: [BackButton()], title: Text('Customize Home')),
      ],
      child: ListenableBuilder(
        listenable: layout,
        builder: (context, _) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Show, hide, and reorder Home sections. Start now is hidden by default because On Deck includes watchlist suggestions.',
            ),
            for (final id in layout.order)
              Row(
                children: [
                  Expanded(child: Text(HomeLayout.labels[id]!)),
                  IconButton.ghost(
                    icon: const Icon(LucideIcons.arrowUp),
                    onPressed: layout.order.first == id
                        ? null
                        : () => _save(layout.move(id, -1)),
                  ),
                  IconButton.ghost(
                    icon: const Icon(LucideIcons.arrowDown),
                    onPressed: layout.order.last == id
                        ? null
                        : () => _save(layout.move(id, 1)),
                  ),
                  Switch(
                    value: !layout.hidden.contains(id),
                    onChanged: (v) => _save(layout.setVisible(id, v)),
                  ),
                ],
              ),
            Button.outline(
              onPressed: () => _save(layout.reset()),
              child: const Text('Restore defaults'),
            ),
          ],
        ),
      ),
    );
  }
}
