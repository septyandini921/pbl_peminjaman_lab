import 'package:flutter/material.dart';
import 'dart:async';
import 'login_screen.dart'; // Ganti dengan path ke login screen

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _showLogo = true;
  bool _showCharacter = false;

  @override
  void initState() {
    super.initState();
    _startSplashScreen();
  }

  Future<void> _startSplashScreen() async {
    // Tampilkan logo SIMPEL pertama kali selama 2 detik
    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      _showLogo = false; // Sembunyikan logo SIMPEL
      _showCharacter = true; // Tampilkan karakter
    });

    // Tampilkan tampilan kedua (karakter dengan ide) selama 2 detik
    await Future.delayed(const Duration(seconds: 2));

    // Pindah ke Login Screen setelah semua tampilan selesai
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()), // Ganti dengan LoginScreen
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Menggunakan LinearGradient untuk gradasi 4 warna
      body: SafeArea(
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF211C84), // Warna pertama
                Color(0xFF4D55CC), // Warna kedua
                Color(0xFF7A73D1), // Warna ketiga
                Color(0xFFB5A8D5), // Warna keempat
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Center( // Menambahkan Center untuk memastikan elemen berada di tengah
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Tampilan pertama: Logo SIMPEL
                AnimatedOpacity(
                  opacity: _showLogo ? 1.0 : 0.0, // Efek fade-out untuk logo
                  duration: const Duration(milliseconds: 500), // Durasi fade-out
                  child: _showLogo
                      ? Image.asset(
                          'assets/images/logosimple.png',
                          width: 140, // Atur ukuran logo sesuai kebutuhan
                        )
                      : const SizedBox.shrink(), // Jika tidak tampilkan, beri SizedBox
                ),
                const SizedBox(height: 16),
                AnimatedOpacity(
                  opacity: _showLogo ? 1.0 : 0.0, // Fade untuk teks logo
                  duration: const Duration(milliseconds: 500),
                  child: _showLogo
                      ? const Text(
                          'Sistem Peminjaman Lab',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
                const SizedBox(height: 32),

                // Tampilan kedua: Karakter dengan ide
                AnimatedOpacity(
                  opacity: _showCharacter ? 1.0 : 0.0, // Fade untuk karakter
                  duration: const Duration(milliseconds: 500), // Durasi fade-in untuk karakter
                  child: _showCharacter
                      ? Image.asset(
                          'assets/images/karakter.png', // Path ke gambar karakter
                          width: 180,
                        )
                      : const SizedBox.shrink(),
                ),
                const SizedBox(height: 32),
                AnimatedOpacity(
                  opacity: _showCharacter ? 1.0 : 0.0, // Fade untuk teks karakter
                  duration: const Duration(milliseconds: 500),
                  child: _showCharacter
                      ? Column(
                          children: const [
                            Text(
                              'HELLO!',
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 12),
                            Text(
                              "Let's get you",
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              "Started",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
