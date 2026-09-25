import 'package:petal/widgets/back_button.dart';
import 'package:petal/widgets/overview/title_comments.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

class CommentsPage extends StatelessWidget {
  final String mediaType;
  final int tmdbId;
  final String title;

  const CommentsPage({super.key, required this.mediaType, required this.tmdbId, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      headers: [
        AppBar(leading: const [BackButton()], title: Text(title)),
      ],
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [TitleComments(mediaType: mediaType, tmdbId: tmdbId)],
      ),
    );
  }
}
