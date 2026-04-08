import 'package:flutter/material.dart';

class Profile extends StatelessWidget {
  const Profile({super.key});

  @override
  Widget build(BuildContext context) {
    return Text('Profile');
    // return FutureBuilder(
    //   future: TraktApi.userProfile(),
    //   builder: (context, snapshot) {
    //     String tooltip = "Profile";
    //     Widget avatarChild = Icon(Icons.person);

    //     if (snapshot.hasData) {
    //       final profile = snapshot.data!;
    //       tooltip = profile.name;
    //       avatarChild = ClipRRect(borderRadius: BorderRadius.circular(25), child: Image.network(Api.proxyImage( profile.images.avatar.full)));
    //     }

    //     return PopupMenuButton(
    //       tooltip: tooltip,
    //       onSelected: (value) => print(value),
    //       borderRadius: BorderRadius.circular(50),
    //       itemBuilder: (context) => [],
    //       child: CircleAvatar(child: avatarChild),
    //     );
    //   },
    // );
  }
}
