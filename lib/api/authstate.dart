import 'package:flutter/material.dart';

class AuthState extends ChangeNotifier {
  bool loggedIn = false;
  bool traktConnected = false;

  void setLoggedIn(bool value) {
    loggedIn = value;
    notifyListeners();
  }

  void setTraktLoggedIn(bool value) {
    traktConnected = value;
    notifyListeners();
  }
}
