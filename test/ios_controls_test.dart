import 'package:liquid_glass_widgets/liquid_glass_widgets.dart' as glass;
import 'package:flutter_test/flutter_test.dart';
import 'package:petal/widgets/ios/ios_controls.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

void main() {
  testWidgets('shared controls render Liquid Glass widgets and forward events', (tester) async {
    var switched = false;
    var pressed = false;
    final controller = TextEditingController();
    await tester.pumpWidget(glass.LiquidGlassWidgets.wrap(
      theme: glass.GlassThemeData.simple(quality: glass.GlassQuality.minimal),
      child: ShadcnApp(
      home: Scaffold(
        child: Column(
          children: [
            PetalButton.primary(onPressed: () => pressed = true, child: const Text('Play')),
            PetalTextField(controller: controller, placeholder: const Text('Search')),
            PetalSwitch(value: false, onChanged: (value) => switched = value),
            const PetalActivityIndicator(),
          ],
        ),
      ),
    )));
    expect(find.byType(glass.GlassButton), findsOneWidget);
    expect(find.byType(glass.GlassTextField), findsOneWidget);
    expect(find.byType(glass.GlassSwitch), findsOneWidget);
    expect(find.byType(glass.GlassProgressIndicator), findsOneWidget);
    await tester.tap(find.text('Play'));
    await tester.tap(find.byType(glass.GlassSwitch));
    await tester.enterText(find.byType(EditableText), 'Petal');
    expect(pressed, isTrue);
    expect(switched, isTrue);
    expect(controller.text, 'Petal');
    await tester.pumpWidget(const SizedBox.shrink());
    controller.dispose();
  });
}
