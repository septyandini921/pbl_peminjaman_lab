import 'package:flutter/material.dart';
import '../../../auth/auth_controller.dart';
import '../student/home_screen.dart' as StudentHomeScreen;

class RegisterStudentScreen extends StatefulWidget {
  const RegisterStudentScreen({super.key});

  @override
  State<RegisterStudentScreen> createState() => _RegisterStudentScreenState();
}

class _RegisterStudentScreenState extends State<RegisterStudentScreen> {
  final nameC = TextEditingController();
  final emailC = TextEditingController();
  final passC = TextEditingController();

  bool isLoading = false;
  String? errorMessage;

  Future<void> register() async {
    if (nameC.text.isEmpty || emailC.text.isEmpty || passC.text.isEmpty) {
      setState(() => errorMessage = "Semua field harus diisi");
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      await AuthController.instance.register(
        nameC.text.trim(),
        emailC.text.trim(),
        passC.text.trim(),
        0, // role student
      );

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const StudentHomeScreen.HomeScreen()),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Registrasi berhasil")),
      );
    } catch (e) {
      setState(() => errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF4D55CC),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
            child: Column(
              children: [
                // Back button
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                    ),
                    const Text(
                      "Kembali",
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    )
                  ],
                ),

                const SizedBox(height: 30),

                // Title Register
                const Text(
                  "Daftar Akun Student",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(height: 30),
                // Form register
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 30, 20, 30),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Column(
                    children: [
                      TextField(
                        controller: nameC,
                        decoration: const InputDecoration(
                          labelText: "Nama",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),

                      TextField(
                        controller: emailC,
                        decoration: const InputDecoration(
                          labelText: "Email",
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 16),

                      TextField(
                        controller: passC,
                        decoration: const InputDecoration(
                          labelText: "Password",
                          border: OutlineInputBorder(),
                        ),
                        obscureText: true,
                      ),

                      const SizedBox(height: 20),

                      if (errorMessage != null)
                        Text(
                          errorMessage!,
                          style: const TextStyle(color: Colors.red, fontSize: 13),
                        ),

                      const SizedBox(height: 20),

                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF4D55CC),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed: register,
                                child: const Text(
                                  "Daftar Akun",
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white ),
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
