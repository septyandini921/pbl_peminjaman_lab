import 'package:flutter/material.dart';
import '../../models/user/user_model.dart';
import '../../service/user_service.dart';

class AslabEditProfilScreen extends StatefulWidget {
  const AslabEditProfilScreen({super.key});

  @override
  State<AslabEditProfilScreen> createState() => _AslabEditProfilScreenState();
}

class _AslabEditProfilScreenState extends State<AslabEditProfilScreen> {
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
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: const Text(
          "Edit Profil",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 10),
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
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
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
                child: Ink(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF4D55CC),
                        Color(0xFF7A73D1),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: const Center(
                    child: Text(
                      "Simpan Perubahan",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
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
