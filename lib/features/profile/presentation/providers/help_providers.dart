import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:house_rental/features/profile/domain/entities/help_article.dart';

final helpSearchQueryProvider = StateProvider<String>((ref) => '');
final helpSelectedCategoryProvider = StateProvider<HelpCategory?>((ref) => null);

final helpArticlesProvider = Provider<List<HelpArticle>>((ref) {
  return const [
    HelpArticle(
      id: '1',
      question: 'How do I reset my password?',
      answer: 'Go to Profile > Login & Security. Tap on "Change Password", enter your current password, and then your new password twice to confirm.',
      category: HelpCategory.account,
    ),
    HelpArticle(
      id: '2',
      question: 'How do I contact a host?',
      answer: 'You can message a host directly from their listing page by tapping the "Message" button. This allows you to ask questions about the property, availability, or house rules.',
      category: HelpCategory.booking,
    ),
    HelpArticle(
      id: '3',
      question: 'What is the cancellation policy?',
      answer: 'Cancellation policies vary by listing and are determined by the host. You can find the specific policy for a property on its details page under the "Terms" section.',
      category: HelpCategory.booking,
    ),
    HelpArticle(
      id: '4',
      question: 'How do I become a host?',
      answer: 'Navigate to Profile > Become a Host. Follow the guided steps to verify your identity and start listing your properties to earn income.',
      category: HelpCategory.hosting,
    ),
    HelpArticle(
      id: '5',
      question: 'Is my payment information secure?',
      answer: 'Yes, Nestora uses industry-standard SSL encryption and partner with secure payment processors like Stripe to ensure your financial data is never stored on our servers directly.',
      category: HelpCategory.payments,
    ),
    HelpArticle(
      id: '6',
      question: 'Can I edit my profile?',
      answer: 'Yes, go to Profile > Edit Profile to update your name, email, phone number, and profile picture at any time.',
      category: HelpCategory.account,
    ),
    HelpArticle(
      id: '7',
      question: 'How do I report a suspicious listing?',
      answer: 'If you encounter a listing that seems fraudulent or violates our policies, use the "Report" button on the listing page or contact support immediately.',
      category: HelpCategory.safety,
    ),
    HelpArticle(
      id: '8',
      question: 'What payment methods are accepted?',
      answer: 'We accept all major credit and debit cards (Visa, Mastercard, American Express), as well as digital wallets like Google Pay and Apple Pay.',
      category: HelpCategory.payments,
    ),
    HelpArticle(
      id: '9',
      question: 'How do I request a visit?',
      answer: 'On any listing page, tap the "Request Visit" button. You can select a preferred date and time, and the host will be notified to confirm your request.',
      category: HelpCategory.booking,
    ),
    HelpArticle(
      id: '10',
      question: 'What is Nestora?',
      answer: 'Nestora is an AI-powered property rental platform that connects tenants with owners. We use advanced search and recommendation engines to make finding your next home effortless.',
      category: HelpCategory.general,
    ),
    HelpArticle(
      id: '11',
      question: 'Is Nestora available in my region?',
      answer: 'We are currently expanding rapidly. You can check available properties in your area by using the search bar or enabling location services in the app.',
      category: HelpCategory.general,
    ),
    HelpArticle(
      id: '12',
      question: 'How do I change the app language?',
      answer: 'Navigate to Profile > Language and Region to choose from our supported languages, including English, Hindi, Telugu, Tamil, and more.',
      category: HelpCategory.general,
    ),
    HelpArticle(
      id: '13',
      question: 'How do I contact support?',
      answer: 'You can reach out to us via the "Live Chat" or "Email Us" buttons at the bottom of the Help Center page. Our support team is available 24/7.',
      category: HelpCategory.general,
    ),
  ];
});

final filteredHelpArticlesProvider = Provider<List<HelpArticle>>((ref) {
  final articles = ref.watch(helpArticlesProvider);
  final query = ref.watch(helpSearchQueryProvider).toLowerCase();
  final category = ref.watch(helpSelectedCategoryProvider);

  return articles.where((article) {
    final matchesQuery = article.question.toLowerCase().contains(query) || 
                         article.answer.toLowerCase().contains(query);
    final matchesCategory = category == null || article.category == category;
    
    return matchesQuery && matchesCategory;
  }).toList();
});
