import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:furpals/NotificationScreen.dart';
import 'package:furpals/calendar.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:furpals/lost&found.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';
import 'package:video_compress/video_compress.dart';
import 'package:gal/gal.dart';
import 'package:furpals/settings.dart';
import 'package:furpals/models.dart';
import 'package:furpals/petmanagement.dart';

class FurPalsColors {
  static const blush = Color(0xFFF9C8D0);
  static const peach = Color(0xFFFFD9C0);
  static const mint = Color(0xFFC5EDD6);
  static const lavender = Color(0xFFDDD0F5);
  static const butter = Color(0xFFFFF3C4);
  static const cream = Color(0xFFFFF8F2);
  static const warmWhite = Color(0xFFFFFAF6);
  static const textDark = Color(0xFF4A3728);
  static const textMid = Color(0xFF7A6055);
  static const textSoft = Color(0x33000000);
  static const pink = Color(0xFFF4738A);
  static const pinkLight = Color(0xFFFF9AB0);
  static const green = Color(0xFF5DB87A);
  static const purple = Color(0xFF8B6FD4);
  static const shadow = Color(0x20B47864);
  static const creamwhite = Color(0xFFF9E9D5);
  static const blue = Color(0xFF448AFF);
  static const onlineGreen = Color(0xFF4CAF50);
  static const offlineGray = Color(0xFFBDBDBD);
  static const heartRed = Color(0xFFE53935);
  static const black100 = Color(0xFF000000);
}

const appBackgroundGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  stops: [0.0, 0.5, 1.0],
  colors: [Color(0xFFFCDDE8), Color(0xFFFFE8D2), Color(0xFFD4F0E4)],
);

Future<Map<String, dynamic>> _getCurrentUserProfile() async {
  try {
    final authUser = FirebaseAuth.instance.currentUser;
    final uid = authUser?.uid;
    if (uid == null) return {};
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    final data = doc.data() ?? {};
    if (data.isNotEmpty) return data;
    final fallbackUsername = authUser?.displayName?.trim().replaceAll(' ', '').toLowerCase() ??
        authUser?.email?.split('@').first ??
        'user_$uid';
    return {
      'userId': uid,
      'username': fallbackUsername,
      'fullName': authUser?.displayName ?? '',
    };
  } catch (_) {
    return {};
  }
}

String _formatTime(Timestamp? ts) {
  if (ts == null) return '';
  final dt = ts.toDate().toLocal();
  final h = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
  final m = dt.minute.toString().padLeft(2, '0');
  final ap = dt.hour >= 12 ? 'PM' : 'AM';
  return '$h:$m $ap';
}

String _formatDate(Timestamp? ts) {
  if (ts == null) return '';
  final dt = ts.toDate().toLocal();
  const months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];
  return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
}

String _formatCount(int n) {
  if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
  if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
  return n.toString();
}

Future<void> _clearRememberMe() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove('remember_me');
}

Future<void> _saveMediaToGallery(String mediaURL, String mediaType) async {
  try {
    final response = await HttpClient().getUrl(Uri.parse(mediaURL));
    final request = await response.close();
    final bytes = await consolidateHttpClientResponseBytes(request);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final ext = mediaType.contains('video') ? '.mp4' : '.png';
    final tempPath = '${Directory.systemTemp.path}/furpals_$timestamp$ext';
    final tempFile = File(tempPath);
    await tempFile.writeAsBytes(bytes);
    if (mediaType.contains('video')) {
      await Gal.putVideo(tempFile.path);
    } else {
      await Gal.putImage(tempFile.path);
    }
    await tempFile.delete();
  } catch (e) {
    print('Error saving media: $e');
  }
}

Future<void> _createNotification(String toUserId, String fromUserId, String type, String postId, {String? commentText}) async {
  if (toUserId.isEmpty || fromUserId.isEmpty || toUserId == fromUserId) return;
  final profile = await _getCurrentUserProfile();
  final fromUsername = profile['username'] ?? FirebaseAuth.instance.currentUser?.displayName ?? '';
  final fromFullName = profile['fullName'] ?? FirebaseAuth.instance.currentUser?.displayName ?? '';
  await FirebaseFirestore.instance.collection('notifications').add({
    'toUserId': toUserId,
    'fromUserId': fromUserId,
    'fromUsername': fromUsername,
    'fromFullName': fromFullName,
    'type': type,
    'postId': postId,
    'commentText': commentText ?? '',
    'isRead': false,
    'createdAt': FieldValue.serverTimestamp(),
  });
}

class Homescreen extends StatelessWidget {
  const Homescreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const MainShell();
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedNav = 1;

  void _onNavTap(int i) {
    if (i == 2) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => const PostModal(),
      );
      return;
    }
    setState(() => _selectedNav = i);
  }

  Widget _currentBody() {
    switch (_selectedNav) {
      case 0:
        return const LostFoundScreen();
      case 3:
        return const PetsBody();
      case 4:
        return const CalendarScreen();
      default:
        return HomeBody(onNavTap: _onNavTap);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const FurPalsDrawer(),
      bottomNavigationBar: _FlatBottomNav(
        selectedIndex: _selectedNav,
        onTap: _onNavTap,
      ),
      body: _currentBody(),
    );
  }
}

