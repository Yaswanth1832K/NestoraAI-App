import 'package:house_rental/features/listings/domain/utils/demo_listings_data.dart';

void main() {
  try {
    print("Generating demo listings...");
    final items = DemoListingsData.generateDemoListings('Coimbatore', 24);
    print("Successfully generated ${items.length} items.");
    print("First item address: ${items.first.address}");
  } catch (e, stack) {
    print("Exception thrown during generation: $e\n$stack");
  }
}
