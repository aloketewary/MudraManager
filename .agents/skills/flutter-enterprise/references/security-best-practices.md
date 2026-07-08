# Security Best Practices for Flutter Enterprise Apps

## Overview

Security is critical for enterprise Flutter applications to protect sensitive data, prevent unauthorized access, and ensure compliance with industry standards. This guide covers comprehensive security strategies for Flutter apps using clean architecture.

## Authentication & Authorization

### Secure Authentication Implementation

```dart
// lib/core/security/auth_service.dart
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService {
  final FlutterSecureStorage _secureStorage;
  static const String _tokenKey = 'auth_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const int _maxLoginAttempts = 5;
  static const Duration _lockoutDuration = Duration(minutes: 15);

  AuthService(this._secureStorage);

  Future<bool> isLoggedIn() async {
    final token = await _secureStorage.read(key: _tokenKey);
    return token != null;
  }

  Future<String?> getAuthToken() async {
    return await _secureStorage.read(key: _tokenKey);
  }

  Future<void> setAuthToken(String token) async {
    await _secureStorage.write(key: _tokenKey, value: token);
  }

  Future<void> clearAuth() async {
    await _secureStorage.delete(key: _tokenKey);
    await _secureStorage.delete(key: _refreshTokenKey);
  }

  Future<bool> login(String username, String password) async {
    final attempts = await _getLoginAttempts(username);

    if (attempts >= _maxLoginAttempts) {
      final lastAttempt = await _getLastAttemptTime(username);
      if (lastAttempt != null &&
          DateTime.now().difference(lastAttempt) < _lockoutDuration) {
        throw AuthException('Account locked. Try again later.', 'ACCOUNT_LOCKED');
      }
    }

    try {
      // Validate credentials
      if (!_validateCredentials(username, password)) {
        await _incrementLoginAttempts(username);
        throw AuthException('Invalid credentials', 'INVALID_CREDENTIALS');
      }

      // Perform authentication
      final token = await _authenticateUser(username, password);
      await setAuthToken(token);
      await _clearLoginAttempts(username);

      return true;
    } catch (e) {
      await _incrementLoginAttempts(username);
      rethrow;
    }
  }

  Future<void> _incrementLoginAttempts(String username) async {
    final attempts = await _getLoginAttempts(username);
    final key = 'login_attempts_$username';
    await _secureStorage.write(key: key, value: (attempts + 1).toString());
    await _secureStorage.write(key: 'last_attempt_$username', value: DateTime.now().toIso8601String());
  }

  Future<int> _getLoginAttempts(String username) async {
    final key = 'login_attempts_$username';
    final attempts = await _secureStorage.read(key: key);
    return attempts != null ? int.parse(attempts!) : 0;
  }

  Future<void> _clearLoginAttempts(String username) async {
    await _secureStorage.delete(key: 'login_attempts_$username');
    await _secureStorage.delete(key: 'last_attempt_$username');
  }

  Future<DateTime?> _getLastAttemptTime(String username) async {
    final key = 'last_attempt_$username';
    final lastAttempt = await _secureStorage.read(key: key);
    return lastAttempt != null ? DateTime.parse(lastAttempt!) : null;
  }

  bool _validateCredentials(String username, String password) {
    // Implement credential validation logic
    if (username.length < 3 || username.length > 50) {
      return false;
    }

    if (password.length < 8 || password.length > 128) {
      return false;
    }

    // Check for common weak passwords
    final weakPasswords = ['password', '123456', 'qwerty', 'admin'];
    if (weakPasswords.contains(password.toLowerCase())) {
      return false;
    }

    return true;
  }

  Future<String> _authenticateUser(String username, String password) async {
    // Implement secure authentication logic
    final hashedPassword = _hashPassword(password);
    final user = await _getUserFromDatabase(username);

    if (user != null && user.passwordHash == hashedPassword) {
      return _generateSecureToken(user);
    }

    throw AuthException('Authentication failed', 'AUTH_FAILED');
  }

  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  String _generateSecureToken(User user) {
    final payload = {
      'sub': user.id,
      'email': user.email,
      'iat': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      'exp': (DateTime.now().add(Duration(hours: 24))).millisecondsSinceEpoch ~/ 1000,
    };

    return _generateJWT(payload);
  }

  String _generateJWT(Map<String, dynamic> payload) {
    // Implement JWT generation with secure signing
    final header = {
      'alg': 'HS256',
      'typ': 'JWT',
    };

    final encodedHeader = base64.encode(utf8.encode(json.encode(header)));
    final encodedPayload = base64.encode(utf8.encode(json.encode(payload)));

    final signature = _signData('$encodedHeader.$encodedPayload');

    return '$encodedHeader.$encodedPayload.$signature';
  }

  String _signData(String data) {
    // Implement HMAC-SHA256 signing
    final key = utf8.encode('your-secret-key');
    final bytes = utf8.encode(data);
    final hmac = Hmac(sha256, key);
    final digest = hmac.convert(bytes);
    return base64.encode(digest.bytes);
  }
}
```

