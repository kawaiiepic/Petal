import 'package:petal/api/api_cache.dart';
import 'package:petal/api/backend/backend_api.dart';
import 'package:petal/models/addon.dart';
import 'package:petal/theme/app_typography.dart';
import 'package:petal/widgets/addons/addon_tile.dart';
import 'package:petal/widgets/addons/recommend_addon_tile.dart';
import 'package:petal/widgets/back_button.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

class AddonsPage extends StatefulWidget {
  const AddonsPage({super.key});

  @override
  State<AddonsPage> createState() => _AddonsPageState();
}

class _AddonsPageState extends State<AddonsPage> {
  final _textController = TextEditingController();
  Future<List<Addon>>? _addonsFuture;

  @override
  void initState() {
    super.initState();
    _reloadAddons();
  }

  void _reloadAddons() {
    setState(() {
      _addonsFuture = ApiCache.getAddons();
    });
  }

  Widget _sectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
    );
  }

  Widget addonsWidget() => FutureBuilder(
    future: _addonsFuture,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator());
      } else if (snapshot.hasError) {
        return Center(child: Text('Error: ${snapshot.error}'));
      } else {
        final addons = snapshot.data!;

        Future<void> removeAddon(Addon addon) async {
          await BackendApi.deleteUserAddon(addon.id);
          _reloadAddons();
        }

        if (addons.isEmpty) {
          return Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'No addons found',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
            ),
          );
        } else {
          return SortableLayer(
            child: SortableDropFallback(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 8,
                children: [
                  _sectionTitle('Installed widgets'),
                  for (int i = 0; i < addons.length; i++)
                    Sortable(
                      data: SortableData(addons[i]),
                      child: AddonTile(
                        key: ValueKey(addons[i].id),
                        addon: addons[i],
                        onRemove: () => removeAddon(addons[i]),
                      ),
                    ),
                ],
              ),
            ),
          );
        }
      }
    },
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      headers: [
        AppBar(title: const Text('Addons'), leading: [BackButton()]),
      ],
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 24,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 8,
              children: [
                _sectionTitle('Addon URL'),
                TextField(
                  controller: _textController,
                  hintText: 'https://example.com (full manifest url)',
                  features: [
                    InputFeature.leading(
                      StatedWidget.builder(
                        builder: (context, states) {
                          if (states.hovered) {
                            return const Icon(LucideIcons.shapes);
                          } else {
                            return const Icon(LucideIcons.shapes)
                                .iconMutedForeground();
                          }
                        },
                      ),
                      visibility: InputFeatureVisibility.textEmpty,
                    ),
                    InputFeature.trailing(
                      IconButton(
                        variance: ButtonVariance.text,
                        density: ButtonDensity.iconDense,
                        icon: const Icon(LucideIcons.plus),
                        onPressed: () async {
                          final url = _textController.text.trim();
                          if (url.isEmpty) return;

                          await BackendApi.addUserAddon(url, false);

                          _textController.clear();
                          _reloadAddons();
                        },
                      ),
                    ),
                    InputFeature.clear(
                      visibility:
                          (InputFeatureVisibility.textNotEmpty &
                              InputFeatureVisibility.focused) |
                          (InputFeatureVisibility.textNotEmpty &
                              InputFeatureVisibility.hovered),
                    ),
                  ],
                ),
                Text(
                  'Note: Addon support is very much in alpha',
                  style: TextStyle(
                    fontSize: AppTypography.smallSize,
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
            addonsWidget(),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 8,
              children: [
                _sectionTitle('Recommended widgets'),
                RecommendAddonTile(
                  manfiestUrl: 'https://v3-cinemeta.strem.io/manifest.json',
                  requireConfig: false,
                  onAdded: _reloadAddons,
                ),
                RecommendAddonTile(
                  manfiestUrl: 'https://comet.elfhosted.com/manifest.json',
                  requireConfig: true,
                  onAdded: _reloadAddons,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
