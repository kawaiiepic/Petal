import 'package:flutter/material.dart';

class Profile extends StatelessWidget {
  const Profile({super.key});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton(
      onSelected: (value) {
        print(value);
      },
      borderRadius: BorderRadius.circular(50),
      itemBuilder: (context) => [],
      child: SizedBox(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(50),
          child: Material(
            child: Ink.image(
              fit: BoxFit.fill,
              width: 45,
              height: 45,
              image: AssetImage('assets/images/profileExample.jpg'),
              child: InkWell(onTap: () {}),
            ),
          ),
        ),
      ),
    );
  }
}
