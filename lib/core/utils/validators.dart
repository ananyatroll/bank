class Validators {
  Validators._();

  static String? validatePhoneNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }
    final phoneRegex = RegExp(r'^\+251[0-9]{9}$|^0[0-9]{9}$');
    if (!phoneRegex.hasMatch(value)) {
      return 'Invalid Ethiopian phone number format';
    }
    return null;
  }

  static String? validatePin(String? value, {int length = 4}) {
    if (value == null || value.isEmpty) {
      return 'PIN is required';
    }
    if (value.length != length) {
      return 'PIN must be $length digits';
    }
    if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
      return 'PIN must contain only numbers';
    }
    return null;
  }

  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Optional
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Invalid email format';
    }
    return null;
  }

  static String? validateAmount(String? value) {
    if (value == null || value.isEmpty) {
      return 'Amount is required';
    }
    final amount = double.tryParse(value);
    if (amount == null) {
      return 'Invalid amount';
    }
    if (amount <= 0) {
      return 'Amount must be greater than 0';
    }
    if (amount > 1000000) {
      return 'Amount exceeds maximum limit';
    }
    return null;
  }

  static String? validateRequired(String? value, {String fieldName = 'Field'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }
}
