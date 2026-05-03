import 'dart:typed_data';
import 'package:tonutils/tonutils.dart';
import 'ton_client.dart';
import 'wallet_manager.dart';

class TransactionService {
  final _walletManager = WalletManager();

  /// Fetch balance in TON
  Future<double> getBalance(WalletState wallet) async {
    try {
      final client = TonClientService.instance.client;
      final bal = await client.getBalance(wallet.address); return bal.toDouble() / 1e9;
    } catch (e) {
      return 0.0;
    }
  }

  /// Fetch transaction history
  Future<List<WalletTransaction>> getTransactions(WalletState wallet, {int limit = 20}) async {
    try {
      final client = TonClientService.instance.client;
      final txns = await client.getTransactions(wallet.address, limit: limit);
      return txns.map((tx) {
        bool isIncoming = tx.inMessage != null;
        return WalletTransaction(
          hash: tx.prevTransactionHash.toRadixString(16).substring(0, 16),
          amount: tx.totalFees.coins.toDouble() / 1e9,
          timestamp: DateTime.fromMillisecondsSinceEpoch(tx.now * 1000),
          isIncoming: isIncoming,
          comment: '',
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  /// Send TON transfer
  Future<String> sendTon({
    required WalletState wallet,
    required String destination,
    required double amount,
    String? comment,
  }) async {
    try {
      final client = TonClientService.instance.client;
      final walletContract = WalletContractV4R2.create(publicKey: wallet.publicKey);
      final opened = client.open(walletContract);

      // Get seqno from chain
      final seqno = await opened.getSeqno();
      wallet.seqno = seqno;

      // Parse destination address
      final destAddr = InternalAddress.parse(destination);

      // Build comment cell if provided
      ScString? body;
      if (comment != null && comment.isNotEmpty) {
        body = ScString(comment);
      }

      // Create and sign transfer
      final transfer = opened.createTransfer(
        seqno: seqno,
        privateKey: wallet.privateKey,
        messages: [
          internal(
            to: SiaInternalAddress(destAddr),
            value: SbiBigInt(BigInt.from((amount * 1e9).round())),
            body: body,
            bounce: true,
          ),
        ],
      );

      // Broadcast
      await opened.send(transfer);

      // Increment seqno locally
      wallet.seqno = seqno + 1;
      await _walletManager.saveSeqno(wallet.seqno);

      return transfer.hash().toString();
    } catch (e) {
      throw TonTransferException(e.toString());
    }
  }

  /// Refresh seqno from chain
  Future<int> refreshSeqno(WalletState wallet) async {
    try {
      final client = TonClientService.instance.client;
      final walletContract = WalletContractV4R2.create(publicKey: wallet.publicKey);
      final opened = client.open(walletContract);
      final seqno = await opened.getSeqno();
      wallet.seqno = seqno;
      await _walletManager.saveSeqno(seqno);
      return seqno;
    } catch (_) {
      return wallet.seqno;
    }
  }
}

class WalletTransaction {
  final String hash;
  final double amount;
  final DateTime timestamp;
  final bool isIncoming;
  final String comment;

  WalletTransaction({
    required this.hash,
    required this.amount,
    required this.timestamp,
    required this.isIncoming,
    required this.comment,
  });
}

class TonTransferException implements Exception {
  final String message;
  TonTransferException(this.message);
  @override String toString() => 'Transfer failed: $message';
}
