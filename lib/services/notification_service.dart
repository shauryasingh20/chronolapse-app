import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/memory.dart';
import '../screens/memory_detail_screen.dart';
import '../services/database_service.dart';
import '../main.dart'; // Import for navigatorKey

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  factory NotificationService() => _instance;

  NotificationService._internal();

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      debugPrint('Initializing notification service...');
      
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      
      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      // Create notification channel for Android
      const androidChannel = AndroidNotificationChannel(
        'chronolapse_channel',
        'Nearby Memories',
        description: 'Notifications for nearby memories',
        importance: Importance.max,
      );

      await _notifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(androidChannel);

      _isInitialized = true;
      debugPrint('Notification service initialized successfully');
    } catch (e, stackTrace) {
      debugPrint('Error initializing notification service: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  void _onNotificationTapped(NotificationResponse response) async {
    try {
      debugPrint('Notification tapped with payload: ${response.payload}');
      
      // Parse the memory ID from the payload
      if (response.payload != null && response.payload!.isNotEmpty) {
        final memoryId = int.tryParse(response.payload!);
        if (memoryId != null) {
          // Get the memory from database
          final dbService = DatabaseService();
          final memory = await dbService.getMemory(memoryId);
          
          if (memory != null) {
            debugPrint('Found memory for navigation: ${memory.note}');
            // Navigate to memory detail screen
            // We'll use a global navigator key to handle navigation from outside the widget tree
            _navigateToMemoryDetail(memory);
          } else {
            debugPrint('Memory not found for ID: $memoryId');
          }
        }
      }
    } catch (e) {
      debugPrint('Error handling notification tap: $e');
    }
  }

  void _navigateToMemoryDetail(Memory memory) {
    try {
      debugPrint('Navigating to memory detail: ${memory.note}');
      
      // Use the global navigator key to navigate from outside the widget tree
      navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (context) => MemoryDetailScreen(memory: memory),
        ),
      );
    } catch (e) {
      debugPrint('Error navigating to memory detail: $e');
    }
  }



  Future<void> showNearbyMemoryNotification(Memory memory) async {
    if (!_isInitialized) {
      debugPrint('Notification service not initialized');
      return;
    }

    try {
      final notificationId = memory.id ?? DateTime.now().millisecondsSinceEpoch;
      final title = 'Nearby Memory!';
      final body = memory.note.isNotEmpty 
          ? memory.note 
          : 'You are near a saved memory.';

      await _notifications.show(
        notificationId,
        title,
        body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'chronolapse_channel',
            'Nearby Memories',
            channelDescription: 'Notifications for nearby memories',
            importance: Importance.max,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: memory.id?.toString() ?? '',
      );

      debugPrint('Nearby memory notification shown for memory ID: ${memory.id}');
    } catch (e) {
      debugPrint('Error showing nearby memory notification: $e');
    }
  }

  Future<void> cancelAllNotifications() async {
    if (!_isInitialized) return;

    try {
      await _notifications.cancelAll();
      debugPrint('All notifications cancelled');
    } catch (e) {
      debugPrint('Error cancelling notifications: $e');
    }
  }
} 