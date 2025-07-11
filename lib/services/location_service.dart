import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';
import '../models/memory.dart';
import 'database_service.dart';

class LocationService {
  static final LocationService _instance = LocationService._internal();
  final DatabaseService _databaseService = DatabaseService();
  bool _isInitialized = false;
  bool _isTracking = false;

  factory LocationService() => _instance;

  LocationService._internal();

  Future<void> initialize() async {
    if (_isInitialized) return;
    try {
      // Check if location services are enabled
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('Location services are disabled');
      }
      _isInitialized = true;
    } catch (e) {
      debugPrint('Error initializing location service: $e');
      // Still mark as initialized to prevent repeated attempts
      _isInitialized = true;
    }
  }

  Future<bool> requestPermissions() async {
    try {
      final locationStatus = await Permission.location.request();
      if (locationStatus.isGranted) {
        final backgroundLocationStatus = await Permission.locationAlways.request();
        return backgroundLocationStatus.isGranted;
      }
      return false;
    } catch (e) {
      debugPrint('Error requesting permissions: $e');
      return false;
    }
  }

  Future<Position?> getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('Location services are disabled');
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('Location permissions are denied');
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('Location permissions are permanently denied');
        return null;
      }

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      debugPrint('Error getting current location: $e');
      return null;
    }
  }

  Future<void> startLocationTracking() async {
    if (_isTracking) return;
    try {
      const locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Update every 10 meters
      );

      _isTracking = true;
      Geolocator.getPositionStream(locationSettings: locationSettings)
          .listen(
            (Position position) async {
              try {
                await checkNearbyMemories(position);
              } catch (e) {
                debugPrint('Error checking nearby memories: $e');
              }
            },
            onError: (e) => debugPrint('Location stream error: $e'),
            cancelOnError: false,
          );
    } catch (e) {
      debugPrint('Error starting location tracking: $e');
      _isTracking = false;
    }
  }

  Future<void> checkNearbyMemories(Position position) async {
    try {
      final nearbyMemories = await _databaseService.getNearbyMemories(
        position.latitude,
        position.longitude,
        0.1, // 100 meters in kilometers
      );

      if (nearbyMemories.isNotEmpty) {
        debugPrint('Found ${nearbyMemories.length} nearby memories:');
        for (final memory in nearbyMemories) {
          debugPrint('- ${memory.note} (${memory.formattedDate})');
        }
      }
    } catch (e) {
      debugPrint('Error checking nearby memories: $e');
    }
  }
} 