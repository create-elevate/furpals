import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:furpals/mypets.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:furpals/notification_service.dart';

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
  static const pink = Color(0xFFF4738A);
  static const pinkLight = Color(0xFFFF9AB0);
  static const green = Color(0xFF5DB87A);
  static const shadow = Color(0x20B47864);
  static const heartRed = Color(0xFFE53935);
}

const appBackgroundGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  stops: [0.0, 0.5, 1.0],
  colors: [Color(0xFFFCDDE8), Color(0xFFFFE8D2), Color(0xFFD4F0E4)],
);

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, this.userId});

  final String? userId;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;
  final _picker = ImagePicker();

  bool _isLoading = false;
  bool _suggestionsVisible = true;
  Map<String, dynamic> _profileData = {};
  List<Map<String, dynamic>> _posts = [];
  List<Map<String, dynamic>> _savedPosts = [];
  List<Map<String, dynamic>> _suggestions = [];
  int _postCount = 0;
  int _followerCount = 0;
  int _followingCount = 0;

  // ── NEW: liked & pinned tracking ──
  Set<String> _likedPostIds = {};
  Set<String> _pinnedPostIds = {};

  String get _currentUid => _auth.currentUser?.uid ?? '';
  String get _viewingUid => widget.userId ?? _currentUid;
  bool get _isOwnProfile =>
      widget.userId == null || widget.userId == _currentUid;

  bool _isFollowing = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadPosts();
    _loadLikedAndPinned();
    if (_isOwnProfile) {
      _loadSavedPosts();
      _loadSuggestions();
    } else {
      _loadFollowState();
    }
  }

  // ── NEW: load liked and pinned sets ──
  Future<void> _loadLikedAndPinned() async {
    if (_currentUid.isEmpty) return;
    try {
      final likedSnap = await _firestore
          .collection('users')
          .doc(_currentUid)
          .collection('likedPosts')
          .get();
      final pinnedSnap = await _firestore
          .collection('users')
          .doc(_currentUid)
          .collection('pinnedPosts')
          .get();
      if (mounted) {
        setState(() {
          _likedPostIds = likedSnap.docs.map((d) => d.id).toSet();
          _pinnedPostIds = pinnedSnap.docs.map((d) => d.id).toSet();
        });
      }
    } catch (_) {}
  }

  Future<void> _loadFollowState() async {
    if (_currentUid.isEmpty || _isOwnProfile) return;
    try {
      final doc = await _firestore
          .collection('users')
          .doc(_currentUid)
          .collection('following')
          .doc(_viewingUid)
          .get();
      if (mounted) {
        setState(() => _isFollowing = doc.exists);
      }
    } catch (_) {}
  }

  bool _isPostPinned(Map<String, dynamic> post) {
    if (_isOwnProfile) {
      final postId = post['postId'] as String? ?? '';
      return _pinnedPostIds.contains(postId);
    }
    return post['pinned'] as bool? ?? false;
  }

  Future<void> _loadProfile() async {
    if (_viewingUid.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      final doc = await _firestore.collection('users').doc(_viewingUid).get();
      final data = doc.data() ?? {};
      final followersSnap = await _firestore
          .collection('users')
          .doc(_viewingUid)
          .collection('followers')
          .get();
      final followingSnap = await _firestore
          .collection('users')
          .doc(_viewingUid)
          .collection('following')
          .get();
      if (mounted) {
        setState(() {
          _profileData = data;
          _followerCount = followersSnap.docs.length;
          _followingCount = followingSnap.docs.length;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadPosts() async {
    if (_viewingUid.isEmpty) return;
    try {
      final query = _firestore
          .collection('posts')
          .where('userId', isEqualTo: _viewingUid);
      final snap = await query.orderBy('createdAt', descending: true).get();
      if (mounted) {
        setState(() {
          _posts = snap.docs.map((d) => {'postId': d.id, ...d.data()}).toList();
          _postCount = snap.docs.length;
        });
      }
    } catch (_) {
      try {
        final snap = await _firestore
            .collection('posts')
            .where('userId', isEqualTo: _viewingUid)
            .get();
        if (mounted) {
          setState(() {
            _posts = snap.docs
                .map((d) => {'postId': d.id, ...d.data()})
                .toList();
            _postCount = snap.docs.length;
          });
        }
      } catch (_) {}
    }
  }

  Future<void> _loadSuggestions() async {
    if (_currentUid.isEmpty || !_isOwnProfile) return;
    try {
      final followingSnap = await _firestore
          .collection('users')
          .doc(_currentUid)
          .collection('following')
          .get();
      final alreadyFollowingIds = followingSnap.docs.map((d) => d.id).toSet();

      final snap = await _firestore.collection('users').limit(20).get();
      if (mounted) {
        final filtered = snap.docs
            .where(
              (d) => d.id != _currentUid && !alreadyFollowingIds.contains(d.id),
            )
            .map((d) => {'userId': d.id, ...d.data()})
            .take(10)
            .toList();
        setState(() {
          _suggestions = filtered;
        });
      }
    } catch (_) {}
  }

  Future<void> _loadSavedPosts() async {
    if (_currentUid.isEmpty || !_isOwnProfile) {
      if (mounted) setState(() => _savedPosts = []);
      return;
    }
    try {
      final snap = await _firestore
          .collection('users')
          .doc(_currentUid)
          .collection('savedPosts')
          .orderBy('savedAt', descending: true)
          .get();
      if (mounted) {
        setState(() {
          _savedPosts = snap.docs
              .map((d) => {'postId': d.id, ...d.data()})
              .toList();
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _savedPosts = [];
        });
      }
    }
  }

  void _showFollowListSheet(String type) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FollowListSheet(
        firestore: _firestore,
        currentUid: _viewingUid,
        currentUserProfile: _profileData,
        type: type,
        onFollowChanged: () {
          _loadProfile();
          if (_isOwnProfile) _loadSuggestions();
        },
      ),
    );
  }

  Future<void> _pickAndUploadAvatar() async {
    try {
      final file = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      if (file == null) return;
      final imageFile = File(file.path);
      if (!imageFile.existsSync()) {
        _showSnack('Could not read image file', FurPalsColors.heartRed);
        return;
      }
      setState(() => _isLoading = true);
      final ref = _storage.ref().child(
        'profile_pictures/$_currentUid/profile.jpg',
      );
      final uploadTask = ref.putFile(
        imageFile,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      await uploadTask;
      final url = await ref.getDownloadURL();
      await _firestore.collection('users').doc(_currentUid).update({
        'photoURL': url,
      });
      await _auth.currentUser?.updatePhotoURL(url);
      if (mounted) {
        setState(() {
          _profileData['photoURL'] = url;
          _isLoading = false;
        });
        _showSnack('Profile photo updated', FurPalsColors.green);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showSnack(
          'Failed: ${e.toString().split(']').last.trim()}',
          FurPalsColors.heartRed,
        );
      }
    }
  }

  Future<void> _toggleFollow(String targetUid) async {
    if (_currentUid.isEmpty || targetUid.isEmpty) return;
    final myFollowingRef = _firestore
        .collection('users')
        .doc(_currentUid)
        .collection('following')
        .doc(targetUid);
    final theirFollowerRef = _firestore
        .collection('users')
        .doc(targetUid)
        .collection('followers')
        .doc(_currentUid);
    try {
      final doc = await myFollowingRef.get();
      final isFollowing = doc.exists;
      if (isFollowing) {
        await myFollowingRef.delete();
        await theirFollowerRef.delete();
        _loadSuggestions();
        if (!_isOwnProfile && mounted) {
          setState(() => _isFollowing = false);
        }
        _showSnack('Unfollowed this Furparent', FurPalsColors.textMid);
      } else {
        final profile = _profileData;
        await myFollowingRef.set({
          'userId': targetUid,
          'followedAt': FieldValue.serverTimestamp(),
        });
        await theirFollowerRef.set({
          'userId': _currentUid,
          'username': profile['username'] ?? '',
          'fullName': profile['fullName'] ?? '',
          'followedAt': FieldValue.serverTimestamp(),
        });
        if (mounted) {
          setState(() {
            _suggestions.removeWhere((s) => s['userId'] == targetUid);
            if (!_isOwnProfile) {
              _isFollowing = true;
            }
          });
        }
        _showSnack('Following this Furparent', FurPalsColors.green);
      }
      _loadProfile();
    } catch (_) {
      _showSnack('Something went wrong', FurPalsColors.heartRed);
    }
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: GoogleFonts.nunito(fontWeight: FontWeight.w700),
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showEditProfileSheet() {
    final nameCtrl = TextEditingController(
      text: _profileData['fullName'] ?? '',
    );
    final bioCtrl = TextEditingController(text: _profileData['bio'] ?? '');
    final locCtrl = TextEditingController(text: _profileData['location'] ?? '');
    bool saving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Container(
            decoration: const BoxDecoration(
              color: FurPalsColors.warmWhite,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: FurPalsColors.blush,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Edit Profile',
                  style: GoogleFonts.baloo2(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: FurPalsColors.textDark,
                  ),
                ),
                const SizedBox(height: 20),
                _editField(nameCtrl, 'Full Name', Icons.person_rounded),
                const SizedBox(height: 12),
                _editField(bioCtrl, 'Bio', Icons.notes_rounded),
                const SizedBox(height: 12),
                _editField(locCtrl, 'Location', Icons.location_on_rounded),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: saving
                      ? null
                      : () async {
                          setModal(() => saving = true);
                          try {
                            await _firestore
                                .collection('users')
                                .doc(_currentUid)
                                .update({
                                  'fullName': nameCtrl.text.trim(),
                                  'bio': bioCtrl.text.trim(),
                                  'location': locCtrl.text.trim(),
                                });
                            await _auth.currentUser?.updateDisplayName(
                              nameCtrl.text.trim(),
                            );
                            if (mounted) {
                              setState(() {
                                _profileData['fullName'] = nameCtrl.text.trim();
                                _profileData['bio'] = bioCtrl.text.trim();
                                _profileData['location'] = locCtrl.text.trim();
                              });
                              Navigator.pop(ctx);
                              _showSnack(
                                'Profile updated',
                                FurPalsColors.green,
                              );
                            }
                          } catch (_) {
                            _showSnack(
                              'Failed to update',
                              FurPalsColors.heartRed,
                            );
                          }
                          setModal(() => saving = false);
                        },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: const LinearGradient(
                        colors: [FurPalsColors.pink, FurPalsColors.pinkLight],
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x55F4738A),
                          blurRadius: 14,
                          offset: Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Center(
                      child: saving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              'Save Changes',
                              style: GoogleFonts.baloo2(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _editField(TextEditingController ctrl, String hint, IconData icon) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: FurPalsColors.blush, width: 1.5),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: FurPalsColors.pink, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: ctrl,
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: GoogleFonts.nunito(
                  color: FurPalsColors.textMid,
                  fontSize: 13,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
              style: GoogleFonts.nunito(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: FurPalsColors.textDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fullName =
        _profileData['fullName'] ??
        _auth.currentUser?.displayName ??
        'Pet Name';
    final username = _profileData['username'] ?? 'username';
    final bio = _profileData['bio'] ?? '';

    final rawLocation = _profileData['location'];
    final location = (rawLocation == null || (rawLocation as String).isEmpty)
        ? ''
        : rawLocation as String;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: [0.0, 0.5, 1.0],
            colors: [Color(0xFFFCDDE8), Color(0xFFFFE8D2), Color(0xFFD4F0E4)],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: FurPalsColors.pink),
                )
              : DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.45),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        _buildHeader(
                          fullName,
                          username,
                          bio,
                          location,
                          _profileData['photoURL'] as String?,
                        ),
                        _buildActionButtons(),
                        _buildMyPetsButton(),
                        _buildSuggestions(),
                        _buildTabsAndGrid(),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildHeader(
    String fullName,
    String username,
    String bio,
    String location,
    String? photoURL,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: _isOwnProfile ? _pickAndUploadAvatar : null,
                child: Stack(
                  children: [
                    Container(
                      width: 90,
                      height: 90,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            FurPalsColors.pink,
                            FurPalsColors.pinkLight,
                            FurPalsColors.mint,
                            FurPalsColors.pink,
                          ],
                        ),
                      ),
                      padding: const EdgeInsets.all(3),
                      child: Container(
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: FurPalsColors.cream,
                        ),
                        child: photoURL != null && photoURL.isNotEmpty
                            ? ClipOval(
                                child: Image.network(
                                  photoURL,
                                  fit: BoxFit.cover,
                                  width: 84,
                                  height: 84,
                                ),
                              )
                            : const Center(
                                child: Icon(
                                  Icons.pets_rounded,
                                  size: 40,
                                  color: FurPalsColors.pink,
                                ),
                              ),
                      ),
                    ),
                    if (_isOwnProfile)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            color: FurPalsColors.pink,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(
                            Icons.add_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _statItem(_postCount.toString(), 'Posts', onTap: null),
                    _statItem(
                      _formatCount(_followerCount),
                      'Followers',
                      onTap: () => _showFollowListSheet('followers'),
                    ),
                    _statItem(
                      _formatCount(_followingCount),
                      'Following',
                      onTap: () => _showFollowListSheet('following'),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            fullName,
            style: GoogleFonts.baloo2(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: FurPalsColors.textDark,
            ),
          ),
          const SizedBox(height: 2),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Flexible(
                child: RichText(
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  text: TextSpan(
                    style: GoogleFonts.nunito(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: FurPalsColors.textMid,
                    ),
                    children: [
                      const TextSpan(text: 'Owner: '),
                      TextSpan(
                        text: '@$username',
                        style: const TextStyle(color: FurPalsColors.pink),
                      ),
                    ],
                  ),
                ),
              ),
              if (location.isNotEmpty) ...[
                const SizedBox(width: 8),
                const Icon(
                  Icons.location_on_rounded,
                  size: 13,
                  color: FurPalsColors.pink,
                ),
                const SizedBox(width: 2),
                Flexible(
                  child: Text(
                    location,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: GoogleFonts.nunito(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: FurPalsColors.textMid,
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (bio.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              bio,
              style: GoogleFonts.nunito(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: FurPalsColors.textDark,
              ),
            ),
          ],
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _statItem(String value, String label, {VoidCallback? onTap}) {
    final content = Column(
      children: [
        Text(
          value,
          style: GoogleFonts.baloo2(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: FurPalsColors.textDark,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.nunito(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: FurPalsColors.textMid,
          ),
        ),
      ],
    );
    if (onTap == null) return content;
    return GestureDetector(onTap: onTap, child: content);
  }

  Widget _buildActionButtons() {
    if (!_isOwnProfile) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => _toggleFollow(_viewingUid),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: _isFollowing ? FurPalsColors.blush : FurPalsColors.pink,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: FurPalsColors.pink, width: 1.5),
                    boxShadow: const [
                      BoxShadow(
                        color: FurPalsColors.shadow,
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      _isFollowing ? 'Following' : 'Follow',
                      style: GoogleFonts.nunito(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: _isFollowing ? FurPalsColors.pink : Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: GestureDetector(
                onTap: () =>
                    _showSnack('Link copied to clipboard', FurPalsColors.green),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: FurPalsColors.pink, width: 1.5),
                    boxShadow: const [
                      BoxShadow(
                        color: FurPalsColors.shadow,
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      'Share Profile',
                      style: GoogleFonts.nunito(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: FurPalsColors.pink,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: _showEditProfileSheet,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: FurPalsColors.pink, width: 1.5),
                  boxShadow: const [
                    BoxShadow(
                      color: FurPalsColors.shadow,
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    'Edit Profile',
                    style: GoogleFonts.nunito(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: FurPalsColors.pink,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: GestureDetector(
              onTap: () =>
                  _showSnack('Link copied to clipboard', FurPalsColors.green),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: FurPalsColors.pink, width: 1.5),
                  boxShadow: const [
                    BoxShadow(
                      color: FurPalsColors.shadow,
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    'Share Profile',
                    style: GoogleFonts.nunito(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: FurPalsColors.pink,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () =>
                setState(() => _suggestionsVisible = !_suggestionsVisible),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: _suggestionsVisible ? FurPalsColors.pink : Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: FurPalsColors.pink, width: 1.5),
                boxShadow: const [
                  BoxShadow(
                    color: FurPalsColors.shadow,
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons.person_add_rounded,
                color: _suggestionsVisible ? Colors.white : FurPalsColors.pink,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyPetsButton() {
    if (!_isOwnProfile) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const myPetsScreen()),
          );
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(50),
            color: FurPalsColors.pink,
            boxShadow: const [
              BoxShadow(
                color: Color(0x55F4738A),
                blurRadius: 16,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.cruelty_free_rounded,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'My Pets',
                style: GoogleFonts.baloo2(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestions() {
    if (!_isOwnProfile || _suggestions.isEmpty) return const SizedBox.shrink();

    return AnimatedCrossFade(
      firstChild: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
            child: Text(
              'Suggested Friends',
              style: GoogleFonts.baloo2(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: FurPalsColors.textMid,
              ),
            ),
          ),
          SizedBox(
            height: 130,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              itemCount: _suggestions.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (_, i) {
                final s = _suggestions[i];
                final uid = s['userId'] ?? '';
                return _SuggestionCard(
                  userId: uid,
                  fullName: s['fullName'] ?? 'User',
                  username: s['username'] ?? '',
                  photoURL: s['photoURL'],
                  onFollow: () => _toggleFollow(uid),
                );
              },
            ),
          ),
        ],
      ),
      secondChild: const SizedBox(width: double.infinity, height: 0),
      crossFadeState: _suggestionsVisible
          ? CrossFadeState.showFirst
          : CrossFadeState.showSecond,
      duration: const Duration(milliseconds: 280),
      sizeCurve: Curves.easeInOut,
    );
  }

  Widget _buildTabsAndGrid() {
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          Container(
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: Color(0xFFF0E4DC), width: 1),
                bottom: BorderSide(color: Color(0xFFF0E4DC), width: 1),
              ),
            ),
            child: TabBar(
              indicatorColor: FurPalsColors.pink,
              indicatorWeight: 2.5,
              tabs: const [
                Tab(icon: Icon(Icons.grid_on_rounded, size: 22)),
                Tab(icon: Icon(Icons.videocam_rounded, size: 22)),
                Tab(icon: Icon(Icons.bookmark_rounded, size: 22)),
              ],
              labelColor: FurPalsColors.textDark,
              unselectedLabelColor: FurPalsColors.textMid,
            ),
          ),
          SizedBox(
            height: 320,
            child: TabBarView(
              children: [
                _buildPostGrid(),
                _buildVideosGrid(),
                _buildSavedPostsGrid(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── UPDATED: _buildPostGrid with long-press, pin overlay, like overlay ──
  Widget _buildPostGrid() {
    if (_posts.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.pets_rounded,
              size: 48,
              color: FurPalsColors.blush,
            ),
            const SizedBox(height: 12),
            Text(
              'No posts yet',
              style: GoogleFonts.baloo2(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: FurPalsColors.textDark,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Share your first moment',
              style: GoogleFonts.nunito(
                fontSize: 13,
                color: FurPalsColors.textMid,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    final colorPairs = [
      [FurPalsColors.blush, FurPalsColors.peach],
      [FurPalsColors.mint, FurPalsColors.butter],
      [FurPalsColors.lavender, FurPalsColors.blush],
      [FurPalsColors.peach, FurPalsColors.mint],
    ];

    // Pinned posts float to top
    final sorted = [..._posts];
    sorted.sort((a, b) {
      final aPinned = _isPostPinned(a);
      final bPinned = _isPostPinned(b);
      if (aPinned && !bPinned) return -1;
      if (!aPinned && bPinned) return 1;
      return 0;
    });

    final postsOnly = sorted
        .where((post) => (post['mediaType'] as String? ?? 'none') != 'video')
        .toList();

    if (postsOnly.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.pets_rounded,
              size: 48,
              color: FurPalsColors.blush,
            ),
            const SizedBox(height: 12),
            Text(
              'No posts yet',
              style: GoogleFonts.baloo2(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: FurPalsColors.textDark,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Share your first moment',
              style: GoogleFonts.nunito(
                fontSize: 13,
                color: FurPalsColors.textMid,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: EdgeInsets.zero,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
      ),
      itemCount: postsOnly.length,
      itemBuilder: (_, i) {
        final post = postsOnly[i];
        final postId = post['postId'] as String? ?? '';
        final mediaURL = post['mediaURL'] as String? ?? '';
        final mediaType = post['mediaType'] as String? ?? 'none';
        final pair = colorPairs[i % colorPairs.length];
        final isPinned = _isPostPinned(post);
        final isLiked = _likedPostIds.contains(postId);

        return GestureDetector(
          onLongPress: () => _showPostActionsSheet(
            post: post,
            postId: postId,
            mediaURL: mediaURL,
            isLiked: isLiked,
            isPinned: isPinned,
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Thumbnail
              if (mediaURL.isNotEmpty && mediaType == 'photo')
                Image.network(
                  mediaURL,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return _gridPlaceholder(pair);
                  },
                  errorBuilder: (_, __, ___) => _gridPlaceholder(pair),
                )
              else
                _gridPlaceholder(pair),

              if (mediaType == 'video')
                const Center(
                  child: Icon(
                    Icons.play_circle_rounded,
                    color: Colors.white70,
                    size: 32,
                  ),
                ),

              // Video badge
              if (mediaType == 'video')
                Positioned(
                  top: 5,
                  left: 5,
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.videocam_rounded,
                      color: Colors.white,
                      size: 12,
                    ),
                  ),
                ),

              // Pin badge
              if (isPinned)
                Positioned(
                  top: 5,
                  right: 5,
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: FurPalsColors.pink,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.push_pin_rounded,
                      color: Colors.white,
                      size: 12,
                    ),
                  ),
                ),

              // Like badge
              if (isLiked)
                Positioned(
                  bottom: 5,
                  right: 5,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: FurPalsColors.heartRed,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.favorite_rounded,
                      color: Colors.white,
                      size: 11,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  // ── NEW: open post actions sheet ──
  void _showPostActionsSheet({
    required Map<String, dynamic> post,
    required String postId,
    required String mediaURL,
    required bool isLiked,
    required bool isPinned,
  }) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: true,
        barrierColor: Colors.transparent,
        pageBuilder: (_, __, ___) => _PostFloatingOverlay(
          post: post,
          postId: postId,
          mediaURL: mediaURL,
          isLiked: isLiked,
          isPinned: isPinned,
          currentUid: _currentUid,
          firestore: _firestore,
          onLikeToggled: (liked) {
            setState(() {
              if (liked) {
                _likedPostIds.add(postId);
              } else {
                _likedPostIds.remove(postId);
              }
            });
          },
          onPinToggled: (pinned) {
            setState(() {
              if (pinned) {
                _pinnedPostIds.add(postId);
              } else {
                _pinnedPostIds.remove(postId);
              }
            });
            _showSnack(
              pinned ? 'Post pinned to profile 📌' : 'Post unpinned',
              pinned ? FurPalsColors.pink : FurPalsColors.textMid,
            );
          },
          onShareTapped: () {
            _showSnack('Link copied to clipboard', FurPalsColors.green);
          },
          onCommentTapped: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => _CommentsSheet(
                postId: postId,
                firestore: _firestore,
                currentUid: _currentUid,
              ),
            );
          },
        ),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  Widget _gridPlaceholder(List<Color> pair) {
    return Container(
      decoration: BoxDecoration(gradient: LinearGradient(colors: pair)),
      child: const Center(
        child: Icon(Icons.pets_rounded, color: Colors.white54, size: 28),
      ),
    );
  }

  Widget _buildSavedPostsGrid() {
    if (!_isOwnProfile) {
      return _buildEmptyTab(Icons.lock_rounded, 'Saved posts are private');
    }
    if (_savedPosts.isEmpty) {
      return _buildEmptyTab(Icons.bookmark_rounded, 'No saved posts');
    }

    final colorPairs = [
      [FurPalsColors.blush, FurPalsColors.peach],
      [FurPalsColors.mint, FurPalsColors.butter],
      [FurPalsColors.lavender, FurPalsColors.blush],
      [FurPalsColors.peach, FurPalsColors.mint],
    ];

    return GridView.builder(
      padding: EdgeInsets.zero,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
      ),
      itemCount: _savedPosts.length,
      itemBuilder: (context, index) {
        final post = _savedPosts[index];
        final postId = post['postId'] ?? '';
        final mediaURL = post['mediaURL'] ?? '';
        final mediaType = post['mediaType'] as String? ?? 'none';
        final isVideo = mediaType == 'video';
        final pair = colorPairs[index % colorPairs.length];

        return GestureDetector(
          onTap: () => _showPostActionsSheet(
            post: post,
            postId: postId,
            mediaURL: mediaURL,
            isLiked: false,
            isPinned: false,
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: mediaURL.isEmpty ? LinearGradient(colors: pair) : null,
              image: mediaURL.isNotEmpty && mediaType == 'photo'
                  ? DecorationImage(
                      image: NetworkImage(mediaURL),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: Stack(
              children: [
                if (mediaURL.isEmpty || mediaType == 'video')
                  const Center(
                    child: Icon(
                      Icons.pets_rounded,
                      color: Colors.white54,
                      size: 28,
                    ),
                  ),
                if (isVideo)
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Icon(
                        Icons.videocam_rounded,
                        color: Colors.white,
                        size: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildVideosGrid() {
    final videos = _posts
        .where((post) => (post['mediaType'] as String? ?? 'none') == 'video')
        .toList();
    if (videos.isEmpty) {
      return _buildEmptyTab(Icons.videocam_rounded, 'No videos yet');
    }

    final colorPairs = [
      [FurPalsColors.blush, FurPalsColors.peach],
      [FurPalsColors.mint, FurPalsColors.butter],
      [FurPalsColors.lavender, FurPalsColors.blush],
      [FurPalsColors.peach, FurPalsColors.mint],
    ];

    return GridView.builder(
      padding: EdgeInsets.zero,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
      ),
      itemCount: videos.length,
      itemBuilder: (context, index) {
        final post = videos[index];
        final postId = post['postId'] ?? '';
        final mediaURL = post['mediaURL'] ?? '';
        final mediaType = post['mediaType'] as String? ?? 'none';
        final isVideo = mediaType == 'video';
        final isLiked = _likedPostIds.contains(postId);
        final isPinned = _isPostPinned(post);
        final pair = colorPairs[index % colorPairs.length];

        return GestureDetector(
          onLongPress: () => _showPostActionsSheet(
            post: post,
            postId: postId,
            mediaURL: mediaURL,
            isLiked: isLiked,
            isPinned: isPinned,
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: mediaURL.isEmpty ? LinearGradient(colors: pair) : null,
              image: mediaURL.isNotEmpty && mediaType == 'photo'
                  ? DecorationImage(
                      image: NetworkImage(mediaURL),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: Stack(
              children: [
                if (mediaURL.isEmpty || isVideo)
                  const Center(
                    child: Icon(
                      Icons.pets_rounded,
                      color: Colors.white54,
                      size: 28,
                    ),
                  ),
                if (isVideo)
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Icon(
                        Icons.videocam_rounded,
                        color: Colors.white,
                        size: 12,
                      ),
                    ),
                  ),
                if (isPinned)
                  Positioned(
                    top: 4,
                    left: 4,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: FurPalsColors.pink.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Icon(
                        Icons.push_pin_rounded,
                        color: Colors.white,
                        size: 12,
                      ),
                    ),
                  ),
                if (isLiked)
                  Positioned(
                    bottom: 4,
                    right: 4,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: FurPalsColors.pink.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Icon(
                        Icons.favorite_rounded,
                        color: Colors.white,
                        size: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyTab(IconData icon, String msg) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 44, color: FurPalsColors.blush),
          const SizedBox(height: 10),
          Text(
            msg,
            style: GoogleFonts.nunito(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: FurPalsColors.textMid,
            ),
          ),
        ],
      ),
    );
  }

  String _formatCount(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }
}

class _PostFloatingOverlay extends StatefulWidget {
  final Map<String, dynamic> post;
  final String postId;
  final String mediaURL;
  final bool isLiked;
  final bool isPinned;
  final String currentUid;
  final FirebaseFirestore firestore;
  final void Function(bool liked) onLikeToggled;
  final void Function(bool pinned) onPinToggled;
  final VoidCallback onShareTapped;
  final VoidCallback onCommentTapped;

  const _PostFloatingOverlay({
    required this.post,
    required this.postId,
    required this.mediaURL,
    required this.isLiked,
    required this.isPinned,
    required this.currentUid,
    required this.firestore,
    required this.onLikeToggled,
    required this.onPinToggled,
    required this.onShareTapped,
    required this.onCommentTapped,
  });

  @override
  State<_PostFloatingOverlay> createState() => _PostFloatingOverlayState();
}

class _PostFloatingOverlayState extends State<_PostFloatingOverlay>
    with SingleTickerProviderStateMixin {
  late bool _liked;
  late bool _pinned;
  late int _likeCount;
  bool _toggling = false;
  late AnimationController _animCtrl;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _liked = widget.isLiked;
    _pinned = widget.isPinned;
    _likeCount = widget.post['likeCount'] as int? ?? 0;

    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _scaleAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutBack);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _dismiss() async {
    await _animCtrl.reverse();
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _toggleLike() async {
    if (_toggling) return;
    setState(() => _toggling = true);

    final postRef = widget.firestore.collection('posts').doc(widget.postId);
    final likedRef = widget.firestore
        .collection('users')
        .doc(widget.currentUid)
        .collection('likedPosts')
        .doc(widget.postId);

    try {
      if (_liked) {
        await likedRef.delete();
        await postRef.update({'likeCount': FieldValue.increment(-1)});
        setState(() {
          _liked = false;
          _likeCount = (_likeCount - 1).clamp(0, 999999);
        });
        widget.onLikeToggled(false);
      } else {
        await likedRef.set({
          'postId': widget.postId,
          'likedAt': FieldValue.serverTimestamp(),
        });
        await postRef.update({'likeCount': FieldValue.increment(1)});
        setState(() {
          _liked = true;
          _likeCount = _likeCount + 1;
        });
        widget.onLikeToggled(true);
      }
    } catch (_) {}
    setState(() => _toggling = false);
  }

  Future<void> _togglePin() async {
    final pinnedRef = widget.firestore
        .collection('users')
        .doc(widget.currentUid)
        .collection('pinnedPosts')
        .doc(widget.postId);

    try {
      if (_pinned) {
        await pinnedRef.delete();
        await widget.firestore.collection('posts').doc(widget.postId).update({
          'pinned': false,
        });
        setState(() => _pinned = false);
        widget.onPinToggled(false);
      } else {
        await pinnedRef.set({
          'postId': widget.postId,
          'pinnedAt': FieldValue.serverTimestamp(),
        });
        await widget.firestore.collection('posts').doc(widget.postId).update({
          'pinned': true,
        });
        setState(() => _pinned = true);
        widget.onPinToggled(true);
      }
    } catch (_) {}
    _dismiss();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _dismiss,
      child: Container(
        color: Colors.black.withOpacity(0.55),
        child: SafeArea(
          child: Center(
            child: ScaleTransition(
              scale: _scaleAnim,
              child: GestureDetector(
                onTap: () {}, // prevent dismiss when tapping card
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.82,
                  margin: const EdgeInsets.symmetric(vertical: 24),
                  decoration: BoxDecoration(
                    color: FurPalsColors.warmWhite,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x40000000),
                        blurRadius: 32,
                        offset: Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Post preview
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(24),
                        ),
                        child:
                            widget.mediaURL.isNotEmpty &&
                                (widget.post['mediaType'] as String? ?? '') !=
                                    'video'
                            ? Image.network(
                                widget.mediaURL,
                                height: 220,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                loadingBuilder:
                                    (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return _fallbackPreview();
                                    },
                                errorBuilder: (_, __, ___) =>
                                    _fallbackPreview(),
                              )
                            : _fallbackPreview(),
                      ),

                      // Pin/unpin badge on preview
                      if (_pinned)
                        Padding(
                          padding: const EdgeInsets.only(top: 10, right: 10),
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: FurPalsColors.pink,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.push_pin_rounded,
                                    color: Colors.white,
                                    size: 12,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Pinned',
                                    style: GoogleFonts.nunito(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                      // Actions
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                        child: Column(
                          children: [
                            // Like + Comment in a row
                            Row(
                              children: [
                                Expanded(
                                  child: _FloatingActionBtn(
                                    icon: _liked
                                        ? Icons.favorite_rounded
                                        : Icons.favorite_border_rounded,
                                    label: _liked
                                        ? 'Unlike  $_likeCount'
                                        : 'Like  $_likeCount',
                                    color: FurPalsColors.heartRed,
                                    bgColor: const Color(0xFFFFEBEB),
                                    isLoading: _toggling,
                                    onTap: _toggleLike,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _FloatingActionBtn(
                                    icon: Icons.chat_bubble_outline_rounded,
                                    label: 'Comment',
                                    color: FurPalsColors.green,
                                    bgColor: const Color(0xFFEAF8EF),
                                    onTap: () {
                                      _dismiss().then((_) {
                                        widget.onCommentTapped();
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            // Pin + Share in a row
                            Row(
                              children: [
                                Expanded(
                                  child: _FloatingActionBtn(
                                    icon: _pinned
                                        ? Icons.push_pin_rounded
                                        : Icons.push_pin_outlined,
                                    label: _pinned ? 'Unpin' : 'Pin',
                                    color: const Color(0xFF9C7FD4),
                                    bgColor: const Color(0xFFF3EEFF),
                                    onTap: _togglePin,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _FloatingActionBtn(
                                    icon: Icons.share_rounded,
                                    label: 'Share',
                                    color: FurPalsColors.pink,
                                    bgColor: const Color(0xFFFFEEF1),
                                    onTap: () {
                                      _dismiss().then((_) {
                                        widget.onShareTapped();
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _fallbackPreview() {
    return Container(
      height: 160,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [FurPalsColors.blush, FurPalsColors.peach],
        ),
      ),
      child: const Center(
        child: Icon(Icons.pets_rounded, color: Colors.white, size: 48),
      ),
    );
  }
}

// Compact 2-column action button used in the floating overlay
class _FloatingActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color bgColor;
  final VoidCallback onTap;
  final bool isLoading;

  const _FloatingActionBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.bgColor,
    required this.onTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
        ),
        child: isLoading
            ? Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: color,
                  ),
                ),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, color: color, size: 22),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: GoogleFonts.nunito(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _CommentsSheet — real-time comments with StreamBuilder + post ability
// ─────────────────────────────────────────────────────────────────────────────
class _CommentsSheet extends StatefulWidget {
  final String postId;
  final FirebaseFirestore firestore;
  final String currentUid;

  const _CommentsSheet({
    required this.postId,
    required this.firestore,
    required this.currentUid,
  });

  @override
  State<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<_CommentsSheet> {
  final _commentCtrl = TextEditingController();
  bool _posting = false;

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _postComment() async {
    final text = _commentCtrl.text.trim();
    if (text.isEmpty) return;
    setState(() => _posting = true);
    try {
      await widget.firestore
          .collection('posts')
          .doc(widget.postId)
          .collection('comments')
          .add({
            'userId': widget.currentUid,
            'text': text,
            'createdAt': FieldValue.serverTimestamp(),
          });
      await widget.firestore.collection('posts').doc(widget.postId).update({
        'commentCount': FieldValue.increment(1),
      });
      _commentCtrl.clear();
    } catch (_) {}
    setState(() => _posting = false);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: FurPalsColors.warmWhite,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: FurPalsColors.blush,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Comments',
            style: GoogleFonts.baloo2(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: FurPalsColors.textDark,
            ),
          ),
          const Divider(color: Color(0xFFF0E4DC), height: 20),

          // Live comments list
          Flexible(
            child: StreamBuilder<QuerySnapshot>(
              stream: widget.firestore
                  .collection('posts')
                  .doc(widget.postId)
                  .collection('comments')
                  .orderBy('createdAt', descending: false)
                  .snapshots(),
              builder: (_, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(color: FurPalsColors.pink),
                  );
                }
                final docs = snap.data?.docs ?? [];
                if (docs.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.chat_bubble_outline_rounded,
                          size: 48,
                          color: FurPalsColors.blush,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'No comments yet — be the first! 🐾',
                          style: GoogleFonts.nunito(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: FurPalsColors.textMid,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  itemCount: docs.length,
                  itemBuilder: (_, i) {
                    final data = docs[i].data() as Map<String, dynamic>;
                    final isMe = data['userId'] == widget.currentUid;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 34,
                            height: 34,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [
                                  FurPalsColors.pink,
                                  FurPalsColors.pinkLight,
                                ],
                              ),
                            ),
                            child: const Icon(
                              Icons.pets_rounded,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: isMe
                                    ? const Color(0xFFFFEEF1)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: FurPalsColors.blush,
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                data['text'] ?? '',
                                style: GoogleFonts.nunito(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: FurPalsColors.textDark,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // Comment input bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: FurPalsColors.blush,
                        width: 1.5,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    child: TextField(
                      controller: _commentCtrl,
                      decoration: InputDecoration(
                        hintText: 'Write a comment…',
                        hintStyle: GoogleFonts.nunito(
                          color: FurPalsColors.textMid,
                          fontSize: 13,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 10,
                        ),
                      ),
                      style: GoogleFonts.nunito(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: FurPalsColors.textDark,
                      ),
                      onSubmitted: (_) => _postComment(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _posting ? null : _postComment,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: FurPalsColors.pink,
                      shape: BoxShape.circle,
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x55F4738A),
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: _posting
                        ? const Center(
                            child: SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            ),
                          )
                        : const Icon(
                            Icons.send_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _FollowListSheet — with instant local removal on unfollow/follow
// ─────────────────────────────────────────────────────────────────────────────
class _FollowListSheet extends StatefulWidget {
  final FirebaseFirestore firestore;
  final String currentUid;
  final Map<String, dynamic> currentUserProfile;
  final String type; // 'followers' or 'following'
  final VoidCallback onFollowChanged;

  const _FollowListSheet({
    required this.firestore,
    required this.currentUid,
    required this.currentUserProfile,
    required this.type,
    required this.onFollowChanged,
  });

  @override
  State<_FollowListSheet> createState() => _FollowListSheetState();
}

class _FollowListSheetState extends State<_FollowListSheet> {
  List<Map<String, dynamic>> _users = [];
  Set<String> _followingIds = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final snap = await widget.firestore
          .collection('users')
          .doc(widget.currentUid)
          .collection(widget.type)
          .get();

      final followingSnap = await widget.firestore
          .collection('users')
          .doc(widget.currentUid)
          .collection('following')
          .get();
      final followingIds = followingSnap.docs.map((d) => d.id).toSet();

      final futures = snap.docs.map((d) async {
        final uid = d.data()['userId'] as String? ?? d.id;
        try {
          final userDoc = await widget.firestore
              .collection('users')
              .doc(uid)
              .get();
          final data = userDoc.data() ?? {};
          return {
            'userId': uid,
            'fullName': data['fullName'] ?? 'User',
            'username': data['username'] ?? '',
            'photoURL': data['photoURL'],
          };
        } catch (_) {
          return {
            'userId': uid,
            'fullName': 'User',
            'username': '',
            'photoURL': null,
          };
        }
      });

      final results = await Future.wait(futures);
      if (mounted) {
        setState(() {
          _users = results;
          _followingIds = followingIds;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggleFollow(String targetUid) async {
    final myFollowingRef = widget.firestore
        .collection('users')
        .doc(widget.currentUid)
        .collection('following')
        .doc(targetUid);
    final theirFollowerRef = widget.firestore
        .collection('users')
        .doc(targetUid)
        .collection('followers')
        .doc(widget.currentUid);

    try {
      final isFollowing = _followingIds.contains(targetUid);

      if (isFollowing) {
        await myFollowingRef.delete();
        await theirFollowerRef.delete();
        if (mounted) {
          setState(() {
            _followingIds.remove(targetUid);
            _users.removeWhere((u) => u['userId'] == targetUid);
          });
        }
      } else {
        await myFollowingRef.set({
          'userId': targetUid,
          'followedAt': FieldValue.serverTimestamp(),
        });
        await theirFollowerRef.set({
          'userId': widget.currentUid,
          'username': widget.currentUserProfile['username'] ?? '',
          'fullName': widget.currentUserProfile['fullName'] ?? '',
          'followedAt': FieldValue.serverTimestamp(),
        });

        // Send follow notification
        await NotificationService.sendFollowNotification(
          toUserId: targetUid,
          fromUserId: widget.currentUid,
          fromUsername: widget.currentUserProfile['username'] ?? 'Someone',
        );

        if (mounted) {
          setState(() {
            _followingIds.add(targetUid);
            _users.removeWhere((u) => u['userId'] == targetUid);
          });
        }
      }

      widget.onFollowChanged();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Something went wrong',
              style: GoogleFonts.nunito(fontWeight: FontWeight.w700),
            ),
            backgroundColor: FurPalsColors.heartRed,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.type == 'followers' ? 'Followers' : 'Following';

    return Container(
      decoration: const BoxDecoration(
        color: FurPalsColors.warmWhite,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.65,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: FurPalsColors.blush,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: GoogleFonts.baloo2(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: FurPalsColors.textDark,
            ),
          ),
          const SizedBox(height: 8),
          const Divider(color: Color(0xFFF0E4DC), height: 1),
          _loading
              ? const Padding(
                  padding: EdgeInsets.all(40),
                  child: CircularProgressIndicator(color: FurPalsColors.pink),
                )
              : _users.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(40),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.people_outline_rounded,
                        size: 48,
                        color: FurPalsColors.blush,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        widget.type == 'followers'
                            ? 'No followers yet'
                            : 'Not following anyone yet',
                        style: GoogleFonts.nunito(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: FurPalsColors.textMid,
                        ),
                      ),
                    ],
                  ),
                )
              : Flexible(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _users.length,
                    itemBuilder: (_, i) {
                      final u = _users[i];
                      final photo = u['photoURL'] as String?;
                      final uid = u['userId'] as String;
                      final isFollowing = _followingIds.contains(uid);

                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 4,
                        ),
                        leading: Container(
                          width: 46,
                          height: 46,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [
                                FurPalsColors.pink,
                                FurPalsColors.pinkLight,
                              ],
                            ),
                          ),
                          child: photo != null && photo.isNotEmpty
                              ? ClipOval(
                                  child: Image.network(
                                    photo,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : const Icon(
                                  Icons.pets_rounded,
                                  color: Colors.white,
                                  size: 22,
                                ),
                        ),
                        title: Text(
                          u['fullName'] ?? 'User',
                          style: GoogleFonts.nunito(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: FurPalsColors.textDark,
                          ),
                        ),
                        subtitle: u['username'] != ''
                            ? Text(
                                '@${u['username']}',
                                style: GoogleFonts.nunito(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: FurPalsColors.pink,
                                ),
                              )
                            : null,
                        trailing: uid != widget.currentUid
                            ? GestureDetector(
                                onTap: () => _toggleFollow(uid),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 7,
                                  ),
                                  decoration: BoxDecoration(
                                    color: widget.type == 'following'
                                        ? FurPalsColors.blush
                                        : (isFollowing
                                              ? FurPalsColors.blush
                                              : FurPalsColors.pink),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: FurPalsColors.pink,
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Text(
                                    widget.type == 'following'
                                        ? 'Unfollow'
                                        : (isFollowing
                                              ? 'Following'
                                              : 'Follow'),
                                    style: GoogleFonts.nunito(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: widget.type == 'following'
                                          ? FurPalsColors.pink
                                          : (isFollowing
                                                ? FurPalsColors.pink
                                                : Colors.white),
                                    ),
                                  ),
                                ),
                              )
                            : const SizedBox.shrink(),
                      );
                    },
                  ),
                ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _SuggestionCard
// ─────────────────────────────────────────────────────────────────────────────
class _SuggestionCard extends StatefulWidget {
  final String userId;
  final String fullName;
  final String username;
  final String? photoURL;
  final VoidCallback onFollow;

  const _SuggestionCard({
    required this.userId,
    required this.fullName,
    required this.username,
    required this.photoURL,
    required this.onFollow,
  });

  @override
  State<_SuggestionCard> createState() => _SuggestionCardState();
}

class _SuggestionCardState extends State<_SuggestionCard> {
  bool _following = false;

  final _colorPairs = const [
    [FurPalsColors.blush, FurPalsColors.peach],
    [FurPalsColors.mint, FurPalsColors.lavender],
    [FurPalsColors.butter, FurPalsColors.blush],
  ];

  @override
  Widget build(BuildContext context) {
    final pair = _colorPairs[widget.userId.hashCode.abs() % _colorPairs.length];

    return Container(
      width: 90,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: FurPalsColors.blush, width: 1),
        boxShadow: const [
          BoxShadow(
            color: FurPalsColors.shadow,
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(colors: [pair[0], pair[1]]),
            ),
            child: widget.photoURL != null && widget.photoURL!.isNotEmpty
                ? ClipOval(
                    child: Image.network(widget.photoURL!, fit: BoxFit.cover),
                  )
                : const Center(
                    child: Icon(
                      Icons.pets_rounded,
                      color: FurPalsColors.pink,
                      size: 22,
                    ),
                  ),
          ),
          const SizedBox(height: 5),
          Text(
            widget.fullName,
            style: GoogleFonts.nunito(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: FurPalsColors.textDark,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 5),
          GestureDetector(
            onTap: () {
              setState(() => _following = !_following);
              widget.onFollow();
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 5),
              decoration: BoxDecoration(
                color: _following ? FurPalsColors.blush : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: FurPalsColors.pink, width: 1.5),
              ),
              child: Center(
                child: Text(
                  _following ? 'Following' : 'Follow',
                  style: GoogleFonts.nunito(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: FurPalsColors.pink,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PetsPagePlaceholder
// ─────────────────────────────────────────────────────────────────────────────
class PetsPagePlaceholder extends StatelessWidget {
  const PetsPagePlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: appBackgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const myPetsScreen()),
                      ),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: const [
                            BoxShadow(
                              color: FurPalsColors.shadow,
                              blurRadius: 10,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: 18,
                          color: FurPalsColors.textDark,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'My Pets',
                      style: GoogleFonts.baloo2(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: FurPalsColors.textDark,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.cruelty_free_rounded,
                        size: 72,
                        color: FurPalsColors.pink,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Your Pets',
                        style: GoogleFonts.baloo2(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: FurPalsColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Add your pets to show them here',
                        style: GoogleFonts.nunito(
                          fontSize: 14,
                          color: FurPalsColors.textMid,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
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
