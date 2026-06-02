import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

Future<void> initializeService() async {
  final service = FlutterBackgroundService();

  // Initialize flutter_local_notifications for Android 8+ Foreground Service
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'patrol_service', // id
    'Patrol Service', // title
    description: 'This channel is used for tracking patrol location.',
    importance: Importance.low, // importance must be low or higher
  );

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Use ic_launcher as the default notification icon
  await flutterLocalNotificationsPlugin.initialize(
    settings: const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    ),
  );

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >()
      ?.createNotificationChannel(channel);

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: false,
      isForegroundMode: true,
      notificationChannelId: 'patrol_service',
      initialNotificationTitle: 'Patrol Active',
      initialNotificationContent: 'Tracking location...',
      foregroundServiceNotificationId: 888,
    ),
    iosConfiguration: IosConfiguration(
      autoStart: false,
      onForeground: onStart,
      onBackground: onIosBackground,
    ),
  );
}

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  return true;
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();

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

  // Check location every 10 seconds, update and send to backend only if user moved >= 10 meters
  Timer.periodic(const Duration(seconds: 10), (timer) async {
    if (service is AndroidServiceInstance) {
      if (await service.isForegroundService()) {
        service.setForegroundNotificationInfo(
          title: "Patrol Active",
          content: "Tracking patrol movement...",
        );
      }
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final prefs = await SharedPreferences.getInstance();
      
      // Get the last saved coordinates
      final double? lastLat = prefs.getDouble('last_latitude');
      final double? lastLng = prefs.getDouble('last_longitude');

      bool shouldUpdate = false;
      if (lastLat == null || lastLng == null) {
        shouldUpdate = true;
      } else {
        // Enforce 10 meters distance rule
        double distance = Geolocator.distanceBetween(
          lastLat,
          lastLng,
          position.latitude,
          position.longitude,
        );
        if (distance >= 10.0) {
          shouldUpdate = true;
        }
      }

      if (shouldUpdate) {
        final String timestamp = DateTime.now().toIso8601String();
        
        // Immediately store longitude, latitude and timestamp in SharedPreferences
        await prefs.setDouble('last_latitude', position.latitude);
        await prefs.setDouble('last_longitude', position.longitude);
        await prefs.setString('last_timestamp', timestamp);

        final String? sessionId = prefs.getString('session_id');

        // Send to backend
        if (sessionId != null) {
          await ApiService().post("/api/v1/patrol/track", {
            "session_id": sessionId,
            "latitude": position.latitude,
            "longitude": position.longitude,
            "timestamp": timestamp,
          });
        }

        // Invoke event to update UI if app is open
        service.invoke('updateLocation', {
          "latitude": position.latitude,
          "longitude": position.longitude,
        });
      }
    } catch (e) {
      debugPrint("Error in background service: $e");
    }
  });
}
