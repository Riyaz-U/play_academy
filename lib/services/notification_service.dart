import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../core/constants/app_constants.dart';
import 'firestore_service.dart';

/// Top-level handler required by firebase_messaging for background messages.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Firebase is already initialized at this point.
  // The notification is automatically shown by the system in background/terminated state.
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    AppConstants.fcmChannelId,
    'Play Academy Notifications',
    description: 'Training sessions, matches, and payment reminders',
    importance: Importance.high,
  );

  bool _initialized = false;

  Future<void> initialize(String uid, {bool isPlayer = false}) async {
    if (_initialized) return;
    _initialized = true;

    // Register background handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Request permissions (Android 13+, iOS)
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Set up local notifications for foreground display
    const initSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );
    await _localNotifications.initialize(initSettings);

    // Create Android channel
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    // Show local notification when app is in foreground
    FirebaseMessaging.onMessage.listen(_showLocalNotification);

    // Subscribe players to the branch-agnostic topic (branch-specific done by Cloud Function)
    if (isPlayer) {
      await _messaging.subscribeToTopic(AppConstants.topicAllPlayers);
    }

    // Save FCM token to Firestore
    final token = await _messaging.getToken();
    if (token != null) {
      await FirestoreService().updateFcmToken(uid, token);
    }

    // Refresh token listener
    _messaging.onTokenRefresh.listen((newToken) {
      FirestoreService().updateFcmToken(uid, newToken);
    });
  }

  void _showLocalNotification(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
    );
  }
}
