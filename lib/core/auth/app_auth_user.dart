class AppAuthUser {
  final String uid;
  final String? email;
  final String? phoneNumber;
  final String? displayName;

  const AppAuthUser({
    required this.uid,
    this.email,
    this.phoneNumber,
    this.displayName,
  });

  AppAuthUser copyWith({
    String? uid,
    String? email,
    String? phoneNumber,
    String? displayName,
  }) {
    return AppAuthUser(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      displayName: displayName ?? this.displayName,
    );
  }
}

class AppAuthException implements Exception {
  final String code;
  final String message;

  const AppAuthException(this.code, this.message);

  @override
  String toString() {
    return message;
  }
}
