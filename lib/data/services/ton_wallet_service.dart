import 'dart:convert';

import 'package:bip39/bip39.dart' as bip39;
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/crypto_models.dart';

class TonWalletService {
  TonWalletService(this._secure);

  final FlutterSecureStorage _secure;

  Future<TonWallet> loadOrCreateWallet() async {
    var mnemonic = await _secure.read(key: 'ton_mnemonic');
    if (mnemonic == null || mnemonic.trim().isEmpty) {
      mnemonic = bip39.generateMnemonic();
      await _secure.write(key: 'ton_mnemonic', value: mnemonic);
    }

    final address = _deriveDemoAddress(mnemonic);
    final balance = await _fetchBalance(address);
    return TonWallet(
      mnemonic: mnemonic,
      address: address,
      balance: balance,
      testnet: true,
    );
  }

  String faucetUrl() => 'https://t.me/testgiver_ton_bot';

  String _deriveDemoAddress(String mnemonic) {
    // DEMO: Replace with tondart wallet derivation for a real testnet address.
    final digest = sha256.convert(utf8.encode(mnemonic)).toString();
    return 'EQ${digest.substring(0, 32)}';
  }

  Future<double> _fetchBalance(String address) async {
    // DEMO: Replace with tondart testnet RPC balance fetch.
    return 0.0;
  }
}
