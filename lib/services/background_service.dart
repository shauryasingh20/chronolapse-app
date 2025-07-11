import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'location_service.dart';
import '../models/memory.dart';
import '../services/database_service.dart';

class BackgroundService {
  static final BackgroundService _instance = BackgroundService._internal();
  final LocationService _locationService = LocationService();
  bool _isInitialized = false;

  factory BackgroundService() => _instance;

  BackgroundService._internal();

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      debugPrint('Initializing background service...');
      final service = FlutterBackgroundService();

      await service.configure(
        androidConfiguration: AndroidConfiguration(
          onStart: onStart,
          autoStart: false,
          isForegroundMode: true,
          notificationChannelId: 'chronolapse_background',
          initialNotificationTitle: 'ChronoLapse',
          initialNotificationContent: 'Running in background',
          foregroundServiceNotificationId: 888,
        ),
        iosConfiguration: IosConfiguration(
          autoStart: false,
          onForeground: onStart,
          onBackground: onIosBackground,
        ),
      );

      _isInitialized = true;
      debugPrint('Background service initialized successfully');
    } catch (e, stackTrace) {
      debugPrint('Error initializing background service: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  @pragma('vm:entry-point')
  static Future<bool> onIosBackground(ServiceInstance service) async {
    try {
      return true;
    } catch (e) {
      debugPrint('Error in iOS background handler: $e');
      return false;
    }
  }

  @pragma('vm:entry-point')
  static void onStart(ServiceInstance service) async {
    try {
      debugPrint('Background service starting...');
      final notifications = FlutterLocalNotificationsPlugin();
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const initSettings = InitializationSettings(android: androidSettings);
      await notifications.initialize(initSettings);

      if (service is AndroidServiceInstance) {
        service.on('setAsForeground').listen((event) {
          service.setAsForegroundService();
        });

        service.on('setAsBackground').listen((event) {
          service.setAsBackgroundService();
        });
      }

      service.on('stopService').listen((event) {
        service.stopSelf();
      });

      final locationService = LocationService();
      await locationService.initialize();
      await locationService.startLocationTracking();

      bool running = true;
      service.on('stopService').listen((event) {
        running = false;
        service.stopSelf();
      });

      // Periodically check for nearby memories and show notification
      while (running) {
        final position = await locationService.getCurrentLocation();
        if (position != null) {
          final dbService = DatabaseService();
          final memories = await dbService.getNearbyMemories(
            position.latitude,
            position.longitude,
            3.0, // 3 km
          );
          if (memories.isNotEmpty) {
            for (final memory in memories) {
              await notifications.show(
                memory.id ?? 0,
                'Nearby Memory!',
                memory.note.isNotEmpty ? memory.note : 'You are near a saved memory.',
                const NotificationDetails(
                  android: AndroidNotificationDetails(
                    'chronolapse_channel',
                    'Nearby Memories',
                    channelDescription: 'Notifications for nearby memories',
                    importance: Importance.max,
                    priority: Priority.high,
                  ),
                ),
              );
            }
          }
        }
        await Future.delayed(const Duration(minutes: 2));
      }
      debugPrint('Background service started successfully');
    } catch (e, stackTrace) {
      debugPrint('Error in background service onStart: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  Future<void> startService() async {
    try {
      if (!_isInitialized) {
        debugPrint('Background service not initialized, initializing now...');
        await initialize();
      }

      debugPrint('Starting background service...');
      final service = FlutterBackgroundService();
      await service.startService();
      debugPrint('Background service start requested');
    } catch (e, stackTrace) {
      debugPrint('Error starting background service: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  Future<void> stopService() async {
    try {
      debugPrint('Stopping background service...');
      final service = FlutterBackgroundService();
      service.invoke('stopService');
      debugPrint('Background service stop requested');
    } catch (e, stackTrace) {
      debugPrint('Error stopping background service: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }
} 