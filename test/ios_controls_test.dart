// ignore: deprecated_member_use
import 'package:flutter/cupertino.dart' as ios;
import 'package:flutter_test/flutter_test.dart';
import 'package:petal/widgets/ios/ios_controls.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

void main() {
  testWidgets('shared controls render Cupertino widgets and forward events', (tester) async {
    var switched = false;
    var pressed = false;
    final controller = TextEditingController();
    await tester.pumpWidget(ShadcnApp(
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
    ));
    expect(find.byType(ios.CupertinoButton), findsOneWidget);
    expect(find.byType(ios.CupertinoTextField), findsOneWidget);
    expect(find.byType(ios.CupertinoSwitch), findsOneWidget);
    expect(find.byType(ios.CupertinoActivityIndicator), findsOneWidget);
    await tester.tap(find.text('Play'));
    await tester.tap(find.byType(ios.CupertinoSwitch));
    await tester.enterText(find.byType(ios.CupertinoTextField), 'Petal');
    expect(pressed, isTrue);
    expect(switched, isTrue);
    expect(controller.text, 'Petal');
    await tester.pumpWidget(const SizedBox.shrink());
    controller.dispose();
  });
}
