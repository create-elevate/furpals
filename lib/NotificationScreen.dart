import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:furpals/lost&found.dart';

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
//de data
enum NotifType { like, comment, follow, share, lostFound }

class NotifItem {
  final String id;
  final String username;
  final String emoji;
  final NotifType type;
  final String action;       //format 
  final String time;
  final DateTime timestamp;
  bool isRead;
  bool isMuted;              // turn off notifications state

  NotifItem({
    required this.id,
    required this.username,
    required this.emoji,
    required this.type,
    required this.action,
    required this.time,
    required this.timestamp,
    this.isRead = false,
    this.isMuted = false,
  });
}
class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  late List<NotifItem> _notifications;
  @override
  void initState() {
    super.initState();
    _notifications = _generateSampleData();
  }
  List<NotifItem> _generateSampleData() {
    final now = DateTime.now();
    return [
      // Today sample
      NotifItem(
        id: '1', username: 'Queenomo', emoji: '🐱',
        type: NotifType.like, action: 'liked your photo.',
        time: 'Now', timestamp: now.subtract(const Duration(minutes: 2)),
      ),
      NotifItem(
        id: '2', username: 'Queenomo', emoji: '🐱',
        type: NotifType.comment, action: 'commented on your post. 🐾',
        time: '1 hr', timestamp: now.subtract(const Duration(hours: 1)),
      ),
      NotifItem(
        id: '3', username: 'fluffybuddyy', emoji: '🐶',
        type: NotifType.follow, action: 'started following you!',
        time: '3 hrs', timestamp: now.subtract(const Duration(hours: 3)),
        isRead: true,
      ),
      // Yesterday sample
      NotifItem(
        id: '4', username: 'Queenomo', emoji: '🐱',
        type: NotifType.like, action: 'liked your photo.',
        time: 'Yesterday', timestamp: now.subtract(const Duration(days: 1, hours: 2)),
        isRead: true,
      ),
      NotifItem(
        id: '5', username: 'mochipaws', emoji: '🐾',
        type: NotifType.share, action: 'shared your post with 3 others.',
        time: 'Yesterday', timestamp: now.subtract(const Duration(days: 1, hours: 5)),
        isRead: true,
      ),
      // Last 7 days sample
      NotifItem(
        id: '6', username: 'Queenomo', emoji: '🐱',
        type: NotifType.comment, action: 'is now your FurPal! 🎉',
        time: '3 days', timestamp: now.subtract(const Duration(days: 3)),
        isRead: true,
      ),
      NotifItem(
        id: '7', username: 'daisywalks', emoji: '🦮',
        type: NotifType.lostFound, action: 'reported a lost pet near you.',
        time: '5 days', timestamp: now.subtract(const Duration(days: 5)),
        isRead: true,
      ),
      NotifItem(
        id: '8', username: 'cocorabbit', emoji: '🐰',
        type: NotifType.like, action: 'and 12 others liked your post.',
        time: '6 days', timestamp: now.subtract(const Duration(days: 6)),
        isRead: true,
      ),
    ];
  }
  void _markAllRead() {
    setState(() {
      for (final n in _notifications) {
        n.isRead = true;
      }
    });
  }
  void _deleteNotif(String id) {
    setState(() => _notifications.removeWhere((n) => n.id == id));
  }
  void _toggleMute(String id) {
    setState(() {
      final n = _notifications.firstWhere((n) => n.id == id);
      n.isMuted = !n.isMuted;
    });
  }
  void _markRead(String id) {
    setState(() {
      final n = _notifications.firstWhere((n) => n.id == id);
      n.isRead = true;
    });
  }

  List<NotifItem> _group(String label) { // group string
    final now = DateTime.now();
    return _notifications.where((n) {
      final diff = now.difference(n.timestamp).inHours;
      if (label == 'Today')        return diff < 24;
      if (label == 'Yesterday')    return diff >= 24 && diff < 48;
      if (label == 'Last 7 days')  return diff >= 48 && diff < 168;
      return false;
    }).toList();
  }

  int get _unreadCount => _notifications.where((n) => !n.isRead).length;

  // small icon status in profile
  IconData _typeIcon(NotifType t) {
    switch (t) {
      case NotifType.like:      return Icons.favorite_rounded;
      case NotifType.comment:   return Icons.chat_bubble_rounded;
      case NotifType.follow:    return Icons.person_add_rounded;
      case NotifType.share:     return Icons.share_rounded;
      case NotifType.lostFound: return Icons.location_on_rounded;
    }
  }

  Color _typeColor(NotifType t) { // color emoji indication of the status
    switch (t) {
      case NotifType.like:      return FurPalsColors.heartRed;
      case NotifType.comment:   return FurPalsColors.pink;
      case NotifType.follow:    return FurPalsColors.purple;
      case NotifType.share:     return FurPalsColors.blue;
      case NotifType.lostFound: return FurPalsColors.green;
    }
  }

  Color _typeBg(NotifType t) {   // color circle indication of the status
    switch (t) {
      case NotifType.like:      return const Color(0xFFFFE4E4);
      case NotifType.comment:   return FurPalsColors.blush;
      case NotifType.follow:    return FurPalsColors.lavender;
      case NotifType.share:     return const Color(0xFFDEEDFF);
      case NotifType.lostFound: return FurPalsColors.mint;
    }
  }

  //3dot menu
  void _showOptions(BuildContext context, NotifItem notif) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: FurPalsColors.warmWhite,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: FurPalsColors.blush,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),

            Row(
              children: [
                Container( // menu dot avatar
                  width: 38, height: 38,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(colors: [FurPalsColors.blush, FurPalsColors.peach]),
                  ),
                  child: Center(child: Text(notif.emoji, style: const TextStyle(fontSize: 18))),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(notif.username,
                        style: GoogleFonts.baloo2(
                          fontSize: 14, fontWeight: FontWeight.w800, color: FurPalsColors.textDark,
                        )),
                    Text(notif.action,
                        style: GoogleFonts.nunito(
                          fontSize: 11, color: FurPalsColors.textMid, fontWeight: FontWeight.w600,
                        )),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16), 
            const Divider(height: 1, color: Color(0xFFF0E4DC)),
            const SizedBox(height: 16),

            // Turn off notifications
            _OptionTile(
              icon: notif.isMuted ? Icons.notifications_active_rounded : Icons.notifications_off_rounded,
              iconColor: FurPalsColors.purple,
              iconBg: FurPalsColors.lavender,
              label: notif.isMuted ? 'Turn on notifications' : 'Turn off notifications',
              sublabel: notif.isMuted ? 'Resume updates from ${notif.username}' : 'Stop updates from ${notif.username}',
              onTap: () {
                Navigator.pop(context);
                _toggleMute(notif.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      notif.isMuted
                          ? 'Notifications on for ${notif.username}'
                          : 'Notifications off for ${notif.username}',
                      style: GoogleFonts.nunito(fontWeight: FontWeight.w700),
                    ),
                    backgroundColor: FurPalsColors.purple,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),

            // Delete notification
            _OptionTile(
              icon: Icons.delete_rounded,
              iconColor: FurPalsColors.heartRed,
              iconBg: const Color(0xFFFFE4E4),
              label: 'Delete notification',
              sublabel: 'Remove this from your list',
              onTap: () {
                Navigator.pop(context);
                _deleteNotif(notif.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Notification deleted',
                        style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
                    backgroundColor: FurPalsColors.heartRed,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
  @override
  Widget build(BuildContext context) { // frame bg
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: appBackgroundGradient),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.50),
                  ),
                  child: _notifications.isEmpty
                      ? _buildEmpty()
                      : _buildList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // app bar top
  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: () => Navigator.maybePop(context),
            child: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [BoxShadow(color: FurPalsColors.shadow, blurRadius: 10, offset: Offset(0, 3))],
              ),
              child: const Center(child: Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: FurPalsColors.textDark)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    'Notifications',
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.baloo2(
                      fontSize: 22, fontWeight: FontWeight.w800, color: FurPalsColors.textDark,
                    ),
                  ),
                ),
                if (_unreadCount > 0) ...[ // indicator for new notif
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [FurPalsColors.pink, FurPalsColors.pinkLight]),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('$_unreadCount new',
                        style: GoogleFonts.nunito(
                          fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white,
                        )),
                  ),
                ],
              ],
            ),
          ),
          // Mark all read 
          if (_unreadCount > 0) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _markAllRead,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: FurPalsColors.blush,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('Mark all read',
                    style: GoogleFonts.nunito(
                      fontSize: 11, fontWeight: FontWeight.w800, color: FurPalsColors.pink,
                    )),
              ),
            ),
          ],
        ],
      ),
    );
  }
  Widget _buildList() { // build list of the notif group
    final groups = ['Today', 'Yesterday', 'Last 7 days'];
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      itemCount: groups.length,
      itemBuilder: (_, i) {
        final items = _group(groups[i]);
        if (items.isEmpty) return const SizedBox.shrink();
        return _buildGroup(groups[i], items);
      },
    );
  }

  Widget _buildGroup(String label, List<NotifItem> items) { // design of frame unread
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 14, 0, 8),
          child: Row(
            children: [
              Container(
                width: 6, height: 6,
                decoration: BoxDecoration(
                  color: FurPalsColors.pink,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(label,
                  style: GoogleFonts.baloo2(
                    fontSize: 13, fontWeight: FontWeight.w800,
                    color: FurPalsColors.textMid,
                    letterSpacing: 0.4,
                  )),
            ],
          ),
        ),
        // Card container for the group read ver.
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [BoxShadow(color: FurPalsColors.shadow, blurRadius: 10, offset: Offset(0, 4))],
          ),
          clipBehavior: Clip.hardEdge,
          child: Column(
            children: List.generate(items.length, (i) {
              final item = items[i];
              return Column(
                children: [
                  _buildNotifTile(item),
                  if (i < items.length - 1)
                    const Divider(height: 1, indent: 70, endIndent: 16, color: Color(0xFFF5EDE8)),
                ],
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildNotifTile(NotifItem notif) {
    final isUnread = !notif.isRead;
    return GestureDetector(
      onTap: () => _markRead(notif.id), // read or unreadstatus
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        color: isUnread ? FurPalsColors.blush.withOpacity(0.35) : Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: notif.isMuted
                          ? [const Color(0xFFE0E0E0), const Color(0xFFBDBDBD)]
                          : [FurPalsColors.blush, FurPalsColors.peach],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: FurPalsColors.shadow.withOpacity(0.5),
                        blurRadius: 6, offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center( // muted status 
                    child: Text(
                      notif.isMuted ? '🔕' : notif.emoji,
                      style: const TextStyle(fontSize: 22),
                    ),
                  ),
                ),
                // Type badge
                Positioned(
                  right: -2, bottom: -2,
                  child: Container(
                    width: 20, height: 20,
                    decoration: BoxDecoration(
                      color: _typeBg(notif.type),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    child: Icon(_typeIcon(notif.type), size: 10, color: _typeColor(notif.type)),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),

            // Text content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      style: GoogleFonts.nunito(
                        fontSize: 13, color: FurPalsColors.textDark, fontWeight: FontWeight.w600,
                      ),
                      children: [
                        TextSpan(
                          text: notif.username,
                          style: GoogleFonts.baloo2(
                            fontSize: 13, fontWeight: FontWeight.w800, color: FurPalsColors.textDark,
                          ),
                        ),
                        TextSpan(text: ' ${notif.action}'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Icon(Icons.access_time_rounded, size: 10, color: FurPalsColors.textSoft),
                      const SizedBox(width: 3),
                      Text(notif.time,
                          style: GoogleFonts.nunito(
                            fontSize: 10, color: FurPalsColors.textSoft, fontWeight: FontWeight.w600,
                          )),
                      if (notif.isMuted) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: FurPalsColors.lavender,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text('Muted',
                              style: GoogleFonts.nunito(
                                fontSize: 9, fontWeight: FontWeight.w800, color: FurPalsColors.purple,
                              )),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // Unread dot & read dot
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                GestureDetector(
                  onTap: () => _showOptions(context, notif),
                  child: Container(
                    width: 30, height: 30,
                    decoration: BoxDecoration(
                      color: isUnread ? FurPalsColors.blush : FurPalsColors.creamwhite,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.more_horiz_rounded,
                        size: 18, color: FurPalsColors.textMid),
                  ),
                ),
                if (isUnread) ...[
                  const SizedBox(height: 6),
                  Container(
                    width: 8, height: 8,
                    decoration: const BoxDecoration(
                      color: FurPalsColors.pink,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildEmpty() { // empty display if no notif
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 90, height: 90,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(colors: [FurPalsColors.blush, FurPalsColors.peach]),
            ),
            child: const Center(child: Text('🔔', style: TextStyle(fontSize: 40))),
          ),
          const SizedBox(height: 18),
          Text('All caught up! 🐾',
              style: GoogleFonts.baloo2(
                fontSize: 22, fontWeight: FontWeight.w800, color: FurPalsColors.textDark,
              )),
          const SizedBox(height: 6),
          Text("No new notifications for now.",
              style: GoogleFonts.nunito(
                fontSize: 13, color: FurPalsColors.textMid, fontWeight: FontWeight.w600,
              )),
        ],
      ),
    );
  }
}
class _OptionTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor, iconBg;
  final String label, sublabel;
  final VoidCallback onTap;
  const _OptionTile({
    required this.icon, required this.iconColor, required this.iconBg,
    required this.label, required this.sublabel, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container( // frame of the 3dot menu choises
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [BoxShadow(color: FurPalsColors.shadow, blurRadius: 6, offset: Offset(0, 2))],
        ),
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: GoogleFonts.nunito(
                      fontSize: 14, fontWeight: FontWeight.w800, color: FurPalsColors.textDark,
                    )),
                Text(sublabel,
                    style: GoogleFonts.nunito(
                      fontSize: 11, color: FurPalsColors.textMid, fontWeight: FontWeight.w600,
                    )),
              ],
            ),
          ],
        ),
      ),
    );
  }
}