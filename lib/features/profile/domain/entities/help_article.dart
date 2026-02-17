enum HelpCategory {
  general,
  booking,
  payments,
  account,
  hosting,
  safety
}

class HelpArticle {
  final String id;
  final String question;
  final String answer;
  final HelpCategory category;

  const HelpArticle({
    required this.id,
    required this.question,
    required this.answer,
    required this.category,
  });
}
