import 'package:house_rental/features/listings/domain/entities/listing_entity.dart';
import 'package:house_rental/features/listings/domain/entities/review_entity.dart';
import 'package:house_rental/features/listings/domain/repositories/listing_repository.dart';
import 'dart:math';

class DemoListingsData {
  static final List<String> houseImages = [
    'https://images.unsplash.com/photo-1613490493576-7fde63acd811?auto=format&fit=crop&q=80&w=1200',
    'https://images.unsplash.com/photo-1613977257363-707ba9343219?auto=format&fit=crop&q=80&w=1200',
    'https://images.unsplash.com/photo-1512917774080-9991f1c4c750?auto=format&fit=crop&q=80&w=1200',
    'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?auto=format&fit=crop&q=80&w=1200',
    'https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?auto=format&fit=crop&q=80&w=1200',
    'https://images.unsplash.com/photo-1600210491816-639c32e54011?auto=format&fit=crop&q=80&w=1200',
    'https://images.unsplash.com/photo-1600566753086-00f18fb6f3ea?auto=format&fit=crop&q=80&w=1200',
    'https://images.unsplash.com/photo-1600047509807-ba8f99d2cdde?auto=format&fit=crop&q=80&w=1200',
  ];

  static final List<String> apartmentImages = [
    'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?auto=format&fit=crop&q=80&w=1200',
    'https://images.unsplash.com/photo-1502672260266-1c1ef2d93688?auto=format&fit=crop&q=80&w=1200',
    'https://images.unsplash.com/photo-1493809842364-78817add7ffb?auto=format&fit=crop&q=80&w=1200',
    'https://images.unsplash.com/photo-1502672023488-70e25813eb80?auto=format&fit=crop&q=80&w=1200',
    'https://images.unsplash.com/photo-1522771739844-6a9f6d5f14af?auto=format&fit=crop&q=80&w=1200',
    'https://images.unsplash.com/photo-1484154218962-a197022b5858?auto=format&fit=crop&q=80&w=1200',
    'https://images.unsplash.com/photo-1493246507139-91e8bef99c17?auto=format&fit=crop&q=80&w=1200',
    'https://images.unsplash.com/photo-1515263487990-61b07816b324?auto=format&fit=crop&q=80&w=1200',
  ];

  static final List<String> villaImages = [
    'https://images.unsplash.com/photo-1512917774080-9991f1c4c750?auto=format&fit=crop&q=80&w=1200',
    'https://images.unsplash.com/photo-1564013799919-ab600027ffc6?auto=format&fit=crop&q=80&w=1200',
    'https://images.unsplash.com/photo-1542314831-068cd1dbfeeb?auto=format&fit=crop&q=80&w=1200',
    'https://images.unsplash.com/photo-1580587771525-78b9dba3b914?auto=format&fit=crop&q=80&w=1200',
    'https://images.unsplash.com/photo-1511840636560-acee95b3a83f?auto=format&fit=crop&q=80&w=1200',
    'https://images.unsplash.com/photo-1605276374104-aa2a1e1b8543?auto=format&fit=crop&q=80&w=1200',
  ];

  static const Map<String, List<double>> cityCenters = {
    'Mumbai': [19.0760, 72.8777],
    'Bangalore': [12.9716, 77.5946],
    'Hyderabad': [17.3850, 78.4867],
    'Chennai': [13.0827, 80.2707],
    'Delhi': [28.6139, 77.2090],
    'Goa': [15.2993, 74.1240],
    'Kochi': [9.9312, 76.2673],
    'Coimbatore': [11.0168, 76.9558],
    'Vijayawada': [16.5062, 80.6480],
    'Dindigul': [10.3673, 77.9803],
    'Madurai': [9.9252, 78.1198],
    'Trichy': [10.7905, 78.7047],
    'Salem': [11.6643, 78.1460],
    'Tirupur': [11.1085, 77.3411],
    'Erode': [11.3410, 77.7172],
    'Tirunelveli': [8.7139, 77.7567],
    'Vellore': [12.9165, 79.1325],
    'Thanjavur': [10.7870, 79.1378],
    'Tuticorin': [8.7642, 78.1348],
    'Pune': [18.5204, 73.8567],
    'Ahmedabad': [23.0225, 72.5714],
    'Kolkata': [22.5726, 88.3639],
    'Surat': [21.1702, 72.8311],
    'Lucknow': [26.8467, 80.9462],
    'Jaipur': [26.9124, 75.7873],
    'Chandigarh': [30.7333, 76.7794],
    'Patna': [25.5941, 85.1376],
    'Indore': [22.7196, 75.8577],
  };

