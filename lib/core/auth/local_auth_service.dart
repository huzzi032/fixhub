import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';
import '../../shared/models/user_model.dart';
import 'app_auth_user.dart';

class LocalAuthService {
  LocalAuthService._();

  static final LocalAuthService instance = LocalAuthService._();
  static const _sessionUidKey = 'fixhub.session.uid';
  static const _sessionTokenKey = 'fixhub.session.token';
  static const _sessionUserKey = 'fixhub.session.user';
  static const _requestTimeout = Duration(seconds: 20);

  final StreamController<AppAuthUser?> _authStateController =
      StreamController<AppAuthUser?>.broadcast();
  final StreamController<String> _userDataEventsController =
      StreamController<String>.broadcast();

  SharedPreferences? _preferences;
  AppAuthUser? _currentUser;
  String? _accessToken;
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    _preferences = await SharedPreferences.getInstance();

    _accessToken = _preferences?.getString(_sessionTokenKey);

    final cachedUserJson = _preferences?.getString(_sessionUserKey);
    if (cachedUserJson != null && cachedUserJson.isNotEmpty) {
      try {
        final decoded = jsonDecode(cachedUserJson);
        if (decoded is Map<String, dynamic>) {
          _currentUser = _authUserFromJson(decoded);
        }
      } catch (_) {
        // Ignore cache parsing errors and continue with clean auth state.
      }
    }

    final sessionUid = _preferences?.getString(_sessionUidKey);
    if (_currentUser == null && sessionUid != null && sessionUid.isNotEmpty) {
      _currentUser = AppAuthUser(uid: sessionUid);
    }

    if (_currentUser != null && _accessToken != null) {
      try {
        await _refreshSessionUser();
      } on AppAuthException catch (error) {
        if (error.code == 'unauthorized') {
          await _clearSession(notify: false);
        }
      } catch (_) {
        // Keep cached session when offline.
      }
    }

