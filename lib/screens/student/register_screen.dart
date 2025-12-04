import 'package:flutter/material.dart';
import '../../../auth/auth_controller.dart';
import '../student/home_screen.dart' as StudentHomeScreen;

class RegisterStudentScreen extends StatefulWidget {
  const RegisterStudentScreen({super.key});

  @override
  State<RegisterStudentScreen> createState() => _RegisterStudentScreenState();
}

class _RegisterStudentScreenState extends State<RegisterStudentScreen> {
  final TextEditingController nameC = TextEditingController();
  final TextEditingController emailC = TextEditingController();
  final TextEditingController passC = TextEditingController();

  bool isLoading = false;
  bool obscurePass = true;
  bool _rememberMe = false;
  String? errorMessage;

  static const Color primaryColor = Color(0xFF4D55CC);
  static const Color gradientEndColor = Color(0xFF7A73D1);

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
        0,
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
      setState(() {
        errorMessage = e.toString().contains('email-already-in-use')
            ? "Email sudah terdaftar."
            : "Registrasi Gagal: $e";
      });
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void navigateToLogin() {
    Navigator.pop(context);
  }

  @override
  void dispose() {
    nameC.dispose();
    emailC.dispose();
    passC.dispose();
    super.dispose();
  }

  Widget _buildTextField(TextEditingController controller, String label, String hint, TextInputType keyboardType) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      ),
    );
  }

  Widget _buildPasswordTextField(TextEditingController controller) {
    return TextField(
      controller: controller,
      obscureText: obscurePass,
      decoration: InputDecoration(
        labelText: "Password",
        hintText: "Masukkan Password",
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        suffixIcon: IconButton(
          icon: Icon(
            obscurePass ? Icons.visibility_off : Icons.visibility,
            color: Colors.grey,
          ),
          onPressed: () {
            setState(() => obscurePass = !obscurePass);
          },
        ),
      ),
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red[700], size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              errorMessage ?? '',
              style: TextStyle(color: Colors.red[700], fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRememberMeAndForgotPassword() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            GestureDetector(
              onTap: () => setState(() => _rememberMe = !_rememberMe),
              child: Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: _rememberMe ? primaryColor : Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _rememberMe ? primaryColor : Colors.grey.shade400,
                  ),
                ),
                child: _rememberMe
                    ? const Icon(Icons.check, size: 12, color: Colors.white)
                    : null,
              ),
            ),
            const SizedBox(width: 6),
            const Text(
              'Remember me',
              style: TextStyle(fontSize: 12, color: primaryColor),
            ),
          ],
        ),
        GestureDetector(
          onTap: () {
            // Implement forgot password flow if needed
          },
          child: const Text(
            'Forgot Password?',
            style: TextStyle(
              fontSize: 12,
              color: primaryColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSignInButton() {
    if (isLoading) {
      return const SizedBox(
        height: 50,
        child: Center(child: CircularProgressIndicator(color: primaryColor)),
      );
    }

    return SizedBox(
      width: double.infinity,
      height: 50,
      child: InkWell(
        onTap: register,
        borderRadius: BorderRadius.circular(30),
        splashColor: Colors.white24,
        child: Material(
          color: Colors.transparent, // Transparent background for Ink effect
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [primaryColor, gradientEndColor],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(30),
            ),
            alignment: Alignment.center,  // Center the text inside the button
            child: const Text(
              'Register',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRegisterButton() {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Sudah punya akun? ',
            style: TextStyle(
              fontSize: 14,
              color: Colors.black54,
            ),
          ),
          GestureDetector(
            onTap: navigateToLogin,
            child: const Text(
              'Login sekarang.',
              style: TextStyle(
                fontSize: 14,
                color: primaryColor,
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF211C84),
                    Color(0xFF4D55CC),
                    Color(0xFF7A73D1),
                    Color(0xFFB5A8D5),
                  ],
                ),
              ),
            ),
            Column(
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back,
                            color: Colors.white, size: 28),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Text(
                        "Back",
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w500),
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Image.asset(
                  "assets/images/Simple.png",
                  height: 80,
                ),
                const SizedBox(height: 10),
                const Text(
                  "SIMPEL",
                  style: TextStyle(
                    fontSize: 32,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
                const Text(
                  "Sistem Peminjaman Lab",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 40),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(32),
                        topRight: Radius.circular(32),
                      ),
                    ),
                    padding: const EdgeInsets.fromLTRB(25, 40, 25, 35),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Text(
                            "REGISTER",
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 35),
                          _buildTextField(
                              nameC, "Nama", "Masukkan Nama Lengkap", TextInputType.name),
                          const SizedBox(height: 18),
                          _buildTextField(
                              emailC, "Email", "Masukkan Email", TextInputType.emailAddress),
                          const SizedBox(height: 18),
                          _buildPasswordTextField(passC),
                          const SizedBox(height: 10),
                          if (errorMessage != null) ...[
                            _buildErrorMessage(),
                            const SizedBox(height: 16),
                          ],
                          _buildRememberMeAndForgotPassword(),
                          const SizedBox(height: 40),
                          _buildSignInButton(),
                          const SizedBox(height: 24),
                          _buildRegisterButton(),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
