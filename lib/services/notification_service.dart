import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _local =
  FlutterLocalNotificationsPlugin();

  // 🔥 INIT FUNCTION
  Future init() async {
    // 1️⃣ Request Permission
    await _fcm.requestPermission();

    // 2️⃣ Get Device Token
    String? token = await _fcm.getToken();
    print("FCM TOKEN: $token");

    // 3️⃣ Local Notification Initialization
    const AndroidInitializationSettings androidInit =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initSettings =
    InitializationSettings(android: androidInit);

    await _local.initialize(
      settings: initSettings, // ✅ FIXED (important)
      onDidReceiveNotificationResponse: (response) {
        print("Notification Clicked");
      },
    );

    // 4️⃣ Foreground Notification Listener
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      showNotification(
        title: message.notification?.title ?? "Metro Update",
        body: message.notification?.body ?? "",
      );
    });
  }

  // 🔔 SHOW NOTIFICATION
  Future showNotification({
    required String title,
    required String body,
  }) async {
    const AndroidNotificationDetails androidDetails =
    AndroidNotificationDetails(
      'metro_channel',
      'Metro Updates',
      importance: Importance.max,
      priority: Priority.high,
    );

    const NotificationDetails details =
    NotificationDetails(android: androidDetails);

    await _local.show(
      id: 0, // ✅ required
      title: title,
      body: body,
      notificationDetails: details,
    );
  }
}