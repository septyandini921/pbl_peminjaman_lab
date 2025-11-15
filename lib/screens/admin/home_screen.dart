import 'package:flutter/material.dart';
import '../../../auth/auth_controller.dart';
import '../auth/login_screen.dart';
import '../../widgets/admin_bottom_navbar.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    await AuthController.instance.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Beranda Admin'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
          ),
        ],
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 0),
      body: Center(
        child: ValueListenableBuilder(
          valueListenable: AuthController.instance.currentUserEmail,
          builder: (context, email, _) {
            return Text('Halo Admin, ${email ?? "User"}'); 
          },
        ),
      ),
    );
  }
}