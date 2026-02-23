/// Firestore collection and field name constants.
/// Do not change collection names — they must match existing production data.
abstract final class FirestoreConstants {
  FirestoreConstants._();

  // Collections
  static const String users = 'users';
  static const String listings = 'listings';
  static const String userActivity = 'user_activity';
  static const String marketStats = 'market_stats';
  static const String priceHistory = 'price_history';
  static const String bookings = 'bookings';
  static const String chats = 'chats';
  static const String reviews = 'reviews';
  static const String roommates = 'roommates';
  static const String notifications = 'notifications';
  static const String rentPayments = 'rent_payments';

  // Subcollections
  static const String favorites = 'favorites';
  static const String viewHistory = 'view_history';
  static const String messages = 'messages';
}
