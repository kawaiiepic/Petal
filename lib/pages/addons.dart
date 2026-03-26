import 'dart:convert';
import 'dart:ui';
import 'package:blssmpetal/api/api_cache.dart';
import 'package:blssmpetal/api/trakt/trakt_helper.dart';
import 'package:blssmpetal/models/addon.dart';
import 'package:blssmpetal/api/api.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class Addons extends StatefulWidget {
  const Addons({super.key});

  @override
  State<Addons> createState() => _AddonsState();
}

class _AddonsState extends State<Addons> {
  final _textController = TextEditingController();
  int? _draggingIndex;

  @override
  void initState() {
    super.initState();
  }

  Widget addonsWidget() => FutureBuilder(
    future: ApiCache.getAddons(),
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
          return ReorderableListView.builder(
            onReorderStart: (index) {
              setState(() {
                _draggingIndex = index;
              });
            },
            onReorderEnd: (index) {
              setState(() {
                _draggingIndex = null;
              });
            },
            onReorder: (oldIndex, newIndex) {
              setState(() {
                if (newIndex > oldIndex) newIndex -= 1;
                final item = addons.removeAt(oldIndex);
                addons.insert(newIndex, item);
              });
            },
            itemCount: addons.length,
            proxyDecorator: (child, index, animation) {
              final t = Curves.easeOut.transform(animation.value);
              return Material(
                elevation: lerpDouble(0, 8, t)!,
                color: Colors.transparent,
                child: Transform.scale(scale: lerpDouble(1.0, 1.03, t)!, child: child),
              );
            },
            buildDefaultDragHandles: false,
            itemBuilder: (context, index) {
              final addon = addons[index];
              return AddonTile(key: ValueKey(addon.id), addon: addon, onRemove: () => removeAddon(addon), isDragging: _draggingIndex == index);
            },
          );
        }
      }
    },
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Addons")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    decoration: InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      suffixIcon: Row(
                        mainAxisSize: MainAxisSize.min, // important to avoid stretching
                        children: [
                          IconButton(icon: const Icon(Icons.clear), onPressed: () => _textController.clear()),
                          IconButton(
                            icon: const Icon(Icons.add),
                            onPressed: () async {
                              final url = _textController.text.trim();
                              if (url.isEmpty) return;

                              try {
                                final manifestRes = await http.get(Uri.parse(url));
                                final manifest = jsonDecode(manifestRes.body);

                                final addon = {
                                  "id": manifest["id"],
                                  "name": manifest["name"],
                                  "manifestUrl": url,
                                  "icon": manifest["logo"],
                                  "enabledResources": ["stream"],
                                  "forced": 0,
                                  "config": {},
                                };

                                // await TraktApi.dio.post(
                                //   "${Api.ServerUrl}/addons/set",
                                //   headers: {"Content-Type": "application/json"},
                                //   body: jsonEncode({
                                //     "addons": [addon],
                                //   }),
                                // );

                                ApiCache.refreshAddons();

                                _textController.clear();
                              } catch (e) {
                                throw ("Addon add failed: $e");
                              }
                            },
                          ),
                        ],
                      ),
                      labelText: 'Addon URL',
                      hintText: 'https://example.com (full manifest url)',
                      helperText: 'Note: Addon support is very much in alpha',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(50)),
                    ),
                  ),
                ),
              ],
            ),
            Expanded(child: addonsWidget()),
          ],
        ),
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
    _image = widget.addon.manifest?['logo'] != null ? CachedNetworkImage(
      imageUrl: Api.proxyImage(widget.addon.manifest?['logo']),
      imageBuilder: (context, imageProvider) => CircleAvatar(foregroundImage: imageProvider, backgroundColor: Colors.transparent),
      progressIndicatorBuilder: (context, url, downloadProgress) => CircularProgressIndicator(value: downloadProgress.progress),
      errorWidget: (context, url, error) => CircleAvatar(child: Icon(Icons.extension)),
    ) : null;
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
          elevation: widget.isDragging ? 8 : 2,
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: ExpansionTile(
            leading: ReorderableDragStartListener(
              index: 0, // ignored when using builder
              child: _image ?? CircleAvatar(child: Icon(Icons.extension)),
            ),
            title: Text(widget.addon.name),
            subtitle: Wrap(
              spacing: 8,
              runSpacing: 4,
              children: widget.addon.resources.map((resource) {
                final enabled = widget.addon.enabledResources.contains(resource.name);

                return FilterChip(
                  label: Text(resource.name.toUpperCase()),
                  selected: enabled,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        widget.addon.enabledResources.add(resource.name);
                      } else {
                        widget.addon.enabledResources.remove(resource.name);
                      }
                    });
                  },
                );
              }).toList(),
            ),
            trailing: widget.addon.forced == 1
                ? IconButton(icon: const Icon(Icons.lock), onPressed: null)
                : IconButton(icon: const Icon(Icons.delete), onPressed: widget.onRemove),
            children: [
              SizedBox(
                height: 300,
                width: double.infinity,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: SingleChildScrollView(
                    child: Container(
                      color: Colors.black.withAlpha(40),
                      child: SelectableText(JsonEncoder.withIndent(' ').convert(widget.addon.manifest), textScaler: TextScaler.linear(1)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