### Role-Based Access Control

```dart
// lib/core/security/rbac_service.dart
enum Permission {
  readUsers,
  writeUsers,
  deleteUsers,
  readReports,
  writeReports,
  administerSystem,
}

enum Role {
  user,
  moderator,
  admin,
  superAdmin,
}

class RBACService {
  final Map<Role, Set<Permission>> _rolePermissions = {
    Role.user: {
      Permission.readUsers,
    },
    Role.moderator: {
      Permission.readUsers,
      Permission.writeUsers,
      Permission.readReports,
    },
    Role.admin: {
      Permission.readUsers,
      Permission.writeUsers,
      Permission.deleteUsers,
      Permission.readReports,
      Permission.writeReports,
    },
    Role.superAdmin: {
      Permission.readUsers,
      Permission.writeUsers,
      Permission.deleteUsers,
      Permission.readReports,
      Permission.writeReports,
      Permission.administerSystem,
    },
  };

  bool hasPermission(Role userRole, Permission permission) {
    final permissions = _rolePermissions[userRole];
    return permissions?.contains(permission) ?? false;
  }

  Set<Permission> getUserPermissions(Role userRole) {
    return _rolePermissions[userRole] ?? {};
  }

  bool canAccessResource(String resource, String action, Role userRole) {
    final permission = _getPermissionForResource(resource, action);
    return hasPermission(userRole, permission);
  }

  Permission _getPermissionForResource(String resource, String action) {
    switch (resource) {
      case 'users':
        switch (action) {
          case 'read':
            return Permission.readUsers;
          case 'write':
            return Permission.writeUsers;
          case 'delete':
            return Permission.deleteUsers;
          default:
            throw ArgumentError('Invalid action for users resource');
        }
      case 'reports':
        switch (action) {
          case 'read':
            return Permission.readReports;
          case 'write':
            return Permission.writeReports;
          default:
            throw ArgumentError('Invalid action for reports resource');
        }
      default:
        throw ArgumentError('Unknown resource: $resource');
    }
  }
}
```

## Data Protection

### Secure Storage

```dart
// lib/core/security/secure_storage_service.dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:crypto/crypto.dart';

class SecureStorageService {
  final FlutterSecureStorage _secureStorage;
  static const String _encryptionKey = 'encryption_key';

  SecureStorageService(this._secureStorage);

  Future<void> initialize() async {
    final existingKey = await _secureStorage.read(key: _encryptionKey);

    if (existingKey == null) {
      final newKey = _generateEncryptionKey();
      await _secureStorage.write(key: _encryptionKey, value: newKey);
    }
  }

  Future<void> storeSecureData(String key, String value) async {
    final encryptionKey = await _getEncryptionKey();
    final encryptedValue = _encryptData(value, encryptionKey);
    await _secureStorage.write(key: key, value: encryptedValue);
  }

  Future<String?> readSecureData(String key) async {
    final encryptedValue = await _secureStorage.read(key: key);

    if (encryptedValue == null) return null;

    final encryptionKey = await _getEncryptionKey();
    return _decryptData(encryptedValue, encryptionKey);
  }

  Future<void> deleteSecureData(String key) async {
    await _secureStorage.delete(key: key);
  }

  Future<String> _getEncryptionKey() async {
    final key = await _secureStorage.read(key: _encryptionKey);
    if (key == null) {
      throw SecurityException('Encryption key not found', 'NO_ENCRYPTION_KEY');
    }
    return key;
  }

  String _generateEncryptionKey() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (i) => random.nextInt(256));
    return base64.encode(bytes);
  }

  String _encryptData(String data, String key) {
    final encrypter = Encrypter(AES(key, mode: AESMode.s256));
    final encrypted = encrypter.encrypt(data);
    return encrypted.base64;
  }

  String _decryptData(String encryptedData, String key) {
    final encrypter = Encrypter(AES(key, mode: AESMode.s256));
    final decrypted = encrypter.decrypt64(encryptedData);
    return decrypted;
  }
}
```

