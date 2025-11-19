import 'package:flutter/material.dart';
import '../../../auth/auth_controller.dart';
import '../auth/login_screen.dart';
import '../../widgets/aslab_bottom_navbar.dart';

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
        title: const Text('Beranda Asisten Lab'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: Center(
        child: ValueListenableBuilder(
          valueListenable: AuthController.instance.currentUserEmail,
          builder: (context, email, _) {
            return Text('Halo Asisten Lab, ${email ?? "User"}'); 
          },
        ),
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 0),
    );
  }
}