// C:\Kuliah\semester5\Moblie\PBL\pbl_peminjaman_lab\test\unit_test\manage_user_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:mockito/mockito.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mockito/annotations.dart';
import 'package:pbl_peminjaman_lab/service/user_service.dart';

// Mock classes
class MockFirebaseAuth extends Mock implements FirebaseAuth {}
class MockUser extends Mock implements User {}
class MockUserCredential extends Mock implements UserCredential {}

// Generate mocks dengan command: flutter pub run build_runner build
@GenerateMocks([FirebaseAuth, User, UserCredential])

void main() {
  late FakeFirebaseFirestore firestore;
  late MockFirebaseAuth mockAuth;
  late UserService userService;

  setUp(() {
    print('Setting up test environment...');
    firestore = FakeFirebaseFirestore();
    mockAuth = MockFirebaseAuth();
    
    // Inisialisasi UserService dengan dependency injection
    userService = UserService.forTesting(
      firestore: firestore,
      auth: mockAuth,
    );
    print('Test environment ready');
  });

  // ==========================================================
  // POSITIVE TESTS - GET USER DATA
  // ==========================================================
  group('UserService Tests - Get User Data - Positive Tests', () {
    test('Admin dapat mengambil data user berdasarkan UID', () async {
      print('Setting up user data in Firestore...');
      await firestore.collection('Users').doc('user123').set({
        'user_name': 'John Doe',
        'user_email': 'john@example.com',
        'user_auth': 1,
        'avatar': 'avatar1.png',
      });
      print('User data setup complete: John Doe (user123)');

      print('Retrieving user data...');
      final result = await userService.getUser('user123');

      print('Verifying user data...');
      expect(result, isNotNull);
      expect(result?.uid, 'user123');
      expect(result?.userName, 'John Doe');
      expect(result?.userEmail, 'john@example.com');
      expect(result?.userAuth, 1);
      expect(result?.avatar, 'avatar1.png');
      print('User data retrieval successful');
    });

    test('Admin dapat mengambil semua data user dengan stream', () async {
      print('Setting up multiple users in Firestore...');
      await firestore.collection('Users').doc('user1').set({
        'user_name': 'Alice',
        'user_email': 'alice@example.com',
        'user_auth': 2,
        'avatar': 'avatar2.png',
      });
      
      await firestore.collection('Users').doc('user2').set({
        'user_name': 'Bob',
        'user_email': 'bob@example.com',
        'user_auth': 1,
        'avatar': 'avatar3.png',
      });
      print('Multiple users setup complete: Alice (admin) and Bob (user)');

      print('Setting up users stream...');
      final usersStream = userService.getUsers();
      print('Waiting for first stream data...');
      final users = await usersStream.first;

      print('Verifying stream data...');
      expect(users.length, 2);
      expect(users.any((u) => u.userName == 'Alice'), true);
      expect(users.any((u) => u.userName == 'Bob'), true);
      print('Stream data retrieval successful');
    });

    test('Stream users mengembalikan data yang ter-update secara real-time',
        () async {
      print('Setting up initial user data...');
      await firestore.collection('Users').doc('user1').set({
        'user_name': 'Initial User',
        'user_email': 'initial@example.com',
        'user_auth': 1,
        'avatar': 'avatar.png',
      });

      print('Setting up users stream for real-time updates...');
      final usersStream = userService.getUsers();
      
      print('Adding new user while listening to stream...');
      await firestore.collection('Users').doc('user2').set({
        'user_name': 'New User',
        'user_email': 'new@example.com',
        'user_auth': 1,
        'avatar': 'avatar2.png',
      });

      print('Waiting for updated stream data...');
      final users = await usersStream.first;

      print('Verifying real-time update...');
      expect(users.length, 2);
      print('Real-time stream update successful');
    });

    test('User dapat difilter berdasarkan user_auth level', () async {
      print('Setting up users with different auth levels...');
      await firestore.collection('Users').doc('admin1').set({
        'user_name': 'Admin User',
        'user_email': 'admin@example.com',
        'user_auth': 3,
        'avatar': 'admin.png',
      });
      
      await firestore.collection('Users').doc('aslab1').set({
        'user_name': 'Aslab User',
        'user_email': 'aslab@example.com',
        'user_auth': 2,
        'avatar': 'aslab.png',
      });
      
      await firestore.collection('Users').doc('mahasiswa1').set({
        'user_name': 'Mahasiswa User',
        'user_email': 'mahasiswa@example.com',
        'user_auth': 1,
        'avatar': 'mahasiswa.png',
      });
      print('Users with different auth levels setup complete');

      print('Retrieving all users...');
      final usersStream = userService.getUsers();
      final users = await usersStream.first;

      print('Verifying auth level filtering...');
      expect(users.length, 3);
      expect(users.where((u) => u.userAuth == 3).length, 1);
      expect(users.where((u) => u.userAuth == 2).length, 1);
      expect(users.where((u) => u.userAuth == 1).length, 1);
      print('Auth level filtering successful');
    });
  });

  // ==========================================================
  // POSITIVE TESTS - UPDATE USER PROFILE
  // ==========================================================
  group('UserService Tests - Update User Profile - Positive Tests', () {
    test('User dapat mengupdate profil (nama dan avatar)', () async {
      print('Creating initial user profile...');
      await firestore.collection('Users').doc('user456').set({
        'user_name': 'Old Name',
        'user_email': 'user@example.com',
        'user_auth': 1,
        'avatar': 'old_avatar.png',
      });
      print('Initial profile created: Old Name with old_avatar.png');

      print('Updating user profile...');
      await userService.updateUser('user456', 'New Name', 'new_avatar.png');
      print('Profile update initiated: New Name with new_avatar.png');

      print('Verifying profile update...');
      final updatedDoc = await firestore.collection('Users').doc('user456').get();
      final data = updatedDoc.data();

      expect(data?['user_name'], 'New Name');
      expect(data?['avatar'], 'new_avatar.png');
      expect(data?['user_email'], 'user@example.com'); // Email tidak berubah
      print('Profile update successful');
    });

    test('Admin dapat mengupdate data user tanpa mengubah password', () async {
      print('Setting up admin user for update test...');
      await firestore.collection('Users').doc('admin123').set({
        'user_name': 'Admin Old',
        'user_email': 'admin@example.com',
        'user_auth': 3,
        'avatar': 'admin_avatar.png',
      });
      print('Admin user setup: Admin Old with auth level 3');

      print('Admin updating user data (no password change)...');
      final result = await userService.updateAkun(
        'admin123',
        'Admin New',
        2,
        'admin.new@example.com',
      );
      print('Admin update result: $result');

      expect(result, 'success');
      
      print('Verifying admin data update...');
      final updatedDoc = await firestore.collection('Users').doc('admin123').get();
      final data = updatedDoc.data();

      expect(data?['user_name'], 'Admin New');
      expect(data?['user_auth'], 2);
      expect(data?['user_email'], 'admin.new@example.com');
      print('Admin update successful');
    });

    test('User dapat mengupdate hanya nama tanpa mengubah avatar', () async {
      print('Creating user with original avatar...');
      await firestore.collection('Users').doc('user789').set({
        'user_name': 'Old Name',
        'user_email': 'user789@example.com',
        'user_auth': 1,
        'avatar': 'original_avatar.png',
      });
      print('User created: Old Name with original_avatar.png');

      print('Updating only user name...');
      await userService.updateUser('user789', 'Updated Name', 'original_avatar.png');
      print('Name update completed: Updated Name with same avatar');

      print('Verifying selective update...');
      final updatedDoc = await firestore.collection('Users').doc('user789').get();
      final data = updatedDoc.data();

      expect(data?['user_name'], 'Updated Name');
      expect(data?['avatar'], 'original_avatar.png');
      print('Selective update successful');
    });

    test('Admin dapat mengupdate user_auth level', () async {
      print('Creating user for promotion...');
      await firestore.collection('Users').doc('promote123').set({
        'user_name': 'Promoted User',
        'user_email': 'promote@example.com',
        'user_auth': 1, // Mahasiswa
        'avatar': 'avatar.png',
      });
      print('User created: Mahasiswa (auth level 1)');

      print('Promoting user to Aslab...');
      await userService.updateAkun(
        'promote123',
        'Promoted User',
        2, // Aslab
        'promote@example.com',
      );
      print('Promotion completed: Mahasiswa → Aslab');

      print('Verifying promotion...');
      final updatedDoc = await firestore.collection('Users').doc('promote123').get();
      final data = updatedDoc.data();

      expect(data?['user_auth'], 2);
      print('User promotion successful');
    });
  });

  // ==========================================================
  // POSITIVE TESTS - CHECK EMAIL
  // ==========================================================
  group('UserService Tests - Check Email - Positive Tests', () {
    test('Sistem dapat memeriksa keberadaan email di database', () async {
      print('Setting up existing email...');
      await firestore.collection('Users').doc('user999').set({
        'user_name': 'Existing User',
        'user_email': 'existing@example.com',
        'user_auth': 1,
        'avatar': 'avatar.png',
      });
      print('Existing email created: existing@example.com');

      print('Checking existing email...');
      final exists = await userService.checkEmailExists('existing@example.com');
      print('Email exists check result: $exists');

      print('Checking non-existent email...');
      final notExists = await userService.checkEmailExists('nonexistent@example.com');
      print('Non-existent email check result: $notExists');

      expect(exists, true);
      expect(notExists, false);
      print('Email check successful');
    });

    test('Check email case-sensitive sesuai data yang disimpan', () async {
      print('Setting up email with specific case...');
      await firestore.collection('Users').doc('user_case').set({
        'user_name': 'Case User',
        'user_email': 'Test@Example.com',
        'user_auth': 1,
        'avatar': 'avatar.png',
      });
      print('Email created: Test@Example.com (case-sensitive)');

      print('Checking email with exact match...');
      final exists = await userService.checkEmailExists('Test@Example.com');
      print('Exact case match result: $exists');

      expect(exists, true);
      print('Case-sensitive email check successful');
    });

    test('Multiple users dengan email berbeda dapat dicek bersamaan', () async {
      print('Setting up multiple users...');
      await firestore.collection('Users').doc('user1').set({
        'user_name': 'User 1',
        'user_email': 'user1@example.com',
        'user_auth': 1,
        'avatar': 'avatar.png',
      });

      await firestore.collection('Users').doc('user2').set({
        'user_name': 'User 2',
        'user_email': 'user2@example.com',
        'user_auth': 1,
        'avatar': 'avatar.png',
      });
      print('Two users created with different emails');

      print('Performing concurrent email checks...');
      final results = await Future.wait([
        userService.checkEmailExists('user1@example.com'),
        userService.checkEmailExists('user2@example.com'),
        userService.checkEmailExists('user3@example.com'),
      ]);
      print('Concurrent check results: $results');

      expect(results[0], true);
      expect(results[1], true);
      expect(results[2], false);
      print('Concurrent email checks successful');
    });

    test('Email dengan spasi di awal/akhir dianggap berbeda', () async {
      print('Setting up clean email...');
      await firestore.collection('Users').doc('email_space').set({
        'user_name': 'Space Email User',
        'user_email': 'test@example.com',
        'user_auth': 1,
        'avatar': 'avatar.png',
      });
      print('Email created: test@example.com (no spaces)');

      print('Checking exact match...');
      final exactMatch = await userService.checkEmailExists('test@example.com');
      print('Exact match result: $exactMatch');

      print('Checking email with spaces...');
      final withSpace = await userService.checkEmailExists(' test@example.com ');
      print('With spaces result: $withSpace');

      expect(exactMatch, true);
      expect(withSpace, false); // Trimming not handled by service
      print('Space handling test successful');
    });

    test('Duplicate email dapat terdeteksi sebelum create user', () async {
      print('Setting up original user...');
      await firestore.collection('Users').doc('original').set({
        'user_name': 'Original User',
        'user_email': 'duplicate@example.com',
        'user_auth': 1,
        'avatar': 'avatar.png',
      });
      print('Original user created with duplicate@example.com');

      print('Checking for duplicate email...');
      final isDuplicate = await userService.checkEmailExists('duplicate@example.com');
      print('Duplicate check result: $isDuplicate');

      expect(isDuplicate, true);
      print('Duplicate email detection successful - would prevent user creation');
    });
  });

  // ==========================================================
  // NEGATIVE TESTS - USER NOT FOUND
  // ==========================================================
  group('UserService Tests - Negative Tests - User Not Found', () {
    test('Mengambil user dengan UID yang tidak ada mengembalikan null', () async {
      print('Attempting to retrieve non-existent user...');
      final result = await userService.getUser('non_existent_uid');
      print('Result for non-existent user: $result');

      expect(result, isNull);
      print('Null returned for non-existent user as expected');
    });

    test('Mengupdate user yang tidak ada melempar exception', () async {
      print('Attempting to update non-existent user...');
      try {
        await userService.updateUser('non_existent', 'New Name', 'avatar.png');
        print('No exception thrown - this might indicate a bug');
        fail('Expected exception but none was thrown');
      } catch (e) {
        print('Exception caught as expected: ${e.toString()}');
        expect(e.toString().contains('not-found'), true);
      }
    });

    test('GetUser dengan empty string UID mengembalikan null', () async {
      print('Attempting to retrieve user with empty UID...');
      final result = await userService.getUser('');
      print('Result for empty UID: $result');

      expect(result, isNull);
      print('Null returned for empty UID as expected');
    });

    test('UpdateAkun untuk user yang tidak ada melempar exception', () async {
      print('Attempting updateAkun on non-existent user...');
      try {
        final result = await userService.updateAkun(
          'non_existent_user',
          'Test Name',
          1,
          'test@example.com',
        );
        print('Update result: $result');
        // If no exception, check that it returns error message
        expect(result.contains('not-found') || result.contains('error'), true);
        print('Error message returned for non-existent user');
      } catch (e) {
        print('Exception caught as expected: ${e.toString()}');
        expect(e.toString().contains('not-found'), true);
      }
    });

    test('Update user yang baru dihapus melempar exception', () async {
      print('Creating temporary user...');
      await firestore.collection('Users').doc('temp_user').set({
        'user_name': 'Temporary',
        'user_email': 'temp@example.com',
        'user_auth': 1,
        'avatar': 'avatar.png',
      });
      print('Temporary user created');

      print('Deleting temporary user...');
      await userService.deleteUser('temp_user');
      print('Temporary user deleted');

      print('Attempting to update deleted user...');
      try {
        await userService.updateUser('temp_user', 'Updated', 'avatar.png');
        print('No exception thrown - this might indicate a bug');
        fail('Expected exception but none was thrown');
      } catch (e) {
        print('Exception caught as expected: ${e.toString()}');
      }
    });
  });

  // ==========================================================
  // NEGATIVE TESTS - INVALID DATA
  // ==========================================================
  group('UserService Tests - Negative Tests - Invalid Data', () {
    test('Sistem tetap stabil ketika data user tidak lengkap', () async {
      print('Creating user with incomplete data...');
      await firestore.collection('Users').doc('incomplete').set({
        'user_name': 'Incomplete User',
        // 'user_email' missing
        // 'user_auth' missing
        'avatar': 'avatar.png',
      });
      print('Incomplete user created (missing email and auth level)');

      print('Retrieving incomplete user...');
      final result = await userService.getUser('incomplete');
      print('Retrieved user data: ${result?.toMap()}');

      expect(result, isNotNull);
      expect(result?.userName, 'Incomplete User');
      expect(result?.userEmail, ''); // Default empty string
      expect(result?.userAuth, 0); // Default 0
      print('Incomplete data handled gracefully with defaults');
    });

    test('User dengan special characters di nama dapat diproses', () async {
      print('Creating user with special characters in name...');
      await firestore.collection('Users').doc('special').set({
        'user_name': "O'Brien Test @#\$%",
        'user_email': 'special@example.com',
        'user_auth': 1,
        'avatar': 'avatar.png',
      });
      print('User created with special characters in name');

      print('Retrieving user with special characters...');
      final result = await userService.getUser('special');
      print('Retrieved name: ${result?.userName}');

      expect(result, isNotNull);
      expect(result?.userName, "O'Brien Test @#\$%");
      print('Special characters in name handled correctly');
    });

    test('Email dengan format invalid tetap dapat disimpan', () async {
      print('Creating user with invalid email format...');
      await firestore.collection('Users').doc('invalid_email').set({
        'user_name': 'Invalid Email User',
        'user_email': 'not-an-email',
        'user_auth': 1,
        'avatar': 'avatar.png',
      });
      print('User created with invalid email: not-an-email');

      print('Retrieving user with invalid email...');
      final result = await userService.getUser('invalid_email');
      print('Retrieved email: ${result?.userEmail}');

      print('Checking if invalid email exists...');
      final emailExists = await userService.checkEmailExists('not-an-email');
      print('Invalid email exists check: $emailExists');

      expect(result, isNotNull);
      expect(emailExists, true);
      print('Invalid email format handled correctly');
    });

    test('UserAuth dengan nilai di luar range tetap dapat diproses', () async {
      print('Creating user with out-of-range auth value...');
      await firestore.collection('Users').doc('invalid_auth').set({
        'user_name': 'Invalid Auth',
        'user_email': 'invalid@example.com',
        'user_auth': -1,
        'avatar': 'avatar.png',
      });
      print('User created with negative auth value: -1');

      print('Retrieving user with invalid auth...');
      final result = await userService.getUser('invalid_auth');
      print('Retrieved auth value: ${result?.userAuth}');

      expect(result, isNotNull);
      expect(result?.userAuth, -1);
      print('Out-of-range auth value stored correctly');
    });
  });

  // ==========================================================
  // EDGE CASES - DATA INTEGRITY
  // ==========================================================
  group('UserService Tests - Edge Cases - Data Integrity', () {
    test('User list stream mengembalikan data kosong ketika tidak ada user', () async {
      print('Testing empty user list scenario...');
      final usersStream = userService.getUsers();
      final users = await usersStream.first;
      print('Empty user list result: ${users.length} users');

      expect(users.isEmpty, true);
      expect(users.length, 0);
      print('Empty user list handled correctly');
    });

    test('Multiple admin dapat mengakses user service secara bersamaan', () async {
      print('Setting up multiple users for concurrent access...');
      for (int i = 1; i <= 5; i++) {
        await firestore.collection('Users').doc('concurrent$i').set({
          'user_name': 'User $i',
          'user_email': 'user$i@example.com',
          'user_auth': 1,
          'avatar': 'avatar$i.png',
        });
      }
      print('5 users setup for concurrent access');

      print('Simulating concurrent user access...');
      final futures = <Future>[];
      for (int i = 1; i <= 5; i++) {
        futures.add(userService.getUser('concurrent$i'));
      }
      
      print('Waiting for all concurrent operations...');
      final results = await Future.wait(futures);
      print('Concurrent access completed: ${results.length} users retrieved');

      expect(results.length, 5);
      expect(results.every((user) => user != null), true);
      print('Concurrent access successful');
    });

    test('User dengan UID yang sangat panjang dapat diproses', () async {
      print('Creating user with very long UID...');
      final longUid = 'a' * 200; // Very long UID (200 characters)
      await firestore.collection('Users').doc(longUid).set({
        'user_name': 'Long UID User',
        'user_email': 'long@example.com',
        'user_auth': 1,
        'avatar': 'avatar.png',
      });
      print('User created with UID length: ${longUid.length}');

      print('Retrieving user with long UID...');
      final result = await userService.getUser(longUid);
      print('Retrieved UID length: ${result?.uid?.length}');

      expect(result, isNotNull);
      expect(result?.uid, longUid);
      print('Long UID handled correctly');
    });

    test('Stream tetap berfungsi setelah update data', () async {
      print('Creating initial user for stream test...');
      await firestore.collection('Users').doc('stream_test').set({
        'user_name': 'Initial Name',
        'user_email': 'stream@example.com',
        'user_auth': 1,
        'avatar': 'avatar.png',
      });
      print('Initial user created for stream test');

      print('Setting up users stream...');
      final usersStream = userService.getUsers();

      print('Updating user data while stream is active...');
      await userService.updateUser('stream_test', 'Updated Name', 'new_avatar.png');
      print('User data updated while streaming');

      print('Waiting for stream update...');
      final users = await usersStream.first;
      final updatedUser = users.firstWhere((u) => u.uid == 'stream_test');
      print('Updated user name: ${updatedUser.userName}');

      expect(updatedUser.userName, 'Updated Name');
      print('Stream updated correctly after data change');
    });
  });

  // ==========================================================
  // EDGE CASES - DELETE USER
  // ==========================================================
  group('UserService Tests - Edge Cases - Delete User', () {
    test('Admin dapat menghapus user dari Firestore', () async {
      print('Setting up user for deletion...');
      await firestore.collection('Users').doc('tobedeleted').set({
        'user_name': 'Delete Me',
        'user_email': 'delete@example.com',
        'user_auth': 1,
        'avatar': 'delete.png',
      });
      print('User setup for deletion: Delete Me');

      print('Deleting user...');
      await userService.deleteUser('tobedeleted');
      print('User deletion completed');

      print('Verifying deletion...');
      final doc = await firestore.collection('Users').doc('tobedeleted').get();
      expect(doc.exists, isFalse);
      print('User successfully deleted from Firestore');
    });

    test('Menghapus user yang sudah tidak ada tidak menyebabkan error', () async {
      print('Attempting to delete non-existent user...');
      try {
        await userService.deleteUser('already_deleted');
        print('Deletion of non-existent user completed without error');
        expect(true, isTrue); // No error = success
      } catch (e) {
        print('Error during deletion: $e');
        fail('Should not throw exception for non-existent user deletion');
      }
    });

    test('Setelah delete, getUser mengembalikan null', () async {
      print('Creating user for deletion test...');
      await firestore.collection('Users').doc('will_be_deleted').set({
        'user_name': 'Will Be Deleted',
        'user_email': 'willbedeleted@example.com',
        'user_auth': 1,
        'avatar': 'avatar.png',
      });
      print('User created for deletion test');

      print('Deleting user...');
      await userService.deleteUser('will_be_deleted');
      print('User deleted');

      print('Attempting to retrieve deleted user...');
      final result = await userService.getUser('will_be_deleted');
      print('Result after deletion: $result');

      expect(result, isNull);
      print('Null returned for deleted user as expected');
    });

    test('Delete user tidak mempengaruhi user lain', () async {
      print('Setting up two users for deletion test...');
      await firestore.collection('Users').doc('user_keep').set({
        'user_name': 'Keep Me',
        'user_email': 'keep@example.com',
        'user_auth': 1,
        'avatar': 'avatar.png',
      });

      await firestore.collection('Users').doc('user_delete').set({
        'user_name': 'Delete Me',
        'user_email': 'delete@example.com',
        'user_auth': 1,
        'avatar': 'avatar.png',
      });
      print('Two users created for test');

      print('Deleting one user...');
      await userService.deleteUser('user_delete');
      print('One user deleted');

      print('Checking remaining user...');
      final keepUser = await userService.getUser('user_keep');
      print('Keep user result: ${keepUser?.userName}');

      print('Checking deleted user...');
      final deletedUser = await userService.getUser('user_delete');
      print('Deleted user result: $deletedUser');

      expect(keepUser, isNotNull);
      expect(deletedUser, isNull);
      print('Delete operation only affected targeted user');
    });
  });

  // ==========================================================
  // EDGE CASES - BATCH OPERATIONS
  // ==========================================================
  group('UserService Tests - Edge Cases - Batch Operations', () {
    test('Multiple update operations secara berurutan', () async {
      print('Creating user for batch update test...');
      await firestore.collection('Users').doc('batch_user').set({
        'user_name': 'Original',
        'user_email': 'original@example.com',
        'user_auth': 1,
        'avatar': 'avatar1.png',
      });
      print('User created with original data');

      print('Performing multiple sequential updates...');
      await userService.updateUser('batch_user', 'Update 1', 'avatar2.png');
      print('Update 1 completed');
      
      await userService.updateUser('batch_user', 'Update 2', 'avatar3.png');
      print('Update 2 completed');
      
      await userService.updateUser('batch_user', 'Final Update', 'avatar4.png');
      print('Final update completed');

      print('Verifying final state...');
      final result = await userService.getUser('batch_user');
      print('Final user name: ${result?.userName}');
      print('Final avatar: ${result?.avatar}');

      expect(result?.userName, 'Final Update');
      expect(result?.avatar, 'avatar4.png');
      print('Sequential updates successful - final state correct');
    });

    test('GetUsers stream dengan banyak user (performance test)', () async {
      print('Creating 50 users for performance test...');
      for (int i = 1; i <= 50; i++) {
        await firestore.collection('Users').doc('perf_user_$i').set({
          'user_name': 'Performance User $i',
          'user_email': 'perf$i@example.com',
          'user_auth': 1,
          'avatar': 'avatar.png',
        });
      }
      print('50 users created for performance test');

      print('Measuring performance of GetUsers stream...');
      final stopwatch = Stopwatch()..start();
      final usersStream = userService.getUsers();
      final users = await usersStream.first;
      stopwatch.stop();
      
      final elapsedMs = stopwatch.elapsedMilliseconds;
      print('GetUsers took: ${elapsedMs}ms');
      print('Users retrieved: ${users.length}');

      expect(users.length, 50);
      expect(elapsedMs, lessThan(5000)); // Should complete in under 5 seconds
      print('Performance test passed - GetUsers completed in ${elapsedMs}ms');
    });

    test('Bulk operations on multiple users', () async {
      print('Creating multiple users for bulk operations...');
      final userCount = 10;
      for (int i = 1; i <= userCount; i++) {
        await firestore.collection('Users').doc('bulk_user_$i').set({
          'user_name': 'Bulk User $i',
          'user_email': 'bulk$i@example.com',
          'user_auth': 1,
          'avatar': 'avatar$i.png',
        });
      }
      print('$userCount users created for bulk operations');

      print('Performing bulk read operations...');
      final futures = <Future>[];
      for (int i = 1; i <= userCount; i++) {
        futures.add(userService.getUser('bulk_user_$i'));
      }
      
      final results = await Future.wait(futures);
      print('Bulk read completed: ${results.length} users retrieved');

      expect(results.length, userCount);
      expect(results.every((user) => user != null), true);
      print('Bulk operations successful');
    });
  });

  // ==========================================================
  // TEST SUMMARY
  // ==========================================================
  tearDown(() {
    print('Cleaning up test environment...');
    print('Test completed');
    print('=' * 50);
  });
}