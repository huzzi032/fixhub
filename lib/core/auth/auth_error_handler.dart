import 'app_auth_user.dart';

class AuthErrorHandler {
  static String getErrorMessage(Object error) {
    if (error is AppAuthException) {
      return error.message;
    }

    return 'An unexpected error occurred. Please try again.';
  }
}