### Data Validation

```dart
// lib/core/security/data_validator.dart
import 'package:flutter/foundation.dart';

class DataValidator {
  static final RegExp _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  static final RegExp _passwordRegex = RegExp(
    r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$',
  );

  static final RegExp _phoneRegex = RegExp(
    r'^\+?[1-9][0-9]{7,15}$',
  );

  static ValidationResult validateEmail(String email) {
    if (email.isEmpty) {
      return ValidationResult(false, 'Email is required');
    }

    if (!_emailRegex.hasMatch(email)) {
      return ValidationResult(false, 'Invalid email format');
    }

    if (email.length > 254) {
      return ValidationResult(false, 'Email too long');
    }

    return ValidationResult(true, null);
  }

  static ValidationResult validatePassword(String password) {
    if (password.isEmpty) {
      return ValidationResult(false, 'Password is required');
    }

    if (password.length < 8) {
      return ValidationResult(false, 'Password must be at least 8 characters');
    }

    if (password.length > 128) {
      return ValidationResult(false, 'Password too long');
    }

    if (!_passwordRegex.hasMatch(password)) {
      return ValidationResult(false, 'Password must contain uppercase, lowercase, number, and special character');
    }

    // Check for common weak passwords
    final weakPasswords = [
      'password', '123456', 'qwerty', 'admin', 'letmein',
      'welcome', 'monkey', 'dragon', 'master', 'hello',
    ];

    if (weakPasswords.contains(password.toLowerCase())) {
      return ValidationResult(false, 'Password is too common');
    }

    return ValidationResult(true, null);
  }

  static ValidationResult validatePhone(String phone) {
    if (phone.isEmpty) {
      return ValidationResult(false, 'Phone number is required');
    }

    if (!_phoneRegex.hasMatch(phone)) {
      return ValidationResult(false, 'Invalid phone format');
    }

    return ValidationResult(true, null);
  }

  static ValidationResult validateUsername(String username) {
    if (username.isEmpty) {
      return ValidationResult(false, 'Username is required');
    }

    if (username.length < 3) {
      return ValidationResult(false, 'Username must be at least 3 characters');
    }

    if (username.length > 50) {
      return ValidationResult(false, 'Username too long');
    }

    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(username)) {
      return ValidationResult(false, 'Username can only contain letters, numbers, and underscores');
    }

    return ValidationResult(true, null);
  }

  static ValidationResult validateRequired(String value, String fieldName) {
    if (value.isEmpty) {
      return ValidationResult(false, '$fieldName is required');
    }

    return ValidationResult(true, null);
  }
}

class ValidationResult {
  final bool isValid;
  final String? errorMessage;

  const ValidationResult(this.isValid, [this.errorMessage]);
}
```

## Network Security

### Secure HTTP Client