  static const Map<String, String> serviceImages = {
    'Deep Cleaning': 'https://images.unsplash.com/photo-1581578731548-c64695cc6952?q=80&w=800&auto=format&fit=crop',
    'Painting': 'https://images.unsplash.com/photo-1562259929-b7e181d8d9b5?q=80&w=800&auto=format&fit=crop',
    'Plumbing': 'https://images.unsplash.com/photo-1607472586893-edb57cb31302?q=80&w=800&auto=format&fit=crop',
    'Electrical': 'https://images.unsplash.com/photo-1621905251189-08b45d6a269e?q=80&w=800&auto=format&fit=crop',
    'AC Repair': 'https://images.unsplash.com/photo-1520624953457-4187e1aab4f3?q=80&w=800&auto=format&fit=crop',
    'Home Maintenance': 'https://images.unsplash.com/photo-1581141849291-1125c7b692b5?q=80&w=800&auto=format&fit=crop',
    'Pest Control': 'https://images.unsplash.com/photo-1587392683838-518d89e52e06?q=80&w=800&auto=format&fit=crop',
  };

  static List<String> _getUniqueImages(String type, int seed) {
    List<String> source;
    if (type == 'Apartment') {
      source = [
        '1545324418-cc1a3fa10c00', '1522708323590-d24dbb6b0267', '1502672260266-1c1ef2d93688', '1512918728675-ed5a9ecdebfd',
        '1493663284031-b7e3aefcae8e', '1515263487990-61b07816b324', '1545324418-cc1a3fa10c00', '1574362844344-1427bc7b8d7c'
      ];
    } else if (type == 'Villa') {
      source = [
        '1613490493576-7fde63acd811', '1512918728675-ed5a9ecdebfd', '1542314831-068cd1dbfeeb', '1600047509807-ba8f99d2cdde',
        '1580587771525-78b9dba3b914', '1523217582562-b9e76fa35f11', '1510627498534-fc241ce42488', '1560185127614-f513d7894a4c'
      ];
    } else {
      source = [
        '1564013799919-ab600027ffc6', '1570129477492-45c003edd2be', '1512917774080-9991f1c4c750', '1600585154340-be6161a56a0c',
        '1600596542815-ffad4c1539a9', '1600607687940-4e2a09695d51', '1518780664697-55e3ad937233', '1480074568708-e7b720bb3f09'
      ];
    }
    
    // Pick 4 unique images
    List<String> urls = [];
    int s = seed;
    for (int i = 0; i < 4; i++) {
      s = (s * 13 + 17) % source.length;
      urls.add('https://images.unsplash.com/photo-${source[s]}?auto=format&fit=crop&q=80&w=800');
    }
    return urls.toSet().toList(); // Ensure uniqueness
  }

