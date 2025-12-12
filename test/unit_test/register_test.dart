// * mencoba mendaftar dengan email yang sudah pernah terdaftar
// * register dengan email yang tidak valid misal studenttest@gmail..com

// test/unit_test/register_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart' as fcs;
import 'package:pbl_peminjaman_lab/auth/auth_controller.dart';
import 'package:firebase_auth/firebase_auth.dart';

void main() {
  group('AuthController Register Tests', () {
    late MockFirebaseAuth mockAuth;
    late fcs.FakeFirebaseFirestore mockFirestore;
    late AuthController authController;

    setUp(() {
      mockAuth = MockFirebaseAuth();
      mockFirestore = fcs.FakeFirebaseFirestore();
      
      authController = AuthController.testConstructor(
        auth: mockAuth,
        firestore: mockFirestore,
      );
    });

    test('Register gagal - Email sudah terdaftar', () async {
      final existingUser = MockUser(
        email: 'existing@example.com',
        uid: 'existing123',
        isEmailVerified: true,
      );

      await mockFirestore.collection('Users').doc('existing123').set({
        'user_auth': 0,
        'user_email': 'existing@example.com',
        'user_name': 'Existing User',
        'avatar': 'assets/avatar/Avatar_Woman.jpg',
      });

      // Buat custom MockFirebaseAuth yang throw error saat createUserWithEmailAndPassword
      mockAuth = _MockFirebaseAuthWithError(
        errorCode: 'email-already-in-use',
        mockUser: existingUser,
      );

      authController = AuthController.testConstructor(
        auth: mockAuth,
        firestore: mockFirestore,
      );

      // Test registrasi dengan email yang sudah ada
      expect(
        () => authController.register(
          'New User',
          'existing@example.com',
          'password123',
          0,
        ),
        throwsA(predicate((e) => 
          e.toString().contains('Email sudah terdaftar'))),
      );

      // Verifikasi state controller tetap null
      expect(authController.currentUserRole.value, isNull);
      expect(authController.currentUserEmail.value, isNull);
    });

    test('Register gagal - Email tidak valid (studenttest@gmail..com)', () async {
      // Buat custom MockFirebaseAuth yang throw error untuk invalid email
      mockAuth = _MockFirebaseAuthWithError(
        errorCode: 'invalid-email',
        errorMessage: 'The email address is badly formatted.',
      );

      authController = AuthController.testConstructor(
        auth: mockAuth,
        firestore: mockFirestore,
      );

      // Test registrasi dengan email invalid
      expect(
        () => authController.register(
          'Student Test',
          'studenttest@gmail..com',
          'password123',
          0,
        ),
        throwsA(predicate((e) => 
          e.toString().contains('Terjadi kesalahan:') &&
          e.toString().contains('email address is badly formatted'))),
      );

      // Verifikasi state controller tetap null
      expect(authController.currentUserRole.value, isNull);
      expect(authController.currentUserEmail.value, isNull);
    });

    test('Register gagal - Password terlalu lemah', () async {
      mockAuth = _MockFirebaseAuthWithError(
        errorCode: 'weak-password',
        errorMessage: 'Password should be at least 6 characters',
      );

      authController = AuthController.testConstructor(
        auth: mockAuth,
        firestore: mockFirestore,
      );

      expect(
        () => authController.register(
          'Test User',
          'test@example.com',
          '123',
          0,
        ),
        throwsA(predicate((e) => 
          e.toString().contains('Password harus lebih kuat'))),
      );

      expect(authController.currentUserRole.value, isNull);
      expect(authController.currentUserEmail.value, isNull);
    });

    test('Register gagal - User null setelah registrasi', () async {
      // Simulasi kondisi dimana user credential berhasil tapi user null
      mockAuth = _MockFirebaseAuthWithNullUser();

      authController = AuthController.testConstructor(
        auth: mockAuth,
        firestore: mockFirestore,
      );

      expect(
        () => authController.register(
          'Test User',
          'test@example.com',
          'password123',
          0,
        ),
        throwsA(predicate((e) => 
          e.toString().contains('Register gagal, user tidak valid'))),
      );

      expect(authController.currentUserRole.value, isNull);
      expect(authController.currentUserEmail.value, isNull);
    });
  });
}

// Custom MockFirebaseAuth untuk simulasi error
class _MockFirebaseAuthWithError extends MockFirebaseAuth {
  final String errorCode;
  final String? errorMessage;

  _MockFirebaseAuthWithError({
    required this.errorCode,
    this.errorMessage,
    MockUser? mockUser,
  }) : super(mockUser: mockUser);

  @override
  Future<UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    throw FirebaseAuthException(
      code: errorCode,
      message: errorMessage,
    );
  }
}

// Custom MockFirebaseAuth untuk simulasi user null
class _MockFirebaseAuthWithNullUser extends MockFirebaseAuth {
  _MockFirebaseAuthWithNullUser() : super();

  @override
  Future<UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    return _MockUserCredentialWithNullUser();
  }
}

class _MockUserCredentialWithNullUser implements UserCredential {
  @override
  User? get user => null;

  @override
  AdditionalUserInfo? get additionalUserInfo => null;

  @override
  AuthCredential? get credential => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}