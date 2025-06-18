// import 'package:flutter/material.dart';
// import 'package:connectivity_plus/connectivity_plus.dart';
// import 'package:kulinerku/services/notification_service.dart'; // Import service
// import 'dart:async';

// class NetworkProvider with ChangeNotifier {
//   bool _isOnline = true;
//   bool _wasOnline = true; // Untuk melacak perubahan status
//   final Connectivity _connectivity = Connectivity();

//   // Stream controller untuk memungkinkan komponen lain mendengarkan status koneksi
//   final StreamController<bool> _connectionStatusController =
//       StreamController<bool>.broadcast();
//   Stream<bool> get connectionStatusStream => _connectionStatusController.stream;

//   bool get isOnline => _isOnline;

//   NetworkProvider() {
//     _initConnectivity();
//     _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
//   }

//   Future<void> _initConnectivity() async {
//     try {
//       final result = await _connectivity.checkConnectivity();
//       _updateConnectionStatus(result);
//     } catch (e) {
//       _isOnline = false;
//       _wasOnline = false;
//       notifyListeners();
//       _connectionStatusController.add(false);
//     }
//   }

//   void _updateConnectionStatus(ConnectivityResult result) {
//     _wasOnline = _isOnline; // Simpan status sebelumnya
//     _isOnline = result != ConnectivityResult.none;

//     // Hanya tampilkan notifikasi jika status berubah
//     if (_wasOnline != _isOnline) {
//       _showConnectivityNotification(_isOnline);
//     }

//     notifyListeners();
//     _connectionStatusController.add(_isOnline);
//   }

//   // Menampilkan notifikasi status koneksi menggunakan flutter_local_notifications
//   Future<void> _showConnectivityNotification(bool isConnected) async {
//     await NotificationService.showNotification(
//       id: 4,
//       title: isConnected ? 'Terhubung ke Internet' : 'Tidak Ada Koneksi',
//       body: isConnected
//           ? 'KulinerKU sekarang online, semua fitur tersedia'
//           : 'KulinerKU dalam mode offline, beberapa fitur mungkin tidak tersedia',
//     );
//   }

//   @override
//   void dispose() {
//     _connectionStatusController.close();
//     super.dispose();
//   }
// }

// lib/providers/network_provider.dart
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';
import 'package:kulinerku/services/notification_service.dart';

class NetworkProvider with ChangeNotifier {
  bool _isOnline = true;
  ConnectivityResult _connectionType = ConnectivityResult.none;
  final Connectivity _connectivity = Connectivity();

  NetworkProvider() {
    _initConnectivity();
    _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
  }

  // Getter
  bool get isOnline => _isOnline;
  ConnectivityResult get connectionType => _connectionType;

  String get connectionName {
    switch (_connectionType) {
      case ConnectivityResult.wifi:
        return 'WiFi';
      case ConnectivityResult.mobile:
        return 'Data Seluler';
      default:
        return 'Tidak Ada Koneksi';
    }
  }

  IconData get connectionIcon {
    switch (_connectionType) {
      case ConnectivityResult.wifi:
        return Icons.wifi;
      case ConnectivityResult.mobile:
        return Icons.signal_cellular_4_bar;
      default:
        return Icons.signal_cellular_off;
    }
  }

  Color get connectionColor {
    switch (_connectionType) {
      case ConnectivityResult.wifi:
        return Colors.green;
      case ConnectivityResult.mobile:
        return Colors.blue;
      default:
        return Colors.red;
    }
  }

  Future<void> _initConnectivity() async {
    try {
      final result = await _connectivity.checkConnectivity();
      _updateConnectionStatus(result);
    } catch (e) {
      _isOnline = false;
      _connectionType = ConnectivityResult.none;
      notifyListeners();
    }
  }

  void _updateConnectionStatus(ConnectivityResult result) {
    _connectionType = result;
    _isOnline = result != ConnectivityResult.none;

    // Opsional: Tampilkan notifikasi saat status koneksi berubah
    _showConnectivityNotification();

    notifyListeners();
  }

  // Menampilkan notifikasi status koneksi
  void _showConnectivityNotification() {
    String title, body;
    int notificationId;

    switch (_connectionType) {
      case ConnectivityResult.wifi:
        notificationId = 1;
        title = 'Terhubung ke WiFi';
        body = 'Anda sedang menggunakan WiFi';
        break;
      case ConnectivityResult.mobile:
        notificationId = 2;
        title = 'Terhubung ke Data Seluler';
        body = 'Anda sedang menggunakan data seluler';
        break;
      default:
        notificationId = 3;
        title = 'Tidak Ada Koneksi';
        body = 'Anda sedang offline';
    }

    NotificationService.showNotification(
      id: notificationId, // Parameter id yang diperlukan
      title: title,
      body: body,
    );
  }
}
