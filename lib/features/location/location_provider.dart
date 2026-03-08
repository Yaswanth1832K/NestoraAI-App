import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class UserLocationState {
  final Position? position;
  final String? city;
  final bool isLoading;
  final String? error;
  final bool permissionDenied;

  const UserLocationState({
    this.position,
    this.city,
    this.isLoading = false,
    this.error,
    this.permissionDenied = false,
  });

  UserLocationState copyWith({
    Position? position,
    String? city,
    bool? isLoading,
    String? error,
    bool? permissionDenied,
  }) {
    return UserLocationState(
      position: position ?? this.position,
      city: city ?? this.city,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      permissionDenied: permissionDenied ?? this.permissionDenied,
    );
  }
}

final userLocationProvider = StateNotifierProvider<UserLocationNotifier, UserLocationState>((ref) {
  return UserLocationNotifier();
});

class UserLocationNotifier extends StateNotifier<UserLocationState> {
  UserLocationNotifier() : super(const UserLocationState()) {
    _loadFromCache();
  }

  static const String _keyLat = 'user_lat';
  static const String _keyLng = 'user_lng';
  static const String _keyCity = 'user_city';

  Future<void> _loadFromCache() async {
    final prefs = await SharedPreferences.getInstance();
    final lat = prefs.getDouble(_keyLat);
    final lng = prefs.getDouble(_keyLng);
    final city = prefs.getString(_keyCity);

    if (lat != null && lng != null) {
      state = state.copyWith(
        position: Position(
          latitude: lat,
          longitude: lng,
          timestamp: DateTime.now(),
          accuracy: 0,
          altitude: 0,
          heading: 0,
          speed: 0,
          speedAccuracy: 0,
          altitudeAccuracy: 0,
          headingAccuracy: 0,
        ),
        city: city,
      );
    }
  }

  Future<void> _saveToCache(Position position, String? city) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyLat, position.latitude);
    await prefs.setDouble(_keyLng, position.longitude);
    if (city != null) await prefs.setString(_keyCity, city);
  }

  Future<void> updateLocation({bool silent = false}) async {
    if (!silent) state = state.copyWith(isLoading: true, error: null);

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        state = state.copyWith(isLoading: false, error: 'Location services disabled');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          state = state.copyWith(isLoading: false, permissionDenied: true, error: 'Permission denied');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        state = state.copyWith(isLoading: false, permissionDenied: true, error: 'Permission permanently denied');
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 15),
      );

      // Reverse geocode
      String? cityName;
      try {
        final placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        if (placemarks.isNotEmpty) {
          final p = placemarks.first;
          cityName = p.locality ?? p.subAdministrativeArea ?? p.administrativeArea ?? p.name;
        }
      } catch (e) {
        if (!kIsWeb) debugPrint('Geocoding fallback triggered: $e');
        // Fallback for Web CORS/NotImplemented errors
        try {
          final url = Uri.parse('https://nominatim.openstreetmap.org/reverse?format=json&lat=${position.latitude}&lon=${position.longitude}');
          final response = await http.get(url, headers: {'User-Agent': 'NestoraApp/1.0'});
          if (response.statusCode == 200) {
            final data = json.decode(response.body);
            final address = data['address'] as Map<String, dynamic>?;
            if (address != null) {
              cityName = address['city'] ?? address['town'] ?? address['village'] ?? address['county'];
            }
          }
        } catch (_) {}
      }

      state = state.copyWith(
        position: position,
        city: cityName,
        isLoading: false,
        permissionDenied: false,
      );

      _saveToCache(position, cityName);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void clearLocation() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyLat);
    await prefs.remove(_keyLng);
    await prefs.remove(_keyCity);
    state = const UserLocationState();
  }
}
