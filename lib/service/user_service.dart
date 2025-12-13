// C:\Kuliah\semester5\Moblie\PBL\pbl_peminjaman_lab\lib\service\user_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user/user_model.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserService {
  final FirebaseFirestore firestore;
  final FirebaseAuth auth;

  // Constructor untuk production
  UserService()
      : firestore = FirebaseFirestore.instance,
        auth = FirebaseAuth.instance;

  // Constructor untuk testing (dependency injection)
  UserService.forTesting({required this.firestore, required this.auth});

  CollectionReference get users => firestore.collection('Users');

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


Stream<List<UserModel>> getUsers() {
  return users.snapshots().map((snapshot) {
    return snapshot.docs.map((doc) {
      return UserModel.fromMap(
        doc.id,
        doc.data() as Map<String, dynamic>,
      );
    }).toList();
  });
}

  // CREATE USER → membuat akun Authentication + simpan ke Firestore
  Future<void> createUser({
    required String name,
    required String email,
    required String password,
    required int userAuth,
    required String avatar,
  }) async {
    // 1. Buat akun Auth Firebase
    UserCredential cred = await FirebaseAuth.instance
        .createUserWithEmailAndPassword(email: email, password: password);

    // 2. Simpan ke Firestore
    await users.doc(cred.user!.uid).set({
      'user_name': name,
      'user_email': email,
      'user_auth': userAuth,
      'avatar': avatar,
    });
  }


// Cek apakah email sudah ada
  Future<bool> checkEmailExists(String email) async {
    final query = await users.where('user_email', isEqualTo: email).get();
    return query.docs.isNotEmpty;
  }

  // UPDATE USER
 Future<String> updateAkun(
    String uid,
    String name,
    int userAuth,
    String email, {
    String? oldPassword,
    String? newPassword,
  }) async {
    try {
      /// ============ UPDATE FIRESTORE DATA ============
      await users.doc(uid).update({
        'user_name': name,
        'user_auth': userAuth,
        'user_email': email,
      });

      /// ============ JIKA TIDAK UBAH PASSWORD ==========
      if (newPassword == null) return "success";

      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return "User tidak ditemukan";

      if (oldPassword == null || oldPassword.isEmpty) {
        return "Password lama wajib diisi untuk mengubah password";
      }

      /// Reauthenticate (WAJIB sebelum update password)
      final credential = EmailAuthProvider.credential(
        email: currentUser.email!,
        password: oldPassword,
      );

      try {
        await currentUser.reauthenticateWithCredential(credential);
      } catch (e) {
        return "Password lama salah";
      }

      /// Update password
      await currentUser.updatePassword(newPassword);

      return "success";
    } catch (e) {
      return e.toString();
    }
  }


  // DELETE USER FIRESTORE + AUTH
  Future<void> deleteUser(String uid) async {
    // Hapus dari Firestore
    await users.doc(uid).delete();
  }
}
