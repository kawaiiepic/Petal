import 'package:flutter/material.dart';

class AuthState extends ChangeNotifier {
  bool loggedIn = false;
  bool traktConnected = false;
  bool initializing = true;

  void setLoggedIn(bool value) {
    loggedIn = value;
    notifyListeners();
  }

  void setTraktLoggedIn(bool value) {
    traktConnected = value;
    notifyListeners();
  }

  void setInitializing(bool value) {
    initializing = value;
    notifyListeners();
  }
}
