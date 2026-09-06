import 'dart:convert';

import 'package:petal/api/api_cache.dart';
import 'package:petal/api/misc.dart';
import 'package:petal/api/trakt/backend_api.dart';
import 'package:petal/models/addon.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:http/http.dart' as http;
import 'package:petal/widgets/back_button.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';
import 'package:sizer/sizer.dart';

class Addons extends StatefulWidget {
  const Addons({super.key});

  @override
  State<Addons> createState() => _AddonsState();
}

class _AddonsState extends State<Addons> {
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
          return Center(child: Text('No addons found'));
        } else {
          return SortableLayer(
            child: SortableDropFallback(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 8,
                children: [
                  Text('Installed Widgets'),
                  Accordion(
                    items: [
                      for (int i = 0; i < addons.length; i++)
                        Sortable(
                          data: SortableData(addons[i]),
                          child: AddonTile(key: ValueKey(addons[i].id), addon: addons[i], onRemove: () => removeAddon(addons[i]), isDragging: false),
                        ),
                    ],
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
        AppBar(title: const Text("Addons"), leading: [BackButton()]),
      ],
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          spacing: 30,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              spacing: 8,
              children: [
                Text('Addon URL'),
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
                            return const Icon(LucideIcons.shapes).iconMutedForeground();
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
                          (InputFeatureVisibility.textNotEmpty & InputFeatureVisibility.focused) |
                          (InputFeatureVisibility.textNotEmpty & InputFeatureVisibility.hovered),
                    ),
                  ],
                ),
                Text('Note: Addon support is very much in alpha'),
              ],
            ),
            addonsWidget(),
            Column(
              spacing: 8,
              children: [
                Text('Recommended Widgets'),
                RecommendAddonTile(manfiestUrl: 'https://v3-cinemeta.strem.io/manifest.json', requireConfig: false, onAdded: _reloadAddons),
                RecommendAddonTile(manfiestUrl: 'https://comet.elfhosted.com/manifest.json', requireConfig: true, onAdded: _reloadAddons),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class RecommendAddonTile extends StatefulWidget {
  final String manfiestUrl;
  final bool requireConfig;
  final VoidCallback onAdded;

  const RecommendAddonTile({super.key, required this.manfiestUrl, required this.requireConfig, required this.onAdded});

  @override
  State<StatefulWidget> createState() => _RecommendedAddonTileState();
}

class _RecommendedAddonTileState extends State<RecommendAddonTile> {
  String name = '';
  String desc = '';
  String? logo;
  bool configurable = false;
  bool mustConfigure = false;

  @override
  void initState() {
    super.initState();

    initManifest();
  }

  Future<void> initManifest() async {
    try {
      final manifestRes = await http.get(Uri.parse(widget.manfiestUrl));
      final manifest = jsonDecode(manifestRes.body);

      setState(() {
        name = manifest['name'];
        desc = manifest['description'];
        logo = manifest['logo'];
        // configurable = manifest['behaviorHints']['configurable'];
        // configurable = manifest['behaviorHints']['configurationRequired'];
      });
    } catch (e) {
      throw ("Manifest failed: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Row(
        spacing: 8,
        children: [
          CachedNetworkImage(
            imageUrl: logo ?? '',
            imageBuilder: (context, imageProvider) => Avatar(initials: 'A', provider: imageProvider, backgroundColor: Colors.transparent),
            progressIndicatorBuilder: (context, url, downloadProgress) => CircularProgressIndicator(value: downloadProgress.progress),
            errorWidget: (context, url, error) => Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(24), color: Colors.gray),
              child: Icon(LucideIcons.puzzle),
            ),
          ),

          Text(name),
          Text(desc, style: TextStyle(fontSize: Misc.smallSize)),

          Row(
            children: [
              IconButton(variance: ButtonVariance.text, onPressed: () {}, icon: const Icon(LucideIcons.share)),

              if (widget.requireConfig)
                IconButton(variance: ButtonVariance.text, onPressed: () {}, icon: const Icon(LucideIcons.settings2))
              else
                IconButton(
                  variance: ButtonVariance.text,
                  onPressed: () async {
                    await BackendApi.addUserAddon(widget.manfiestUrl, false);
                    widget.onAdded();
                  },
                  icon: const Icon(LucideIcons.plus),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class AddonTile extends StatefulWidget {
  final Addon addon;
  final VoidCallback onRemove;
  final bool isDragging;

  const AddonTile({super.key, required this.addon, required this.onRemove, this.isDragging = true});

  @override
  State<AddonTile> createState() => _AddonTileState();
}

class _AddonTileState extends State<AddonTile> {
  String name = '';
  String desc = '';
  String? logo;

  @override
  void initState() {
    super.initState();
    initManifest();
  }

  Future<void> initManifest() async {
    setState(() {
      name = widget.addon.manifest?["name"];
      desc = widget.addon.manifest?['description'];
      logo = widget.addon.manifest?['logo'];
    });
  }

  @override
  Widget build(BuildContext context) {
    return AccordionItem(
      trigger: AccordionTrigger(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 8,
          children: [
            Row(
              spacing: 8,
              children: [
                CachedNetworkImage(
                  imageUrl: logo ?? '',
                  imageBuilder: (context, imageProvider) => Avatar(initials: 'A', provider: imageProvider, backgroundColor: Colors.transparent),
                  progressIndicatorBuilder: (context, url, downloadProgress) => CircularProgressIndicator(value: downloadProgress.progress),
                  errorWidget: (context, url, error) => Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(24), color: Colors.gray),
                    child: Icon(LucideIcons.puzzle),
                  ),
                ),
                Text(name),
                Text(desc, style: TextStyle(fontSize: Misc.smallSize)),
                widget.addon.forced == 1
                    ? IconButton(variance: ButtonVariance.text, onPressed: null, icon: const Icon(LucideIcons.lock))
                    : IconButton(variance: ButtonVariance.text, onPressed: widget.onRemove, icon: const Icon(LucideIcons.circleX)),
              ],
            ),
            Wrap(
              spacing: 8,
              children: widget.addon.resources.map((resource) {
                final enabled = widget.addon.enabledResources.contains(resource.name);

                return Toggle(
                  value: enabled,
                  child: Text(resource.name[0].toUpperCase() + resource.name.substring(1)),
                  style: ButtonStyle.primaryIcon(density: ButtonDensity.dense),
                  onChanged: (selected) {
                    setState(() {
                      if (selected) {
                        widget.addon.enabledResources.add(resource.name);
                        BackendApi.addAddonResource(widget.addon.id, resource.name);
                      } else {
                        widget.addon.enabledResources.remove(resource.name);
                        BackendApi.delAddonResource(widget.addon.id, resource.name);
                      }
                    });
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
      content: SizedBox(
        height: 300,
        width: double.infinity,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 8,
              children: [
                Text(
                  widget.addon.manifestUrl,
                  maxLines: 1,
                  style: TextStyle(decoration: TextDecoration.underline, decorationStyle: TextDecorationStyle.dotted),
                ),
                Container(child: SelectableText(JsonEncoder.withIndent(' ').convert(widget.addon.manifest), textScaler: TextScaler.linear(1))),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
