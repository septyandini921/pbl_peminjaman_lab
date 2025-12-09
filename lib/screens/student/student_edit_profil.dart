import 'package:flutter/material.dart';
import '../../models/user/user_model.dart';
import '../../service/user_service.dart';

class StudentEditProfilScreen extends StatefulWidget {
  const StudentEditProfilScreen({super.key});

  @override
  State<StudentEditProfilScreen> createState() => _StudentEditProfilScreenState();
}

class _StudentEditProfilScreenState extends State<StudentEditProfilScreen> {
  late UserModel user;
  final userService = UserService();

  String selectedAvatar = "female";

  late TextEditingController nameController;
  late TextEditingController emailController;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    user = ModalRoute.of(context)!.settings.arguments as UserModel;

    selectedAvatar = user.avatar.contains("Woman") ? "female" : "male";

    nameController = TextEditingController(text: user.userName);
    emailController = TextEditingController(text: user.userEmail);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F6FF),

      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: AppBar(
          elevation: 0,
          backgroundColor: const Color(0xFFD9D5EC),
          centerTitle: true,
          title: const Text(
            "SIMPEL",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: Colors.black87,
            ),
          ),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text("Edit Profil",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),

            CircleAvatar(
              radius: 60,
              backgroundImage: AssetImage(
                selectedAvatar == "female"
                    ? "assets/avatar/Avatar_Woman.jpg"
                    : "assets/avatar/Avatar_Man.jpg",
              ),
            ),

            const SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                avatarOption("female", "assets/avatar/Avatar_Woman.jpg"),
                const SizedBox(width: 20),
                avatarOption("male", "assets/avatar/Avatar_Man.jpg"),
              ],
            ),

            const SizedBox(height: 30),

            Align(
              alignment: Alignment.centerLeft,
              child: const Text(
                "Nama",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 5),

            TextField(
              controller: nameController,
              decoration: InputDecoration(
                filled: true,
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),

            const SizedBox(height: 15),

            Align(
              alignment: Alignment.centerLeft,
              child: const Text(
                "Email",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 5),

            TextField(
              controller: emailController,
              readOnly: true,
              decoration: InputDecoration(
                filled: true,
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3C53CC),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30)),
                ),
                onPressed: () async {
                  String avatar = selectedAvatar == "female"
                      ? "assets/avatar/Avatar_Woman.jpg"
                      : "assets/avatar/Avatar_Man.jpg";

                  await userService.updateUser(
                    user.uid,
                    nameController.text,
                    avatar,
                  );

                  Navigator.pop(context);
                },
                child: const Text("Simpan Perubahan",
                    style: TextStyle(fontSize: 16,color: Colors.white)),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget avatarOption(String value, String imagePath) {
    bool active = selectedAvatar == value;

    return GestureDetector(
      onTap: () {
        setState(() => selectedAvatar = value);
      },
      child: CircleAvatar(
        radius: active ? 38 : 34,
        backgroundColor: active ? Colors.blue : Colors.grey.shade400,
        child: CircleAvatar(
          radius: active ? 34 : 32,
          backgroundImage: AssetImage(imagePath),
        ),
      ),
    );
  }
}
