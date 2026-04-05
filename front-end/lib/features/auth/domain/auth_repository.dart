import '../../../shared/models/user.dart';

/// Abstract repository for authentication operations
/// This defines the contract that all auth repository implementations must follow
abstract class AuthRepository {
  /// Login user with email and password
  /// Returns a User object with token if successful
  /// Throws an exception if login fails
  Future<User> login(String email, String password);

  /// Login user with Google Sign-In
  /// Returns a User object if successful
  Future<User> loginWithGoogle();

  /// Register a new user
  /// Returns a User object with token if successful
  /// Throws an exception if registration fails
  Future<User> register(
    String firstName,
    String lastName,
    String email,
    String password,
  );

  /// Logout current user
  /// Clears token and user data
  /// Returns void if successful
  /// Throws an exception if logout fails
  Future<void> logout();

  /// Get current authenticated user
  /// Returns User if user is logged in, null otherwise
  /// Throws an exception if there's an error fetching user data
  Future<User?> getCurrentUser();
}
