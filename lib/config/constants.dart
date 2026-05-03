class AppConstants {
  AppConstants._();

  static const String appName = 'TeleBank UI';
  static const String appVersion = '1.0.0';
  static const String appDescription = 'Modern Ethiopian USSD Banking';

  // Supported Banks with CORRECT USSD codes
  static const List<BankConfig> supportedBanks = [
    BankConfig(id: 'cbe', name: 'Commercial Bank of Ethiopia', shortName: 'CBE', ussdCode: '*889#', color: '0xFF1E3A5F'),
    BankConfig(id: 'dashen', name: 'Dashen Bank', shortName: 'Dashen', ussdCode: '*675#', color: '0xFF2D7A4F'),
    BankConfig(id: 'awash', name: 'Awash Bank', shortName: 'Awash', ussdCode: '*901#', color: '0xFFF4B942'),
    BankConfig(id: 'coop', name: 'Cooperative Bank of Oromia', shortName: 'COOP', ussdCode: '*841#', color: '0xFF4A9F7A'),
  ];

  // Security
  static const int pinLength = 4;
  static const int maxBiometricAttempts = 3;
  static const Duration biometricTimeout = Duration(seconds: 30);
  static const String encryptionSalt = 'telebank_secure_salt_2024';

  // Database
  static const String storageBoxName = 'telebank_storage';
  static const String secureBoxName = 'telebank_secure';
  static const String pinKey = 'user_pin';
  static const String biometricEnabledKey = 'biometric_enabled';
  static const String isFirstLaunchKey = 'is_first_launch';

  // Crypto Wallet (Testnet)
  static const String tonTestnetRpcUrl = 'https://testnet.toncenter.com/api/v2';
  static const String tonTestnetExplorer = 'https://testnet.tonviewer.com';
  static const String ethSepoliaRpcUrl = 'https://eth-sepolia.g.alchemy.com/v2/YOUR_API_KEY';
  static const int ethSepoliaChainId = 11155111;

  // Feature Flags
  static const bool enableCryptoWallet = true;
  static const bool enableSmsSync = true;
  static const bool enableUssdWrapper = true;
  static const bool enableDarkMode = true;

  // Currency
  static const String defaultCurrency = 'ETB';
  static const String currencySymbol = 'ETB';
}

class BankConfig {
  final String id;
  final String name;
  final String shortName;
  final String ussdCode;
  final String color;

  const BankConfig({required this.id, required this.name, required this.shortName, required this.ussdCode, required this.color});
}
