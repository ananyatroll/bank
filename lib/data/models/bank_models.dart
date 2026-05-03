enum BankId {
  cbe,
  dashen,
  awash,
  coop,
  other,
}

enum TxnDirection {
  credit,
  debit,
}

class BankBalance {
  final BankId bankId;
  final double amount;
  final String currency;
  final String last4;
  final DateTime updatedAt;

  const BankBalance({
    required this.bankId,
    required this.amount,
    required this.currency,
    required this.last4,
    required this.updatedAt,
  });

  String get displayName {
    switch (bankId) {
      case BankId.cbe:
        return 'CBE';
      case BankId.dashen:
        return 'Dashen';
      case BankId.awash:
        return 'Awash';
      case BankId.coop:
        return 'COOP';
      case BankId.other:
        return 'Other';
    }
  }

  BankBalance copyWith({
    BankId? bankId,
    double? amount,
    String? currency,
    String? last4,
    DateTime? updatedAt,
  }) {
    return BankBalance(
      bankId: bankId ?? this.bankId,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      last4: last4 ?? this.last4,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class BankTransaction {
  final String title;
  final double amount;
  final DateTime timestamp;
  final TxnDirection direction;

  const BankTransaction({
    required this.title,
    required this.amount,
    required this.timestamp,
    required this.direction,
  });
}

class BankState {
  final Map<BankId, BankBalance> balances;
  final List<BankTransaction> transactions;
  final bool isLoading;
  final String? error;

  const BankState({
    required this.balances,
    required this.transactions,
    required this.isLoading,
    this.error,
  });

  factory BankState.initial() {
    return const BankState(
      balances: {},
      transactions: [],
      isLoading: false,
    );
  }

  BankState copyWith({
    Map<BankId, BankBalance>? balances,
    List<BankTransaction>? transactions,
    bool? isLoading,
    String? error,
  }) {
    return BankState(
      balances: balances ?? this.balances,
      transactions: transactions ?? this.transactions,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}