```dart
// lib/core/security/secure_http_client.dart
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class SecureHttpClient {
  late Dio _dio;

  SecureHttpClient({
    required String baseUrl,
    Duration timeout = const Duration(seconds: 30),
    String? apiKey,
  }) {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: timeout,
      receiveTimeout: timeout,
      sendTimeout: timeout,
      headers: _buildSecureHeaders(apiKey),
    ));

    _setupInterceptors();
  }

  Map<String, String> _buildSecureHeaders(String? apiKey) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'User-Agent': 'Enterprise-Flutter-App/1.0.0',
    };

    if (apiKey != null) {
      headers['Authorization'] = 'Bearer $apiKey';
    }

    if (!kReleaseMode) {
      headers['X-Debug-Mode'] = 'true';
    }

    return headers;
  }

  void _setupInterceptors() {
    _dio.interceptors.add(SecurityInterceptor());
    _dio.interceptors.add(ErrorInterceptor());
    _dio.interceptors.add(LoggingInterceptor());
  }

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleSecurityException(e);
    }
  }

  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleSecurityException(e);
    }
  }

  SecurityException _handleSecurityException(DioException exception) {
    switch (exception.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return SecurityException('Request timeout', 'TIMEOUT');

      case DioExceptionType.connectionError:
        return SecurityException('Network connection failed', 'CONNECTION_ERROR');

      case DioExceptionType.badResponse:
        final statusCode = exception.response?.statusCode;

        switch (statusCode) {
          case 401:
            return SecurityException('Unauthorized access', 'UNAUTHORIZED');
          case 403:
            return SecurityException('Access forbidden', 'FORBIDDEN');
          case 429:
            return SecurityException('Too many requests', 'RATE_LIMIT');
          default:
            return SecurityException('Server error: $statusCode', 'SERVER_ERROR');
        }

      default:
        return SecurityException('Unknown error: ${exception.message}', 'UNKNOWN_ERROR');
    }
  }
}

class SecurityInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // Add security headers
    options.headers['X-Request-ID'] = _generateRequestId();
    options.headers['X-Timestamp'] = DateTime.now().toIso8601String();

    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    // Log response for security monitoring
    if (!kReleaseMode) {
      debugPrint('Response: ${response.statusCode} - ${response.requestOptions.path}');
    }

    handler.next(response);
  }

  @override
  void onError(DioException error, ErrorInterceptorHandler handler) {
    // Log errors for security monitoring
    if (!kReleaseMode) {
      debugPrint('Security Error: ${error.message}');
    }

    handler.next(error);
  }

  String _generateRequestId() {
    return '${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(10000)}';
  }
}
```

### Certificate Pinning

```dart
// lib/core/security/certificate_pinning.dart
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';

class CertificatePinning {
  static const String _expectedSha256 = 'YOUR_EXPECTED_CERTIFICATE_SHA256';

  static void setupCertificatePinning(Dio dio) {
    (dio.httpClientAdapter as DefaultHttpClientAdapter).onHttpClientCreate = (client) {
      client.badCertificateCallback = (cert, host) {
        // Verify certificate
        final certBytes = _getCertificateBytes(cert);
        final certSha256 = _calculateSHA256(certBytes);

        if (certSha256 != _expectedSha256) {
          throw SecurityException('Certificate verification failed', 'CERT_PINNING_FAILED');
        }

        return true;
      };
    };
  }

  static List<int> _getCertificateBytes(X509Certificate cert) {
    // Extract certificate bytes
    return cert.der;
  }

  String _calculateSHA256(List<int> bytes) {
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}
```

## Input Validation & Sanitization

### Secure Text Input

```dart
// lib/core/security/secure_text_input.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SecureTextInput extends StatefulWidget {
  final String? initialValue;
  final String? hintText;
  final bool obscureText;
  final bool enableSuggestions;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;
  final Function(String)? onChanged;
  final Function(String)? onSubmitted;

  const SecureTextInput({
    Key? key,
    this.initialValue,
    this.hintText,
    this.obscureText = false,
    this.enableSuggestions = true,
    this.maxLength,
    this.inputFormatters,
    this.onChanged,
    this.onSubmitted,
  }) : super(key: key);

  @override
  _SecureTextInputState createState() => _SecureTextInputState();
}

class _SecureTextInputState extends State<SecureTextInput> {
  late TextEditingController _controller;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue ?? '');
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      focusNode: _focusNode,
      obscureText: widget.obscureText,
      maxLength: widget.maxLength,
      inputFormatters: [
        FilteringTextInputFormatter.deny(RegExp(r'[<>"\']')),
        ...?widget.inputFormatters ?? [],
      ],
      decoration: InputDecoration(
        hintText: widget.hintText,
        suffixIcon: widget.obscureText
            ? IconButton(
                icon: Icon(
                  _controller.text.isEmpty ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: () {
                  setState(() {});
                },
              )
            : null,
      ),
      onChanged: (value) {
        final sanitizedValue = _sanitizeInput(value);
        _controller.value = sanitizedValue;
        _controller.selection = TextSelection.fromPosition(
          TextPosition(offset: sanitizedValue.length),
        );
        widget.onChanged?.call(sanitizedValue);
      },
      onSubmitted: (value) {
        final sanitizedValue = _sanitizeInput(value);
        widget.onSubmitted?.call(sanitizedValue);
      },
    );
  }

  String _sanitizeInput(String input) {
    // Remove potentially dangerous characters
    return input
        .replaceAll(RegExp(r'[<>"\']'), '')
        .replaceAll(RegExp(r'javascript:'), '')
        .replaceAll(RegExp(r'vbscript:'), '')
        .replaceAll(RegExp(r'onload='), '')
        .replaceAll(RegExp(r'onerror='), '');
  }
}
```

