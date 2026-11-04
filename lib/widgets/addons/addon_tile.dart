import 'dart:convert';

import 'package:petal/api/backend/backend_api.dart';
import 'package:petal/models/addon.dart';
import 'package:petal/widgets/addons/addon_header.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

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
              child: AddonHeader(
                name: name,
                desc: desc,
                logo: logo,
                actions: [
                  IconButton(
                    variance: ButtonVariance.text,
                    density: ButtonDensity.iconDense,
                    onPressed: () => setState(() => _open = !_open),
                    icon: Icon(
                      _open ? LucideIcons.chevronUp : LucideIcons.chevronDown,
                    ),
                  ),
                  widget.addon.forced == 1
                      ? IconButton(
                          variance: ButtonVariance.text,
                          density: ButtonDensity.iconDense,
                          onPressed: null,
                          icon: const Icon(LucideIcons.lock),
                        )
                      : IconButton(
                          variance: ButtonVariance.text,
                          density: ButtonDensity.iconDense,
                          onPressed: widget.onRemove,
                          icon: const Icon(LucideIcons.circleX),
                        ),
                ],
              ),
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.addon.resources.map((resource) {
                return Toggle(
                  value: !widget.addon.enabledResources.contains(resource.name),
                  child: Text(
                    resource.name[0].toUpperCase() + resource.name.substring(1),
                  ),
                  style: ButtonStyle.primary(density: ButtonDensity.dense),
                  onChanged: (selected) {
                    setState(() {
                      // value is inverted: selected=true means show ON = resource disabled
                      if (selected) {
                        widget.addon.enabledResources.remove(resource.name);
                        BackendApi.delAddonResource(
                          widget.addon.id,
                          resource.name,
                        );
                      } else {
                        widget.addon.enabledResources.add(resource.name);
                        BackendApi.addAddonResource(
                          widget.addon.id,
                          resource.name,
                        );
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
                    style: const TextStyle(
                      decoration: TextDecoration.underline,
                      decorationStyle: TextDecorationStyle.dotted,
                    ),
                  ),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 240),
                    child: SingleChildScrollView(
                      child: SelectableText(
                        const JsonEncoder.withIndent(' ')
                            .convert(widget.addon.manifest),
                        textScaler: const TextScaler.linear(1),
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
