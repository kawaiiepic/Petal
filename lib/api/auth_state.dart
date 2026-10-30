import 'package:petal/models/profile.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

class AuthState extends ChangeNotifier {
  bool loggedIn = false;
  bool initializing = true;

  String? id = "";
  String? email = "";
  String? username = "";
  int? iat = -1;

  Profile? selectedProfile;

  void setLoggedIn(Map<String, dynamic>? jwt) {
    if (jwt != null) {
      loggedIn = true;
      id = jwt['id'];
      email = jwt['email'];
      username = jwt['username'];
      iat = jwt['iat'];
    } else {
      loggedIn = false;
    }
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
