class TonWallet {
  final String mnemonic;
  final String address;
  final double balance;
  final bool testnet;

  const TonWallet({
    required this.mnemonic,
    required this.address,
    required this.balance,
    required this.testnet,
  });
}
