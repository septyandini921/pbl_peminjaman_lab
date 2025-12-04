import 'package:flutter/material.dart';
import '../screens/aslab/home_screen.dart';
import '../screens/aslab/jadwal_screen.dart';
import '../screens/aslab/profil_aslab.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;

  const BottomNavBar({super.key, required this.currentIndex});

  // Fungsi untuk menangani tap pada bottom navigation bar
  void _onTap(BuildContext context, int index) {
    if (index == currentIndex) return;

    // Navigasi berdasarkan index yang dipilih
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
            pageBuilder: (_, __, ___) => const JadwalScreen(),
            transitionDuration: Duration.zero,
            reverseTransitionDuration: Duration.zero,
          ),
        );
        break;

      case 2:
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const ProfilAslabScreen(),
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
      onTap: (index) => _onTap(context, index), // Fungsi saat tab dipilih

      backgroundColor: Colors.indigo,
      selectedItemColor: Colors.white, // Warna saat item dipilih
      unselectedItemColor: Colors.white70, // Warna saat item tidak dipilih
      type: BottomNavigationBarType
          .fixed, // Menampilkan semua item dalam satu baris

      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: "Beranda", // Label untuk halaman beranda
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.list), // Ikon untuk jadwal
          label: "Jadwal", // Label untuk halaman jadwal
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person), // Ikon untuk profil
          label: "Profil", // Label untuk halaman profil
        ),
      ],
    );
  }
}
