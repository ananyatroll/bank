import 'dart:typed_data';
import 'package:tonutils/tonutils.dart';
import 'ton_client.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class WalletManager {
  final _storage = const FlutterSecureStorage();
  static const _mnemonicKey = 'ton_mnemonic_v4';
  static const _seqnoKey = 'ton_seqno_v4';
  static const _privateKeyKey = 'ton_private_key_v4';
  static const _publicKeyKey = 'ton_public_key_v4';

  Future<WalletState> createWallet() async {
    try {
      final mnemonic = Mnemonic.generate();
      final keyPair = Mnemonic.toKeyPair(mnemonic);
      final privKey = keyPair.privateKey;
      final pubKey = keyPair.publicKey;
      final wallet = WalletContractV4R2.create(publicKey: pubKey);

      final state = WalletState(
        address: wallet.address,
        publicKey: pubKey,
        privateKey: privKey,
        mnemonic: mnemonic,
        seqno: 0,
        isDeployed: false,
      );

      await _storage.write(key: _mnemonicKey, value: mnemonic.join(' '));
      await _storage.write(key: _seqnoKey, value: '0');
      await _storage.write(key: _privateKeyKey, value: _bytesToHex(privKey));
      await _storage.write(key: _publicKeyKey, value: _bytesToHex(pubKey));

      return state;
    } catch (e) {
      throw Exception('Failed to create wallet: $e');
    }
  }

  Future<WalletState?> loadWallet() async {
    try {
      final mnemonicStr = await _storage.read(key: _mnemonicKey);
      if (mnemonicStr == null || mnemonicStr.isEmpty) return null;

      final privKeyHex = await _storage.read(key: _privateKeyKey);
      if (privKeyHex == null) return null;
      final pubKeyHex = await _storage.read(key: _publicKeyKey);
      if (pubKeyHex == null) return null;

      final privKey = _hexToBytes(privKeyHex);
      final pubKey = _hexToBytes(pubKeyHex);
      final mnemonic = mnemonicStr.split(' ');

      final wallet = WalletContractV4R2.create(publicKey: pubKey);

      int seqno = 0;
      bool isDeployed = false;
      try {
        // Try to get seqno from chain (may fail if offline)
        final client = TonClientService.instance.client;
        final opened = client.open(wallet);
        seqno = await opened.getSeqno();
        isDeployed = true;
      } catch (_) {
        final cached = await _storage.read(key: _seqnoKey);
        seqno = int.tryParse(cached ?? '0') ?? 0;
      }

      return WalletState(
        address: wallet.address,
        publicKey: pubKey,
        privateKey: privKey,
        mnemonic: mnemonic,
        seqno: seqno,
        isDeployed: isDeployed,
      );
    } catch (e) {
      return null;
    }
  }

  Future<void> saveSeqno(int seqno) async {
    try { await _storage.write(key: _seqnoKey, value: seqno.toString()); } catch (_) {}
  }

  Future<void> clearWallet() async {
    try {
      await _storage.deleteAll();
    } catch (_) {}
  }

  String _bytesToHex(Uint8List bytes) {
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  Uint8List _hexToBytes(String hex) {
    final bytes = <int>[];
    for (var i = 0; i < hex.length; i += 2) {
      bytes.add(int.parse(hex.substring(i, i + 2), radix: 16));
    }
    return Uint8List.fromList(bytes);
  }
}

class WalletState {
  final InternalAddress address;
  final Uint8List publicKey;
  final Uint8List privateKey;
  final List<String> mnemonic;
  int seqno;
  final bool isDeployed;

  WalletState({
    required this.address,
    required this.publicKey,
    required this.privateKey,
    required this.mnemonic,
    required this.seqno,
    required this.isDeployed,
  });

  String get userFriendlyAddress => address.toString(isTestOnly: true, isBounceable: false);

  String get shortAddress {
    final addr = userFriendlyAddress;
    return addr.length > 16
        ? '${addr.substring(0, 8)}...${addr.substring(addr.length - 6)}'
        : addr;
  }
}
