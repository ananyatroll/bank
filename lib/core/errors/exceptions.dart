/// Base exception class
class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;
  final StackTrace? stackTrace;

  const AppException({
    this.message = 'An unexpected error occurred',
    this.code,
    this.originalError,
    this.stackTrace,
  });

  @override
  String toString() => 'AppException($code): $message';
}

/// Authentication exceptions
class AuthenticationException extends AppException {
  const AuthenticationException({String message = 'Authentication failed', String? code})
      : super(message: message, code: code);
}

class BiometricNotAvailableException extends AppException {
  const BiometricNotAvailableException({String message = 'Biometric authentication not available'})
      : super(message: message);
}

/// Network exceptions
class NetworkException extends AppException {
  const NetworkException({String message = 'Network error occurred', dynamic error})
      : super(message: message, originalError: error);
}

class TimeoutException extends AppException {
  const TimeoutException({String message = 'Request timed out'})
      : super(message: message);
}

/// USSD exceptions
class USSDException extends AppException {
  const USSDException({String message = 'USSD operation failed'})
      : super(message: message);
}

class USSDNotSupportedException extends AppException {
  const USSDNotSupportedException({String message = 'USSD not supported on this device'})
      : super(message: message);
}

/// SMS exceptions
class SMSException extends AppException {
  const SMSException({String message = 'SMS operation failed'})
      : super(message: message);
}

class SMSPermissionDeniedException extends AppException {
  const SMSPermissionDeniedException({String message = 'SMS permission denied'})
      : super(message: message);
}

/// Wallet exceptions
class WalletException extends AppException {
  const WalletException({String message = 'Wallet operation failed'})
      : super(message: message);
}

class InvalidMnemonicException extends AppException {
  const InvalidMnemonicException({String message = 'Invalid mnemonic phrase'})
      : super(message: message);
}

/// Storage exceptions
class StorageException extends AppException {
  const StorageException({String message = 'Storage operation failed'})
      : super(message: message);
}

class EncryptionException extends AppException {
  const EncryptionException({String message = 'Encryption/decryption failed'})
      : super(message: message);
}

/// Validation exceptions
class ValidationException extends AppException {
  final Map<String, String>? fieldErrors;

  const ValidationException({
    String message = 'Validation failed',
    this.fieldErrors,
  }) : super(message: message);
}
