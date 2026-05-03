import 'dart:async';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:local_auth/local_auth.dart';

import 'data/models/bank_models.dart';
import 'data/models/crypto_models.dart';
import 'data/models/sms_event.dart';
import 'data/services/device_security_service.dart';
import 'data/services/pin_vault_service.dart';
import 'data/services/sms_bridge.dart';
import 'data/services/sms_parser.dart';
import 'data/services/storage_service.dart';
import 'data/services/ton_wallet_service.dart';
import 'data/services/ussd_bridge.dart';

final storageBoxProvider = Provider<Box<dynamic>>((ref) => StorageService.box);

final deviceSecurityProvider = Provider<DeviceSecurityService>(
  (ref) => DeviceSecurityService(),
);

final pinVaultProvider = Provider<PinVaultService>((ref) {
  return PinVaultService(
    ref.read(storageBoxProvider),
    LocalAuthentication(),
    ref.read(deviceSecurityProvider),
  );
});

final smsBridgeProvider = Provider<SmsBridge>((ref) => SmsBridge());
final ussdBridgeProvider = Provider<UssdBridge>((ref) => UssdBridge());
final smsParserProvider = Provider<SmsBalanceParser>((ref) => SmsBalanceParser());

final bankControllerProvider = StateNotifierProvider<BankController, BankState>(
  (ref) => BankController(ref),
);

final tonWalletServiceProvider = Provider<TonWalletService>((ref) {
  return TonWalletService(const FlutterSecureStorage());
});

final tonWalletProvider = FutureProvider<TonWallet>((ref) async {
  return ref.read(tonWalletServiceProvider).loadOrCreateWallet();
});

class BankController extends StateNotifier<BankState> {
  BankController(this.ref) : super(BankState.initial());

  final Ref ref;
  StreamSubscription<SmsEvent>? _sub;

  void start() {
    _sub ??= ref.read(smsBridgeProvider).smsStream.listen(_onSms);
  }

  void _onSms(SmsEvent event) {
    final parsed = ref.read(smsParserProvider).parse(event);
    if (parsed == null) return;

    final balances = Map<BankId, BankBalance>.from(state.balances);
    balances[parsed.bankId] = parsed;

    final transactions = List<BankTransaction>.from(state.transactions);
    transactions.insert(
      0,
      BankTransaction(
        title: '${parsed.displayName} balance sync',
        amount: parsed.amount,
        timestamp: parsed.updatedAt,
        direction: TxnDirection.credit,
      ),
    );

    state = state.copyWith(balances: balances, transactions: transactions);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
