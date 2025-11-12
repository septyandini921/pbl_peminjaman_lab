import 'package:flutter/material.dart';
import 'screens/auth/splash_screen.dart';
import 'auth/auth_controller.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  AuthController.instance.initAuthListener();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aplikasi Peminjaman Lab',
      theme: ThemeData(primarySwatch: Colors.indigo),
      home: const SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}