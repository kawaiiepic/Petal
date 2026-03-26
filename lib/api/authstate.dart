import 'package:flutter/material.dart';

class AuthState extends ChangeNotifier {
  bool loggedIn = false;

  void setLoggedIn(bool value) {
    loggedIn = value;
    notifyListeners();
  }
}