class _FlatBottomNav extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;

  const _FlatBottomNav({required this.selectedIndex, required this.onTap});

  static const _icons = [
    Icons.pets_rounded,
    Icons.home_rounded,
    Icons.add_rounded,
    Icons.cruelty_free_rounded,
    Icons.person_rounded,
  ];
  static const _labels = ['Lost & Found', 'Home', 'Post', 'Pets', 'Profile'];

  @override
  Widget build(BuildContext context) {
    final double systemBottom = MediaQuery.of(context).padding.bottom;
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(color: FurPalsColors.shadow, blurRadius: 24, offset: Offset(0, -6)),
        ],
      ),
      padding: EdgeInsets.fromLTRB(0, 10, 0, systemBottom + 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: List.generate(5, (i) {
          final isPost = i == 2;
          final isActive = !isPost && i == selectedIndex;
          return Expanded(
            child: GestureDetector(
              onTap: () => onTap(i),
              behavior: HitTestBehavior.opaque,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: 40,
                    child: Center(
                      child: isPost
                          ? Container(
                              width: 44, height: 44,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [FurPalsColors.pink, FurPalsColors.pinkLight],
                                ),
                                boxShadow: const [
                                  BoxShadow(color: Color(0x55F4738A), blurRadius: 14, offset: Offset(0, 4)),
                                ],
                              ),
                              child: const Icon(Icons.add_rounded, color: Colors.white, size: 26),
                            )
                          : AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: isActive ? FurPalsColors.blush : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                _icons[i],
                                size: 22,
                                color: isActive ? FurPalsColors.pink : FurPalsColors.pink.withOpacity(0.4),
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _labels[i],
                    style: GoogleFonts.nunito(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: isPost
                          ? FurPalsColors.pink
                          : isActive
                              ? FurPalsColors.pink
                              : FurPalsColors.textDark.withOpacity(0.4),
                      letterSpacing: 0.2,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

class FurPalsDrawer extends StatelessWidget {
  const FurPalsDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: MediaQuery.of(context).size.width * 0.72,
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: [0.0, 0.50, 0.84, 1.0],
            colors: [Color(0xFFFDEBEC), Color(0xFFFDEBEC), Color(0xFFFFFFFF), Color(0xFFFFFFFF)],
          ),
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(32),
            bottomRight: Radius.circular(32),
          ),
          boxShadow: [
            BoxShadow(color: Color(0x25B47864), blurRadius: 32, offset: Offset(8, 0)),
          ],
        ),
        child: SafeArea(
          child: FutureBuilder<Map<String, dynamic>>(
            future: _getCurrentUserProfile(),
            builder: (context, snapshot) {
              final profile = snapshot.data ?? {};
              final fullName = profile['fullName'] ?? 'FurPals User';
              final username = profile['username'] ?? '';
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 30),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Container(
                          width: 60, height: 60,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(colors: [FurPalsColors.blush, FurPalsColors.peach]),
                          ),
                          child: const Center(child: Text('🐾', style: TextStyle(fontSize: 30))),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                fullName,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                                style: GoogleFonts.baloo2(
                                  fontSize: 25, fontWeight: FontWeight.w800,
                                  color: const Color(0xFF4A3728), height: 1.1,
                                ),
                              ),
                              Text(
                                '@$username',
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                                style: GoogleFonts.nunito(
                                  fontSize: 15, fontWeight: FontWeight.w600,
                                  color: const Color(0x40000000),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  _pill(context, Icons.settings_rounded, 'Settings', () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
                  }),
                  const SizedBox(height: 12),
                  _pill(context, Icons.bookmark_rounded, 'Saved Posts', () => Navigator.pop(context)),
                  const SizedBox(height: 12),
                  _pill(context, Icons.info_outline_rounded, 'About', () => Navigator.pop(context)),
                  const SizedBox(height: 12),
                  _pill(context, Icons.help_outline_rounded, 'Help & Support', () => Navigator.pop(context)),
                  const Spacer(),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                    child: GestureDetector(
                      onTap: () async {
                        Navigator.pop(context);
                        final uid = FirebaseAuth.instance.currentUser?.uid;
                        if (uid != null) {
                          await FirebaseFirestore.instance
                              .collection('users')
                              .doc(uid)
                              .update({'isOnline': false});
                        }
                        await FirebaseAuth.instance.signOut();
                        await _clearRememberMe();
                        if (context.mounted) {
                          Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
                        }
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFDE0E6),
                          borderRadius: BorderRadius.circular(50),
                          border: Border.all(color: FurPalsColors.pinkLight.withOpacity(0.5), width: 1.5),
                          boxShadow: const [
                            BoxShadow(color: Color(0x20F4738A), blurRadius: 10, offset: Offset(0, 4)),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.logout_rounded, color: FurPalsColors.pink, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              'LOG OUT',
                              style: GoogleFonts.nunito(
                                fontSize: 13, fontWeight: FontWeight.w900,
                                color: FurPalsColors.pink, letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _pill(BuildContext context, IconData icon, String label, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: double.infinity, height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: const Color(0xFFFBEDE4),
            borderRadius: BorderRadius.circular(50),
            boxShadow: const [
              BoxShadow(color: Colors.grey, blurRadius: 3, offset: Offset(0, 3)),
            ],
          ),
          child: Row(
            children: [
              Icon(icon, size: 30, color: Colors.black),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.baloo2(
                    fontSize: 15, fontWeight: FontWeight.w700, color: const Color(0xFF4A3728),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void _showPostOptionsMenu(
  BuildContext context,
  String username,
  String postId,
  String currentUid,
  String postOwnerId,
  String mediaURL,
  String mediaType,
) {
  final isOwner = currentUid == postOwnerId;
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (_) => Container(
      decoration: const BoxDecoration(
        color: FurPalsColors.warmWhite,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(color: FurPalsColors.blush, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 20),
          _PostOptionTile(
            icon: Icons.bookmark_add_rounded,
            iconColor: FurPalsColors.purple,
            iconBg: FurPalsColors.lavender,
            label: 'Save Post',
            onTap: () async {
              Navigator.pop(context);
              if (mediaURL.isNotEmpty) {
                await _saveMediaToGallery(mediaURL, mediaType);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Media saved to gallery!',
                        style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
                    backgroundColor: FurPalsColors.green,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('No media to save.',
                        style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
                    backgroundColor: FurPalsColors.heartRed,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                );
              }
            },
          ),
          const SizedBox(height: 12),
          _PostOptionTile(
            icon: Icons.flag_rounded,
            iconColor: FurPalsColors.heartRed,
            iconBg: const Color(0xFFFFE4E4),
            label: 'Report Post',
            onTap: () {
              Navigator.pop(context);
              _showReportDialog(context, username);
            },
          ),
          if (isOwner) ...[
            const SizedBox(height: 12),
            _PostOptionTile(
              icon: Icons.delete_rounded,
              iconColor: FurPalsColors.heartRed,
              iconBg: const Color(0xFFFFE4E4),
              label: 'Delete Post',
              onTap: () {
                Navigator.pop(context);
                _showDeleteConfirmation(context, postId);
              },
            ),
          ],
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
}

class _PostOptionTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor, iconBg;
  final String label;
  final VoidCallback onTap;

  const _PostOptionTile({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(color: FurPalsColors.shadow, blurRadius: 6, offset: Offset(0, 2)),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Text(label,
                style: GoogleFonts.nunito(
                    fontSize: 15, fontWeight: FontWeight.w700, color: FurPalsColors.textDark)),
          ],
        ),
      ),
    );
  }
}

void _showReportDialog(BuildContext context, String username) {
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      backgroundColor: FurPalsColors.warmWhite,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text('Report Post',
          style: GoogleFonts.baloo2(
              fontSize: 18, fontWeight: FontWeight.w800, color: FurPalsColors.textDark)),
      content: Text(
          "Are you sure you want to report $username's post? We'll review it shortly.",
          style: GoogleFonts.nunito(fontSize: 13, color: FurPalsColors.textMid)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel',
              style: GoogleFonts.nunito(fontWeight: FontWeight.w700, color: FurPalsColors.textMid)),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Report submitted. Thank you!',
                    style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
                backgroundColor: FurPalsColors.heartRed,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            );
          },
          child: Text('Report',
              style: GoogleFonts.nunito(fontWeight: FontWeight.w800, color: FurPalsColors.heartRed)),
        ),
      ],
    ),
  );
}

void _showDeleteConfirmation(BuildContext context, String postId) {
  showDialog(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: FurPalsColors.warmWhite,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text('Delete Post?',
          style: GoogleFonts.baloo2(
              fontSize: 18, fontWeight: FontWeight.w800, color: FurPalsColors.textDark)),
      content: Text("This action can't be undone.",
          style: GoogleFonts.nunito(fontSize: 13, color: FurPalsColors.textMid)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: Text('Cancel',
              style: GoogleFonts.nunito(fontWeight: FontWeight.w700, color: FurPalsColors.textMid)),
        ),
        TextButton(
          onPressed: () async {
            Navigator.pop(dialogContext);
            try {
              await FirebaseFirestore.instance.collection('posts').doc(postId).delete();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Post deleted. 🐾',
                      style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
                  backgroundColor: FurPalsColors.heartRed,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              );
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Failed to delete post.',
                      style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
                  backgroundColor: FurPalsColors.heartRed,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              );
            }
          },
          child: Text('Delete',
              style: GoogleFonts.nunito(fontWeight: FontWeight.w800, color: FurPalsColors.heartRed)),
        ),
      ],
    ),
  );
}

