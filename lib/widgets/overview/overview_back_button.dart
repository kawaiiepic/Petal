import 'package:petal/widgets/back_button.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

/// Artwork stays edge-to-edge while the control clears notches and status bars.
class OverviewBackButton extends StatelessWidget {
  const OverviewBackButton({super.key});

  @override
  Widget build(BuildContext context) => Positioned(
    top: 0,
    left: 0,
    right: 0,
    child: SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
        child: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: 44,
            height: 44,
            child: Semantics(
              label: 'Back',
              button: true,
              child: const BackButton(),
            ),
          ),
        ),
      ),
    ),
  );
}