## Security Best Practices

### 1. Authentication & Authorization

- **Strong password policies**: Enforce complex password requirements
- **Multi-factor authentication**: Implement 2FA for sensitive operations
- **Session management**: Use secure session handling with proper timeouts
- **Role-based access**: Implement principle of least privilege
- **Account lockout**: Lock accounts after failed login attempts
- **Secure token storage**: Use encrypted storage for authentication tokens

### 2. Data Protection

- **Encryption at rest**: Encrypt sensitive data stored locally
- **Encryption in transit**: Use HTTPS/TLS for all communications
- **Key management**: Securely manage encryption keys
- **Data minimization**: Collect only necessary data
- **Data retention**: Implement proper data retention policies

### 3. Network Security

- **Certificate pinning**: Pin SSL certificates to prevent MITM attacks
- **API security**: Use proper authentication and authorization
- **Input validation**: Validate all inputs on both client and server
- **Rate limiting**: Implement rate limiting to prevent abuse
- **Secure headers**: Use appropriate security headers

### 4. Input Validation & Sanitization

- **Input sanitization**: Remove potentially dangerous characters
- **Output encoding**: Encode output to prevent XSS attacks
- **SQL injection prevention**: Use parameterized queries
- **File upload security**: Validate file types and sizes
- **Length limits**: Enforce appropriate input length limits

### 5. Mobile Security

- **Root detection**: Detect and handle rooted/jailbroken devices
- **Screen recording**: Prevent screen recording in sensitive areas
- **App shielding**: Use app shielding in production
- **Debug detection**: Disable debug features in production
- **Backup prevention**: Prevent sensitive data backup

### 6. Compliance & Monitoring

- **Audit logging**: Log all security-relevant events
- **Compliance checks**: Ensure compliance with regulations
- **Security testing**: Regular security assessments
- **Vulnerability scanning**: Regular code and dependency scans
- **Incident response**: Have a plan for security incidents

## Security Testing

### Security Tests

```dart
// test/security/security_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

void main() {
  group('Security Tests', () {
    test('secure storage should encrypt sensitive data', () async {
      final secureStorage = FlutterSecureStorage();

      await secureStorage.write(key: 'test_key', value: 'sensitive_data');
      final storedValue = await secureStorage.read(key: 'test_key');

      expect(storedValue, isNotNull);
      expect(storedValue, isNot(equals('sensitive_data')));
    });

    test('input validation should reject malicious input', () {
      final result = DataValidator.validateEmail('<script>alert("xss")</script>');

      expect(result.isValid, isFalse);
      expect(result.errorMessage, contains('Invalid email format'));
    });

    test('authentication should enforce password complexity', () {
      final weakPassword = 'password123';
      final result = DataValidator.validatePassword(weakPassword);

      expect(result.isValid, isFalse);
      expect(result.errorMessage, contains('Password must contain'));
    });
  });
}
```

### Penetration Testing

```dart
// test/security/penetration_test.dart
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Penetration Tests', () {
    testWidgets('should prevent XSS attacks', (WidgetTester tester) async {
      await tester.pumpWidget(SecureTextInput());

      final textField = tester.widget<SecureTextInput>(find.byType(TextField));

      // Attempt XSS injection
      await tester.enterText(find.byType(TextField), '<script>alert("xss")</script>');

      // Verify script tags are sanitized
      expect(textField.controller.text, isNot(contains('<script>')));
      expect(textField.controller.text, isNot(contains('javascript:')));
    });

    testWidgets('should prevent SQL injection', (WidgetTester tester) async {
      await tester.pumpWidget(SecureTextInput());

      final textField = tester.widget<SecureTextInput>(find.byType(TextField));

      // Attempt SQL injection
      await tester.enterText(find.byType(TextField), "'; DROP TABLE users; --");

      // Verify SQL commands are sanitized
      expect(textField.controller.text, isNot(contains('DROP TABLE')));
      expect(textField.controller.text, isNot(contains(';')));
    });
  });
}
```

This comprehensive security guide ensures Flutter enterprise applications implement robust security measures to protect sensitive data and prevent common vulnerabilities.