void _showWhoLikedModal(BuildContext context, String postId, int likeCount) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => DraggableScrollableSheet(
      initialChildSize: 0.55,
      maxChildSize: 0.85,
      minChildSize: 0.35,
      builder: (_, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(color: FurPalsColors.blush, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  const Icon(Icons.favorite_rounded, color: FurPalsColors.heartRed, size: 20),
                  const SizedBox(width: 8),
                  Text('${_formatCount(likeCount)} Likes',
                      style: GoogleFonts.baloo2(
                          fontSize: 18, fontWeight: FontWeight.w800, color: FurPalsColors.textDark)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Divider(height: 1, color: Color(0xFFF0E4DC)),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('posts')
                    .doc(postId)
                    .collection('likes')
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator(color: FurPalsColors.pink));
                  }
                  final likers = snapshot.data!.docs;
                  if (likers.isEmpty) {
                    return Center(
                      child: Text('No likes yet 🐾',
                          style: GoogleFonts.nunito(color: FurPalsColors.textMid, fontWeight: FontWeight.w600)),
                    );
                  }
                  return ListView.separated(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    itemCount: likers.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 4),
                    itemBuilder: (_, i) {
                      final data = likers[i].data() as Map<String, dynamic>;
                      final displayName = data['fullName'] ?? '';
                      final uname = data['username'] ?? '';
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Container(
                          width: 46, height: 46,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(colors: [FurPalsColors.blush, FurPalsColors.peach]),
                          ),
                          child: const Center(child: Text('🐾', style: TextStyle(fontSize: 22))),
                        ),
                        title: Text(displayName,
                            style: GoogleFonts.baloo2(
                                fontSize: 14, fontWeight: FontWeight.w800, color: FurPalsColors.textDark)),
                        subtitle: Text('@$uname',
                            style: GoogleFonts.nunito(
                                fontSize: 12, color: FurPalsColors.textMid, fontWeight: FontWeight.w600)),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: FurPalsColors.blush,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text('Follow',
                              style: GoogleFonts.nunito(
                                  fontSize: 12, fontWeight: FontWeight.w800, color: FurPalsColors.pink)),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

void _showCommentsModal(BuildContext context, String postId, int commentCount) async {
  final postDoc = await FirebaseFirestore.instance.collection('posts').doc(postId).get();
  final postOwnerId = postDoc.data()?['userId'] ?? '';
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _CommentsModal(postId: postId, commentCount: commentCount, postOwnerId: postOwnerId),
  );
}

class _CommentsModal extends StatefulWidget {
  final String postId;
  final int commentCount;
  final String postOwnerId;

  const _CommentsModal({required this.postId, required this.commentCount, required this.postOwnerId});

  @override
  State<_CommentsModal> createState() => _CommentsModalState();
}

class _CommentsModalState extends State<_CommentsModal> {
  final TextEditingController _commentCtrl = TextEditingController();
  bool _sending = false;
  late int _commentCount;

  String? _replyingToUsername;
  String? _replyingToCommentId;
  String? _editingCommentId;

  @override
  void initState() {
    super.initState();
    _commentCount = widget.commentCount;
  }

  @override
  void didUpdateWidget(covariant _CommentsModal oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.commentCount != oldWidget.commentCount) {
      setState(() => _commentCount = widget.commentCount);
    }
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _deleteComment(String commentId) async {
    try {
      await FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.postId)
          .collection('comments')
          .doc(commentId)
          .delete();
      await FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.postId)
          .update({'commentCount': FieldValue.increment(-1)});
      if (mounted) {
        setState(() => _commentCount = (_commentCount - 1).clamp(0, 99999999));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Comment deleted.',
                style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
            backgroundColor: FurPalsColors.heartRed,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unable to delete comment. Please try again.',
                style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
            backgroundColor: FurPalsColors.heartRed,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  void _confirmDelete(String commentId) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: FurPalsColors.warmWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Delete comment?',
            style: GoogleFonts.baloo2(
                fontSize: 18, fontWeight: FontWeight.w800, color: FurPalsColors.textDark)),
        content: Text('This will remove your comment permanently.',
            style: GoogleFonts.nunito(fontSize: 13, color: FurPalsColors.textMid)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('Cancel',
                style: GoogleFonts.nunito(fontWeight: FontWeight.w700, color: FurPalsColors.textMid)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await _deleteComment(commentId);
            },
            child: Text('Delete',
                style: GoogleFonts.nunito(fontWeight: FontWeight.w700, color: FurPalsColors.heartRed)),
          ),
        ],
      ),
    );
  }

  void _startEdit(String commentId, String currentText) {
    setState(() {
      _editingCommentId = commentId;
      _replyingToUsername = null;
      _replyingToCommentId = null;
      _commentCtrl.text = currentText;
    });
  }

  Future<void> _saveEdit() async {
    final text = _commentCtrl.text.trim();
    final commentId = _editingCommentId;
    if (text.isEmpty || commentId == null) return;
    setState(() => _sending = true);
    try {
      await FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.postId)
          .collection('comments')
          .doc(commentId)
          .update({'text': text, 'editedAt': FieldValue.serverTimestamp()});
      if (mounted) {
        setState(() {
          _editingCommentId = null;
          _commentCtrl.clear();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Comment updated! 🐾',
                style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
            backgroundColor: FurPalsColors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      print('Edit comment error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update: $e',
                style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
            backgroundColor: FurPalsColors.heartRed,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
    if (mounted) setState(() => _sending = false);
  }

  void _startReply(String commentId, String username) {
    setState(() {
      _replyingToCommentId = commentId;
      _replyingToUsername = username;
      _editingCommentId = null;
      _commentCtrl.clear();
    });
  }

  Future<void> _toggleCommentLike(String commentId, bool currentlyLiked, int currentCount) async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (uid.isEmpty) return;
    final likeRef = FirebaseFirestore.instance
        .collection('posts')
        .doc(widget.postId)
        .collection('comments')
        .doc(commentId)
        .collection('likes')
        .doc(uid);
    final commentRef = FirebaseFirestore.instance
        .collection('posts')
        .doc(widget.postId)
        .collection('comments')
        .doc(commentId);
    if (currentlyLiked) {
      await likeRef.delete();
      await commentRef.update({'likeCount': FieldValue.increment(-1)});
    } else {
      await likeRef.set({'uid': uid, 'createdAt': FieldValue.serverTimestamp()});
      await commentRef.update({'likeCount': FieldValue.increment(1)});
    }
  }

  void _reportComment(String commentId, String username) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: FurPalsColors.warmWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Report Comment',
            style: GoogleFonts.baloo2(
                fontSize: 18, fontWeight: FontWeight.w800, color: FurPalsColors.textDark)),
        content: Text(
            "Are you sure you want to report @$username's comment? We'll review it shortly.",
            style: GoogleFonts.nunito(fontSize: 13, color: FurPalsColors.textMid)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel',
                style: GoogleFonts.nunito(fontWeight: FontWeight.w700, color: FurPalsColors.textMid)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Report submitted. Thank you!',
                      style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
                  backgroundColor: FurPalsColors.heartRed,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              );
            },
            child: Text('Report',
                style: GoogleFonts.nunito(fontWeight: FontWeight.w800, color: FurPalsColors.heartRed)),
          ),
        ],
      ),
    );
  }

  Future<void> _sendComment() async {
    final text = _commentCtrl.text.trim();
    if (text.isEmpty) return;

    if (_editingCommentId != null) {
      await _saveEdit();
      return;
    }

    setState(() => _sending = true);
    try {
      final profile = await _getCurrentUserProfile();
      final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
      final uname = profile['username'] ?? '';
      final fullName = profile['fullName'] ?? '';

      final ref = FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.postId)
          .collection('comments')
          .doc();

      await ref.set({
        'commentId': ref.id,
        'userId': uid,
        'username': uname,
        'fullName': fullName,
        'text': text,
        'likeCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
        'replyToCommentId': _replyingToCommentId,
        'replyToUsername': _replyingToUsername,
      });

      await FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.postId)
          .update({'commentCount': FieldValue.increment(1)});

      await _createNotification(widget.postOwnerId, uid, 'comment', widget.postId, commentText: text);

      if (mounted) {
        setState(() {
          _commentCount++;
          _commentCtrl.clear();
          _replyingToUsername = null;
          _replyingToCommentId = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Comment posted! 🐾',
                style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
            backgroundColor: FurPalsColors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (_) {}
    if (mounted) setState(() => _sending = false);
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      maxChildSize: 0.92,
      minChildSize: 0.4,
      builder: (_, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(color: FurPalsColors.blush, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  const Icon(Icons.chat_bubble_rounded, color: FurPalsColors.pink, size: 20),
                  const SizedBox(width: 8),
                  Text('${_formatCount(_commentCount)} Comments',
                      style: GoogleFonts.baloo2(
                          fontSize: 18, fontWeight: FontWeight.w800, color: FurPalsColors.textDark)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Divider(height: 1, color: Color(0xFFF0E4DC)),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('posts')
                    .doc(widget.postId)
                    .collection('comments')
                    .orderBy('createdAt', descending: false)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator(color: FurPalsColors.pink));
                  }
                  final comments = snapshot.data!.docs;
                  if (comments.isEmpty) {
                    return Center(
                      child: Text('No comments yet. Be the first! 🐾',
                          style: GoogleFonts.nunito(
                              color: FurPalsColors.textMid, fontWeight: FontWeight.w600)),
                    );
                  }
                  return ListView.separated(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    itemCount: comments.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final c = comments[i].data() as Map<String, dynamic>;
                      final commentId = comments[i].id;
                      final commentUserId = c['userId'] ?? '';
                      final isMine = commentUserId == FirebaseAuth.instance.currentUser?.uid;
                      final uname = c['username'] ?? '';
                      final text = c['text'] ?? '';
                      final ts = c['createdAt'] as Timestamp?;
                      final editedAt = c['editedAt'] as Timestamp?;
                      final timeAgo = ts != null ? _timeAgo(ts.toDate()) : '';
                      final likeCount = (c['likeCount'] as num?)?.toInt() ?? 0;
                      final replyToUsername = c['replyToUsername'] as String?;

                      return _CommentTile(
                        commentId: commentId,
                        uname: uname,
                        text: text,
                        timeAgo: timeAgo,
                        isEdited: editedAt != null,
                        likeCount: likeCount,
                        replyToUsername: replyToUsername,
                        isMine: isMine,
                        postId: widget.postId,
                        onEdit: () => _startEdit(commentId, text),
                        onDelete: () => _confirmDelete(commentId),
                        onReply: () => _startReply(commentId, uname),
                        onReport: () => _reportComment(commentId, uname),
                        onLikeToggle: (liked, count) => _toggleCommentLike(commentId, liked, count),
                      );
                    },
                  );
                },
              ),
            ),
            const Divider(height: 1, color: Color(0xFFF0E4DC)),
            if (_replyingToUsername != null || _editingCommentId != null)
              Container(
                color: FurPalsColors.warmWhite,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Row(
                  children: [
                    Icon(
                      _editingCommentId != null ? Icons.edit_rounded : Icons.reply_rounded,
                      size: 14, color: FurPalsColors.pink,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _editingCommentId != null
                            ? 'Editing your comment'
                            : 'Replying to @$_replyingToUsername',
                        style: GoogleFonts.nunito(
                            fontSize: 12, fontWeight: FontWeight.w700, color: FurPalsColors.textMid),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => setState(() {
                        _replyingToUsername = null;
                        _replyingToCommentId = null;
                        _editingCommentId = null;
                        _commentCtrl.clear();
                      }),
                      child: const Icon(Icons.close_rounded, size: 16, color: FurPalsColors.textMid),
                    ),
                  ],
                ),
              ),
            Padding(
              padding: EdgeInsets.fromLTRB(16, 10, 16, MediaQuery.of(context).viewInsets.bottom + 16),
              child: Row(
                children: [
                  Container(
                    width: 36, height: 36,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(colors: [FurPalsColors.blush, FurPalsColors.peach]),
                    ),
                    child: const Center(child: Text('🐾', style: TextStyle(fontSize: 18))),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      decoration: BoxDecoration(
                        color: FurPalsColors.warmWhite,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFF0E4DC), width: 1.5),
                      ),
                      child: TextField(
                        controller: _commentCtrl,
                        decoration: InputDecoration(
                          hintText: _editingCommentId != null
                              ? 'Edit your comment...'
                              : _replyingToUsername != null
                                  ? 'Reply to @$_replyingToUsername...'
                                  : 'Add a comment...',
                          hintStyle: GoogleFonts.nunito(color: FurPalsColors.textSoft, fontSize: 13),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                        style: GoogleFonts.nunito(
                            fontSize: 13, color: FurPalsColors.black100, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _sending ? null : _sendComment,
                    child: Container(
                      width: 38, height: 38,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                            colors: [FurPalsColors.pink, FurPalsColors.pinkLight]),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: _sending
                          ? const Padding(
                              padding: EdgeInsets.all(10),
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : Icon(
                              _editingCommentId != null ? Icons.check_rounded : Icons.send_rounded,
                              color: Colors.white, size: 18,
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CommentTile extends StatefulWidget {
  final String commentId;
  final String uname;
  final String text;
  final String timeAgo;
  final bool isEdited;
  final int likeCount;
  final String? replyToUsername;
  final bool isMine;
  final String postId;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onReply;
  final VoidCallback onReport;
  final void Function(bool liked, int count) onLikeToggle;

  const _CommentTile({
    required this.commentId,
    required this.uname,
    required this.text,
    required this.timeAgo,
    required this.isEdited,
    required this.likeCount,
    required this.replyToUsername,
    required this.isMine,
    required this.postId,
    required this.onEdit,
    required this.onDelete,
    required this.onReply,
    required this.onReport,
    required this.onLikeToggle,
  });

  @override
  State<_CommentTile> createState() => _CommentTileState();
}

class _CommentTileState extends State<_CommentTile> {
  bool _liked = false;
  late int _likeCount;

  @override
  void initState() {
    super.initState();
    _likeCount = widget.likeCount;
    _checkLiked();
  }

  @override
  void didUpdateWidget(covariant _CommentTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.likeCount != oldWidget.likeCount) {
      setState(() => _likeCount = widget.likeCount);
    }
  }

  Future<void> _checkLiked() async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (uid.isEmpty) return;
    final doc = await FirebaseFirestore.instance
        .collection('posts')
        .doc(widget.postId)
        .collection('comments')
        .doc(widget.commentId)
        .collection('likes')
        .doc(uid)
        .get();
    if (mounted) setState(() => _liked = doc.exists);
  }

  void _handleLike() {
    setState(() {
      if (_liked) {
        _liked = false;
        _likeCount = (_likeCount - 1).clamp(0, 99999999);
      } else {
        _liked = true;
        _likeCount++;
      }
    });
    widget.onLikeToggle(_liked, _likeCount);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38, height: 38,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(colors: [FurPalsColors.mint, FurPalsColors.lavender]),
          ),
          child: const Center(child: Text('🐾', style: TextStyle(fontSize: 18))),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('@${widget.uname}',
                      style: GoogleFonts.nunito(
                          fontSize: 12, fontWeight: FontWeight.w800, color: FurPalsColors.textDark)),
                  const SizedBox(width: 6),
                  Text(widget.timeAgo,
                      style: GoogleFonts.nunito(fontSize: 10, color: FurPalsColors.textMid)),
                  if (widget.isEdited) ...[
                    const SizedBox(width: 4),
                    Text('· edited',
                        style: GoogleFonts.nunito(
                            fontSize: 10,
                            color: FurPalsColors.textMid,
                            fontStyle: FontStyle.italic)),
                  ],
                ],
              ),
              const SizedBox(height: 2),
              if (widget.replyToUsername != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text('@${widget.replyToUsername}',
                      style: GoogleFonts.nunito(
                          fontSize: 12, fontWeight: FontWeight.w700, color: FurPalsColors.pink)),
                ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: FurPalsColors.warmWhite,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(widget.text,
                    style: GoogleFonts.nunito(
                        fontSize: 13, color: FurPalsColors.textDark, fontWeight: FontWeight.w600)),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  if (!widget.isMine) ...[
                    GestureDetector(
                      onTap: _handleLike,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _liked ? Icons.favorite_rounded : Icons.favorite_outline,
                            size: 13, color: FurPalsColors.heartRed,
                          ),
                          if (_likeCount > 0) ...[
                            const SizedBox(width: 3),
                            Text(_likeCount.toString(),
                                style: GoogleFonts.nunito(
                                    fontSize: 11, fontWeight: FontWeight.w700, color: FurPalsColors.textMid)),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    GestureDetector(
                      onTap: widget.onReply,
                      child: Text('Reply',
                          style: GoogleFonts.nunito(
                              fontSize: 11, fontWeight: FontWeight.w700, color: FurPalsColors.textMid)),
                    ),
                    const SizedBox(width: 14),
                    GestureDetector(
                      onTap: widget.onReport,
                      child: Text('Report',
                          style: GoogleFonts.nunito(
                              fontSize: 11, fontWeight: FontWeight.w700, color: FurPalsColors.heartRed)),
                    ),
                  ],
                  if (widget.isMine) ...[
                    if (_likeCount > 0) ...[
                      const Icon(Icons.favorite_rounded, size: 13, color: FurPalsColors.heartRed),
                      const SizedBox(width: 3),
                      Text(_likeCount.toString(),
                          style: GoogleFonts.nunito(
                              fontSize: 11, fontWeight: FontWeight.w700, color: FurPalsColors.textMid)),
                      const SizedBox(width: 14),
                    ],
                    GestureDetector(
                      onTap: widget.onEdit,
                      child: Text('Edit',
                          style: GoogleFonts.nunito(
                              fontSize: 11, fontWeight: FontWeight.w700, color: FurPalsColors.blue)),
                    ),
                    const SizedBox(width: 14),
                    GestureDetector(
                      onTap: widget.onDelete,
                      child: Text('Delete',
                          style: GoogleFonts.nunito(
                              fontSize: 11, fontWeight: FontWeight.w700, color: FurPalsColors.heartRed)),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

String _timeAgo(DateTime dt) {
  final diff = DateTime.now().difference(dt);
  if (diff.inMinutes < 1) return 'now';
  if (diff.inHours < 1) return '${diff.inMinutes}m';
  if (diff.inDays < 1) return '${diff.inHours}h';
  return '${diff.inDays}d';
}

void _showShareModal(BuildContext context, String username) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _ShareFullSheet(username: username),
  );
}

class _ShareFullSheet extends StatefulWidget {
  final String username;
  const _ShareFullSheet({required this.username});

  @override
  State<_ShareFullSheet> createState() => _ShareFullSheetState();
}

class _ShareFullSheetState extends State<_ShareFullSheet> {
  String _audience = 'Feed';
  String _privacy = 'Only me';

  static const _audienceOptions = ['Feed', 'Group', 'Lost and Found'];
  static const _privacyOptions = ['Only me', 'Friends', 'Everyone'];

  final List<Map<String, dynamic>> _platforms = [
    {'label': 'WhatsApp', 'color': const Color(0xFF93E67F), 'icon': Icons.chat_rounded},
    {'label': 'Messenger', 'color': const Color(0xFF1163EC), 'icon': Icons.send_rounded},
    {'label': 'Facebook', 'color': const Color(0xFF1877F2), 'icon': Icons.facebook_sharp},
    {'label': 'Threads', 'color': const Color(0xFF000000), 'icon': Icons.alternate_email_rounded},
    {'label': 'X', 'color': const Color(0xFF000000), 'icon': Icons.close_rounded},
    {'label': 'Instagram', 'color': const Color(0xFFF4738A), 'icon': Icons.camera_alt_rounded},
    {'label': 'IG Story', 'color': const Color(0xFFF4738A), 'icon': Icons.add_circle_outline},
    {'label': 'Copy Link', 'color': const Color(0xFFBBB2CF), 'icon': Icons.link_rounded},
    {'label': 'SMS', 'color': const Color(0xFFD4F0E4), 'icon': Icons.sms_rounded},
    {'label': 'Email', 'color': const Color(0xFFFF383C), 'icon': Icons.email_rounded},
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.62,
      decoration: const BoxDecoration(
        color: FurPalsColors.warmWhite,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(color: FurPalsColors.blush, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(colors: [FurPalsColors.blush, FurPalsColors.peach]),
                  ),
                  child: const Center(child: Text('🐾', style: TextStyle(fontSize: 22))),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.username,
                        style: GoogleFonts.baloo2(
                            fontSize: 15, fontWeight: FontWeight.w800, color: FurPalsColors.textDark)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _ShareDropdownPill(
                          value: _audience,
                          options: _audienceOptions,
                          icon: Icons.public_rounded,
                          onChanged: (v) => setState(() => _audience = v),
                        ),
                        const SizedBox(width: 6),
                        _ShareDropdownPill(
                          value: _privacy,
                          options: _privacyOptions,
                          icon: Icons.lock_outline_rounded,
                          onChanged: (v) => setState(() => _privacy = v),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 1),
            child: TextField(
              maxLines: 2,
              style: GoogleFonts.nunito(
                  fontSize: 14, color: FurPalsColors.textDark, fontWeight: FontWeight.w500),
              decoration: InputDecoration(
                hintText: 'Say something...',
                hintStyle: GoogleFonts.nunito(
                    fontSize: 14, color: FurPalsColors.textSoft, fontWeight: FontWeight.w500),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 4),
            child: Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Post shared! 🐾',
                          style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
                      backgroundColor: FurPalsColors.blue,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
                  decoration: BoxDecoration(
                    color: FurPalsColors.blue, borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('Share now',
                      style: GoogleFonts.nunito(
                          fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white)),
                ),
              ),
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF0E4DC)),
          const SizedBox(height: 15),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                _buildPlatformRow(context, _platforms.sublist(0, 5)),
                const SizedBox(height: 16),
                _buildPlatformRow(context, _platforms.sublist(5)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlatformRow(BuildContext context, List<Map<String, dynamic>> row) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: row.map((p) {
        final label = p['label'] as String;
        final color = p['color'] as Color;
        final icon = p['icon'] as IconData;
        final iconColor = (label == 'SMS') ? FurPalsColors.green : Colors.white;
        return GestureDetector(
          onTap: () {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Sharing via $label...',
                    style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
                backgroundColor: color,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            );
          },
          child: SizedBox(
            width: 58,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 50, height: 50,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                  child: Icon(icon, color: iconColor, size: 30),
                ),
                const SizedBox(height: 10),
                Text(label,
                    style: GoogleFonts.nunito(
                        fontSize: 10, fontWeight: FontWeight.w700, color: FurPalsColors.textDark),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _ShareDropdownPill extends StatelessWidget {
  final String value;
  final List<String> options;
  final IconData icon;
  final ValueChanged<String> onChanged;

  const _ShareDropdownPill({
    required this.value,
    required this.options,
    required this.icon,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final RenderBox box = context.findRenderObject() as RenderBox;
        final Offset offset = box.localToGlobal(Offset.zero);
        final picked = await showMenu<String>(
          context: context,
          color: FurPalsColors.warmWhite,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          position: RelativeRect.fromLTRB(
              offset.dx, offset.dy + box.size.height + 4, offset.dx + 120, 0),
          items: options
              .map((o) => PopupMenuItem(
                    value: o,
                    child: Text(o,
                        style: GoogleFonts.nunito(
                            fontSize: 13, fontWeight: FontWeight.w700, color: FurPalsColors.textDark)),
                  ))
              .toList(),
        );
        if (picked != null) onChanged(picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: FurPalsColors.creamwhite,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFFF0E4DC), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: FurPalsColors.textMid),
            const SizedBox(width: 4),
            Text(value,
                style: GoogleFonts.nunito(
                    fontSize: 12, fontWeight: FontWeight.w700, color: FurPalsColors.textDark)),
            const SizedBox(width: 3),
            const Icon(Icons.keyboard_arrow_down_rounded, size: 14, color: FurPalsColors.textMid),
          ],
        ),
      ),
    );
  }
}

class HomeBody extends StatefulWidget {
  final ValueChanged<int> onNavTap;
  const HomeBody({super.key, required this.onNavTap});

  @override
  State<HomeBody> createState() => _HomeBodyState();
}

class _HomeBodyState extends State<HomeBody> {
  bool _hasNewNotif = true;

  final List<Map<String, dynamic>> _activeUsers = [
    {'emoji': '🐶', 'label': 'Buddy', 'online': true},
    {'emoji': '🐱', 'label': 'Luna', 'online': true},
    {'emoji': '🐰', 'label': 'Coco', 'online': false},
    {'emoji': '🐾', 'label': 'Mochi', 'online': true},
    {'emoji': '🦮', 'label': 'Daisy', 'online': false},
    {'emoji': '🐹', 'label': 'Peanut', 'online': true},
  ];

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: appBackgroundGradient),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildTopBar(context),
            Expanded(
              child: DecoratedBox(
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.45)),
                child: Column(
                  children: [
                    _buildActiveUsersRow(),
                    _buildSearchBar(),
                    Expanded(child: _buildFeed()),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final displayName = user?.displayName ?? 'FurPals User';

    return StreamBuilder<QuerySnapshot>(
      stream: user == null
          ? const Stream<QuerySnapshot>.empty()
          : FirebaseFirestore.instance
              .collection('notifications')
              .where('toUserId', isEqualTo: user.uid)
              .where('isRead', isEqualTo: false)
              .snapshots(),
      builder: (context, snapshot) {
        final hasUnread = snapshot.hasData && snapshot.data!.docs.isNotEmpty;
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              Builder(
                builder: (ctx) => GestureDetector(
                  onTap: () => Scaffold.of(ctx).openDrawer(),
                  child: Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [
                        BoxShadow(color: FurPalsColors.shadow, blurRadius: 10, offset: Offset(0, 3)),
                      ],
                    ),
                    child: const Center(
                      child: Icon(Icons.menu_rounded, size: 20, color: FurPalsColors.textDark),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        displayName,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        style: GoogleFonts.baloo2(
                            fontSize: 25, fontWeight: FontWeight.w800, color: FurPalsColors.textDark),
                      ),
                    ),
                    const SizedBox(width: 1),
                    const Text('🐾', style: TextStyle(fontSize: 18)),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () async {
                  await Navigator.push(
                      context, MaterialPageRoute(builder: (_) => const NotificationScreen()));
                },
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: FurPalsColors.warmWhite,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: const [
                          BoxShadow(color: Color(0x40F4738A), blurRadius: 12, offset: Offset(0, 4)),
                        ],
                      ),
                      child: const Center(
                        child: Icon(Icons.favorite_rounded, color: FurPalsColors.heartRed, size: 20),
                      ),
                    ),
                    if (hasUnread)
                      Positioned(
                        top: -3, right: -3,
                        child: Container(
                          width: 12, height: 12,
                          decoration: BoxDecoration(
                            color: FurPalsColors.heartRed,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: const [
                              BoxShadow(color: Color(0x55E53935), blurRadius: 4, offset: Offset(0, 1)),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActiveUsersRow() {
    return SizedBox(
      height: 100,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        itemCount: _activeUsers.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) => _buildUserAvatar(_activeUsers[i]),
      ),
    );
  }

  Widget _buildUserAvatar(Map<String, dynamic> user) {
    final bool online = user['online'] as bool;
    final String emoji = user['emoji'] as String;
    final String label = user['label'] as String;
    return SizedBox(
      width: 64,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: online ? FurPalsColors.onlineGreen : FurPalsColors.offlineGray,
              boxShadow: [
                BoxShadow(
                  color: online
                      ? FurPalsColors.onlineGreen.withOpacity(0.28)
                      : FurPalsColors.offlineGray.withOpacity(0.18),
                  blurRadius: 8, offset: const Offset(0, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.all(3),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: online
                      ? [FurPalsColors.blush, FurPalsColors.peach]
                      : [FurPalsColors.cream, FurPalsColors.warmWhite],
                ),
              ),
              child: Center(child: Text(emoji, style: const TextStyle(fontSize: 24))),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.nunito(
              fontSize: 10, fontWeight: FontWeight.w700,
              color: online ? FurPalsColors.textMid : FurPalsColors.textSoft,
            ),
            overflow: TextOverflow.ellipsis, maxLines: 1, textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 10),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFF0E4DC), width: 1.5),
          boxShadow: const [
            BoxShadow(color: FurPalsColors.shadow, blurRadius: 4, offset: Offset(0, 3)),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        child: Row(
          children: [
            const Icon(Icons.search_sharp, color: FurPalsColors.textSoft, size: 30),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search Something...',
                  hintStyle: GoogleFonts.nunito(
                      color: FurPalsColors.textSoft, fontWeight: FontWeight.w500, fontSize: 13),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
                style: GoogleFonts.nunito(
                    fontSize: 13, fontWeight: FontWeight.w600, color: FurPalsColors.black100),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeed() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('posts')
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
                Text('No posts yet!',
                    style: GoogleFonts.baloo2(
                        fontSize: 22, fontWeight: FontWeight.w800, color: FurPalsColors.textDark)),
                const SizedBox(height: 6),
                Text('Be the first to share something',
                    style: GoogleFonts.nunito(
                        fontSize: 14, color: FurPalsColors.textMid, fontWeight: FontWeight.w600)),
              ],
            ),
          );
        }
        final posts = snapshot.data!.docs;
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
          itemCount: posts.length,
          separatorBuilder: (_, __) => const SizedBox(height: 14),
          itemBuilder: (_, i) {
            final data = posts[i].data() as Map<String, dynamic>;
            return _buildPostCard(data, posts[i].id);
          },
        );
      },
    );
  }

  Widget _buildPostCard(Map<String, dynamic> post, String postId) {
    final username = post['username'] as String? ?? '';
    final fullName = post['fullName'] as String? ?? username;
    final description = post['description'] as String? ?? '';
    final mediaURL = post['mediaURL'] as String? ?? '';
    final mediaType = post['mediaType'] as String? ?? 'none';
    final location = post['location'] as String? ?? '';
    final likeCount = (post['likeCount'] as num?)?.toInt() ?? 0;
    final commentCount = (post['commentCount'] as num?)?.toInt() ?? 0;
    final createdAt = post['createdAt'] as Timestamp?;
    final currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';

    final colorPairs = [
      [FurPalsColors.blush, FurPalsColors.peach],
      [FurPalsColors.mint, FurPalsColors.butter],
      [FurPalsColors.lavender, FurPalsColors.blush],
      [FurPalsColors.peach, FurPalsColors.mint],
    ];
    final pair = colorPairs[postId.hashCode.abs() % colorPairs.length];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: FurPalsColors.textSoft, blurRadius: 2, offset: Offset(0, 4)),
        ],
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: Row(
              children: [
                Container(
                  width: 46, height: 46,
                  decoration: const BoxDecoration(
                      shape: BoxShape.circle, color: FurPalsColors.onlineGreen),
                  padding: const EdgeInsets.all(2.5),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(colors: [pair[0], pair[1]]),
                    ),
                    child: const Center(child: Text('🐾', style: TextStyle(fontSize: 22))),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(fullName,
                          style: GoogleFonts.baloo2(
                              fontSize: 15, fontWeight: FontWeight.w800,
                              color: FurPalsColors.textDark, height: 1.1)),
                      const SizedBox(height: 2),
                      Text('@$username',
                          style: GoogleFonts.nunito(
                              fontSize: 11, fontWeight: FontWeight.w600, color: FurPalsColors.textMid)),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => _showPostOptionsMenu(
                      context, username, postId, currentUid, post['userId'] ?? '', mediaURL, mediaType),
                  child: const Icon(Icons.more_horiz_rounded, color: Colors.black, size: 22),
                ),
              ],
            ),
          ),
          if (mediaURL.isNotEmpty && mediaType == 'photo')
            Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxHeight: 400, minHeight: 200),
              child: Image.network(
                mediaURL,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _emojiPlaceholder(pair),
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    width: double.infinity, height: 220,
                    decoration: BoxDecoration(gradient: LinearGradient(colors: pair)),
                    child: const Center(child: CircularProgressIndicator(color: FurPalsColors.pink)),
                  );
                },
              ),
            )
          else if (mediaURL.isNotEmpty && mediaType == 'video')
            GestureDetector(
              onTap: () {},
              child: Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxHeight: 500),
                child: _NetworkVideoPlayer(url: mediaURL),
              ),
            )
          else
            _emojiPlaceholder(pair),
          if (location.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
              child: Row(
                children: [
                  const Icon(Icons.location_on_rounded, size: 13, color: FurPalsColors.pink),
                  const SizedBox(width: 4),
                  Text(location,
                      style: GoogleFonts.nunito(
                          fontSize: 11, fontWeight: FontWeight.w700, color: FurPalsColors.textMid)),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
            child: Row(
              children: [
                _LikeButton(
                  key: ValueKey(postId),
                  postId: postId,
                  likeCount: likeCount,
                  currentUid: currentUid,
                  postOwnerId: post['userId'] ?? '',
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _showCommentsModal(context, postId, commentCount),
                  child: _actionPill(
                      Icons.chat_bubble_outline, _formatCount(commentCount),
                      FurPalsColors.creamwhite, FurPalsColors.textDark),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _showShareModal(context, username),
                  child: _actionPill(
                      Icons.share_outlined, '', FurPalsColors.creamwhite, FurPalsColors.blue),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 4, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (description.isNotEmpty)
                  Text(description,
                      style: GoogleFonts.nunito(
                          fontSize: 13, fontWeight: FontWeight.w700, color: FurPalsColors.textDark)),
                const SizedBox(height: 5),
                Row(
                  children: [
                    const Icon(Icons.access_time_rounded, size: 11, color: FurPalsColors.textSoft),
                    const SizedBox(width: 3),
                    Text(_formatTime(createdAt),
                        style: GoogleFonts.nunito(
                            fontSize: 11, fontWeight: FontWeight.w600, color: FurPalsColors.textSoft)),
                    const SizedBox(width: 8),
                    const Icon(Icons.calendar_today_rounded, size: 11, color: FurPalsColors.textSoft),
                    const SizedBox(width: 3),
                    Text(_formatDate(createdAt),
                        style: GoogleFonts.nunito(
                            fontSize: 11, fontWeight: FontWeight.w600, color: FurPalsColors.textSoft)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _emojiPlaceholder(List<Color> pair) {
    return Container(
      width: double.infinity, height: 220,
      decoration: BoxDecoration(
        gradient: LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight, colors: pair),
      ),
      child: const Center(child: Text('🐾', style: TextStyle(fontSize: 90))),
    );
  }

  Widget _actionPill(IconData icon, String count, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(22)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: fg),
          if (count.isNotEmpty) ...[
            const SizedBox(width: 5),
            Text(count,
                style: GoogleFonts.nunito(
                    fontSize: 12, fontWeight: FontWeight.w800, color: FurPalsColors.textDark)),
          ],
        ],
      ),
    );
  }
}

class _LikeButton extends StatefulWidget {
  final String postId;
  final int likeCount;
  final String currentUid;
  final String postOwnerId;

  const _LikeButton({
    required this.postId,
    required this.likeCount,
    required this.currentUid,
    required this.postOwnerId,
    required ValueKey<String> key,
  });

  @override
  State<_LikeButton> createState() => _LikeButtonState();
}

class _LikeButtonState extends State<_LikeButton> {
  bool _liked = false;
  bool _loading = false;
  int _count = 0;

  @override
  void initState() {
    super.initState();
    _count = widget.likeCount;
    _checkIfLiked();
  }

  @override
  void didUpdateWidget(covariant _LikeButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.likeCount != oldWidget.likeCount) {
      setState(() => _count = widget.likeCount);
    }
    if (widget.postId != oldWidget.postId || widget.currentUid != oldWidget.currentUid) {
      _checkIfLiked();
    }
  }

  Future<void> _checkIfLiked() async {
    if (widget.currentUid.isEmpty) return;
    final doc = await FirebaseFirestore.instance
        .collection('posts')
        .doc(widget.postId)
        .collection('likes')
        .doc(widget.currentUid)
        .get();
    if (mounted) setState(() => _liked = doc.exists);
  }

  Future<void> _toggleLike() async {
    if (_loading || widget.currentUid.isEmpty) return;
    setState(() => _loading = true);

    final likeRef = FirebaseFirestore.instance
        .collection('posts')
        .doc(widget.postId)
        .collection('likes')
        .doc(widget.currentUid);
    final postRef = FirebaseFirestore.instance.collection('posts').doc(widget.postId);

    try {
      final didLike = await FirebaseFirestore.instance.runTransaction<bool>((tx) async {
        final likeSnapshot = await tx.get(likeRef);
        final postSnapshot = await tx.get(postRef);
        final postData = postSnapshot.data();
        final currentCount = (postData?['likeCount'] as num?)?.toInt() ?? 0;

        if (likeSnapshot.exists) {
          tx.delete(likeRef);
          tx.update(postRef, {'likeCount': FieldValue.increment(-1)});
          if (mounted) setState(() { _liked = false; _count = (currentCount - 1).clamp(0, 99999999); });
          return false;
        }

        final profile = await _getCurrentUserProfile();
        tx.set(likeRef, {
          'userId': widget.currentUid,
          'username': profile['username'] ?? '',
          'fullName': profile['fullName'] ?? '',
          'createdAt': FieldValue.serverTimestamp(),
        });
        tx.update(postRef, {'likeCount': FieldValue.increment(1)});
        if (mounted) setState(() { _liked = true; _count = currentCount + 1; });
        return true;
      });

      if (didLike) {
        await _createNotification(widget.postOwnerId, widget.currentUid, 'like', widget.postId);
      }
    } catch (_) {}

    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggleLike,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: _liked ? FurPalsColors.heartRed.withOpacity(0.12) : FurPalsColors.creamwhite,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _liked ? Icons.favorite_rounded : Icons.favorite_outline,
              size: 15, color: FurPalsColors.heartRed,
            ),
            const SizedBox(width: 5),
            Text(_formatCount(_count),
                style: GoogleFonts.nunito(
                    fontSize: 12, fontWeight: FontWeight.w800, color: FurPalsColors.textDark)),
          ],
        ),
      ),
    );
  }
}

