import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'app.dart';
import 'services/ton_client.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  // Initialize TON testnet client
  await TonClientService.instance.init();
  runApp(const ProviderScope(child: TeleBankApp()));
}
