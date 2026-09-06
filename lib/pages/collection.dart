import 'package:petal/widgets/back_button.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

class Collection extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _Collection();
}

class _Collection extends State<Collection> {
  int index = 0;

  @override
  Widget build(BuildContext context) => Scaffold(
    headers: [
      AppBar(
        // title: const Text("Addons"),
        leadingGap: 30,
        leading: [
          BackButton(),
          Text('Collection'),
          Tabs(
            // Bind the active tab index; Tabs is the header-only control.
            index: index,
            children: const [
              TabItem(child: Text('Tab 1')),
              TabItem(child: Text('Tab 2')),
              TabItem(child: Text('Tab 3')),
            ],
            onChanged: (int value) {
              // Keep header and body in sync by updating state.
              setState(() {
                index = value;
              });
            },
          ),
          Select<String>(
            itemBuilder: (context, item) {
              return Text(item);
            },
            popup: const SelectPopup(),
          ),
        ],
      ),
    ],
    child: Text(''),
  );
}

class WatchList extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Text('');
}