  static List<ListingEntity> generateDemoListings(String city, int count, {String? category, ListingFilter? filter, String? ownerId}) {
    final types = ['Apartment', 'Villa', 'House'];
    final baseLat = (cityCenters[city]?[0] ?? 11.0168);
    final baseLng = (cityCenters[city]?[1] ?? 76.9558);

    List<ListingEntity> allGenerated = List.generate(count * 2, (i) {
      String type = types[i % types.length];
      if (category != null) {
        if (category == 'Villas') type = 'Villa';
        else if (category == 'Apartments') type = 'Apartment';
        else if (category != 'Homes') type = category;
      }
      
      final price = 12000 + (i * 2500) + (Random(i).nextDouble() * 5000);
      final bedrooms = 1 + (i % 4); // 1, 2, 3, 4
      final bathrooms = 1 + (i % 3); // 1, 2, 3
      final sqft = 800 + (i * 200);
      final rating = 3.5 + (Random(i).nextDouble() * 1.5);
      final isAvailableNow = i % 4 != 0; // Most are available
      
      final lat = baseLat + (Random(i).nextDouble() - 0.5) * 0.05;
      final lng = baseLng + (Random(i).nextDouble() - 0.5) * 0.05;

      final seed = (city.hashCode.abs() * 11 + i * 13) % 10000;
      final listingImages = _getUniqueImages(type, seed);

      final furnishingOptions = ['Furnished', 'Semi-Furnished', 'Unfurnished'];
      final furnishing = furnishingOptions[i % 3];

      return ListingEntity(
        id: 'demo_${city.toLowerCase()}_${type.toLowerCase()}_${i + 1}_${ownerId ?? "demo"}',
        ownerId: ownerId ?? 'owner_demo',
        title: '${type == 'Villa' ? 'Luxury' : 'Modern'} $type in $city',
        description: 'Experience premium living in the heart of $city. This $type offers state-of-the-art amenities, gorgeous interiors, and prime location convenience.',
        price: price,
        propertyType: type,
        furnishing: furnishing,
        bedrooms: bedrooms,
        bathrooms: bathrooms,
        sqft: sqft.toDouble(),
        address: {
          'street': 'Main Street $i',
          'city': city,
          'state': 'State',
          'pincode': '600001',
        },
        amenities: const ['WiFi', 'Parking', 'AC', 'Swimming Pool', 'Balcony', 'Pet Friendly', 'Security', 'Gym'],
        images: listingImages,
        imageUrls: listingImages,
        searchTokens: [city.toLowerCase(), type.toLowerCase()],
        latitude: lat,
        longitude: lng,
        status: isAvailableNow ? ListingEntity.statusAvailable : ListingEntity.statusRented,
        averageRating: rating,
        reviewCount: 5 + Random(i).nextInt(10),
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        updatedAt: DateTime.now(),
        aiSummaryBullets: const [
          'High-speed WiFi for remote work',
          'Secure gated community with 24/7 guard',
          'Walking distance to public transport',
        ],
      );
    });

    // Apply Filter to Generated Data
    if (filter != null) {
      allGenerated = allGenerated.where((l) {
        if (filter.minPrice != null && l.price < filter.minPrice!) return false;
        if (filter.maxPrice != null && l.price > filter.maxPrice!) return false;
        if (filter.propertyType != null && l.propertyType != filter.propertyType) return false;
        if (filter.bedrooms != null && l.bedrooms < filter.bedrooms!) return false;
        if (filter.bathrooms != null && l.bathrooms < filter.bathrooms!) return false;
        if (filter.furnishing != null && l.furnishing != filter.furnishing) return false;
        if (filter.minRating != null && l.averageRating < filter.minRating!) return false;
        if (filter.minSqft != null && l.sqft < filter.minSqft!) return false;
        if (filter.maxSqft != null && l.sqft > filter.maxSqft!) return false;
        if (filter.availableNow == true && l.status != ListingEntity.statusAvailable) return false;
        if (filter.amenities != null) {
          for (var a in filter.amenities!) {
            if (!l.amenities.contains(a)) return false;
          }
        }
        return true;
      }).toList();
    }

    return allGenerated.take(count).toList();
  }

  static List<ReviewEntity> generateReviews(String listingId) {
    final List<String> names = ['Arjun', 'Sriya', 'Rahul', 'Anita', 'Karthik', 'Meera', 'Vijay', 'Deepa'];
    final List<String> comments = [
      'Absolutely amazing place! The host was super helpful and the house was exactly as pictured.',
      'Very clean and modern. The location is perfect for commuting.',
      'Great value for money. Loved the balcony view!',
      'Highly recommend this to anyone visiting the city. Security is top-notch.',
      'A bit noisy due to construction nearby, but the house itself is perfect.',
      'The amenities are world-class. The gym and pool were very well maintained.',
      'Easy check-in process. Very comfortable stay for my family.',
      'The interior design is stunning. Feels very premium and worth every penny.',
    ];

    return List.generate(6, (i) {
      final random = Random(listingId.hashCode + i);
      return ReviewEntity(
        id: 'rev_demo_${listingId}_$i',
        listingId: listingId,
        listingTitle: 'Premium Stay',
        ownerId: 'owner_demo',
        reviewerId: 'rev_$i',
        reviewerName: names[i % names.length],
        bookingId: 'book_$i',
        rating: 4.0 + (random.nextDouble()),
        comment: comments[i % comments.length],
        createdAt: DateTime.now().subtract(Duration(days: i * 5)),
      );
    });
  }
}
