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

  // Tracks which sport topics this device is currently subscribed to.
  final Set<String> _subscribedSportTopics = {};

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

    // Subscribe players to the all_players topic for non-session notifications
    // (payment reminders, announcements). Session notifications use sport topics.
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

  /// Called whenever a player's sport profile list changes.
  /// Subscribes to new sport topics and unsubscribes from removed ones.
  /// Topic format: "sport_football", "sport_cricket", etc.
  Future<void> syncSportTopics(List<String> currentSports) async {
    final next = currentSports.toSet();

    final toAdd = next.difference(_subscribedSportTopics);
    final toRemove = _subscribedSportTopics.difference(next);

    for (final sport in toAdd) {
      await _messaging.subscribeToTopic('sport_$sport');
    }
    for (final sport in toRemove) {
      await _messaging.unsubscribeFromTopic('sport_$sport');
    }

    _subscribedSportTopics
      ..removeAll(toRemove)
      ..addAll(toAdd);
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
