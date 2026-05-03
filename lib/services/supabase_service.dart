import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

class SupabaseService {
  // TODO: Replace with your actual Supabase credentials
  static const String supabaseUrl = 'YOUR_SUPABASE_URL';
  static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';

  static SupabaseClient get supabase => Supabase.instance.client;

  static Future<void> init() async {
    await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
  }

  static String _hashPin(String pin) {
    return sha256.convert(utf8.encode('telebank_salt_$pin')).toString();
  }

  static Future<Map<String, dynamic>> register(String username, String pin) async {
    try {
      final existing = await supabase.from('users').select().eq('username', username).maybeSingle();
      if (existing != null) return {'error': 'Username already taken'};
      final result = await supabase.from('users').insert({'username': username, 'pin_hash': _hashPin(pin), 'balance': 100.00}).select();
      if (result.isNotEmpty) return {'success': true, 'id': result[0]['id'], 'balance': double.parse(result[0]['balance'].toString())};
      return {'error': 'Registration failed'};
    } catch (e) { return {'error': e.toString()}; }
  }

  static Future<Map<String, dynamic>> login(String username, String pin) async {
    try {
      final user = await supabase.from('users').select().eq('username', username).maybeSingle();
      if (user == null) return {'error': 'User not found'};
      if (user['pin_hash'] != _hashPin(pin)) return {'error': 'Wrong PIN'};
      return {'success': true, 'id': user['id'], 'username': user['username'], 'balance': double.parse(user['balance'].toString())};
    } catch (e) { return {'error': e.toString()}; }
  }

  static Future<double?> getBalance(String userId) async {
    try {
      final user = await supabase.from('users').select('balance').eq('id', userId).maybeSingle();
      if (user != null) return double.parse(user['balance'].toString());
    } catch (_) {}
    return null;
  }

  static Future<Map<String, dynamic>> sendMoney(String senderId, String recipientUsername, double amount, String type) async {
    try {
      final recipient = await supabase.from('users').select().eq('username', recipientUsername).maybeSingle();
      if (recipient == null) return {'error': 'User not found'};
      if (recipient['id'] == senderId) return {'error': 'Cannot send to yourself'};
      final sender = await supabase.from('users').select('balance').eq('id', senderId).maybeSingle();
      if (sender == null) return {'error': 'Sender not found'};
      final senderBalance = double.parse(sender['balance'].toString());
      if (amount > senderBalance) return {'error': 'Insufficient balance'};
      await supabase.rpc('transfer_money', params: {'p_sender_id': senderId, 'p_receiver_id': recipient['id'], 'p_amount': amount, 'p_type': type, 'p_desc': '$type to @$recipientUsername'});
      return {'success': true};
    } catch (e) { return {'error': e.toString()}; }
  }

  static Future<List<Map<String, dynamic>>> getTransactions(String userId, {int limit = 20}) async {
    try {
      final result = await supabase.from('transactions').select().or('sender_id.eq.$userId,receiver_id.eq.$userId').order('created_at', ascending: false).limit(limit);
      return (result as List).map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (_) { return []; }
  }
}
