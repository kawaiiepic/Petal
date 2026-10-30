import 'package:flutter/foundation.dart';
import 'package:petal/models/package_license.dart';
import 'package:petal/widgets/back_button.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

class OpenSourceLicensesPage extends StatefulWidget {
  const OpenSourceLicensesPage({
    super.key,
    required this.applicationName,
    required this.applicationVersion,
  });

  final String applicationName;
  final String applicationVersion;

  @override
  State<OpenSourceLicensesPage> createState() => _OpenSourceLicensesPageState();
}

class _OpenSourceLicensesPageState extends State<OpenSourceLicensesPage> {
  late final Future<List<PackageLicense>> _licenses = _load();

  Future<List<PackageLicense>> _load() async {
    final byName = <String, PackageLicense>{};
    await for (final entry in LicenseRegistry.licenses) {
      final text = entry.paragraphs
          .map((paragraph) => paragraph.text)
          .join('\n\n');
      for (final package in entry.packages) {
        byName
            .putIfAbsent(package, () => PackageLicense(package))
            .texts
            .add(text);
      }
    }

    final packages = byName.values.toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return packages;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      headers: [
        AppBar(
          title: const Text('Open Source Licenses'),
          leading: [BackButton()],
        ),
      ],
      child: FutureBuilder<List<PackageLicense>>(
        future: _licenses,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text("Couldn't load licenses"));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final packages = snapshot.data!;
          final version = widget.applicationVersion.isEmpty
              ? ''
              : ' ${widget.applicationVersion}';

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('${widget.applicationName}$version'),
              const SizedBox(height: 4),
              Text('${packages.length} packages'),
              const SizedBox(height: 16),
              Accordion(
                items: [
                  for (final package in packages)
                    AccordionItem(
                      trigger: AccordionTrigger(child: Text(package.name)),
                      content: Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: SelectableText(package.texts.join('\n\n')),
                      ),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
