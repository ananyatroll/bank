import 'package:equatable/equatable.dart';

/// Base Failure class for error handling
abstract class Failure extends Equatable {
  final String message;
  final StackTrace? stackTrace;

  const Failure({this.message = 'An unexpected error occurred', this.stackTrace});

  @override
  List<Object?> get props => [message, stackTrace];
}

// Authentication failures
class AuthFailure extends Failure {
  const AuthFailure({String message = 'Authentication failed'}) : super(message: message);
}

class BiometricFailure extends Failure {
  const BiometricFailure({String message = 'Biometric authentication failed'}) : super(message: message);
}

class PinMismatchFailure extends Failure {
  const PinMismatchFailure({String message = 'PIN does not match'}) : super(message: message);
}

class PinNotSetFailure extends Failure {
  const PinNotSetFailure({String message = 'PIN has not been set up'}) : super(message: message);
}

// Network failures
class NetworkFailure extends Failure {
  const NetworkFailure({String message = 'Network connection unavailable'}) : super(message: message);
}

class ServerFailure extends Failure {
  const ServerFailure({String message = 'Server error occurred'}) : super(message: message);
}

class TimeoutFailure extends Failure {
  const TimeoutFailure({String message = 'Operation timed out'}) : super(message: message);
}

// USSD failures
class USSDFailure extends Failure {
  const USSDFailure({String message = 'USSD operation failed'}) : super(message: message);
}

class USSDNotSupportedFailure extends Failure {
  const USSDNotSupportedFailure({String message = 'USSD not supported on this device'}) : super(message: message);
}

// SMS failures
class SMSFailure extends Failure {
  const SMSFailure({String message = 'SMS operation failed'}) : super(message: message);
}

class SMSPermissionFailure extends Failure {
  const SMSPermissionFailure({String message = 'SMS permission denied'}) : super(message: message);
}

class SMSParsingFailure extends Failure {
  const SMSParsingFailure({String message = 'Failed to parse SMS'}) : super(message: message);
}

// Wallet failures
class WalletFailure extends Failure {
  const WalletFailure({String message = 'Wallet operation failed'}) : super(message: message);
}

class InvalidMnemonicFailure extends Failure {
  const InvalidMnemonicFailure({String message = 'Invalid mnemonic phrase'}) : super(message: message);
}

// Storage failures
class StorageFailure extends Failure {
  const StorageFailure({String message = 'Storage operation failed'}) : super(message: message);
}

// Cache failure
class CacheFailure extends Failure {
  const CacheFailure({String message = 'Cache operation failed'}) : super(message: message);
}
