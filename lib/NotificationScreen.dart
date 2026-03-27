import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FurPalsColors {
  static const blush      = Color(0xFFF9C8D0);
  static const lavender   = Color(0xFFDDD0F5);
  static const cream      = Color(0xFFFFF8F2);
  static const warmWhite  = Color(0xFFFFFAF6);
  static const textDark   = Color(0xFF4A3728);
  static const textMid    = Color(0xFF7A6055);
  static const textSoft   = Color(0x66000000);
  static const pink       = Color(0xFFF4738A);
  static const blue       = Color(0xFF448AFF);
  static const heartRed   = Color(0xFFE53935);
}

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  String _formatTime(Timestamp? ts) {
    if (ts == null) return '';
    final dt = ts.toDate().toLocal();
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Now';
    if (diff.inHours < 1) return '${diff.inMinutes}m';
    if (diff.inDays < 1) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '1w+';
  }

  Future<void> _markAllRead(String currentUid) async {
    final batch = FirebaseFirestore.instance.batch();
    final snapshot = await FirebaseFirestore.instance
        .collection('notifications')
        .where('toUserId', isEqualTo: currentUid)
        .where('isRead', isEqualTo: false)
        .get();
    for (final doc in snapshot.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  Future<void> _muteSender(String currentUid, String fromUserId) async {
    if (fromUserId.isEmpty) return;
    final userRef = FirebaseFirestore.instance.collection('users').doc(currentUid);
    await userRef.set({
      'mutedUsers': FieldValue.arrayUnion([fromUserId]),
    }, SetOptions(merge: true));
  }

  Future<void> _deleteNotification(String docId) async {
    if (docId.isEmpty) return;
    await FirebaseFirestore.instance.collection('notifications').doc(docId).delete();
  }

  Future<void> _showNotificationOptions(
      BuildContext context, QueryDocumentSnapshot doc) async {
    final data = doc.data() as Map<String, dynamic>;
    final fromUsername = data['fromUsername'] ?? 'User';
    final fromUserId = data['fromUserId'] ?? '';

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: FurPalsColors.lavender,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.notifications, color: Colors.white),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          fromUsername,
                          style: GoogleFonts.nunito(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: FurPalsColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Notification options',
                          style: GoogleFonts.nunito(
                            fontSize: 14,
                            color: FurPalsColors.textMid,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () async {
                  Navigator.of(ctx).pop();
                  await _muteSender(FirebaseAuth.instance.currentUser?.uid ?? '', fromUserId);
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: FurPalsColors.lavender.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: FurPalsColors.pink.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.notifications_off, color: Color(0xFFF4738A)),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Turn off notifications',
                              style: GoogleFonts.nunito(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: FurPalsColors.textDark,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Stop updates from $fromUsername',
                              style: GoogleFonts.nunito(
                                fontSize: 13,
                                color: FurPalsColors.textMid,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () async {
                  Navigator.of(ctx).pop();
                  await _deleteNotification(doc.id);
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEBEE),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFCDD2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.delete_outline, color: Color(0xFFC62828)),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Delete notification',
                              style: GoogleFonts.nunito(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: FurPalsColors.textDark,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Remove this from your list',
                              style: GoogleFonts.nunito(
                                fontSize: 13,
                                color: FurPalsColors.textMid,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Map<String, List<QueryDocumentSnapshot>> _groupNotifications(
      List<QueryDocumentSnapshot> docs) {
    final groups = {
      'New': <QueryDocumentSnapshot>[],
      'Yesterday': <QueryDocumentSnapshot>[],
      'Last 7 days': <QueryDocumentSnapshot>[],
    };
    final now = DateTime.now();

    for (final doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final ts = data['createdAt'] as Timestamp?;
      if (ts == null) {
        groups['Last 7 days']!.add(doc);
        continue;
      }

      final diff = now.difference(ts.toDate().toLocal());
      if (diff.inDays == 0) {
        groups['New']!.add(doc);
      } else if (diff.inDays == 1) {
        groups['Yesterday']!.add(doc);
      } else {
        groups['Last 7 days']!.add(doc);
      }
    }

    return groups;
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        title,
        style: GoogleFonts.baloo2(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: FurPalsColors.textDark,
        ),
      ),
    );
  }

  Widget _buildNotificationCard(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final fromUsername = data['fromUsername'] ?? 'Username';
    final type = data['type'] ?? '';
    final isRead = data['isRead'] ?? false;
    final commentText = data['commentText'] ?? '';
    final ts = data['createdAt'] as Timestamp?;
    final time = _formatTime(ts);

    String action = '';
    IconData icon = Icons.notifications;
    Color iconBg = FurPalsColors.lavender;

    if (type == 'like') {
      action = 'liked your photo.';
      icon = Icons.favorite_rounded;
      iconBg = FurPalsColors.heartRed.withOpacity(0.12);
    } else if (type == 'comment') {
      action = commentText.isNotEmpty
          ? 'commented: "$commentText"'
          : 'commented on your post.';
      icon = Icons.chat_bubble_rounded;
      iconBg = FurPalsColors.pink.withOpacity(0.12);
    } else if (type == 'follow') {
      action = 'started following you!';
      icon = Icons.person_add_rounded;
      iconBg = FurPalsColors.blue.withOpacity(0.12);
    } else {
      action = 'sent you a notification.';
      icon = Icons.notifications;
      iconBg = FurPalsColors.blue.withOpacity(0.12);
    }

    return InkWell(
      onTap: () async {
        await FirebaseFirestore.instance
            .collection('notifications')
            .doc(doc.id)
            .update({'isRead': true});
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: isRead ? Colors.white : const Color(0xFFFDEFF4),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: iconBg,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: FurPalsColors.pink, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fromUsername,
                    style: GoogleFonts.nunito(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: FurPalsColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    action,
                    style: GoogleFonts.nunito(
                      fontSize: 14,
                      color: FurPalsColors.textMid,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    time,
                    style: GoogleFonts.nunito(
                      fontSize: 12,
                      color: FurPalsColors.textSoft,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: () => _showNotificationOptions(context, doc),
              child: const Icon(Icons.more_horiz, color: Color(0xFFBDBDBD), size: 24),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';

    if (currentUid.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: FurPalsColors.warmWhite,
          elevation: 0,
          title: Text(
            'Notifications',
            style: GoogleFonts.baloo2(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: FurPalsColors.textDark,
            ),
          ),
          leading: BackButton(color: FurPalsColors.textDark),
        ),
        body: Center(
          child: Text(
            'Please log in to see notifications.',
            style: GoogleFonts.nunito(fontSize: 16, color: FurPalsColors.textMid),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFFF3F5),
      appBar: AppBar(
        backgroundColor: FurPalsColors.warmWhite,
        elevation: 0,
        leading: BackButton(color: FurPalsColors.textDark),
        title: Text(
          'Notifications',
          style: GoogleFonts.baloo2(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: FurPalsColors.textDark,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => _markAllRead(currentUid),
            child: Text(
              'Mark all read',
              style: GoogleFonts.nunito(
                color: FurPalsColors.pink,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(currentUid).snapshots(),
        builder: (context, userSnapshot) {
          if (userSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: FurPalsColors.pink));
          }
          if (userSnapshot.hasError) {
            return Center(
              child: Text(
                'Unable to load settings.\n${userSnapshot.error}',
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(fontSize: 16, color: Colors.red),
              ),
            );
          }

          final userData = userSnapshot.data?.data() as Map<String, dynamic>? ?? {};
          final mutedUsers = List<String>.from(userData['mutedUsers'] ?? []);

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('notifications')
                .where('toUserId', isEqualTo: currentUid)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: FurPalsColors.pink));
              }
              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Unable to load notifications.\n${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.nunito(fontSize: 16, color: Colors.red),
                  ),
                );
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('🐾', style: TextStyle(fontSize: 64)),
                      const SizedBox(height: 16),
                      Text(
                        'No notifications yet!',
                        style: GoogleFonts.baloo2(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: FurPalsColors.textDark,
                        ),
                      ),
                    ],
                  ),
                );
              }

              final notifications = snapshot.data!.docs
                  .where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final fromUserId = data['fromUserId'] ?? '';
                    return !mutedUsers.contains(fromUserId);
                  })
                  .toList();

              notifications.sort((a, b) {
                final aTs = (a.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
                final bTs = (b.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
                if (aTs == null && bTs == null) return 0;
                if (aTs == null) return 1;
                if (bTs == null) return -1;
                return bTs.compareTo(aTs);
              });

              final groups = _groupNotifications(notifications);
              final newCount = notifications.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return (data['isRead'] ?? false) == false;
              }).length;

              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (newCount > 0)
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: FurPalsColors.pink.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '$newCount new',
                              style: GoogleFonts.nunito(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: FurPalsColors.pink,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              '${notifications.length} notifications',
                              style: GoogleFonts.nunito(
                                fontSize: 13,
                                color: FurPalsColors.textMid,
                              ),
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 18),
                    if (groups['New']!.isNotEmpty) ...[
                      _buildSectionHeader('New'),
                      Column(
                        children: groups['New']!
                            .map((doc) => Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _buildNotificationCard(doc),
                                ))
                            .toList(),
                      ),
                    ],
                    if (groups['Yesterday']!.isNotEmpty) ...[
                      _buildSectionHeader('Yesterday'),
                      Column(
                        children: groups['Yesterday']!
                            .map((doc) => Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _buildNotificationCard(doc),
                                ))
                            .toList(),
                      ),
                    ],
                    if (groups['Last 7 days']!.isNotEmpty) ...[
                      _buildSectionHeader('Last 7 days'),
                      Column(
                        children: groups['Last 7 days']!
                            .map((doc) => Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _buildNotificationCard(doc),
                                ))
                            .toList(),
                      ),
                    ],
                    const SizedBox(height: 24),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
