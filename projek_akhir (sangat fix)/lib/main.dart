import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kulinerku/providers/auth_provider.dart';
import 'package:kulinerku/providers/kuliner_provider.dart';
import 'package:kulinerku/providers/network_provider.dart';
import 'package:kulinerku/screens/splash_screen.dart';
import 'package:kulinerku/services/notification_service.dart'; // Import service

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi notifikasi
  await NotificationService.initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => NetworkProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => KulinerProvider()),
      ],
      child: MaterialApp(
        title: 'KulinerKU',
        theme: ThemeData(
          primarySwatch: Colors.orange,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: const SplashScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
