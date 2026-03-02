import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../utilities/app_constants.dart';
import '../utilities/app_exception.dart';

/// Storage Service
/// 
/// Handles secure storage of tokens and user data using flutter_secure_storage.
/// Provides a clean interface for storing and retrieving sensitive information.
class StorageService {
  final FlutterSecureStorage _secureStorage;

  StorageService({FlutterSecureStorage? secureStorage})
      : _secureStorage = secureStorage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(
                encryptedSharedPreferences: true,
              ),
            );

  // Token Management

  /// Save access token securely
  Future<void> saveAccessToken(String token) async {
    try {
      await _secureStorage.write(
        key: AppConstants.accessTokenKey,
        value: token,
      );
    } catch (e) {
      throw CacheException('Failed to save access token', originalError: e);
    }
  }

  /// Get access token
  Future<String?> getAccessToken() async {
    try {
      return await _secureStorage.read(key: AppConstants.accessTokenKey);
    } catch (e) {
      throw CacheException('Failed to retrieve access token', originalError: e);
    }
  }

  /// Save refresh token securely
  Future<void> saveRefreshToken(String token) async {
    try {
      await _secureStorage.write(
        key: AppConstants.refreshTokenKey,
        value: token,
      );
    } catch (e) {
      throw CacheException('Failed to save refresh token', originalError: e);
    }
  }

  /// Get refresh token
  Future<String?> getRefreshToken() async {
    try {
      return await _secureStorage.read(key: AppConstants.refreshTokenKey);
    } catch (e) {
      throw CacheException('Failed to retrieve refresh token', originalError: e);
    }
  }

  /// Save both access and refresh tokens
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await Future.wait([
      saveAccessToken(accessToken),
      saveRefreshToken(refreshToken),
    ]);
  }

  /// Delete access token
  Future<void> deleteAccessToken() async {
    try {
      await _secureStorage.delete(key: AppConstants.accessTokenKey);
    } catch (e) {
      throw CacheException('Failed to delete access token', originalError: e);
    }
  }

  /// Delete refresh token
  Future<void> deleteRefreshToken() async {
    try {
      await _secureStorage.delete(key: AppConstants.refreshTokenKey);
    } catch (e) {
      throw CacheException('Failed to delete refresh token', originalError: e);
    }
  }

  /// Delete all tokens
  Future<void> deleteTokens() async {
    await Future.wait([
      deleteAccessToken(),
      deleteRefreshToken(),
    ]);
  }

  // User Data Management

  /// Save user ID
  Future<void> saveUserId(String userId) async {
    try {
      await _secureStorage.write(
        key: AppConstants.userIdKey,
        value: userId,
      );
    } catch (e) {
      throw CacheException('Failed to save user ID', originalError: e);
    }
  }

  /// Get user ID
  Future<String?> getUserId() async {
    try {
      return await _secureStorage.read(key: AppConstants.userIdKey);
    } catch (e) {
      throw CacheException('Failed to retrieve user ID', originalError: e);
    }
  }

  /// Save username
  Future<void> saveUsername(String username) async {
    try {
      await _secureStorage.write(
        key: AppConstants.usernameKey,
        value: username,
      );
    } catch (e) {
      throw CacheException('Failed to save username', originalError: e);
    }
  }

  /// Get username
  Future<String?> getUsername() async {
    try {
      return await _secureStorage.read(key: AppConstants.usernameKey);
    } catch (e) {
      throw CacheException('Failed to retrieve username', originalError: e);
    }
  }

  /// Save role
  Future<void> saveRole(String role) async {
    try {
      await _secureStorage.write(
        key: AppConstants.roleKey,
        value: role,
      );
    } catch (e) {
      throw CacheException('Failed to save role', originalError: e);
    }
  }

  /// Get role
  Future<String?> getRole() async {
    try {
      return await _secureStorage.read(key: AppConstants.roleKey);
    } catch (e) {
      throw CacheException('Failed to retrieve role', originalError: e);
    }
  }

  /// Save email
  Future<void> saveEmail(String email) async {
    try {
      await _secureStorage.write(
        key: AppConstants.emailKey,
        value: email,
      );
    } catch (e) {
      throw CacheException('Failed to save email', originalError: e);
    }
  }

  /// Get email
  Future<String?> getEmail() async {
    try {
      return await _secureStorage.read(key: AppConstants.emailKey);
    } catch (e) {
      throw CacheException('Failed to retrieve email', originalError: e);
    }
  }

  /// Set login status
  Future<void> setLoggedIn(bool isLoggedIn) async {
    try {
      await _secureStorage.write(
        key: AppConstants.isLoggedInKey,
        value: isLoggedIn.toString(),
      );
    } catch (e) {
      throw CacheException('Failed to save login status', originalError: e);
    }
  }

  /// Check if user is logged in
  Future<bool> isLoggedIn() async {
    try {
      final value = await _secureStorage.read(key: AppConstants.isLoggedInKey);
      return value == 'true';
    } catch (e) {
      throw CacheException('Failed to check login status', originalError: e);
    }
  }

  // Credential Management for Token Refresh

  /// Save login credentials securely (for automatic token refresh)
  Future<void> saveCredentials({
    required String identifier,
    required String password,
  }) async {
    try {
      await Future.wait([
        _secureStorage.write(
          key: AppConstants.credentialIdentifierKey,
          value: identifier,
        ),
        _secureStorage.write(
          key: AppConstants.credentialPasswordKey,
          value: password,
        ),
      ]);
    } catch (e) {
      throw CacheException('Failed to save credentials', originalError: e);
    }
  }

  /// Get stored identifier
  Future<String?> getCredentialIdentifier() async {
    try {
      return await _secureStorage.read(
        key: AppConstants.credentialIdentifierKey,
      );
    } catch (e) {
      throw CacheException('Failed to retrieve identifier', originalError: e);
    }
  }

  /// Get stored password
  Future<String?> getCredentialPassword() async {
    try {
      return await _secureStorage.read(
        key: AppConstants.credentialPasswordKey,
      );
    } catch (e) {
      throw CacheException('Failed to retrieve password', originalError: e);
    }
  }

  /// Clear all stored data (logout)
  Future<void> clearAll() async {
    try {
      await _secureStorage.deleteAll();
    } catch (e) {
      throw CacheException('Failed to clear storage', originalError: e);
    }
  }

  // Session Cookie Management for OTP

  /// Save session cookies
  Future<void> saveSessionCookies(String cookies) async {
    try {
      await _secureStorage.write(
        key: 'session_cookies',
        value: cookies,
      );
    } catch (e) {
      throw CacheException('Failed to save session cookies', originalError: e);
    }
  }

  /// Get session cookies
  Future<String?> getSessionCookies() async {
    try {
      return await _secureStorage.read(key: 'session_cookies');
    } catch (e) {
      throw CacheException('Failed to retrieve session cookies', originalError: e);
    }
  }

  /// Delete session cookies
  Future<void> deleteSessionCookies() async {
    try {
      await _secureStorage.delete(key: 'session_cookies');
    } catch (e) {
      throw CacheException('Failed to delete session cookies', originalError: e);
    }
  }
}
