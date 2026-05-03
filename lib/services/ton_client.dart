import 'package:tonutils/tonutils.dart';

class TonClientService {
  static final TonClientService _instance = TonClientService._();
  static TonClientService get instance => _instance;
  TonClientService._();

  late final TonJsonRpc _client;
  bool _initialized = false;

  static const String testnetRpc = 'https://testnet.toncenter.com/api/v2/jsonRPC';

  TonJsonRpc get client {
    if (!_initialized) throw StateError('Call init() first');
    return _client;
  }

  Future<void> init() async {
    if (_initialized) return;
    _client = TonJsonRpc(testnetRpc, null, 30000);
    _initialized = true;
  }

  Future<bool> isTestnetReachable() async {
    try {
      await _client.getMasterchainInfo();
      return true;
    } catch (_) {
      return false;
    }
  }
}
