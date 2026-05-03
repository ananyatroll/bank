class UssdOption {
  final String code;
  final String label;

  const UssdOption({
    required this.code,
    required this.label,
  });
}

class UssdMenu {
  final String title;
  final List<UssdOption> options;
  final String? prompt;

  const UssdMenu({
    required this.title,
    required this.options,
    required this.prompt,
  });
}
