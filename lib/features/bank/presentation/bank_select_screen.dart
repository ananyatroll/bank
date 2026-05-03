import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../config/constants.dart';
import '../../../core/theme.dart';

class BankSelectScreen extends StatefulWidget {
  const BankSelectScreen({super.key});
  @override
  State<BankSelectScreen> createState() => _BankSelectScreenState();
}

class _BankSelectScreenState extends State<BankSelectScreen> {
  int? _selected;

  final _colors = [AppColors.ethiopianGreen, AppColors.navyBlue, AppColors.goldenYellow, AppColors.tealGreen];

  Future<void> _continue() async {
    if (_selected == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_bank', AppConstants.banks[_selected!]['id']);
    if (mounted) Navigator.pushReplacementNamed(context, '/dashboard');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select Your Bank')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text('Choose your primary bank', style: AppTextStyles.bodyLarge.copyWith(color: AppColors.mediumGray)),
            const SizedBox(height: 24),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                children: List.generate(AppConstants.banks.length, (i) {
                  final bank = AppConstants.banks[i];
                  final selected = _selected == i;
                  return GestureDetector(
                    onTap: () => setState(() => _selected = i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: selected ? _colors[i] : Colors.grey.shade300, width: selected ? 3 : 1),
                        boxShadow: selected ? AppColors.getShadow(4) : AppColors.getShadow(1),
                      ),
                      child: Stack(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.account_balance, size: 48, color: _colors[i]),
                                const SizedBox(height: 8),
                                Text(bank['short'], style: AppTextStyles.heading3.copyWith(color: _colors[i])),
                                const SizedBox(height: 4),
                                Text(bank['name'], style: AppTextStyles.caption, textAlign: TextAlign.center),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                  decoration: BoxDecoration(color: _colors[i].withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                                  child: Text(bank['ussd'], style: TextStyle(color: _colors[i], fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                          ),
                          if (selected) Positioned(top: 8, right: 8, child: Icon(Icons.check_circle, color: _colors[i])),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _selected != null ? _continue : null,
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text('Continue', style: AppTextStyles.button),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
