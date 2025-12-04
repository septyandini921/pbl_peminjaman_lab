import 'package:flutter/material.dart';
import '../screens/student/home_screen.dart';
import '../screens/student/info_screen.dart';
import '../screens/student/profil_student.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
  });

  void _onTap(BuildContext context, int index) {
    if (index == currentIndex) return;

    // Handle navigation based on tapped index
    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const HomeScreen(),
            transitionDuration: Duration.zero,
            reverseTransitionDuration: Duration.zero,
          ),
        );
        break;

      case 1:
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const InfoScreen(),
            transitionDuration: Duration.zero,
            reverseTransitionDuration: Duration.zero,
          ),
        );
        break;

      case 2:
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const ProfilStudent(),
            transitionDuration: Duration.zero,
            reverseTransitionDuration: Duration.zero,
          ),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: (index) => _onTap(context, index),

      backgroundColor: const Color(0xFF3949AB), // Warna background ungu
      selectedItemColor: Colors.white, // Warna ikon yang dipilih
      unselectedItemColor: Colors.white70, // Warna ikon yang tidak dipilih
      type: BottomNavigationBarType.fixed, // Tipe bottom nav bar tetap

      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: "Beranda",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.info),
          label: "Informasi",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person), 
          label: "Profil",
        ),
      ],
    );
  }
}
