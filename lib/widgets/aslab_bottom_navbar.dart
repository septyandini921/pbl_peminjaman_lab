import 'package:flutter/material.dart';
import '../screens/aslab/home_screen.dart';
import '../screens/aslab/jadwal_screen.dart';
import '../screens/aslab/profil_aslab.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;

  const BottomNavBar({super.key, required this.currentIndex});

  void _onTap(BuildContext context, int index) {
    if (index == currentIndex) return;

    Widget page;
    switch (index) {
      case 0:
        page = const HomeScreen();
        break;
      case 1:
        page = const JadwalScreen();
        break;
      case 2:
        page = const ProfilAslabScreen();
        break;
      default:
        return;
    }

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => page,
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      key: const Key('bottomnavbar_aslab'),
      currentIndex: currentIndex,
      onTap: (index) => _onTap(context, index),

      backgroundColor: Colors.indigo,
      selectedItemColor: Colors.white,
      unselectedItemColor: Colors.white70,
      type: BottomNavigationBarType.fixed,

      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: "Beranda",
        ),

        BottomNavigationBarItem(
          icon: Icon(
            Icons.list,
            key: Key('bottomnav_jadwal'),
          ),
          label: "Jadwal",
        ),

        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: "Profil",
        ),
      ],
    );
  }
}
