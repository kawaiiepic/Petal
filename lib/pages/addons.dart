import 'dart:convert';
import 'dart:ui';
import 'package:petal/api/api_cache.dart';
import 'package:petal/api/trakt/backend_api.dart';
import 'package:petal/models/addon.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:http/http.dart' as http;
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

class Addons extends StatefulWidget {
  const Addons({super.key});

  @override
  State<Addons> createState() => _AddonsState();
}

class _AddonsState extends State<Addons> {
  final _textController = TextEditingController();
  int? _draggingIndex;
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

        void removeAddon(Addon addon) {
          setState(() {
            addons.removeWhere((a) => a.id == addon.id);
          });
        }

        if (addons.isEmpty) {
          return Center(child: Text('No addons found'));
        } else {
          return SortableLayer(
            child: SortableDropFallback(
              child: Column(
                children: [
                  for (int i = 0; i < addons.length; i++)
                    Sortable(
                      data: SortableData(addons[i]),
                      child: AddonTile(key: ValueKey(addons[i].id), addon: addons[i], onRemove: () => removeAddon(addons[i]), isDragging: false),
                    ),
                ],
              ),
            ),
          );
          // return ReorderableListView.builder(
          //   shrinkWrap: true,
          //   physics: const NeverScrollableScrollPhysics(),
          //   onReorderStart: (index) {
          //     setState(() {
          //       _draggingIndex = index;
          //     });
          //   },
          //   onReorderEnd: (index) {
          //     setState(() {
          //       _draggingIndex = null;
          //     });
          //   },
          //   onReorder: (oldIndex, newIndex) {
          //     setState(() {
          //       if (newIndex > oldIndex) newIndex -= 1;
          //       final item = addons.removeAt(oldIndex);
          //       addons.insert(newIndex, item);
          //     });
          //   },
          //   itemCount: addons.length,
          //   proxyDecorator: (child, index, animation) {
          //     final t = Curves.easeOut.transform(animation.value);
          //     return Material(
          //       elevation: lerpDouble(0, 8, t)!,
          //       color: Colors.transparent,
          //       child: Transform.scale(scale: lerpDouble(1.0, 1.03, t)!, child: child),
          //     );
          //   },
          //   buildDefaultDragHandles: false,
          //   itemBuilder: (context, index) {
          //     final addon = addons[index];
          //     return AddonTile(key: ValueKey(addon.id), addon: addon, onRemove: () => removeAddon(addon), isDragging: _draggingIndex == index);
          //   },
          // );
        }
      }
    },
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      headers: [AppBar(title: const Text("Addons"))],
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          spacing: 30,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
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
                            return const Icon(Icons.search);
                          } else {
                            return const Icon(Icons.search).iconMutedForeground();
                          }
                        },
                      ),
                      visibility: InputFeatureVisibility.textEmpty,
                    ),
                    InputFeature.trailing(
                      IconButton(
                        variance: ButtonVariance.text,
                        density: ButtonDensity.iconDense,
                        icon: const Icon(Icons.add),
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
                  // decoration: InputDecoration(
                  //   prefixIcon: Icon(Icons.search),
                  //   suffixIcon: Row(
                  //     mainAxisSize: MainAxisSize.min, // important to avoid stretching
                  //     children: [
                  //       IconButton(icon: const Icon(Icons.clear), onPressed: () => _textController.clear()),
                  //       IconButton(
                  //         icon: const Icon(Icons.add),
                  //         onPressed: () async {
                  //           final url = _textController.text.trim();
                  //           if (url.isEmpty) return;

                  //           await BackendApi.addUserAddon(url, false);

                  //           _textController.clear();
                  //           _reloadAddons();
                  //         },
                  //       ),
                  //     ],
                  //   ),
                  //   labelText: 'Addon URL',
                  //   hintText: 'https://example.com (full manifest url)',
                  //   helperText: 'Note: Addon support is very much in alpha',
                  //   border: OutlineInputBorder(borderRadius: BorderRadius.circular(50)),
                  // ),
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
        children: [
          if (logo != null)
            CachedNetworkImage(
              imageUrl: logo!,
              imageBuilder: (context, imageProvider) => Avatar(initials: 'A', provider: imageProvider, backgroundColor: Colors.transparent),
              progressIndicatorBuilder: (context, url, downloadProgress) => CircularProgressIndicator(value: downloadProgress.progress),
            )
          else
            Avatar(initials: 'A'),

          Text(name),
          Text(desc),

          Row(
            children: [
              IconButton(variance: ButtonVariance.text, onPressed: () {}, icon: const Icon(Icons.share)),

              if (widget.requireConfig)
                IconButton(variance: ButtonVariance.text, onPressed: () {}, icon: const Icon(Icons.settings))
              else
                IconButton(
                  variance: ButtonVariance.text,
                  onPressed: () async {
                    await BackendApi.addUserAddon(widget.manfiestUrl, false);
                    widget.onAdded();
                  },
                  icon: const Icon(Icons.add),
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
  late final CachedNetworkImage? _image;

  @override
  void initState() {
    super.initState();
    _image = widget.addon.manifest?['logo'] != null
        ? CachedNetworkImage(
            imageUrl: widget.addon.manifest?['logo'],
            imageBuilder: (context, imageProvider) => Avatar(initials: 'Addon', provider: imageProvider, backgroundColor: Colors.transparent),
            progressIndicatorBuilder: (context, url, downloadProgress) => CircularProgressIndicator(value: downloadProgress.progress),
          )
        : null;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      transform: widget.isDragging ? Matrix4.identity().scaledByDouble(0, 0, 0, 1.03) : Matrix4.identity(),
      child: Opacity(
        opacity: widget.isDragging ? 0.2 : 1,
        child: Card(
          child: Collapsible(children: [
            CollapsibleTrigger(child: Text(widget.addon.manifest?["name"] ?? 'Name Here')),
            // CollapsibleContent(child: child)

            ]),
        ),
      ),
    );
    // return AnimatedContainer(
    //   duration: const Duration(milliseconds: 200),
    //   curve: Curves.easeOut,
    //   transform: widget.isDragging ? Matrix4.identity().scaledByDouble(0, 0, 0, 1.03) : Matrix4.identity(),
    //   child: Opacity(
    //     opacity: widget.isDragging ? 0.2 : 1,
    //     child: Card(
    //       elevation: widget.isDragging ? 8 : 2,
    //       margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    //       child: ExpansionTile(
    //         leading: ReorderableDragStartListener(
    //           index: 0, // ignored when using builder
    //           child: _image ?? CircleAvatar(child: Icon(Icons.extension)),
    //         ),
    //         title: Text(widget.addon.manifest?["name"] ?? 'Name Here'),
    //         subtitle: Wrap(
    //           spacing: 8,
    //           runSpacing: 4,
    //           children: widget.addon.resources.map((resource) {
    //             final enabled = widget.addon.enabledResources.contains(resource.name);

    //             return FilterChip(
    //               label: Text(resource.name.toUpperCase()),
    //               selected: enabled,
    //               onSelected: (selected) {
    //                 setState(() {
    //                   if (selected) {
    //                     widget.addon.enabledResources.add(resource.name);
    //                     BackendApi.addAddonResource(widget.addon.id, resource.name);
    //                   } else {
    //                     widget.addon.enabledResources.remove(resource.name);
    //                     BackendApi.delAddonResource(widget.addon.id, resource.name);
    //                   }
    //                 });
    //               },
    //             );
    //           }).toList(),
    //         ),
    //         trailing: widget.addon.forced == 0
    //             ? IconButton(variance: ButtonVariance.menubar, icon: const Icon(Icons.lock), onPressed: null)
    //             : IconButton(variance: ButtonVariance.menubar, icon: const Icon(Icons.delete), onPressed: widget.onRemove),
    //         children: [
    //           SizedBox(
    //             height: 300,
    //             width: double.infinity,
    //             child: Padding(
    //               padding: const EdgeInsets.all(12),
    //               child: SingleChildScrollView(
    //                 child: Container(
    //                   color: Colors.black.withAlpha(40),
    //                   child: SelectableText(JsonEncoder.withIndent(' ').convert(widget.addon.manifest), textScaler: TextScaler.linear(1)),
    //                 ),
    //               ),
    //             ),
    //           ),
    //         ],
    //       ),
    //     ),
    //   ),
    // );
  }
}
