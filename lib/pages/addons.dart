import 'dart:convert';

import 'package:petal/api/api_cache.dart';
import 'package:petal/api/misc.dart';
import 'package:petal/api/query_proxy.dart';
import 'package:petal/api/trakt/backend_api.dart';
import 'package:petal/models/addon.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:petal/widgets/back_button.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

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
            child: Text('No addons found', style: TextStyle(color: Colors.white.withValues(alpha: 0.6))),
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
                      child: AddonTile(key: ValueKey(addons[i].id), addon: addons[i], onRemove: () => removeAddon(addons[i])),
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
                Text('Note: Addon support is very much in alpha', style: TextStyle(fontSize: Misc.smallSize, color: Colors.white.withValues(alpha: 0.6))),
              ],
            ),
            addonsWidget(),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 8,
              children: [
                _sectionTitle('Recommended widgets'),
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

class _AddonLogo extends StatelessWidget {
  final String? logo;

  const _AddonLogo({this.logo});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      height: 40,
      child: CachedNetworkImage(
        imageUrl: logo ?? '',
        imageBuilder: (context, imageProvider) => Avatar(initials: 'A', provider: imageProvider, backgroundColor: Colors.transparent),
        progressIndicatorBuilder: (context, url, downloadProgress) => CircularProgressIndicator(value: downloadProgress.progress),
        errorWidget: (context, url, error) => Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(24), color: Colors.gray),
          child: const Icon(LucideIcons.puzzle),
        ),
      ),
    );
  }
}

class _AddonHeader extends StatelessWidget {
  final String name;
  final String desc;
  final String? logo;
  final List<Widget> actions;

  const _AddonHeader({required this.name, required this.desc, this.logo, required this.actions});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _AddonLogo(logo: logo),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name.isEmpty ? 'Loading...' : name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
              if (desc.isNotEmpty)
                Text(
                  desc,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: Misc.smallSize, color: Colors.white.withValues(alpha: 0.65)),
                ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Row(mainAxisSize: MainAxisSize.min, children: actions),
      ],
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

  @override
  void initState() {
    super.initState();
    initManifest();
  }

  Future<void> initManifest() async {
    try {
      final manifestRes = await BackendApi.dio.get(QueryProxy.wrap(widget.manfiestUrl));
      final raw = manifestRes.data;
      final manifest = raw is Map<String, dynamic>
          ? raw
          : raw is Map
          ? Map<String, dynamic>.from(raw)
          : jsonDecode(raw as String) as Map<String, dynamic>;

      setState(() {
        name = manifest['name']?.toString() ?? '';
        desc = manifest['description']?.toString() ?? '';
        logo = manifest['logo']?.toString();
      });
    } catch (e) {
      throw ('Manifest failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: _AddonHeader(
          name: name,
          desc: desc,
          logo: logo,
          actions: [
            IconButton(variance: ButtonVariance.text, density: ButtonDensity.iconDense, onPressed: () {}, icon: const Icon(LucideIcons.share)),
            if (widget.requireConfig)
              IconButton(variance: ButtonVariance.text, density: ButtonDensity.iconDense, onPressed: () {}, icon: const Icon(LucideIcons.settings2))
            else
              IconButton(
                variance: ButtonVariance.text,
                density: ButtonDensity.iconDense,
                onPressed: () async {
                  await BackendApi.addUserAddon(widget.manfiestUrl, false);
                  widget.onAdded();
                },
                icon: const Icon(LucideIcons.plus),
              ),
          ],
        ),
      ),
    );
  }
}

class AddonTile extends StatefulWidget {
  final Addon addon;
  final VoidCallback onRemove;

  const AddonTile({super.key, required this.addon, required this.onRemove});

  @override
  State<AddonTile> createState() => _AddonTileState();
}

class _AddonTileState extends State<AddonTile> {
  String name = '';
  String desc = '';
  String? logo;
  bool _open = false;

  @override
  void initState() {
    super.initState();
    initManifest();
  }

  Future<void> initManifest() async {
    setState(() {
      name = widget.addon.manifest?['name']?.toString() ?? '';
      desc = widget.addon.manifest?['description']?.toString() ?? '';
      logo = widget.addon.manifest?['logo']?.toString();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 10,
          children: [
            GestureDetector(
              onTap: () => setState(() => _open = !_open),
              child: _AddonHeader(
                name: name,
                desc: desc,
                logo: logo,
                actions: [
                  IconButton(
                    variance: ButtonVariance.text,
                    density: ButtonDensity.iconDense,
                    onPressed: () => setState(() => _open = !_open),
                    icon: Icon(_open ? LucideIcons.chevronUp : LucideIcons.chevronDown),
                  ),
                  widget.addon.forced == 1
                      ? IconButton(variance: ButtonVariance.text, density: ButtonDensity.iconDense, onPressed: null, icon: const Icon(LucideIcons.lock))
                      : IconButton(variance: ButtonVariance.text, density: ButtonDensity.iconDense, onPressed: widget.onRemove, icon: const Icon(LucideIcons.circleX)),
                ],
              ),
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.addon.resources.map((resource) {
                final enabled = widget.addon.enabledResources.contains(resource.name);
                return Toggle(
                  value: !enabled,
                  child: Text(resource.name[0].toUpperCase() + resource.name.substring(1)),
                  style: ButtonStyle.primary(density: ButtonDensity.dense),
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
            if (_open)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 8,
                children: [
                  Text(
                    widget.addon.manifestUrl,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(decoration: TextDecoration.underline, decorationStyle: TextDecorationStyle.dotted),
                  ),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 240),
                    child: SingleChildScrollView(
                      child: SelectableText(const JsonEncoder.withIndent(' ').convert(widget.addon.manifest), textScaler: const TextScaler.linear(1)),
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
