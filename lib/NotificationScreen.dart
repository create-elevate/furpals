import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:furpals/lost&found.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

//colorsssssssss
class FurPalsColors {
  static const blush       = Color(0xFFF9C8D0);
  static const peach       = Color(0xFFFFD9C0);
  static const mint        = Color(0xFFC5EDD6);
  static const lavender    = Color(0xFFDDD0F5);
  static const butter      = Color(0xFFFFF3C4);
  static const cream       = Color(0xFFFFF8F2);
  static const warmWhite   = Color(0xFFFFFAF6);
  static const textDark    = Color(0xFF4A3728);
  static const textMid     = Color(0xFF7A6055);
  static const textSoft    = Color(0x66000000);
  static const pink        = Color(0xFFF4738A);
  static const pinkLight   = Color(0xFFFF9AB0);
  static const green       = Color(0xFF5DB87A);
  static const purple      = Color(0xFF8B6FD4);
  static const shadow      = Color(0x20B47864);
  static const creamwhite  = Color(0xFFF9E9D5);
  static const blue        = Color(0xFF448AFF);
  static const heartRed    = Color(0xFFE53935);
  static const black100    = Color(0xFF000000);
}

const appBackgroundGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  stops: [0.0, 0.5, 1.0],
  colors: [Color(0xFFFCDDE8), Color(0xFFFFE8D2), Color(0xFFD4F0E4)],
);

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

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

  @override
  Widget build(BuildContext context) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';

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
        actions: [
          IconButton(
            icon: Icon(Icons.done_all_rounded, color: FurPalsColors.pink),
            onPressed: () async {
              // Mark all as read
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
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('notifications')
            .where('toUserId', isEqualTo: currentUid)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: FurPalsColors.pink));
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

          final notifications = snapshot.data!.docs;
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: notifications.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) {
              final data = notifications[i].data() as Map<String, dynamic>;
              final fromUsername = data['fromUsername'] ?? '';
              final type = data['type'] ?? '';
              final isRead = data['isRead'] ?? false;
              final ts = data['createdAt'] as Timestamp?;
              final time = _formatTime(ts);

              String action = '';
              IconData icon = Icons.notifications;
              Color iconBg = FurPalsColors.lavender;

              if (type == 'like') {
                action = 'liked your post.';
                icon = Icons.favorite_rounded;
                iconBg = FurPalsColors.heartRed.withOpacity(0.1);
              } else if (type == 'comment') {
                action = 'commented on your post.';
                icon = Icons.chat_bubble_rounded;
                iconBg = FurPalsColors.pink.withOpacity(0.1);
              }

              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isRead ? FurPalsColors.warmWhite : FurPalsColors.blush.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isRead ? FurPalsColors.cream : FurPalsColors.blush,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: iconBg,
                      ),
                      child: Icon(icon, color: FurPalsColors.pink, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: '@$fromUsername ',
                                  style: GoogleFonts.nunito(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: FurPalsColors.textDark,
                                  ),
                                ),
                                TextSpan(
                                  text: action,
                                  style: GoogleFonts.nunito(
                                    fontSize: 16,
                                    color: FurPalsColors.textMid,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 4),
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
                  ],
                ));
              },
            );
        },
      ),
    );
  }
}
