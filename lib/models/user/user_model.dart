class UserModel {
  final String uid;
  final String userName;
  final String userEmail;
  final int userAuth;
  final String avatar;

  UserModel({
    required this.uid,
    required this.userName,
    required this.userEmail,
    required this.userAuth,
    required this.avatar,
  });

  // Convert from Firestore
  factory UserModel.fromMap(String uid, Map<String, dynamic> map) {
    return UserModel(
      uid: uid,
      userName: map['user_name'] ?? '',
      userEmail: map['user_email'] ?? '',
      userAuth: map['user_auth'] ?? 0,
      avatar: map['avatar'] ??
          "assets/avatar/Avatar_Woman.jpg", // default jika tidak ada
    );
  }

  // Convert to Firestore
  Map<String, dynamic> toMap() {
    return {
      'user_name': userName,
      'user_email': userEmail,
      'user_auth': userAuth,
      'avatar': avatar,
    };
  }
}
