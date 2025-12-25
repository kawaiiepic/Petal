import 'dart:convert';
import 'dart:ui';

import 'package:blssmpetal/models/addon.dart';
import 'package:blssmpetal/api/api.dart';
import 'package:flutter/material.dart';

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

  Widget addonsWidget() {
    toggleAddon(Addon addon) async {}

    return FutureBuilder<List<Addon>>(
      future: Api.addonsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else {
          final addons = snapshot.data!;

          void removeAddon(Addon addon) {
            if (false) return;

            setState(() {
              addons.removeWhere((a) => a.id == addon.id);
            });

            // http.delete(Uri.parse('$ServerUrl/addons/${addon.id}'));
          }

          return ReorderableListView.builder(
            onReorderStart: (index) {
              setState(() {
                print("Start dragging..");
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
              // saveAddonOrder(addons);
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
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text("Addons"),

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
                        onPressed: () {
                          // Handle adding a new addon
                          print('Add button clicked');
                        },
                      ),
                    ],
                  ),
                  labelText: 'Addon URL',
                  hintText: 'https://example.com (full manifest url)',
                  helperText: 'Note: Addon support is very much in alpha',
                  border: OutlineInputBorder(),
                ),
              ),
            ),

            // const SizedBox(width: 8),
          ],
        ),

        Expanded(child: addonsWidget()),
      ],
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
              child: widget.addon.manifest != null && widget.addon.manifest!['logo'] != null
                  ? CircleAvatar(backgroundImage: NetworkImage(widget.addon.manifest?['logo']), backgroundColor: Colors.transparent)
                  : const CircleAvatar(child: Icon(Icons.extension)),
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

                    // Call your backend here if needed
                    // saveAddonResource(widget.addon.id, resource.name, selected);
                  },
                );
              }).toList(),
            ),
            trailing: false ? const Icon(Icons.lock) : IconButton(icon: const Icon(Icons.delete), onPressed: widget.onRemove),
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: SelectableText(JsonEncoder.withIndent('  ').convert(widget.addon.manifest), textScaler: TextScaler.linear(0.8)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