    _authStateController.add(_currentUser);
    _isInitialized = true;
  }

  Stream<AppAuthUser?> authStateChanges() => _authStateController.stream;

  AppAuthUser? get currentUser => _currentUser;

  Future<Map<String, dynamic>> request({
    required String method,
    required String path,
    Map<String, dynamic>? body,
    bool requireAuth = false,
  }) {
    return _sendRequest(
      method: method,
      path: path,
      body: body,
      requireAuth: requireAuth,
    );
  }

  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    _validateEmailOrThrow(normalizedEmail);

    final response = await _sendRequest(
      method: 'POST',
      path: '/api/auth/email-signin',
      body: <String, dynamic>{
        'email': normalizedEmail,
        'password': password,
      },
    );

    final token = (response['token'] ?? '').toString().trim();
    final userMap = response['user'];
    if (token.isEmpty || userMap is! Map<String, dynamic>) {
      throw const AppAuthException(
        'invalid-response',
        'Invalid sign in response from server.',
      );
    }

    final user = _parseAuthUser(userMap);
    await _setCurrentUser(user: user, token: token);
    _userDataEventsController.add(user.uid);
  }

  Future<AppAuthUser> signUpWithEmail({
    required String email,
    required String password,
    required String name,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    _validateEmailOrThrow(normalizedEmail);

    final response = await _sendRequest(
      method: 'POST',
      path: '/api/auth/email-signup',
      body: <String, dynamic>{
        'name': name.trim(),
        'email': normalizedEmail,
        'password': password,
      },
    );

    final token = (response['token'] ?? '').toString().trim();
    final userMap = response['user'];
    if (token.isEmpty || userMap is! Map<String, dynamic>) {
      throw const AppAuthException(
        'invalid-response',
        'Invalid sign up response from server.',
      );
    }

    final user = _parseAuthUser(userMap);
    await _setCurrentUser(user: user, token: token);
    _userDataEventsController.add(user.uid);
    return user;
  }

  Future<void> resetPassword(String email) async {
    final normalizedEmail = email.trim().toLowerCase();
    _validateEmailOrThrow(normalizedEmail);

    // Backend currently does not expose password reset email APIs.
    // Keep this as a successful no-op to preserve current UX.
  }

  Future<void> signOut() async {
    await _clearSession(notify: true);
  }

  Future<bool> userExists(String uid) async {
    final data = await getUserData(uid);
    return data != null;
  }

  Future<UserModel?> getUserData(String uid) async {
    if (_currentUser == null || _accessToken == null) {
      return null;
    }

    if (_currentUser!.uid != uid) {
      return null;
    }

    final response = await _sendRequest(
      method: 'GET',
      path: '/api/users/me',
      requireAuth: true,
    );

    final userData = response['user'];
    if (userData is! Map<String, dynamic>) {
      throw const AppAuthException(
        'invalid-response',
        'Invalid user response from server.',
      );
    }

    final authUser = _parseAuthUser(userData);
    await _cacheCurrentUser(authUser, notify: false);

    final profile = userData['profile'];
    if (profile is! Map<String, dynamic>) {
      return null;
    }

    final mapped = <String, dynamic>{
      'uid': userData['uid']?.toString() ?? uid,
      'name': profile['name']?.toString() ?? authUser.displayName ?? 'User',
      'phone': profile['phone']?.toString() ?? authUser.phoneNumber ?? '',
      'email': profile['email']?.toString() ?? authUser.email,
      'role': profile['role']?.toString() ?? 'customer',
      'profile_photo_url': profile['profilePhotoUrl'],
      'fcm_token': profile['fcmToken'],
      'created_at':
          profile['createdAt'] ?? DateTime.now().millisecondsSinceEpoch,
      'is_active': profile['isActive'] ?? true,
    };

    return UserModel.fromMap(mapped);
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
    if (_currentUser == null || _currentUser!.uid != uid) {
      throw const AppAuthException(
        'unauthorized',
        'Current session does not match target user.',
      );
    }

    await _sendRequest(
      method: 'POST',
      path: '/api/users/create-profile',
      requireAuth: true,
      body: <String, dynamic>{
        'name': name.trim(),
        'phone': phone.trim(),
        'email': email?.trim().isEmpty == true ? null : email?.trim(),
        'role': role,
      },
    );

    _userDataEventsController.add(uid);

    if (_currentUser?.uid == uid) {
      final updated = _currentUser!.copyWith(
        displayName: name,
        email: email ?? _currentUser?.email,
        phoneNumber: phone,
      );
      await _cacheCurrentUser(updated, notify: true);
    }
  }

  Future<void> updateUserProfile({
    required String uid,
    required String name,
    required String phone,
    String? email,
  }) async {
    final normalizedEmail = email?.trim().toLowerCase();

    if (normalizedEmail != null && normalizedEmail.isNotEmpty) {
      _validateEmailOrThrow(normalizedEmail);
    }

    if (_currentUser == null || _currentUser!.uid != uid) {
      throw const AppAuthException(
        'unauthorized',
        'Current session does not match target user.',
      );
    }

    final existing = await getUserData(uid);
    final role = existing?.role ?? 'customer';

    await _sendRequest(
      method: 'POST',
      path: '/api/users/create-profile',
      requireAuth: true,
      body: <String, dynamic>{
        'name': name.trim(),
        'phone': phone.trim(),
        'email': normalizedEmail == null || normalizedEmail.isEmpty
            ? null
            : normalizedEmail,
        'role': role,
      },
    );

    _userDataEventsController.add(uid);

    if (_currentUser?.uid == uid) {
      final updated = _currentUser!.copyWith(
        displayName: name.trim(),
        phoneNumber: phone.trim().isEmpty ? null : phone.trim(),
        email: normalizedEmail == null || normalizedEmail.isEmpty
            ? _currentUser?.email
            : normalizedEmail,
      );
      await _cacheCurrentUser(updated, notify: true);
    }
  }

  Future<List<SavedAddress>> getSavedAddresses(String uid) async {
    if (_currentUser == null || _currentUser!.uid != uid) {
      return <SavedAddress>[];
    }

    final response = await _sendRequest(
      method: 'GET',
      path: '/api/users/saved-addresses',
      requireAuth: true,
    );

    final savedAddresses = response['savedAddresses'];
    if (savedAddresses is! List<dynamic>) {
      return <SavedAddress>[];
    }

    return savedAddresses
        .whereType<Map<String, dynamic>>()
        .map(SavedAddress.fromMap)
        .toList();
  }

  Future<void> addSavedAddress({
    required String uid,
    required String label,
    required String address,
  }) async {
    if (_currentUser == null || _currentUser!.uid != uid) {
      throw const AppAuthException(
        'unauthorized',
        'Current session does not match target user.',
      );
    }

    await _sendRequest(
      method: 'POST',
      path: '/api/users/add-saved-address',
      requireAuth: true,
      body: <String, dynamic>{
        'label': label.trim(),
        'address': address.trim(),
      },
    );

    _userDataEventsController.add(uid);
  }

  Future<void> removeSavedAddress({
    required String uid,
    required String addressId,
  }) async {
    if (_currentUser == null || _currentUser!.uid != uid) {
      throw const AppAuthException(
        'unauthorized',
        'Current session does not match target user.',
      );
    }

    await _sendRequest(
      method: 'POST',
      path: '/api/users/remove-saved-address',
      requireAuth: true,
      body: <String, dynamic>{'addressId': addressId},
    );

    _userDataEventsController.add(uid);
  }

  Future<void> submitProviderRegistration({
    required String uid,
  }) async {
    if (_currentUser == null || _currentUser!.uid != uid) {
      throw const AppAuthException(
        'unauthorized',
        'Current session does not match target user.',
      );
    }

    final existing = await getUserData(uid);
    final fallbackName = _currentUser?.displayName?.trim();
    final name = existing?.name.trim().isNotEmpty == true
        ? existing!.name.trim()
        : (fallbackName?.isNotEmpty == true ? fallbackName! : 'Provider');

    final phone = existing?.phone ?? _currentUser?.phoneNumber ?? '';
    final email = existing?.email ?? _currentUser?.email;

    await createUserDocument(
      uid: uid,
      name: name,
      phone: phone,
      email: email,
      role: 'provider',
    );
  }

  Future<String> getProviderVerificationStatus(String uid) async {
    if (_currentUser == null || _currentUser!.uid != uid) {
      return 'pending';
    }

    final response = await _sendRequest(
      method: 'GET',
      path: '/api/users/provider-status',
      requireAuth: true,
    );

    final status = response['verificationStatus']?.toString().trim();
    if (status == null || status.isEmpty) {
      return 'pending';
    }

    return status;
  }

  AppAuthUser _parseAuthUser(Map<String, dynamic> row) {
    final uid = (row['uid'] ?? '').toString().trim();
    if (uid.isEmpty) {
      throw const AppAuthException(
        'invalid-response',
        'Missing user id in server response.',
      );
    }

    return AppAuthUser(
      uid: uid,
      email: row['email']?.toString(),
      phoneNumber: row['phoneNumber']?.toString() ?? row['phone']?.toString(),
      displayName:
          row['displayName']?.toString() ?? row['display_name']?.toString(),
    );
  }

  AppAuthUser? _authUserFromJson(Map<String, dynamic> json) {
    final uid = (json['uid'] ?? '').toString().trim();
    if (uid.isEmpty) {
      return null;
    }

    return AppAuthUser(
      uid: uid,
      email: json['email']?.toString(),
      phoneNumber: json['phoneNumber']?.toString(),
      displayName: json['displayName']?.toString(),
    );
  }

  Future<void> _setCurrentUser({
    required AppAuthUser user,
    required String token,
  }) async {
    _accessToken = token;
    await _preferences?.setString(_sessionTokenKey, token);
    await _cacheCurrentUser(user, notify: true);
  }

  Future<void> _cacheCurrentUser(
    AppAuthUser user, {
    required bool notify,
  }) async {
    _currentUser = user;
    await _preferences?.setString(_sessionUidKey, user.uid);
    await _preferences?.setString(
      _sessionUserKey,
      jsonEncode(<String, dynamic>{
        'uid': user.uid,
        'email': user.email,
        'phoneNumber': user.phoneNumber,
        'displayName': user.displayName,
      }),
    );

    if (notify) {
      _authStateController.add(user);
    }
  }

  Future<void> _clearSession({required bool notify}) async {
    _currentUser = null;
    _accessToken = null;
    await _preferences?.remove(_sessionUidKey);
    await _preferences?.remove(_sessionTokenKey);
    await _preferences?.remove(_sessionUserKey);

    if (notify) {
      _authStateController.add(null);
    }
  }

  String _resolveApiBaseUrl() {
    final configured =
        const String.fromEnvironment('FIXHUB_API_BASE_URL', defaultValue: '')
            .trim();

    if (configured.isEmpty) {
      throw const AppAuthException(
        'config-missing',
        'Backend URL is missing. Rebuild with --dart-define=FIXHUB_API_BASE_URL=https://your-backend.vercel.app',
      );
    }

    return configured.endsWith('/')
        ? configured.substring(0, configured.length - 1)
        : configured;
  }

  Future<void> _refreshSessionUser() async {
    final user = _currentUser;
    if (user == null) {
      return;
    }

    try {
      await getUserData(user.uid);
    } catch (_) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> _sendRequest({
    required String method,
    required String path,
    Map<String, dynamic>? body,
    bool requireAuth = false,
  }) async {
    final baseUrl = _resolveApiBaseUrl();
    final uri = Uri.parse('$baseUrl$path');
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (requireAuth) {
      final token = _accessToken;
      if (token == null || token.isEmpty) {
        throw const AppAuthException(
          'unauthorized',
          'Please sign in to continue.',
        );
      }
      headers['Authorization'] = 'Bearer $token';
    }

    http.Response response;
    try {
      switch (method.toUpperCase()) {
        case 'GET':
          response =
              await http.get(uri, headers: headers).timeout(_requestTimeout);
          break;
        case 'POST':
          response = await http
              .post(
                uri,
                headers: headers,
                body: body == null ? null : jsonEncode(body),
              )
              .timeout(_requestTimeout);
          break;
        default:
          throw AppAuthException(
            'invalid-request',
            'Unsupported HTTP method: $method',
          );
      }
    } on TimeoutException {
      throw const AppAuthException(
        'timeout',
        'Request timed out. Please try again.',
      );
    } on SocketException {
      throw const AppAuthException(
        'network-error',
        'Cannot reach server. Check your internet connection.',
      );
    }

    Map<String, dynamic> payload = <String, dynamic>{};
    final rawBody = utf8.decode(response.bodyBytes);
    if (rawBody.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(rawBody);
        if (decoded is Map<String, dynamic>) {
          payload = decoded;
        } else if (decoded is Map) {
          payload = Map<String, dynamic>.from(decoded);
        }
      } catch (_) {
        // Keep payload empty when server body is not valid JSON.
      }
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return payload;
    }

    final message = payload['error']?.toString() ?? 'Request failed.';

    if (response.statusCode == 401) {
      await _clearSession(notify: true);
      throw AppAuthException('unauthorized', message);
    }

    if (response.statusCode == 404) {
      throw AppAuthException('not-found', message);
    }

    if (response.statusCode == 409) {
      throw AppAuthException('conflict', message);
    }

    if (response.statusCode == 400) {
      throw AppAuthException('invalid-request', message);
    }

    throw AppAuthException('request-failed', message);
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
