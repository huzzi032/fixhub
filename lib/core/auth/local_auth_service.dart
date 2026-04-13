import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../constants/app_constants.dart';
import '../../shared/models/user_model.dart';
import '../database/app_database.dart';
import 'app_auth_user.dart';

class LocalAuthService {
  LocalAuthService._();

  static final LocalAuthService instance = LocalAuthService._();
  static const _sessionUidKey = 'fixhub.session.uid';

  final StreamController<AppAuthUser?> _authStateController =
      StreamController<AppAuthUser?>.broadcast();
  final StreamController<String> _userDataEventsController =
      StreamController<String>.broadcast();

  SharedPreferences? _preferences;
  AppAuthUser? _currentUser;
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    await AppDatabase.instance.initialize();
    _preferences = await SharedPreferences.getInstance();

    final sessionUid = _preferences?.getString(_sessionUidKey);
    if (sessionUid != null && sessionUid.isNotEmpty) {
      _currentUser = await _findAuthUserByUid(sessionUid);
      if (_currentUser == null) {
        await _preferences?.remove(_sessionUidKey);
      }
    }

    _authStateController.add(_currentUser);
    _isInitialized = true;
  }

  Stream<AppAuthUser?> authStateChanges() => _authStateController.stream;

  AppAuthUser? get currentUser => _currentUser;

  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final db = await AppDatabase.instance.database;
    final normalizedEmail = email.trim().toLowerCase();
    _validateEmailOrThrow(normalizedEmail);

    final rows = await db.query(
      'auth_accounts',
      where: 'email = ?',
      whereArgs: <Object>[normalizedEmail],
      limit: 1,
    );

    if (rows.isEmpty) {
      throw const AppAuthException(
          'user-not-found', 'No account found with this email.');
    }

    final row = rows.first;
    final savedHash = row['password_hash'] as String?;
    if (savedHash == null || savedHash.isEmpty) {
      throw const AppAuthException(
        'operation-not-allowed',
        'This account does not support email sign in.',
      );
    }

    if (savedHash != _hashPassword(password)) {
      throw const AppAuthException('wrong-password', 'Incorrect password.');
    }

    final user = _authUserFromRow(row);
    await _setCurrentUser(user);
  }

  Future<AppAuthUser> signUpWithEmail({
    required String email,
    required String password,
    required String name,
  }) async {
    final db = await AppDatabase.instance.database;
    final normalizedEmail = email.trim().toLowerCase();
    _validateEmailOrThrow(normalizedEmail);

    final existing = await db.query(
      'auth_accounts',
      where: 'email = ?',
      whereArgs: <Object>[normalizedEmail],
      limit: 1,
    );

    if (existing.isNotEmpty) {
      throw const AppAuthException(
        'email-already-in-use',
        'An account already exists with this email.',
      );
    }

    final uid = const Uuid().v4();
    final createdAt = DateTime.now().millisecondsSinceEpoch;

    await db.insert(
      'auth_accounts',
      <String, Object?>{
        'uid': uid,
        'email': normalizedEmail,
        'phone': null,
        'display_name': name.trim(),
        'password_hash': _hashPassword(password),
        'created_at': createdAt,
      },
    );

    final user = AppAuthUser(
      uid: uid,
      email: normalizedEmail,
      displayName: name.trim(),
    );

    await _setCurrentUser(user);
    return user;
  }

  Future<void> resetPassword(String email) async {
    final db = await AppDatabase.instance.database;
    final normalizedEmail = email.trim().toLowerCase();
    _validateEmailOrThrow(normalizedEmail);

    final rows = await db.query(
      'auth_accounts',
      where: 'email = ?',
      whereArgs: <Object>[normalizedEmail],
      limit: 1,
    );

    if (rows.isEmpty) {
      throw const AppAuthException(
          'user-not-found', 'No account found with this email.');
    }

    // Local mode cannot send emails. Keep this as a successful no-op.
  }

  Future<void> signOut() async {
    _currentUser = null;
    await _preferences?.remove(_sessionUidKey);
    _authStateController.add(null);
  }

  Future<bool> userExists(String uid) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query(
      'users',
      columns: <String>['uid'],
      where: 'uid = ?',
      whereArgs: <Object>[uid],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  Future<UserModel?> getUserData(String uid) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query(
      'users',
      where: 'uid = ?',
      whereArgs: <Object>[uid],
      limit: 1,
    );

    if (rows.isEmpty) {
      return null;
    }

    return UserModel.fromMap(Map<String, dynamic>.from(rows.first));
  }

  Stream<UserModel?> watchUserData(String uid) async* {
    yield await getUserData(uid);

    await for (final changedUid in _userDataEventsController.stream) {
      if (changedUid == uid) {
        yield await getUserData(uid);
      }
    }
  }

  Future<void> createUserDocument({
    required String uid,
    required String name,
    required String phone,
    String? email,
    required String role,
  }) async {
    final db = await AppDatabase.instance.database;
    final now = DateTime.now().millisecondsSinceEpoch;

    await db.insert(
      'users',
      <String, Object?>{
        'uid': uid,
        'name': name,
        'phone': phone,
        'email': email,
        'role': role,
        'profile_photo_url': null,
        'fcm_token': null,
        'created_at': now,
        'is_active': 1,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    if (role == 'customer') {
      await db.insert(
        'customers',
        <String, Object?>{
          'user_id': uid,
          'saved_addresses': jsonEncode(<Map<String, dynamic>>[]),
          'loyalty_points': 0,
          'total_orders_placed': 0,
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }

    if (role == 'provider') {
      await db.insert(
        'providers',
        <String, Object?>{
          'user_id': uid,
          'verification_status': 'pending',
          'wallet_balance': 0,
          'earnings_total': 0,
          'joined_at': now,
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }

    _userDataEventsController.add(uid);

    if (_currentUser?.uid == uid) {
      _currentUser = _currentUser?.copyWith(
        displayName: name,
        email: email ?? _currentUser?.email,
        phoneNumber: phone,
      );
      _authStateController.add(_currentUser);
    }
  }

  Future<void> updateUserProfile({
    required String uid,
    required String name,
    required String phone,
    String? email,
  }) async {
    final db = await AppDatabase.instance.database;
    final normalizedEmail = email?.trim().toLowerCase();

    if (normalizedEmail != null && normalizedEmail.isNotEmpty) {
      _validateEmailOrThrow(normalizedEmail);
    }

    await db.update(
      'users',
      <String, Object?>{
        'name': name.trim(),
        'phone': phone.trim(),
        'email': normalizedEmail == null || normalizedEmail.isEmpty
            ? null
            : normalizedEmail,
      },
      where: 'uid = ?',
      whereArgs: <Object>[uid],
    );

    await db.update(
      'auth_accounts',
      <String, Object?>{
        'display_name': name.trim(),
        'phone': phone.trim().isEmpty ? null : phone.trim(),
        if (normalizedEmail != null && normalizedEmail.isNotEmpty)
          'email': normalizedEmail,
      },
      where: 'uid = ?',
      whereArgs: <Object>[uid],
    );

    _userDataEventsController.add(uid);

    if (_currentUser?.uid == uid) {
      _currentUser = _currentUser?.copyWith(
        displayName: name.trim(),
        phoneNumber: phone.trim().isEmpty ? null : phone.trim(),
        email: normalizedEmail == null || normalizedEmail.isEmpty
            ? _currentUser?.email
            : normalizedEmail,
      );
      _authStateController.add(_currentUser);
    }
  }

  Future<List<SavedAddress>> getSavedAddresses(String uid) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query(
      'customers',
      columns: <String>['saved_addresses'],
      where: 'user_id = ?',
      whereArgs: <Object>[uid],
      limit: 1,
    );

    if (rows.isEmpty) {
      return <SavedAddress>[];
    }

    final raw = rows.first['saved_addresses'] as String?;
    if (raw == null || raw.isEmpty) {
      return <SavedAddress>[];
    }

    final decoded = jsonDecode(raw);
    if (decoded is! List<dynamic>) {
      return <SavedAddress>[];
    }

    return decoded
        .whereType<Map<String, dynamic>>()
        .map(SavedAddress.fromMap)
        .toList();
  }

  Future<void> addSavedAddress({
    required String uid,
    required String label,
    required String address,
  }) async {
    final db = await AppDatabase.instance.database;
    final current = await getSavedAddresses(uid);

    final updated = <SavedAddress>[
      ...current,
      SavedAddress(
        id: const Uuid().v4(),
        label: label.trim(),
        address: address.trim(),
      ),
    ];

    await db.insert(
      'customers',
      <String, Object?>{
        'user_id': uid,
        'saved_addresses': jsonEncode(updated.map((a) => a.toMap()).toList()),
        'loyalty_points': 0,
        'total_orders_placed': 0,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );

    await db.update(
      'customers',
      <String, Object?>{
        'saved_addresses': jsonEncode(updated.map((a) => a.toMap()).toList()),
      },
      where: 'user_id = ?',
      whereArgs: <Object>[uid],
    );
  }

  Future<void> removeSavedAddress({
    required String uid,
    required String addressId,
  }) async {
    final db = await AppDatabase.instance.database;
    final current = await getSavedAddresses(uid);
    final updated = current.where((item) => item.id != addressId).toList();

    await db.update(
      'customers',
      <String, Object?>{
        'saved_addresses': jsonEncode(updated.map((a) => a.toMap()).toList()),
      },
      where: 'user_id = ?',
      whereArgs: <Object>[uid],
    );
  }

  Future<AppAuthUser?> _findAuthUserByUid(String uid) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query(
      'auth_accounts',
      where: 'uid = ?',
      whereArgs: <Object>[uid],
      limit: 1,
    );

    if (rows.isEmpty) {
      return null;
    }

    return _authUserFromRow(rows.first);
  }

  AppAuthUser _authUserFromRow(Map<String, Object?> row) {
    return AppAuthUser(
      uid: row['uid'] as String,
      email: row['email'] as String?,
      phoneNumber: row['phone'] as String?,
      displayName: row['display_name'] as String?,
    );
  }

  Future<void> _setCurrentUser(AppAuthUser user) async {
    _currentUser = user;
    await _preferences?.setString(_sessionUidKey, user.uid);
    _authStateController.add(user);
  }

  String _hashPassword(String password) {
    return sha256.convert(utf8.encode(password)).toString();
  }

  void _validateEmailOrThrow(String email) {
    final regex = RegExp(AppConstants.emailRegex);
    final normalized = email.trim().toLowerCase();

    if (normalized.isEmpty || normalized.contains('..')) {
      throw const AppAuthException(
          'invalid-email', 'Please enter a valid email address.');
    }

    final parts = normalized.split('@');
    if (parts.length != 2 ||
        parts[0].isEmpty ||
        parts[0].startsWith('.') ||
        parts[0].endsWith('.') ||
        parts[1].isEmpty ||
        !parts[1].contains('.')) {
      throw const AppAuthException(
          'invalid-email', 'Please enter a valid email address.');
    }

    if (!regex.hasMatch(normalized)) {
      throw const AppAuthException(
          'invalid-email', 'Please enter a valid email address.');
    }
  }
}
