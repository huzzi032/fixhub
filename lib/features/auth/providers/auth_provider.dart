import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/auth/app_auth_user.dart';
import '../../../core/auth/local_auth_service.dart';
import '../../../shared/models/user_model.dart';

// Auth State
final authStateProvider = StreamProvider<AppAuthUser?>((ref) {
  return LocalAuthService.instance.authStateChanges();
});

// Current User Provider
final currentUserProvider = Provider<AppAuthUser?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.maybeWhen(
    data: (user) => user,
    orElse: () => LocalAuthService.instance.currentUser,
  );
});

// User Data Provider
final userDataProvider = StreamProvider.family<UserModel?, String>((ref, uid) {
  return LocalAuthService.instance.watchUserData(uid);
});

// Current User Data Provider
final currentUserDataProvider = StreamProvider<UserModel?>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value(null);
  return LocalAuthService.instance.watchUserData(user.uid);
});

// Auth Notifier
class AuthNotifier extends StateNotifier<AsyncValue<void>> {
  AuthNotifier() : super(const AsyncValue.data(null));

  // Email Authentication
  Future<void> signInWithEmail(String email, String password) async {
    state = const AsyncValue.loading();

    try {
      await LocalAuthService.instance.signInWithEmail(
        email: email,
        password: password,
      );
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> signUpWithEmail(
    String email,
    String password,
    String name,
  ) async {
    state = const AsyncValue.loading();

    try {
      await LocalAuthService.instance.signUpWithEmail(
        email: email,
        password: password,
        name: name,
      );

      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> resetPassword(String email) async {
    state = const AsyncValue.loading();

    try {
      await LocalAuthService.instance.resetPassword(email);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  // Sign Out
  Future<void> signOut() async {
    state = const AsyncValue.loading();

    try {
      await LocalAuthService.instance.signOut();
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  // Check if user exists
  Future<bool> checkUserExists(String uid) async {
    return LocalAuthService.instance.userExists(uid);
  }

  // Create user document
  Future<void> createUserDocument({
    required String uid,
    required String name,
    required String phone,
    String? email,
    required String role,
  }) async {
    state = const AsyncValue.loading();

    try {
      await LocalAuthService.instance.createUserDocument(
        uid: uid,
        name: name,
        phone: phone,
        email: email,
        role: role,
      );

      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

// Auth Notifier Provider
final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<void>>((ref) {
  return AuthNotifier();
});

// Auth Form State
final authFormProvider = StateProvider<Map<String, String>>((ref) => {
      'email': '',
      'password': '',
      'confirmPassword': '',
      'name': '',
    });

// Selected Role Provider
final selectedRoleProvider = StateProvider<String?>((ref) => null);
