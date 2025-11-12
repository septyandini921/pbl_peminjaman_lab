import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../auth/auth_controller.dart';
import 'login_screen.dart';

import '../student/home_screen.dart' as StudentHomeScreen;
import '../admin/home_screen.dart' as AdminHomeScreen;

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateUser();
  }

  Future<void> _navigateUser() async {
    await Future.delayed(const Duration(seconds: 2));

    User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
      return; 
    }

    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('Users') 
          .doc(user.uid)
          .get();

      if (userDoc.exists) {
        int userRole = (userDoc.data() as Map<String, dynamic>)['user_auth'] as int;

        AuthController.instance.currentUserRole.value = userRole;
        AuthController.instance.currentUserEmail.value = user.email;

        if (mounted) {
          if (userRole == 0) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const StudentHomeScreen.HomeScreen()),
            );
          } else if (userRole == 1) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const AdminHomeScreen.HomeScreen()),
            );
          } else {
            throw Exception('Role tidak valid');
          }
        }
      } else {
        throw Exception('Data user tidak ditemukan');
      }
    } catch (e) {
      await AuthController.instance.signOut();
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}