import '../models/ussd_models.dart';

class UssdParser {
  UssdMenu parse(String raw) {
    final lines = raw
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();

    if (lines.isEmpty) {
      return const UssdMenu(title: 'USSD', options: [], prompt: null);
    }

    final title = lines.first;
    final options = <UssdOption>[];
    String? prompt;

    final optionPattern = RegExp(r'^(\d+)[\.)-]\s*(.+)$');
    for (final line in lines.skip(1)) {
      final match = optionPattern.firstMatch(line);
      if (match != null) {
        options.add(
          UssdOption(code: match.group(1)!, label: match.group(2)!),
        );
        continue;
      }

      final lower = line.toLowerCase();
      if (lower.contains('enter') ||
          lower.contains('amount') ||
          lower.contains('pin') ||
          lower.contains('account') ||
          lower.contains('mobile') ||
          lower.contains('confirm')) {
        prompt = line;
      }
    }

    return UssdMenu(title: title, options: options, prompt: prompt);
  }
}
