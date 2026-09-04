
import 'package:petal/models/profile.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

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
