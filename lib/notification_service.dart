import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class NotificationService {
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<void> initialize() async {
    // Request permission
    await _firebaseMessaging.requestPermission();

    // Get FCM token
    final token = await _firebaseMessaging.getToken();
    if (token != null) {
      await _saveTokenToDatabase(token);
    }

    // Handle token refresh
    FirebaseMessaging.instance.onTokenRefresh.listen(_saveTokenToDatabase);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_handleBackgroundMessage);
  }

  static Future<void> _saveTokenToDatabase(String token) async {
    // This would be called when user logs in
    // For now, we'll assume current user is available
    // In a real app, you'd get the current user ID
  }

  static void _handleForegroundMessage(RemoteMessage message) {
    // Handle foreground notifications
    // You can show a local notification or update UI
  }

  static Future<void> _handleBackgroundMessage(RemoteMessage message) async {
    // Handle background messages
  }

  static Future<void> sendFollowNotification({
    required String toUserId,
    required String fromUserId,
    required String fromUsername,
  }) async {
    try {
      // Get the target user's FCM token
      final userDoc = await _firestore.collection('users').doc(toUserId).get();
      final token = userDoc.data()?['fcmToken'];

      if (token == null) return;

      // Create notification in Firestore
      await _firestore.collection('notifications').add({
        'toUserId': toUserId,
        'fromUserId': fromUserId,
        'fromUsername': fromUsername,
        'type': 'follow',
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Send push notification via FCM
      await _sendFCMNotification(
        token: token,
        title: 'New Follower',
        body: '$fromUsername started following you!',
        data: {
          'type': 'follow',
          'fromUserId': fromUserId,
        },
      );
    } catch (e) {
      print('Error sending follow notification: $e');
    }
  }

  static Future<void> sendAttendanceNotification({
    required String toUserId,
    required String fromUserId,
    required String fromUsername,
    required String eventId,
    required String eventTitle,
  }) async {
    try {
      final userDoc = await _firestore.collection('users').doc(toUserId).get();
      final token = userDoc.data()?['fcmToken'];

      await _firestore.collection('notifications').add({
        'toUserId': toUserId,
        'fromUserId': fromUserId,
        'fromUsername': fromUsername,
        'eventId': eventId,
        'eventTitle': eventTitle,
        'type': 'going',
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (token == null) return;

      await _sendFCMNotification(
        token: token,
        title: 'Someone is going to your event',
        body: '$fromUsername is going to "$eventTitle"',
        data: {
          'type': 'going',
          'fromUserId': fromUserId,
          'eventId': eventId,
        },
      );
    } catch (e) {
      print('Error sending attendance notification: $e');
    }
  }

  static Future<void> _sendFCMNotification({
    required String token,
    required String title,
    required String body,
    required Map<String, dynamic> data,
  }) async {
    const serverKey = 'YOUR_SERVER_KEY'; // Replace with your FCM server key

    final message = {
      'to': token,
      'notification': {
        'title': title,
        'body': body,
      },
      'data': data,
    };

    final response = await http.post(
      Uri.parse('https://fcm.googleapis.com/fcm/send'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'key=$serverKey',
      },
      body: jsonEncode(message),
    );

    if (response.statusCode != 200) {
      print('Failed to send FCM notification: ${response.body}');
    }
  }

  static Future<void> saveTokenForUser(String userId, String token) async {
    await _firestore.collection('users').doc(userId).update({
      'fcmToken': token,
    });
  }
}