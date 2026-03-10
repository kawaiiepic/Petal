import 'package:blssmpetal/api/trakt/trakt.dart';
import 'package:flutter/material.dart';

class Profile extends StatelessWidget {
  const Profile({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: Trakt.userProfile(),
      builder: (context, snapshot) {
        String tooltip = "Profile"; // default tooltip
        Widget avatarChild = Icon(Icons.person);

        if (snapshot.hasData) {
          final profile = snapshot.data!;
          tooltip = profile.name; // set tooltip to username
          avatarChild = ClipRRect(borderRadius: BorderRadius.circular(25), child: Image.network(profile.images.avatar.full));
        }

        return PopupMenuButton(
          tooltip: tooltip, // directly set tooltip here
          onSelected: (value) => print(value),
          borderRadius: BorderRadius.circular(50),
          itemBuilder: (context) => [],
          child: CircleAvatar(child: avatarChild),
        );
      },
    );
  }
}
