import 'package:tonutils/tonutils.dart';

class TonClientService {
  static final TonClientService _instance = TonClientService._();
  static TonClientService get instance => _instance;
  TonClientService._();

  TonJsonRpc? _client;
  static const String testnetRpc = 'https://testnet.toncenter.com/api/v2/jsonRPC';

  TonJsonRpc get client {
    _client ??= TonJsonRpc(testnetRpc, null, 15000);
    return _client!;
  }

  Future<bool> isInitialized() async {
    try {
      await client.getMasterchainInfo();
      return true;
    } catch (_) {
      return false;
    }
  }
}
