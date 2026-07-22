import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

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
  try {
    DartPluginRegistrant.ensureInitialized();
  } catch (e) {
    debugPrint("Failed to initialize DartPluginRegistrant on iOS background: $e");
  }
  return true;
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  HttpOverrides.global = MyHttpOverrides();
  WidgetsFlutterBinding.ensureInitialized();
  try {
    DartPluginRegistrant.ensureInitialized();
  } catch (e) {
    debugPrint("Failed to initialize DartPluginRegistrant on Android background: $e");
  }

  if (service is AndroidServiceInstance) {
    service.on('setAsForeground').listen((event) {
      service.setAsForegroundService();
    });

    service.on('setAsBackground').listen((event) {
      service.setAsBackgroundService();
    });
  }

  // Get the vehicle/patrol method from SharedPreferences
  final prefs = await SharedPreferences.getInstance();
  final int? patrolId = prefs.getInt('patrol_id');
  if (patrolId == null) {
    debugPrint("No active patrol ID found. Stopping background service immediately.");
    service.stopSelf();
    return;
  }

  final String patrolVehicle = prefs.getString('patrol_vehicle') ?? 'car';
  final int intervalSeconds;
  if (patrolVehicle == 'foot') {
    intervalSeconds = 300; // 5 minutes
  } else {
    intervalSeconds = 60;  // 1 minute (Car and Motorcycle)
  }

  Position? currentPosition;
  StreamSubscription<Position>? positionSubscription;

  // Listen to the device's location stream in the background isolate
  try {
    positionSubscription =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 0,
          ),
        ).listen((Position position) {
          currentPosition = position;

          // Smoothly broadcast location updates to the foreground UI in real-time
          service.invoke('updateLocation', {
            "latitude": position.latitude,
            "longitude": position.longitude,
          });
        }, onError: (error) {
          debugPrint("Error in background location stream: $error");
        });
  } catch (e) {
    debugPrint("Failed to listen to background location stream: $e");
  }

  Timer? periodicTimer;

  service.on('stopService').listen((event) {
    periodicTimer?.cancel();
    positionSubscription?.cancel();
    service.stopSelf();
  });

  // Check location periodically and send to backend
  periodicTimer = Timer.periodic(Duration(seconds: intervalSeconds), (
    timer,
  ) async {
    if (service is AndroidServiceInstance) {
      if (await service.isForegroundService()) {
        service.setForegroundNotificationInfo(
          title: "Patrol Active",
          content: "Tracking patrol movement...",
        );
      }
    }

    try {
      await prefs.reload();
      final int? patrolId = prefs.getInt('patrol_id');

      if (patrolId == null) {
        debugPrint("[GPS_TRACK] patrol_id is null. Stopping background service.");
        periodicTimer?.cancel();
        positionSubscription?.cancel();
        service.stopSelf();
        return;
      }

      Position? position = currentPosition;

      // Fallback if we haven't received a stream update yet
      if (position == null) {
        try {
          position = await Geolocator.getLastKnownPosition();
        } catch (e) {
          debugPrint("Failed to get last known position in background: $e");
        }
      }

      if (position == null) {
        debugPrint("Skipping location update: Position is null.");
        return;
      }

      final String timestamp =
          DateTime.now().toUtc().toIso8601String().substring(0, 19) + "Z";

      // Store coordinates locally
      await prefs.setDouble('last_latitude', position.latitude);
      await prefs.setDouble('last_longitude', position.longitude);
      await prefs.setString('last_timestamp', timestamp);

      // Send to backend
      try {
        final String endpoint = "/api/v1/patrols/$patrolId/locations";
        final Map<String, dynamic> requestBody = {
          "locations": [
            {
              "latitude": position.latitude,
              "longitude": position.longitude,
              "recorded_at": timestamp,
            },
          ],
        };

        final response = await ApiService().post(endpoint, requestBody);

        if (response.statusCode == 200 || response.statusCode == 201) {
          print(
            "[GPS_TRACK] Sent update successfully: lat=${position.latitude}, lng=${position.longitude}",
          );
        } else {
          print(
            "[GPS_TRACK] Failed: ${response.statusCode} - ${response.body}",
          );
        }
      } catch (e) {
        debugPrint("Error sending background update: $e");
      }
    } catch (e) {
      debugPrint("Error in background service loop: $e");
    }
  });
}
