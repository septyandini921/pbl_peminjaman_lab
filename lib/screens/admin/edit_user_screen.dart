import 'package:flutter/material.dart';
import '../../models/user/user_model.dart';
import '../../service/user_service.dart';

class EditUserScreen extends StatefulWidget {
  final UserModel user;

  const EditUserScreen({super.key, required this.user});

  @override
  State<EditUserScreen> createState() => _EditUserScreenState();
}

class _EditUserScreenState extends State<EditUserScreen> {
  final UserService userService = UserService();
  final _formKey = GlobalKey<FormState>();

  late TextEditingController nameCtrl;
  late TextEditingController emailCtrl;
  late TextEditingController newPasswordCtrl;

  int role = 0;
  bool showPassword = false;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    nameCtrl = TextEditingController(text: widget.user.userName);
    emailCtrl = TextEditingController(text: widget.user.userEmail);
    newPasswordCtrl = TextEditingController();
    role = widget.user.userAuth;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit User"),
        backgroundColor: Colors.indigo,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              figmaInputField(
                label: "Nama",
                controller: nameCtrl,
                hint: "Masukkan nama",
              ),

              figmaInputField(
                label: "Email",
                controller: emailCtrl,
                readOnly: true,
                hint: "Email tidak bisa diubah",
              ),

              figmaInputField(
                label: "Password Baru",
                controller: newPasswordCtrl,
                obscure: !showPassword,
                hint: "Kosongkan jika tidak ingin ganti",
                suffixIcon: IconButton(
                  icon: Icon(
                      showPassword ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => setState(() => showPassword = !showPassword),
                ),
              ),

              const SizedBox(height: 10),

              figmaDropdownField(
                label: "Role",
                value: role,
                items: const [
                  DropdownMenuItem(value: 0, child: Text("Mahasiswa")),
                  DropdownMenuItem(value: 1, child: Text("Admin")),
                  DropdownMenuItem(value: 2, child: Text("Aslab")),
                ],
                onChanged: (v) => setState(() => role = v!),
              ),

              const SizedBox(height: 25),

              isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: () async {
                        if (_formKey.currentState!.validate()) {
                          setState(() => isLoading = true);

                          try {
                            String? newPass = newPasswordCtrl.text.trim().isEmpty
                                ? null
                                : newPasswordCtrl.text.trim();

                            // Panggil service update (tanpa avatar)
                            await userService.updateAkun(
                              widget.user.uid,
                              nameCtrl.text.trim(),
                              role,
                              emailCtrl.text.trim(),
                              newPassword: newPass,
                            );

                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text("Berhasil memperbarui akun")),
                            );
                            Navigator.pop(context);
                          } catch (e) {
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text("Gagal update akun: $e")),
                            );
                          } finally {
                            if (mounted) setState(() => isLoading = false);
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        padding:
                            const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                      ),
                      child: const Text("Simpan Perubahan",
                          style: TextStyle(color: Colors.white)),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget figmaInputField({
    required String label,
    required TextEditingController controller,
    bool readOnly = false,
    bool obscure = false,
    String? hint,
    Widget? suffixIcon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 130,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF7986CB),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade400),
              ),
              child: TextFormField(
                controller: controller,
                obscureText: obscure,
                readOnly: readOnly,
                decoration: InputDecoration(
                  hintText: hint,
                  border: InputBorder.none,
                  suffixIcon: suffixIcon,
                ),
                validator: (value) {
                  if (label == "Nama" && (value == null || value.isEmpty)) {
                    return "Nama tidak boleh kosong";
                  }
                  return null;
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget figmaDropdownField({
    required String label,
    required int value,
    required List<DropdownMenuItem<int>> items,
    required Function(int?) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 130,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF7986CB),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: DropdownButtonFormField<int>(
              value: value,
              items: items,
              onChanged: onChanged,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
