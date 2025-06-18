// import 'package:flutter/material.dart';
// import 'package:appwrite/appwrite.dart';
// import 'package:appwrite/models.dart';
// import 'package:kulinerku/services/appwrite_service.dart';
// import 'package:shared_preferences/shared_preferences.dart';
//
// class AuthProvider with ChangeNotifier {
//   User? _user;
//   bool _isLoading = false;
//   String? _error;
//
//   User? get user => _user;
//   bool get isLoading => _isLoading;
//   String? get error => _error;
//   bool get isAuthenticated => _user != null;
//
//   Future<void> checkAuthStatus() async {
//     _setLoading(true);
//     try {
//       _user = await AppwriteService.account.get();
//       _error = null;
//     } catch (e) {
//       _user = null;
//       _error = null; // Don't show error for initial check
//     }
//     _setLoading(false);
//   }
//
//   Future<bool> register(String email, String password, String name) async {
//     _setLoading(true);
//     try {
//       await AppwriteService.account.create(
//         userId: ID.unique(),
//         email: email,
//         password: password,
//         name: name,
//       );
//
//       // Auto login after registration
//       await AppwriteService.account.createEmailPasswordSession(
//         email: email,
//         password: password,
//       );
//
//       _user = await AppwriteService.account.get();
//       _error = null;
//       _setLoading(false);
//       return true;
//     } catch (e) {
//       _error = e.toString();
//       _setLoading(false);
//       return false;
//     }
//   }
//
//   Future<bool> login(String email, String password) async {
//     _setLoading(true);
//     try {
//       await AppwriteService.account.createEmailPasswordSession(
//         email: email,
//         password: password,
//       );
//
//       _user = await AppwriteService.account.get();
//       _error = null;
//       _setLoading(false);
//       return true;
//     } catch (e) {
//       _error = e.toString();
//       _setLoading(false);
//       return false;
//     }
//   }
//
//   Future<void> logout() async {
//     _setLoading(true);
//     try {
//       await AppwriteService.account.deleteSession(sessionId: 'current');
//       _user = null;
//       _error = null;
//
//       // Clear local storage
//       final prefs = await SharedPreferences.getInstance();
//       await prefs.clear();
//     } catch (e) {
//       _error = e.toString();
//     }
//     _setLoading(false);
//   }
//
//   void clearError() {
//     _error = null;
//     notifyListeners();
//   }
//
//   void _setLoading(bool loading) {
//     _isLoading = loading;
//     notifyListeners();
//   }
// }

import 'package:flutter/material.dart';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';
import 'package:kulinerku/services/appwrite_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider with ChangeNotifier {
  User? _user;
  bool _isLoading = false;
  String? _error;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;

  Future<void> checkAuthStatus() async {
    _setLoading(true);
    try {
      _user = await AppwriteService.account.get();
      _error = null;
    } catch (e) {
      _user = null;
      _error = null; // Don't show error for initial check
    }
    _setLoading(false);
  }

  Future<bool> register(String email, String password, String name) async {
    _setLoading(true);
    try {
      await AppwriteService.account.create(
        userId: ID.unique(),
        email: email,
        password: password,
        name: name,
      );

      // Auto login after registration
      await AppwriteService.account.createEmailPasswordSession(
        email: email,
        password: password,
      );

      _user = await AppwriteService.account.get();
      _error = null;
      _setLoading(false);
      return true;
    } catch (e) {
      _error = _formatError(e);
      _setLoading(false);
      return false;
    }
  }

  Future<bool> login(String email, String password) async {
    _setLoading(true);
    try {
      await AppwriteService.account.createEmailPasswordSession(
        email: email,
        password: password,
      );

      _user = await AppwriteService.account.get();
      _error = null;
      _setLoading(false);
      return true;
    } catch (e) {
      _error = _formatError(e);
      _setLoading(false);
      return false;
    }
  }

  // Helper method to format error messages
  String _formatError(dynamic error) {
    if (error is AppwriteException) {
      // Check for specific Appwrite error codes
      switch (error.code) {
        case 401: // Unauthorized
          return 'Email atau password salah';
        case 429: // Too many requests
          return 'Terlalu banyak percobaan, silakan coba lagi nanti';
        case 404: // Not found
          return 'Akun tidak ditemukan';
        case 400: // Bad request
          if (error.message != null) {
            if (error.message!.contains('password')) {
              return 'Password tidak valid';
            } else if (error.message!.contains('email')) {
              return 'Email tidak valid';
            }
          }
          return error.message ?? 'Terjadi kesalahan';
        default:
          return 'Gagal login: ${error.message ?? 'Terjadi kesalahan'}';
      }
    }
    return error.toString();
  }

  Future<void> logout() async {
    _setLoading(true);
    try {
      await AppwriteService.account.deleteSession(sessionId: 'current');
      _user = null;
      _error = null;

      // Clear local storage
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    } catch (e) {
      _error = _formatError(e);
    }
    _setLoading(false);
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
}
