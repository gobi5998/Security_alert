import 'package:flutter/material.dart';

class AuthProvider with ChangeNotifier {
  bool _isLoggedIn = false;

  bool get isLoggedIn => _isLoggedIn;
  bool _isRegistered = false;

  bool get isRegistered => _isRegistered;

  void login(String username, String password) {
    // TODO: Add real authentication logic here
    if (username.isNotEmpty && password.isNotEmpty) {
      _isLoggedIn = true;
      notifyListeners();
    }
  }


    void register(String username, String email, String password) {
      // Simulate a successful registration
      if (username.isNotEmpty && email.isNotEmpty && password.length >= 8) {
        _isRegistered = true;
        notifyListeners();
      }
    }

  void reset() {
    _isRegistered = false;
    notifyListeners();
  }

  void logout() {
    _isLoggedIn = false;
    notifyListeners();
  }
}

