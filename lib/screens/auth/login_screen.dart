import 'package:flutter/material.dart';
import '../../../auth/auth_controller.dart';
import '../student/home_screen.dart' as StudentHomeScreen;
import '../admin/home_screen.dart' as AdminHomeScreen;
import '../aslab/home_screen.dart' as AslabHomeScreen;
import '../student/register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _rememberMe = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  static const Color _primaryColor = Color(0xFF211C84);
  static const Color _secondaryColor = Color(0xFF4D55CC);
  static const Color _tertiaryColor = Color(0xFF7A73D1);
  static const Color _quaternaryColor = Color(0xFFB5A8D5);
  static const LinearGradient _primaryGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF211C84),
      Color(0xFF4D55CC),
      Color(0xFF7A73D1),
      Color(0xFFB5A8D5),
    ],
  );

  Future<void> _login() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Email dan password harus diisi';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final int userRole = await AuthController.instance.signIn(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      if (!mounted) return;

      if (userRole == 0) {
        // student
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const StudentHomeScreen.HomeScreen(),
          ),
        );
      } else if (userRole == 1) {
        // admin
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AdminHomeScreen.HomeScreen()),
        );
      } else if (userRole == 2) {
        // aslab
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AslabHomeScreen.HomeScreen()),
        );
      } else {
        throw 'Role pengguna tidak dikenal.';
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            Container(
              decoration: const BoxDecoration(gradient: _primaryGradient),
            ),

            SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(
                            Icons.arrow_back_ios,
                            color: Colors.white,
                          ),
                        ),
                        const Text(
                          'Kembali',
                          style: TextStyle(color: Colors.white, fontSize: 18),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/images/Simple.png',
                          width: 100,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'SIMPEL',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Sistem Peminjaman Lab',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  Container(
                    width: double.infinity,
                    height: MediaQuery.of(context).size.height,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(32),
                        topRight: Radius.circular(32),
                      ),
                    ),
                    padding: const EdgeInsets.fromLTRB(24, 40, 24, 40),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Center(
                          child: Text(
                            'LOGIN',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ),

                        const SizedBox(height: 32),

                        _buildEmailField(),
                        const SizedBox(height: 24),

                        _buildPasswordField(),
                        const SizedBox(height: 16),

                        if (_errorMessage != null) _buildErrorMessage(),
                        if (_errorMessage != null) const SizedBox(height: 16),

                        _buildSignInButton(),

                        const SizedBox(height: 24),
                      _buildRegisterButton(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

    Widget _buildEmailField() {
      return TextField(
        controller: _emailController,
        keyboardType: TextInputType.emailAddress,
        style: const TextStyle(fontSize: 14, color: Colors.black87),
        decoration: InputDecoration(
          labelText: 'Email',
          hintText: 'Masukkan Email',
          hintStyle: const TextStyle(fontSize: 14, color: Colors.black38),
          labelStyle: const TextStyle(
            color: _primaryColor,
            fontWeight: FontWeight.w500,
          ),

          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: _primaryColor, width: 1.0),
          ),

          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: _primaryColor, width: 2.0),
          ),

          contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          isDense: true,
          constraints: const BoxConstraints(maxHeight: 50),
        ),
      );
    }

   Widget _buildPasswordField() {
  return TextField(
    controller: _passwordController,
    obscureText: _obscurePassword,
    style: const TextStyle(fontSize: 14, color: Colors.black87),
    decoration: InputDecoration(
      labelText: 'Password',
      hintText: 'Masukkan Password',
      hintStyle: const TextStyle(fontSize: 14, color: Colors.black38),

      labelStyle: const TextStyle(
        color: _primaryColor,
        fontWeight: FontWeight.w500,
      ),

      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: _primaryColor, width: 1.0),
      ),

      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: _primaryColor, width: 2.0),
      ),

      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      isDense: true,
      constraints: const BoxConstraints(maxHeight: 50),

      // ✅ sudah diperbaiki
      suffixIcon: IconButton(
        icon: Icon(
          _obscurePassword
              ? Icons.visibility_off_outlined
              : Icons.visibility_outlined,
          color: Colors.grey[600],
          size: 20,
        ),
        onPressed: () {
          setState(() {
            _obscurePassword = !_obscurePassword;
          });
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
              _errorMessage!,
              style: TextStyle(color: Colors.red[700], fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildSignInButton() {
    if (_isLoading) {
      return const SizedBox(
        height: 50,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return Container(
      width: double.infinity,
      height: 50,
      decoration: BoxDecoration(
        color: const Color(0xFF4D55CC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: _login,
        borderRadius: BorderRadius.circular(12),
        splashColor: Colors.white24,
        child: const Center(
          child: Text(
            'Login',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color.fromARGB(255, 255, 255, 255),
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
          'Belum punya akun? ',
          style: TextStyle(
            fontSize: 14,
            color: Colors.black,
          ),
        ),
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const RegisterStudentScreen()),
            );
          },
          child: const Text(
            'Daftar akun',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF4D55CC),
              fontWeight: FontWeight.bold,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ],
    ),
  );
}
}
