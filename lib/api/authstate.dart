import 'package:flutter/material.dart';
import 'package:petal/models/profile.dart';

class AuthState extends ChangeNotifier {
  bool loggedIn = false;
  bool initializing = true;
  Profile? selectedProfile;

  void setLoggedIn(bool value) {
    loggedIn = value;
    notifyListeners();
  }

  void setInitializing(bool value) {
    initializing = value;
    notifyListeners();
  }

  void setProfile(Profile profile) {
    selectedProfile = profile;
    notifyListeners();
  }
}
