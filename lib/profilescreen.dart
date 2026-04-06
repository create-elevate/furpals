import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

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
  const ProfileScreen({super.key});

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
  List<Map<String, dynamic>> _suggestions = [];
  int _postCount = 0;
  int _followerCount = 0;
  int _followingCount = 0;

  String get _currentUid => _auth.currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadPosts();
    _loadSuggestions();
  }

  Future<void> _loadProfile() async {
    if (_currentUid.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      final doc = await _firestore.collection('users').doc(_currentUid).get();
      final data = doc.data() ?? {};
      final followersSnap = await _firestore
          .collection('users')
          .doc(_currentUid)
          .collection('followers')
          .get();
      final followingSnap = await _firestore
          .collection('users')
          .doc(_currentUid)
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
    if (_currentUid.isEmpty) return;
    try {
      final snap = await _firestore
          .collection('posts')
          .where('userId', isEqualTo: _currentUid)
          .orderBy('createdAt', descending: true)
          .get();
      if (mounted) {
        setState(() {
          _posts = snap.docs.map((d) => d.data()).toList();
          _postCount = snap.docs.length;
        });
      }
    } catch (_) {
      try {
        final snap = await _firestore
            .collection('posts')
            .where('userId', isEqualTo: _currentUid)
            .get();
        if (mounted) {
          setState(() {
            _posts = snap.docs.map((d) => d.data()).toList();
            _postCount = snap.docs.length;
          });
        }
      } catch (_) {}
    }
  }

  Future<void> _loadSuggestions() async {
    if (_currentUid.isEmpty) return;
    try {
      final snap = await _firestore.collection('users').limit(20).get();
      if (mounted) {
        final filtered = snap.docs
            .where((d) => d.id != _currentUid)
            .map((d) => {'userId': d.id, ...d.data()})
            .take(10)
            .toList();
        setState(() {
          _suggestions = filtered;
        });
      }
    } catch (_) {}
  }

  void _showFollowListSheet(String type) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FollowListSheet(
        firestore: _firestore,
        currentUid: _currentUid,
        type: type,
      ),
    );
  }

  Future<void> _pickAndUploadAvatar() async {
    try {
      final file =
          await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
      if (file == null) return;
      final imageFile = File(file.path);
      if (!imageFile.existsSync()) {
        _showSnack('Could not read image file', FurPalsColors.heartRed);
        return;
      }
      setState(() => _isLoading = true);
      final ref = _storage.ref().child('avatars/$_currentUid.jpg');
      final uploadTask = ref.putFile(
        imageFile,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      await uploadTask;
      final url = await ref.getDownloadURL();
      await _firestore
          .collection('users')
          .doc(_currentUid)
          .update({'photoURL': url});
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
            FurPalsColors.heartRed);
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
      if (doc.exists) {
        await myFollowingRef.delete();
        await theirFollowerRef.delete();
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
      }
      _loadSuggestions();
      _loadProfile();
    } catch (_) {
      _showSnack('Something went wrong', FurPalsColors.heartRed);
    }
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg,
            style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showEditProfileSheet() {
    final nameCtrl =
        TextEditingController(text: _profileData['fullName'] ?? '');
    final bioCtrl = TextEditingController(text: _profileData['bio'] ?? '');
    final locCtrl =
        TextEditingController(text: _profileData['location'] ?? '');
    bool saving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            decoration: const BoxDecoration(
              color: FurPalsColors.warmWhite,
              borderRadius:
                  BorderRadius.vertical(top: Radius.circular(28)),
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
                      borderRadius: BorderRadius.circular(2)),
                ),
                const SizedBox(height: 16),
                Text('Edit Profile',
                    style: GoogleFonts.baloo2(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: FurPalsColors.textDark)),
                const SizedBox(height: 20),
                _editField(nameCtrl, 'Full Name', Icons.person_rounded),
                const SizedBox(height: 12),
                _editField(bioCtrl, 'Bio', Icons.notes_rounded),
                const SizedBox(height: 12),
                _editField(
                    locCtrl, 'Location', Icons.location_on_rounded),
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
                            await _auth.currentUser
                                ?.updateDisplayName(nameCtrl.text.trim());
                            if (mounted) {
                              setState(() {
                                _profileData['fullName'] =
                                    nameCtrl.text.trim();
                                _profileData['bio'] = bioCtrl.text.trim();
                                _profileData['location'] =
                                    locCtrl.text.trim();
                              });
                              Navigator.pop(ctx);
                              _showSnack(
                                  'Profile updated', FurPalsColors.green);
                            }
                          } catch (_) {
                            _showSnack('Failed to update',
                                FurPalsColors.heartRed);
                          }
                          setModal(() => saving = false);
                        },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: const LinearGradient(colors: [
                        FurPalsColors.pink,
                        FurPalsColors.pinkLight
                      ]),
                      boxShadow: const [
                        BoxShadow(
                            color: Color(0x55F4738A),
                            blurRadius: 14,
                            offset: Offset(0, 6))
                      ],
                    ),
                    child: Center(
                      child: saving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : Text('Save Changes',
                              style: GoogleFonts.baloo2(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white)),
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

  Widget _editField(
      TextEditingController ctrl, String hint, IconData icon) {
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
                    color: FurPalsColors.textMid, fontSize: 13),
                border: InputBorder.none,
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 10),
              ),
              style: GoogleFonts.nunito(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: FurPalsColors.textDark),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fullName = _profileData['fullName'] ??
        _auth.currentUser?.displayName ??
        'Pet Name';
    final username = _profileData['username'] ?? 'username';
    final bio = _profileData['bio'] ?? '';
    final location =
        _profileData['location'] ?? 'Manila, Philippines';
    final photoURL = _profileData['photoURL'] as String?;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: [0.0, 0.5, 1.0],
            colors: [
              Color(0xFFFCDDE8),
              Color(0xFFFFE8D2),
              Color(0xFFD4F0E4)
            ],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                      color: FurPalsColors.pink))
              : DecoratedBox(
                  decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.45)),
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        _buildHeader(
                            fullName, username, bio, location, photoURL),
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

  Widget _buildHeader(String fullName, String username, String bio,
      String location, String? photoURL) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: _pickAndUploadAvatar,
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
                            FurPalsColors.pink
                          ],
                        ),
                      ),
                      padding: const EdgeInsets.all(3),
                      child: Container(
                        decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: FurPalsColors.cream),
                        child: photoURL != null && photoURL.isNotEmpty
                            ? ClipOval(
                                child: Image.network(photoURL,
                                    fit: BoxFit.cover,
                                    width: 84,
                                    height: 84))
                            : const Center(
                                child: Icon(Icons.pets_rounded,
                                    size: 40,
                                    color: FurPalsColors.pink)),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: FurPalsColors.pink,
                          shape: BoxShape.circle,
                          border:
                              Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(Icons.add_rounded,
                            color: Colors.white, size: 16),
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
                    _statItem(_postCount.toString(), 'Posts',
                        onTap: null),
                    _statItem(
                        _formatCount(_followerCount), 'Followers',
                        onTap: () => _showFollowListSheet('followers')),
                    _statItem(
                        _formatCount(_followingCount), 'Following',
                        onTap: () => _showFollowListSheet('following')),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(fullName,
              style: GoogleFonts.baloo2(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: FurPalsColors.textDark)),
          const SizedBox(height: 2),
          RichText(
            text: TextSpan(
              style: GoogleFonts.nunito(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: FurPalsColors.textMid),
              children: [
                const TextSpan(text: 'Owner: '),
                TextSpan(
                    text: '@$username',
                    style:
                        const TextStyle(color: FurPalsColors.pink)),
              ],
            ),
          ),
          if (bio.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(bio,
                style: GoogleFonts.nunito(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: FurPalsColors.textDark)),
          ],
          if (location.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.location_on_rounded,
                    size: 13, color: FurPalsColors.pink),
                const SizedBox(width: 3),
                Text(location,
                    style: GoogleFonts.nunito(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: FurPalsColors.textMid)),
              ],
            ),
          ],
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _statItem(String value, String label,
      {VoidCallback? onTap}) {
    final content = Column(
      children: [
        Text(value,
            style: GoogleFonts.baloo2(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: FurPalsColors.textDark)),
        const SizedBox(height: 2),
        Text(label,
            style: GoogleFonts.nunito(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: FurPalsColors.textMid)),
      ],
    );

    if (onTap == null) return content;
    return GestureDetector(onTap: onTap, child: content);
  }

  Widget _buildActionButtons() {
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
                  border: Border.all(
                      color: FurPalsColors.pink, width: 1.5),
                  boxShadow: const [
                    BoxShadow(
                        color: FurPalsColors.shadow,
                        blurRadius: 6,
                        offset: Offset(0, 2))
                  ],
                ),
                child: Center(
                  child: Text('Edit Profile',
                      style: GoogleFonts.nunito(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: FurPalsColors.pink)),
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
                  border: Border.all(
                      color: FurPalsColors.pink, width: 1.5),
                  boxShadow: const [
                    BoxShadow(
                        color: FurPalsColors.shadow,
                        blurRadius: 6,
                        offset: Offset(0, 2))
                  ],
                ),
                child: Center(
                  child: Text('Share Profile',
                      style: GoogleFonts.nunito(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: FurPalsColors.pink)),
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
                      offset: Offset(0, 2))
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: GestureDetector(
        onTap: () {
          Navigator.push(context,
              MaterialPageRoute(builder: (_) => const PetsPagePlaceholder()));
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
                  offset: Offset(0, 6))
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.cruelty_free_rounded,
                  color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text('My Pets',
                  style: GoogleFonts.baloo2(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Colors.white)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestions() {
    if (_suggestions.isEmpty) return const SizedBox.shrink();

    return AnimatedCrossFade(
      firstChild: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
            child: Text('Suggested Friends',
                style: GoogleFonts.baloo2(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: FurPalsColors.textMid)),
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
                _buildEmptyTab(Icons.videocam_rounded, 'No videos yet'),
                _buildEmptyTab(
                    Icons.bookmark_rounded, 'No saved posts'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostGrid() {
    if (_posts.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.pets_rounded,
                size: 48, color: FurPalsColors.blush),
            const SizedBox(height: 12),
            Text('No posts yet',
                style: GoogleFonts.baloo2(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: FurPalsColors.textDark)),
            const SizedBox(height: 4),
            Text('Share your first moment',
                style: GoogleFonts.nunito(
                    fontSize: 13,
                    color: FurPalsColors.textMid,
                    fontWeight: FontWeight.w600)),
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

    return GridView.builder(
      padding: EdgeInsets.zero,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
      ),
      itemCount: _posts.length,
      itemBuilder: (_, i) {
        final post = _posts[i];
        final mediaURL = post['mediaURL'] as String? ?? '';
        final mediaType = post['mediaType'] as String? ?? 'none';
        final pair = colorPairs[i % colorPairs.length];

        if (mediaURL.isNotEmpty && mediaType == 'photo') {
          return Image.network(mediaURL,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _gridPlaceholder(pair));
        }
        return Stack(
          fit: StackFit.expand,
          children: [
            _gridPlaceholder(pair),
            if (mediaType == 'video')
              const Center(
                  child: Icon(Icons.play_circle_rounded,
                      color: Colors.white70, size: 32)),
          ],
        );
      },
    );
  }

  Widget _gridPlaceholder(List<Color> pair) {
    return Container(
      decoration:
          BoxDecoration(gradient: LinearGradient(colors: pair)),
      child: const Center(
          child: Icon(Icons.pets_rounded,
              color: Colors.white54, size: 28)),
    );
  }

  Widget _buildEmptyTab(IconData icon, String msg) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 44, color: FurPalsColors.blush),
          const SizedBox(height: 10),
          Text(msg,
              style: GoogleFonts.nunito(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: FurPalsColors.textMid)),
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

class _FollowListSheet extends StatefulWidget {
  final FirebaseFirestore firestore;
  final String currentUid;
  final String type; // 'followers' or 'following'

  const _FollowListSheet({
    required this.firestore,
    required this.currentUid,
    required this.type,
  });

  @override
  State<_FollowListSheet> createState() => _FollowListSheetState();
}

class _FollowListSheetState extends State<_FollowListSheet> {
  List<Map<String, dynamic>> _users = [];
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
          .collection(widget.type) // 'followers' or 'following'
          .get();

      // Each doc has at minimum a userId field; fetch display info
      final futures = snap.docs.map((d) async {
        final uid = d.data()['userId'] as String? ?? d.id;
        try {
          final userDoc =
              await widget.firestore.collection('users').doc(uid).get();
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
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title =
        widget.type == 'followers' ? 'Followers' : 'Following';

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
          // Handle
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
                color: FurPalsColors.blush,
                borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 14),
          // Title
          Text(title,
              style: GoogleFonts.baloo2(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: FurPalsColors.textDark)),
          const SizedBox(height: 8),
          const Divider(color: Color(0xFFF0E4DC), height: 1),
          // List
          _loading
              ? const Padding(
                  padding: EdgeInsets.all(40),
                  child: CircularProgressIndicator(
                      color: FurPalsColors.pink),
                )
              : _users.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(40),
                      child: Column(
                        children: [
                          const Icon(Icons.people_outline_rounded,
                              size: 48, color: FurPalsColors.blush),
                          const SizedBox(height: 10),
                          Text(
                            widget.type == 'followers'
                                ? 'No followers yet'
                                : 'Not following anyone yet',
                            style: GoogleFonts.nunito(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: FurPalsColors.textMid),
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
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 4),
                            leading: Container(
                              width: 46,
                              height: 46,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(colors: [
                                  FurPalsColors.pink,
                                  FurPalsColors.pinkLight
                                ]),
                              ),
                              child: photo != null && photo.isNotEmpty
                                  ? ClipOval(
                                      child: Image.network(photo,
                                          fit: BoxFit.cover))
                                  : const Icon(Icons.pets_rounded,
                                      color: Colors.white, size: 22),
                            ),
                            title: Text(
                              u['fullName'] ?? 'User',
                              style: GoogleFonts.nunito(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: FurPalsColors.textDark),
                            ),
                            subtitle: u['username'] != ''
                                ? Text(
                                    '@${u['username']}',
                                    style: GoogleFonts.nunito(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: FurPalsColors.pink),
                                  )
                                : null,
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
    final pair =
        _colorPairs[widget.userId.hashCode.abs() % _colorPairs.length];

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
              offset: Offset(0, 2))
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
              gradient:
                  LinearGradient(colors: [pair[0], pair[1]]),
            ),
            child: widget.photoURL != null &&
                    widget.photoURL!.isNotEmpty
                ? ClipOval(
                    child: Image.network(widget.photoURL!,
                        fit: BoxFit.cover))
                : const Center(
                    child: Icon(Icons.pets_rounded,
                        color: FurPalsColors.pink, size: 22)),
          ),
          const SizedBox(height: 5),
          Text(
            widget.fullName,
            style: GoogleFonts.nunito(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: FurPalsColors.textDark),
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
                color: _following
                    ? FurPalsColors.blush
                    : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: FurPalsColors.pink, width: 1.5),
              ),
              child: Center(
                child: Text(
                  _following ? 'Following' : 'Follow',
                  style: GoogleFonts.nunito(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: FurPalsColors.pink),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PetsPagePlaceholder extends StatelessWidget {
  const PetsPagePlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration:
            const BoxDecoration(gradient: appBackgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
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
                                offset: Offset(0, 3))
                          ],
                        ),
                        child: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            size: 18,
                            color: FurPalsColors.textDark),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text('My Pets',
                        style: GoogleFonts.baloo2(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: FurPalsColors.textDark)),
                  ],
                ),
              ),
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.cruelty_free_rounded,
                          size: 72, color: FurPalsColors.pink),
                      const SizedBox(height: 16),
                      Text('Your Pets',
                          style: GoogleFonts.baloo2(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: FurPalsColors.textDark)),
                      const SizedBox(height: 6),
                      Text('Add your pets to show them here',
                          style: GoogleFonts.nunito(
                              fontSize: 14,
                              color: FurPalsColors.textMid,
                              fontWeight: FontWeight.w600)),
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