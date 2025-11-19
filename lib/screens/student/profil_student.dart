import 'package:flutter/material.dart';
import '../../widgets/student_bottom_navbar.dart';

class ProfilStudent extends StatelessWidget {
  const ProfilStudent({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(0), 
        child: SizedBox.shrink(),
      ),
      body: Center(
        child: Text(
          'ini halaman profil',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.blueGrey,
          ),
        ),
      ),
      bottomNavigationBar: BottomNavBar(currentIndex: 3),
    );
  }
}