import 'package:flutter/material.dart';

class AppConstants {
  AppConstants._();
  static const String appName = 'TeleBank';
  static const String appVersion = '1.0.0';
  static const int pinLength = 4;

  static const List<Map<String, dynamic>> banks = [
    {'id': 'cbe', 'name': 'Commercial Bank of Ethiopia', 'short': 'CBE', 'ussd': '*889#'},
    {'id': 'dashen', 'name': 'Dashen Bank', 'short': 'Dashen', 'ussd': '*675#'},
    {'id': 'awash', 'name': 'Awash Bank', 'short': 'Awash', 'ussd': '*901#'},
    {'id': 'coop', 'name': 'Cooperative Bank of Oromia', 'short': 'COOP', 'ussd': '*841#'},
  ];

  static const String tonTestnetRpc = 'https://testnet.toncenter.com/api/v2';
  static const String tonFaucet = 'https://t.me/testgiver_ton_bot';
  static const String ethSepoliaRpc = 'https://eth-sepolia.g.alchemy.com/v2/demo';
  static const int ethSepoliaChainId = 11155111;
}