class _NetworkVideoPlayer extends StatefulWidget {
  final String url;
  const _NetworkVideoPlayer({required this.url});

  @override
  State<_NetworkVideoPlayer> createState() => _NetworkVideoPlayerState();
}

class _NetworkVideoPlayerState extends State<_NetworkVideoPlayer> with WidgetsBindingObserver {
  VideoPlayerController? _controller;
  bool _initialized = false;
  bool _hasError = false;
  bool _isMuted = true;
  bool _showControls = false;
  Timer? _overlayTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = VideoPlayerController.network(widget.url)
      ..setLooping(true)
      ..setVolume(0)
      ..addListener(_handleVideoState)
      ..initialize().then((_) {
        if (mounted) setState(() { _initialized = true; _hasError = false; });
      }).catchError((e) {
        if (mounted) setState(() => _hasError = true);
      });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) _controller?.pause();
  }

  void _handleVideoState() {
    if (_controller?.value.hasError ?? false) {
      setState(() => _hasError = true);
    }
  }

  @override
  void dispose() {
    _overlayTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _controller?.removeListener(_handleVideoState);
    _controller?.pause();
    _controller?.dispose();
    super.dispose();
  }

  void _togglePlayback() {
    if (_controller == null || !_controller!.value.isInitialized) return;
    if (_controller!.value.isPlaying) {
      _controller?.pause();
    } else {
      _controller?.play();
    }
    _showControls = true;
    _overlayTimer?.cancel();
    _overlayTimer = Timer(const Duration(seconds: 1), () {
      if (mounted) setState(() => _showControls = false);
    });
  }

  void _seekForward() {
    if (_controller != null) {
      final duration = _controller!.value.duration;
      final newPosition = _controller!.value.position + const Duration(seconds: 10);
      _controller!.seekTo(newPosition > duration ? duration : newPosition);
    }
  }

  void _seekBackward() {
    if (_controller != null) {
      final newPosition = _controller!.value.position - const Duration(seconds: 10);
      _controller!.seekTo(newPosition < Duration.zero ? Duration.zero : newPosition);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return Container(
        width: double.infinity, height: 220,
        decoration: BoxDecoration(
            color: FurPalsColors.lavender, borderRadius: BorderRadius.circular(10)),
        child: Center(
          child: Text(
            'Video unavailable. Please try a smaller file or check connection.',
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
                color: FurPalsColors.textDark, fontSize: 13, fontWeight: FontWeight.w700),
          ),
        ),
      );
    }

    if (!_initialized || _controller == null) {
      return const Center(child: CircularProgressIndicator(color: FurPalsColors.pink));
    }

    final aspectRatio = _controller!.value.aspectRatio > 0 ? _controller!.value.aspectRatio : 16 / 9;

    return Stack(
      fit: StackFit.expand,
      children: [
        AspectRatio(
          aspectRatio: aspectRatio,
          child: Stack(
            alignment: Alignment.center,
            children: [
              VideoPlayer(_controller!),
              if (!_controller!.value.isInitialized)
                Container(
                  color: Colors.black54,
                  child: const Center(child: CircularProgressIndicator(color: FurPalsColors.pink)),
                ),
            ],
          ),
        ),
        Positioned.fill(
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onDoubleTap: _seekBackward,
                  onTap: () => setState(() => _togglePlayback()),
                  onHorizontalDragEnd: (details) {
                    if (details.primaryVelocity != null) {
                      if (details.primaryVelocity! > 0) _seekBackward(); else _seekForward();
                    }
                  },
                  child: Container(color: Colors.transparent, alignment: Alignment.center),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onDoubleTap: _seekForward,
                  onTap: () => setState(() => _togglePlayback()),
                  onHorizontalDragEnd: (details) {
                    if (details.primaryVelocity != null) {
                      if (details.primaryVelocity! > 0) _seekBackward(); else _seekForward();
                    }
                  },
                  child: Container(color: Colors.transparent, alignment: Alignment.center),
                ),
              ),
            ],
          ),
        ),
        if (_showControls)
          Positioned.fill(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  if (_controller!.value.isPlaying) {
                    _controller?.pause();
                  } else {
                    _controller?.play();
                  }
                  _showControls = true;
                  _overlayTimer?.cancel();
                  _overlayTimer = Timer(const Duration(seconds: 1), () {
                    if (mounted) setState(() => _showControls = false);
                  });
                });
              },
              child: Container(
                color: Colors.transparent,
                alignment: Alignment.center,
                child: Icon(
                  _controller!.value.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                  size: 56, color: Colors.white70,
                ),
              ),
            ),
          ),
        Positioned(
          top: 8, right: 8,
          child: GestureDetector(
            onTap: () {
              setState(() {
                _isMuted = !_isMuted;
                _controller?.setVolume(_isMuted ? 0 : 1);
              });
            },
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(20)),
              child: Icon(
                _isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                color: Colors.white, size: 20,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class PostModal extends StatefulWidget {
  const PostModal({super.key});

  @override
  State<PostModal> createState() => _PostModalState();
}

class _PostModalState extends State<PostModal> {
  String _audience = 'Feed';
  String _privacy = 'Only me';
  static const _audienceOptions = ['Feed', 'Group', 'Lost and Found'];
  static const _privacyOptions = ['Only me', 'Friends', 'Everyone'];

  final _descriptionCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();

  XFile? _pickedMedia;
  String _mediaType = 'none';
  bool _showLocation = false;
  VideoPlayerController? _videoController;
  bool _postVideoMuted = false;

  @override
  void dispose() {
    _descriptionCtrl.dispose();
    _locationCtrl.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (file != null) {
      setState(() { _pickedMedia = file; _mediaType = 'photo'; });
    }
  }

  Future<void> _pickVideo() async {
    try {
      final picker = ImagePicker();
      final file = await picker.pickVideo(source: ImageSource.gallery, maxDuration: const Duration(minutes: 5));
      if (file != null) {
        final videoFile = File(file.path);
        final videoSize = videoFile.lengthSync();
        final videoSizeMB = videoSize / 1024 / 1024;
        const maxSize = 100 * 1024 * 1024;

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Video size: ${videoSizeMB.toStringAsFixed(1)} MB',
                  style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
              backgroundColor: videoSizeMB > 80 ? FurPalsColors.heartRed : FurPalsColors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              duration: const Duration(seconds: 2),
            ),
          );
        }

        if (videoSize > maxSize) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    '❌ Video too large! (${videoSizeMB.toStringAsFixed(1)} MB)\nMax: 100 MB\n\nTip: Videos are auto-compressed. Try again or use a shorter clip.',
                    style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
                backgroundColor: FurPalsColors.heartRed,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                duration: const Duration(seconds: 4),
              ),
            );
          }
          return;
        }

        _videoController?.dispose();
        _videoController = VideoPlayerController.file(videoFile);
        await _videoController!.initialize();
        _videoController!.setLooping(true);
        _videoController!.setVolume(0.0);
        await Future.delayed(const Duration(milliseconds: 200));
        _videoController!.play();
        setState(() { _pickedMedia = file; _mediaType = 'video'; _postVideoMuted = false; });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unable to pick video. Try again.',
                style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
            backgroundColor: FurPalsColors.heartRed,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  Future<File?> _compressVideo(File videoFile) async {
    try {
      final info = await VideoCompress.compressVideo(
        videoFile.path,
        quality: VideoQuality.LowQuality,
        deleteOrigin: false,
        includeAudio: true,
      ).catchError((error, stack) {
        print('VideoCompress isolate error: $error');
        return null;
      });
      if (info == null || info.path == null) return null;
      return File(info.path!);
    } catch (e) {
      return null;
    }
  }

  Future<String> _uploadMedia(String uid) async {
    if (_pickedMedia == null) return '';
    try {
      File file = File(_pickedMedia!.path);
      if (!file.existsSync()) return '';

      if (_mediaType == 'video') {
        _videoController?.pause();
        final compressed = await _compressVideo(file);
        if (compressed != null && compressed.existsSync()) file = compressed;
      }

      final ext = _mediaType == 'photo' ? 'jpg' : 'mp4';
      final path = 'posts/$uid/${DateTime.now().millisecondsSinceEpoch}.$ext';
      final ref = FirebaseStorage.instance.ref().child(path);
      final uploadTask = ref.putFile(file);
      await uploadTask;
      return await ref.getDownloadURL();
    } catch (e) {
      return '';
    }
  }

  Future<void> _sharePost() async {
    if (_mediaType == 'video' && _videoController != null) {
      _videoController!.pause();
    }

    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          backgroundColor: FurPalsColors.warmWhite,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: FurPalsColors.pink),
              const SizedBox(height: 16),
              Text('Uploading your post...',
                  style: GoogleFonts.baloo2(
                      fontSize: 14, fontWeight: FontWeight.w700, color: FurPalsColors.textDark)),
              const SizedBox(height: 8),
              Text(
                  _mediaType == 'video'
                      ? 'Videos may take longer (max 100 MB)'
                      : 'This may take a moment...',
                  style: GoogleFonts.nunito(fontSize: 12, color: FurPalsColors.textMid)),
            ],
          ),
        ),
      );
    }

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
      if (uid.isEmpty) throw 'User not authenticated';

      final profile = await _getCurrentUserProfile();
      final uname = profile['username'] ?? '';
      final fname = profile['fullName'] ?? '';
      final mediaURL = await _uploadMedia(uid);

      if (_pickedMedia != null && mediaURL.isEmpty) {
        if (mounted) Navigator.pop(context);
        final fileSize = File(_pickedMedia!.path).lengthSync() / 1024 / 1024;
        throw 'Upload failed (${fileSize.toStringAsFixed(1)} MB).\n\n✗ Can handle: up to 100 MB\n✗ Check: Internet connection and Firebase usage limits\n✗ Tip: Convert to lower quality or shorter duration if you see a black screen';
      }

      final postRef = FirebaseFirestore.instance.collection('posts').doc();
      await postRef.set({
        'postId': postRef.id,
        'userId': uid,
        'username': uname,
        'fullName': fname,
        'description': _descriptionCtrl.text.trim(),
        'mediaURL': mediaURL,
        'mediaType': _mediaType,
        'videoWidth': _mediaType == 'video' && _videoController != null
            ? _videoController!.value.size.width : 0,
        'videoHeight': _mediaType == 'video' && _videoController != null
            ? _videoController!.value.size.height : 0,
        'location': _showLocation ? _locationCtrl.text.trim() : '',
        'audience': _audience,
        'privacy': _privacy,
        'likeCount': 0,
        'commentCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Post shared! 🐾',
                style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
            backgroundColor: FurPalsColors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                e.toString().contains('Failed') ? e.toString() : 'Failed to post. Please try again.',
                style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
            backgroundColor: FurPalsColors.heartRed,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: FurPalsColors.warmWhite,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(color: FurPalsColors.blush, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Text('New Post',
                    style: GoogleFonts.baloo2(
                        fontSize: 20, fontWeight: FontWeight.w800, color: FurPalsColors.textDark)),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                        color: FurPalsColors.blush, borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.close_rounded, color: FurPalsColors.pink, size: 18),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(colors: [FurPalsColors.blush, FurPalsColors.peach]),
                  ),
                  child: const Center(child: Text('🐾', style: TextStyle(fontSize: 22))),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        FirebaseAuth.instance.currentUser?.displayName ?? 'FurPals User',
                        style: GoogleFonts.baloo2(
                            fontSize: 15, fontWeight: FontWeight.w800, color: FurPalsColors.textDark),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          _ShareDropdownPill(
                            value: _audience,
                            options: _audienceOptions,
                            icon: Icons.public_rounded,
                            onChanged: (v) => setState(() => _audience = v),
                          ),
                          const SizedBox(width: 6),
                          _ShareDropdownPill(
                            value: _privacy,
                            options: _privacyOptions,
                            icon: Icons.lock_outline_rounded,
                            onChanged: (v) => setState(() => _privacy = v),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),
                      TextField(
                        controller: _descriptionCtrl,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: "What's your pet up to?",
                          hintStyle: GoogleFonts.nunito(color: FurPalsColors.textSoft, fontSize: 14),
                          border: InputBorder.none,
                        ),
                        style: GoogleFonts.nunito(
                            fontSize: 14, color: FurPalsColors.black100, fontWeight: FontWeight.w600),
                      ),
                      if (_showLocation)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 10),
                            TextField(
                              controller: _locationCtrl,
                              decoration: InputDecoration(
                                hintText: 'Search or enter location...',
                                hintStyle: GoogleFonts.nunito(color: FurPalsColors.textSoft, fontSize: 13),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(color: FurPalsColors.mint, width: 1.5),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(color: FurPalsColors.mint, width: 1.5),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(color: FurPalsColors.pink, width: 2),
                                ),
                                prefixIcon: const Icon(Icons.location_on_rounded,
                                    color: FurPalsColors.pink, size: 18),
                                suffixIcon: _locationCtrl.text.isNotEmpty
                                    ? GestureDetector(
                                        onTap: () => setState(() => _locationCtrl.clear()),
                                        child: const Icon(Icons.close_rounded,
                                            color: FurPalsColors.textMid, size: 18),
                                      )
                                    : null,
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              ),
                              style: GoogleFonts.nunito(
                                  fontSize: 13, color: FurPalsColors.textDark, fontWeight: FontWeight.w600),
                              onChanged: (value) => setState(() {}),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (_pickedMedia != null) ...[
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: _mediaType == 'photo'
                        ? Image.file(File(_pickedMedia!.path),
                            height: 200, width: double.infinity, fit: BoxFit.cover)
                        : (_videoController != null && _videoController!.value.isInitialized)
                            ? SizedBox(
                                height: 200, width: double.infinity,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    AspectRatio(
                                      aspectRatio: _videoController!.value.aspectRatio,
                                      child: VideoPlayer(_videoController!),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _videoController!.value.isPlaying
                                              ? _videoController!.pause()
                                              : _videoController!.play();
                                        });
                                      },
                                      child: Container(
                                        color: Colors.black26,
                                        child: Icon(
                                          _videoController!.value.isPlaying
                                              ? Icons.pause_circle
                                              : Icons.play_circle,
                                          size: 56, color: Colors.white70,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : Container(
                                height: 200, color: FurPalsColors.lavender,
                                child: const Center(
                                    child: CircularProgressIndicator(color: FurPalsColors.pink)),
                              ),
                  ),
                  if (_mediaType == 'video')
                    Positioned(
                      top: 8, left: 8,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _postVideoMuted = !_postVideoMuted;
                            _videoController!.setVolume(_postVideoMuted ? 0.0 : 1.0);
                          });
                        },
                        child: Container(
                          width: 28, height: 28,
                          decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                          child: Icon(
                            _postVideoMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                            color: Colors.white, size: 16,
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    top: 8, right: 8,
                    child: GestureDetector(
                      onTap: () => setState(() {
                        _pickedMedia = null;
                        _mediaType = 'none';
                        _videoController?.pause();
                        _videoController?.dispose();
                        _videoController = null;
                      }),
                      child: Container(
                        width: 28, height: 28,
                        decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                        child: const Icon(Icons.close_rounded, color: Colors.white, size: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: Builder(
                builder: (context) {
                  final fileSize = File(_pickedMedia!.path).lengthSync() / 1024 / 1024;
                  final isLarge = fileSize > 80;
                  return Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isLarge
                            ? FurPalsColors.heartRed.withOpacity(0.15)
                            : FurPalsColors.mint.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: isLarge ? FurPalsColors.heartRed : FurPalsColors.green, width: 1.5),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isLarge ? Icons.warning_amber_rounded : Icons.image_rounded,
                            color: isLarge ? FurPalsColors.heartRed : FurPalsColors.green, size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isLarge
                                ? '${fileSize.toStringAsFixed(1)} MB — Upload will be slow'
                                : '${fileSize.toStringAsFixed(1)} MB',
                            style: GoogleFonts.nunito(
                                fontSize: 12, fontWeight: FontWeight.w700,
                                color: isLarge ? FurPalsColors.heartRed : FurPalsColors.green),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
            child: Row(
              children: [
                GestureDetector(
                  onTap: _pickImage,
                  child: _opt(Icons.image_rounded, 'Photo', FurPalsColors.mint),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: _pickVideo,
                  child: _opt(Icons.videocam_rounded, 'Video', FurPalsColors.lavender),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: _showLocationPicker,
                  child: _opt(Icons.location_on_rounded, 'Location', FurPalsColors.peach),
                ),
              ],
            ),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: GestureDetector(
              onTap: _sharePost,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: const LinearGradient(
                      colors: [FurPalsColors.pink, FurPalsColors.pinkLight]),
                  boxShadow: const [
                    BoxShadow(color: Color(0x55F4738A), blurRadius: 14, offset: Offset(0, 6)),
                  ],
                ),
                child: Center(
                  child: Text('Share Post 🐾',
                      style: GoogleFonts.baloo2(
                          fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showLocationPicker() async {
    final TextEditingController searchCtrl = TextEditingController();
    List<String> commonLocations = [
      'Home', 'Park', 'Beach', 'Coffee Shop', 'Dog Park',
      'Pet Store', 'Vet Clinic', 'Downtown', 'Shopping Mall', 'Garden',
    ];
    List<String> filteredLocations = commonLocations;

    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              backgroundColor: FurPalsColors.warmWhite,
              title: Text('Select Location 📍',
                  style: GoogleFonts.baloo2(
                      fontSize: 16, fontWeight: FontWeight.w800, color: FurPalsColors.textDark)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: searchCtrl,
                      decoration: InputDecoration(
                        hintText: 'Search or type location...',
                        hintStyle: GoogleFonts.nunito(color: FurPalsColors.textSoft, fontSize: 13),
                        prefixIcon: const Icon(Icons.search_rounded, color: FurPalsColors.pink, size: 18),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: FurPalsColors.mint, width: 1.5),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: FurPalsColors.mint, width: 1.5),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: FurPalsColors.pink, width: 2),
                        ),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      style: GoogleFonts.nunito(
                          fontSize: 13, color: FurPalsColors.textDark, fontWeight: FontWeight.w600),
                      onChanged: (value) {
                        setModalState(() {
                          filteredLocations = commonLocations
                              .where((loc) => loc.toLowerCase().contains(value.toLowerCase()))
                              .toList();
                          if (value.isNotEmpty && !filteredLocations.contains(value)) {
                            filteredLocations.insert(0, value);
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 200,
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: filteredLocations.length,
                        itemBuilder: (context, index) {
                          final location = filteredLocations[index];
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _locationCtrl.text = location;
                                _showLocation = true;
                              });
                              Navigator.pop(context);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              margin: const EdgeInsets.only(bottom: 6),
                              decoration: BoxDecoration(
                                color: FurPalsColors.mint.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: FurPalsColors.mint, width: 1),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.location_on_rounded,
                                      color: FurPalsColors.pink, size: 18),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(location,
                                        style: GoogleFonts.nunito(
                                            fontSize: 13, fontWeight: FontWeight.w600,
                                            color: FurPalsColors.textDark)),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel',
                      style: GoogleFonts.nunito(
                          fontSize: 13, fontWeight: FontWeight.w700, color: FurPalsColors.textMid)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _opt(IconData icon, String label, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(color: bg.withOpacity(0.6), borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: FurPalsColors.textMid),
          const SizedBox(width: 6),
          Text(label,
              style: GoogleFonts.nunito(
                  fontSize: 12, fontWeight: FontWeight.w700, color: FurPalsColors.textMid)),
        ],
      ),
    );
  }
}

class PetsBody extends StatelessWidget {
  const PetsBody({super.key});

  @override
  Widget build(BuildContext context) {
    return const PetsScreen();
  }
}

class ProfileBody extends StatelessWidget {
  const ProfileBody({super.key});

  @override
  Widget build(BuildContext context) => const _PlaceholderBody(
        emoji: '😊',
        title: 'Profile',
        subtitle: 'Your FurPals account',
      );
}

class _PlaceholderBody extends StatelessWidget {
  final String emoji, title, subtitle;
  const _PlaceholderBody({required this.emoji, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: appBackgroundGradient),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            Text(title,
                style: GoogleFonts.baloo2(
                    fontSize: 28, fontWeight: FontWeight.w800, color: FurPalsColors.textDark)),
            const SizedBox(height: 6),
            Text(subtitle,
                style: GoogleFonts.nunito(
                    fontSize: 14, color: FurPalsColors.textMid, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}