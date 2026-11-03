import 'dart:convert';

import 'package:petal/api/backend/backend_api.dart';
import 'package:petal/api/query_proxy.dart';
import 'package:petal/widgets/addons/addon_header.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

class RecommendAddonTile extends StatefulWidget {
  final String manfiestUrl;
  final bool requireConfig;
  final VoidCallback onAdded;

  const RecommendAddonTile({
    super.key,
    required this.manfiestUrl,
    required this.requireConfig,
    required this.onAdded,
  });

  @override
  State<StatefulWidget> createState() => _RecommendAddonTileState();
}

class _RecommendAddonTileState extends State<RecommendAddonTile> {
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
      final manifestRes = await BackendApi.dio.get(
        QueryProxy.wrap(widget.manfiestUrl),
      );
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
        child: AddonHeader(
          name: name,
          desc: desc,
          logo: logo,
          actions: [
            IconButton(
              variance: ButtonVariance.text,
              density: ButtonDensity.iconDense,
              onPressed: () {},
              icon: const Icon(LucideIcons.share),
            ),
            if (widget.requireConfig)
              IconButton(
                variance: ButtonVariance.text,
                density: ButtonDensity.iconDense,
                onPressed: () {},
                icon: const Icon(LucideIcons.settings2),
              )
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
