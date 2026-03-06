import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

/// Provider that manages the user's current GPS position.
final userLocationProvider = StateNotifierProvider<UserLocationNotifier, AsyncValue<Position?>>((ref) {
  return UserLocationNotifier();
});

class UserLocationNotifier extends StateNotifier<AsyncValue<Position?>> {
  UserLocationNotifier() : super(const AsyncValue.data(null)) {
    // Optionally auto-fetch on init
    // updateLocation();
  }

  Future<void> updateLocation() async {
    state = const AsyncValue.loading();
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        state = AsyncValue.error('Location services disabled', StackTrace.current);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          state = AsyncValue.error('Permission denied', StackTrace.current);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        state = AsyncValue.error('Permission permanently denied', StackTrace.current);
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 10),
      );
      state = AsyncValue.data(position);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}
