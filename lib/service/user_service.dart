import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user/user_model.dart';

class UserService {
  final CollectionReference users =
      FirebaseFirestore.instance.collection('Users');

  // 🔹 Get user by UID
  Future<UserModel?> getUser(String uid) async {
    DocumentSnapshot snapshot = await users.doc(uid).get();
    if (snapshot.exists) {
      return UserModel.fromMap(uid, snapshot.data() as Map<String, dynamic>);
    }
    return null;
  }

  // 🔹 Update profile (name + avatar)
  Future<void> updateUser(String uid, String name, String avatar) async {
    await users.doc(uid).update({
      'user_name': name,
      'avatar': avatar,
    });
  }
}
