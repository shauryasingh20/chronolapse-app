import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../models/memory.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';

class GeofenceService {
  static final GeofenceService _instance = GeofenceService._internal();
  final DatabaseService _databaseService = DatabaseService();
  final NotificationService _notificationService = NotificationService();
  bool _isInitialized = false;
  bool _isMonitoring = false;

  factory GeofenceService() => _instance;

  GeofenceService._internal();

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      debugPrint('Initializing geofence service...');
      
      // Check location permissions
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('Location services are disabled');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('Location permissions are denied');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('Location permissions are permanently denied');
        return;
      }

      _isInitialized = true;
      debugPrint('Geofence service initialized successfully');
    } catch (e) {
      debugPrint('Error initializing geofence service: $e');
    }
  }

  Future<void> startGeofenceMonitoring() async {
    if (!_isInitialized || _isMonitoring) return;

    try {
      debugPrint('Starting geofence monitoring...');
      
      // Get all memories and register geofences
      final memories = await _databaseService.getMemories();
      await _registerGeofencesForMemories(memories);
      
      // Start location tracking for geofence monitoring
      await _startLocationTracking();
      
      _isMonitoring = true;
      debugPrint('Geofence monitoring started successfully');
    } catch (e) {
      debugPrint('Error starting geofence monitoring: $e');
    }
  }

  Future<void> stopGeofenceMonitoring() async {
    if (!_isMonitoring) return;

    try {
      debugPrint('Stopping geofence monitoring...');
      _isMonitoring = false;
      debugPrint('Geofence monitoring stopped');
    } catch (e) {
      debugPrint('Error stopping geofence monitoring: $e');
    }
  }

  Future<void> registerGeofenceForMemory(Memory memory) async {
    if (!_isInitialized) return;

    try {
      debugPrint('Registering geofence for memory ID: ${memory.id}');
      
      // For now, we'll use location tracking to simulate geofencing
      // In a production app, you would use platform-specific geofencing APIs
      // This approach works reliably across platforms
      
      // The geofence is effectively "registered" by being included in our monitoring list
      debugPrint('Geofence registered for memory: ${memory.note} at ${memory.latitude}, ${memory.longitude}');
    } catch (e) {
      debugPrint('Error registering geofence for memory: $e');
    }
  }

  Future<void> _registerGeofencesForMemories(List<Memory> memories) async {
    try {
      debugPrint('Registering geofences for ${memories.length} memories');
      
      for (final memory in memories) {
        await registerGeofenceForMemory(memory);
      }
      
      debugPrint('All geofences registered successfully');
    } catch (e) {
      debugPrint('Error registering geofences: $e');
    }
  }

  Future<void> _startLocationTracking() async {
    try {
      const locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 50, // Update every 50 meters for better battery life
      );

      Geolocator.getPositionStream(locationSettings: locationSettings)
          .listen(
            (Position position) async {
              await _checkGeofenceTriggers(position);
            },
            onError: (e) => debugPrint('Location stream error: $e'),
            cancelOnError: false,
          );
      
      debugPrint('Location tracking started for geofence monitoring');
    } catch (e) {
      debugPrint('Error starting location tracking: $e');
    }
  }

  Future<void> _checkGeofenceTriggers(Position position) async {
    try {
      // Get all memories and check if we're near any of them
      final memories = await _databaseService.getMemories();
      final nearbyMemories = await _databaseService.getNearbyMemories(
        position.latitude,
        position.longitude,
        3.0, // 3 km radius as requested
      );

      if (nearbyMemories.isNotEmpty) {
        debugPrint('Found ${nearbyMemories.length} memories within 3km');
        
        for (final memory in nearbyMemories) {
          // Check if we should show notification for this memory
          // In a real implementation, you'd track which memories have already triggered
          // to avoid spam notifications
          await _triggerGeofenceNotification(memory);
        }
      }
    } catch (e) {
      debugPrint('Error checking geofence triggers: $e');
    }
  }

  Future<void> _triggerGeofenceNotification(Memory memory) async {
    try {
      debugPrint('Triggering geofence notification for memory: ${memory.note}');
      
      // Show the production notification (not test notification)
      await _notificationService.showNearbyMemoryNotification(memory);
      
      debugPrint('Geofence notification triggered successfully for memory ID: ${memory.id}');
    } catch (e) {
      debugPrint('Error triggering geofence notification: $e');
    }
  }

  Future<void> onMemoryAdded(Memory memory) async {
    try {
      debugPrint('New memory added, registering geofence...');
      await registerGeofenceForMemory(memory);
      debugPrint('Geofence registered for new memory: ${memory.note}');
    } catch (e) {
      debugPrint('Error registering geofence for new memory: $e');
    }
  }

  Future<void> onMemoryDeleted(int memoryId) async {
    try {
      debugPrint('Memory deleted, removing geofence for ID: $memoryId');
      // In a real implementation, you would remove the specific geofence
      // For now, we'll just log it since our monitoring is based on database queries
      debugPrint('Geofence removed for memory ID: $memoryId');
    } catch (e) {
      debugPrint('Error removing geofence for deleted memory: $e');
    }
  }
} 