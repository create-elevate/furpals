import 'package:flutter/material.dart';
import 'package:furpals/NotificationScreen.dart';
import 'package:google_fonts/google_fonts.dart';

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
  static const textSoft    = Color(0x33000000); // d ko pa na aaayos yung sa nav icon teh lyka pero yan muna icon gamitin
  static const pink        = Color(0xFFF4738A); 
  static const pinkLight   = Color(0xFFFF9AB0);
  static const green       = Color(0xFF5DB87A);
  static const purple      = Color(0xFF8B6FD4);
  static const shadow      = Color(0x20B47864);
  static const creamwhite  = Color(0xFFF9E9D5);
  static const blue        = Color(0xFF448AFF);
  static const onlineGreen = Color(0xFF4CAF50);
  static const offlineGray = Color(0xFFBDBDBD);
  static const heartRed    = Color(0xFFE53935); 
  static const black100    = Color(0xFF000000); 
}

// The background gradient 
const appBackgroundGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  stops: [0.0, 0.5, 1.0], 
  colors: [
    Color(0xFFFCDDE8), 
    Color(0xFFFFE8D2),
    Color(0xFFD4F0E4), 
  ],
);

class Homescreen extends StatelessWidget {
  const Homescreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(fontFamily: GoogleFonts.nunito().fontFamily),
      home: const MainShell(),
    );
  }
}
// main shell wrapper that holds the bottom nav bar and swaps screens
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  // Tracks which tab the user is on 
  int _selectedNav = 1;

  void _onNavTap(int i) {
    // post pop up
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

  // Returns the correct screen based on which tab is selected
  Widget _currentBody() {
    switch (_selectedNav) {
      case 0:
        return const LostFoundBody();
      case 3:
        return const PetsBody();
      case 4:
        return const ProfileBody();
      default:
        return HomeBody(onNavTap: _onNavTap);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const FurPalsDrawer(), // Side menu that slides in
      bottomNavigationBar: _FlatBottomNav(
        selectedIndex: _selectedNav,
        onTap: _onNavTap,
      ),
      body: _currentBody(),
    );
  }
}

// btn navi designs
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
      decoration: const BoxDecoration( // navi box frame
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
          final isPost   = i == 2;
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
                          // post btn
                          ? Container(
                              width: 44, height: 44,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [FurPalsColors.pink, FurPalsColors.pinkLight], // btn add bg
                                ),
                                boxShadow: const [ // add shadow
                                  BoxShadow(color: Color(0x55F4738A), blurRadius: 14, offset: Offset(0, 4)),
                                ],
                              ), //add post
                              child: const Icon(Icons.add_rounded, color: Colors.white, size: 26),
                            )
                          // if not selected light penk
                          : AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: isActive ? FurPalsColors.blush : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                _icons[i], size: 22,
                                // if selcted it will turn to penk
                                color: isActive ? FurPalsColors.pink : FurPalsColors.pink.withOpacity(0.4),
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 3),
                  // bottom navi design 
                  Text(
                    _labels[i],
                    style: GoogleFonts.nunito(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: isPost
                          ? FurPalsColors.pink
                          : isActive ? FurPalsColors.pink : FurPalsColors.textDark.withOpacity(0.4),
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

// flyout box
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
            colors: [
              Color(0xFFFDEBEC), 
              Color(0xFFFDEBEC), 
              Color(0xFFFFFFFF), 
              Color(0xFFFFFFFF), 
            ],
          ),
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(32),
            bottomRight: Radius.circular(32),
          ),
          boxShadow: [BoxShadow(color: Color(0x25B47864), blurRadius: 32, offset: Offset(8, 0))],
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 30 ),  // User profile section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    // pofile flyout
                    Container(
                      width: 60,
                      height: 60,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [FurPalsColors.blush, FurPalsColors.peach],
                        ),
                      ),
                      child: const Center(
                        child: Text('🐾', style: TextStyle(fontSize: 30)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Full Name', // profile flyout Name
                          style: GoogleFonts.baloo2(
                            fontSize: 25,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF4A3728), // profile flyout name color
                            height: 1.1,
                          ),
                        ),
                        Text(
                          '@mickaluvsyou',
                          style: GoogleFonts.nunito(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: const Color(0x40000000), // username flyout
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ), // btn navigation flyout
              const SizedBox(height: 30),
              _pill(context, Icons.settings_rounded,     'Settings',       () => Navigator.pop(context)),
              const SizedBox(height: 12),
              _pill(context, Icons.bookmark_rounded,     'Saved Posts',    () => Navigator.pop(context)),
              const SizedBox(height: 12),
              _pill(context, Icons.info_outline_rounded, 'About',          () => Navigator.pop(context)),
              const SizedBox(height: 12),
              _pill(context, Icons.help_outline_rounded, 'Help & Support', () => Navigator.pop(context)),
              const Spacer(),
              // Log out button
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pushNamed('/login'),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFDE0E6),
                      borderRadius: BorderRadius.circular(50),
                      border: Border.all(color: FurPalsColors.pinkLight.withOpacity(0.5), width: 1.5),
                      boxShadow: const [BoxShadow(color: Color(0x20F4738A), blurRadius: 10, offset: Offset(0, 4))],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.logout_rounded, color: FurPalsColors.pink, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'LOG OUT', // log out
                          style: GoogleFonts.nunito(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            color: FurPalsColors.pink,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pill(BuildContext context, IconData icon, String label, VoidCallback onTap) { // flyout design btns
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 350,
          height: 50,// btn flyout size
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: const Color(0xFFFBEDE4),
            borderRadius: BorderRadius.circular(50),
            boxShadow: const [BoxShadow(color: Colors.grey,blurRadius: 3, offset: Offset(0, 3))],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              //icon flyout
              Icon(icon, size: 30, color: Colors.black),
              const SizedBox(width: 12),
              Text( // flyout label
                label,
                style: GoogleFonts.baloo2(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF4A3728),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void _showPostOptionsMenu(BuildContext context, String username) {
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
          // Drag handle for the options modal
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: FurPalsColors.blush,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          // Save Post option button
          _PostOptionTile(
            icon: Icons.bookmark_add_rounded,
            iconColor: FurPalsColors.purple,
            iconBg: FurPalsColors.lavender,
            label: 'Save Post',
            onTap: () {
              Navigator.pop(context);
              // Show confirmation snackbar after saving
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Post saved!',
                      style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
                  backgroundColor: FurPalsColors.purple,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          // Report Post option button
          _PostOptionTile(
            icon: Icons.flag_rounded,
            iconColor: FurPalsColors.heartRed,
            iconBg: const Color(0xFFFFE4E4),
            label: 'Report Post',
            onTap: () {
              Navigator.pop(context);
              // Show report confirmation dialog after tapping report
              _showReportDialog(context, username);
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
}

// tile widget used inside the post options modal
class _PostOptionTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
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
  Widget build(BuildContext context) { // 3 dot selection frame
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [BoxShadow(color: FurPalsColors.shadow, blurRadius: 6, offset: Offset(0, 2))],
        ),
        child: Row(
          children: [
            // 3dot menu in post card
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Text(label,
                style: GoogleFonts.nunito(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: FurPalsColors.textDark,
                )),
          ],
        ),
      ),
    );
  }
}

// Report confirmation dialog 
void _showReportDialog(BuildContext context, String username) {
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      backgroundColor: FurPalsColors.warmWhite,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text('Report Post',
          style: GoogleFonts.baloo2(
            fontSize: 18, fontWeight: FontWeight.w800, color: FurPalsColors.textDark,
          )),
      content: Text(
        "Are you sure you want to report $username's post? We'll review it shortly.",
        style: GoogleFonts.nunito(fontSize: 13, color: FurPalsColors.textMid),
      ),
      actions: [
        // Cancel btn
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel',
              style: GoogleFonts.nunito(fontWeight: FontWeight.w700, color: FurPalsColors.textMid)),
        ),
        // Confirm btn
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

void _showWhoLikedModal(BuildContext context, String likeCount) {
  // Sample data like post
  final likers = [
    {'emoji': '🐱', 'name': 'luna.meows',    'display': 'Luna Cat'},
    {'emoji': '🐶', 'name': 'buddydog',      'display': 'Buddy Boy'},
    {'emoji': '🐰', 'name': 'cocorabbit',    'display': 'Coco Bunny'},
    {'emoji': '🐾', 'name': 'mochipaws',     'display': 'Mochi'},
    {'emoji': '🦮', 'name': 'daisywalks',    'display': 'Daisy Guide'},
    {'emoji': '🐹', 'name': 'peanuthamster', 'display': 'Peanut Ham'},
  ];

  showModalBottomSheet(
    context: context, // modal sheet for likes list
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
              decoration: BoxDecoration(
                color: FurPalsColors.blush, borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            // total likes
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  const Icon(Icons.favorite_rounded, color: FurPalsColors.heartRed, size: 20),
                  const SizedBox(width: 8),
                  Text('$likeCount Likes',
                      style: GoogleFonts.baloo2(
                        fontSize: 18, fontWeight: FontWeight.w800, color: FurPalsColors.textDark,
                      )),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Divider(height: 1, color: Color(0xFFF0E4DC)),
            // list of users who liked (scrooll function)
            Expanded(
              child: ListView.separated(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                itemCount: likers.length,
                separatorBuilder: (_, _) => const SizedBox(height: 4),
                itemBuilder: (_, i) {
                  final user = likers[i];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    // Avatar user (for testing only)
                    leading: Container(
                      width: 46, height: 46,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(colors: [FurPalsColors.blush, FurPalsColors.peach]),
                      ),
                      child: Center(child: Text(user['emoji']!, style: const TextStyle(fontSize: 22))),
                    ),
                    title: Text(user['display']!,
                        style: GoogleFonts.baloo2(
                          fontSize: 14, fontWeight: FontWeight.w800, color: FurPalsColors.textDark,
                        )),
                    subtitle: Text('@${user['name']}',
                        style: GoogleFonts.nunito(
                          fontSize: 12, color: FurPalsColors.textMid, fontWeight: FontWeight.w600,
                        )),
                    // Follow btn
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: FurPalsColors.blush,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text('Follow',
                          style: GoogleFonts.nunito(
                            fontSize: 12, fontWeight: FontWeight.w800, color: FurPalsColors.pink,
                          )),
                    ),
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

//comment list 
void _showCommentsModal(BuildContext context, String commentCount) {
  // Sample for comments data
  final comments = [
    {'emoji': '🐱', 'name': 'luna.meows',  'text': 'So cute!! 😍🐾',           'time': '2m'},
    {'emoji': '🐶', 'name': 'buddydog',    'text': 'Best post ever 🐶❤️',       'time': '5m'},
    {'emoji': '🐰', 'name': 'cocorabbit',  'text': 'Awww I love this so much!', 'time': '10m'},
    {'emoji': '🐾', 'name': 'mochipaws',   'text': 'My heart 🥺💕',             'time': '15m'},
    {'emoji': '🦮', 'name': 'daisywalks',  'text': 'Goals honestly 🌿',         'time': '20m'},
  ];

  showModalBottomSheet( // comment frame design
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => DraggableScrollableSheet(
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
              decoration: BoxDecoration(
                color: FurPalsColors.blush, borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            // total comment
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  const Icon(Icons.chat_bubble_rounded, color: FurPalsColors.pink, size: 20),
                  const SizedBox(width: 8),
                  Text('$commentCount Comments',
                      style: GoogleFonts.baloo2(
                        fontSize: 18, fontWeight: FontWeight.w800, color: FurPalsColors.textDark,
                      )),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Divider(height: 1, color: Color(0xFFF0E4DC)),
            // list of comments
            Expanded(
              child: ListView.separated(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                itemCount: comments.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (_, i) {
                  final c = comments[i];
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Commenter avatar 
                      Container(
                        width: 38, height: 38,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(colors: [FurPalsColors.mint, FurPalsColors.lavender]),
                        ),
                        child: Center(child: Text(c['emoji']!, style: const TextStyle(fontSize: 18))),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                // Commenter username
                                Text('@${c['name']}',
                                    style: GoogleFonts.nunito(
                                      fontSize: 12, fontWeight: FontWeight.w800, color: FurPalsColors.textDark,
                                    )),
                                const SizedBox(width: 6),
                                // Time label in comment
                                Text(c['time']!,
                                    style: GoogleFonts.nunito(
                                      fontSize: 10, color: FurPalsColors.textMid,
                                    )),
                              ],
                            ),
                            const SizedBox(height: 2),
                            // Comment text bubble
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: FurPalsColors.warmWhite,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(c['text']!,
                                  style: GoogleFonts.nunito(
                                    fontSize: 13, color: FurPalsColors.textDark, fontWeight: FontWeight.w600,
                                  )),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            const Divider(height: 1, color: Color(0xFFF0E4DC)),
            // Comment input bar 
            Padding(
              padding: EdgeInsets.fromLTRB(16, 10, 16, MediaQuery.of(context).viewInsets.bottom + 16),
              child: Row(
                children: [
                  // Current user avatar beside input bar comment
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
                        decoration: InputDecoration(
                          hintText: 'Add a comment...', // comment input hint
                          hintStyle: GoogleFonts.nunito(
                            color: FurPalsColors.textSoft, fontSize: 13,
                          ),
                          border: InputBorder.none, isDense: true,
                          contentPadding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                        style: GoogleFonts.nunito(
                          fontSize: 13, color: FurPalsColors.black100, fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Send button for the comment 
                  Container(
                    width: 38, height: 38,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [FurPalsColors.pink, FurPalsColors.pinkLight]),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
// share frame
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
  // selected audience 
  String _audience = 'Feed';
  // selected privacy 
  String _privacy  = 'Only me';

  // Audience options 
  static const _audienceOptions = ['Feed', 'Friends', 'Public'];
  // Privacy options 
  static const _privacyOptions  = ['Only me', 'Friends', 'Everyone'];

 final List<Map<String, dynamic>> _platforms = [ // icon share icons
  // Row 1
  {'label': 'WhatsApp',  'color': const Color(0xFF93E67F), 'icon': Icons.chat_rounded},
  {'label': 'Messenger', 'color': const Color(0xFF1163EC), 'icon': Icons.send_rounded},
  {'label': 'Facebook',  'color': const Color(0xFF1877F2), 'icon': Icons.facebook_sharp},
  {'label': 'Threads',   'color': const Color(0xFF000000), 'icon': Icons.alternate_email_rounded},
  {'label': 'X',         'color': const Color(0xFF000000), 'icon': Icons.close_rounded},
  // Row 2
  {'label': 'Instagram', 'color': const Color(0xFFF4738A), 'icon': Icons.camera_alt_rounded},
  {'label': 'IG Story',  'color': const Color(0xFFF4738A), 'icon': Icons.add_circle_outline},
  {'label': 'Copy Link', 'color': const Color(0xFFBBB2CF), 'icon': Icons.link_rounded},
  {'label': 'SMS',       'color': const Color(0xFFD4F0E4), 'icon': Icons.sms_rounded},
  {'label': 'Email',     'color': const Color(0xFFFF383C), 'icon': Icons.email_rounded},
];
  @override
  Widget build(BuildContext context) { // share frame design
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
              decoration: BoxDecoration(
                color: FurPalsColors.blush,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 14), // whole content height
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Container( // avatar user
                  width: 44, height: 44,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [FurPalsColors.blush, FurPalsColors.peach],
                    ),
                  ),
                  child: const Center(child: Text('🐾', style: TextStyle(fontSize: 22))),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mickaluvsyou', // username
                      style: GoogleFonts.baloo2(
                        fontSize: 15, fontWeight: FontWeight.w800, color: FurPalsColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _ShareDropdownPill( // the options fuctions
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

          //Say something... Caption
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 1),
            child: TextField(
              maxLines: 2,
              style: GoogleFonts.nunito(
                fontSize: 14, color: FurPalsColors.textDark, fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                hintText: 'Say something...',
                hintStyle: GoogleFonts.nunito(
                  fontSize: 14, color: FurPalsColors.textSoft, fontWeight: FontWeight.w500,
                ),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),

          // snack bar post shared
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
                child: Container( // share now btn
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
                  decoration: BoxDecoration(
                    color: FurPalsColors.blue,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Share now',
                    style: GoogleFonts.nunito(
                      fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),

          const Divider(height: 1, color: Color(0xFFF0E4DC)),
          const SizedBox(height: 15), // line devider share part

          Padding(  
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                _buildPlatformRow(context, _platforms.sublist(0, 5)), // first row
                const SizedBox(height: 16),
                _buildPlatformRow(context, _platforms.sublist(5)),// 2nd row
              ],
            ),
          ),

          const SizedBox(height: 30),
        ],
      ),
    );
  }

Widget _buildPlatformRow(BuildContext context, List<Map<String, dynamic>> row) { // icon share design
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: row.map((p) {
      final label = p['label'] as String;
      final color = p['color'] as Color;
      final icon  = p['icon']  as IconData;
      final iconColor = (label == 'SMS') ? FurPalsColors.green : Colors.white;

      return GestureDetector(
        onTap: () {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar( // snackbar share
            SnackBar(
              content: Text('Sharing via $label...',
                  style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
              backgroundColor: color,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        },
        child: SizedBox( // circle share icon and text
          width: 58, 
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 30),
              ),
              const SizedBox(height: 10),
              Text(
                label,
                style: GoogleFonts.nunito(
                  fontSize: 10, fontWeight: FontWeight.w700, color: FurPalsColors.textDark,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      );
    }).toList(),
  );
}
}
class _ShareDropdownPill extends StatelessWidget { // Dropdown feed and and only me part
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
        final RenderBox box = context.findRenderObject() as RenderBox; // only me dropdown design
        final Offset offset = box.localToGlobal(Offset.zero);
        final picked = await showMenu<String>(
          context: context,
          color: FurPalsColors.warmWhite,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          position: RelativeRect.fromLTRB(
            offset.dx, offset.dy + box.size.height + 4, offset.dx + 120, 0,
          ),
          items: options.map((o) => PopupMenuItem(
            value: o,
            child: Text(o,
                style: GoogleFonts.nunito(
                  fontSize: 13, fontWeight: FontWeight.w700, color: FurPalsColors.textDark,
                )),
          )).toList(),
        );
        if (picked != null) onChanged(picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: FurPalsColors.creamwhite,
          borderRadius: BorderRadius.circular(6), // Feed dropdown design
          border: Border.all(color: const Color(0xFFF0E4DC), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: FurPalsColors.textMid),
            const SizedBox(width: 4),
            Text(value,
                style: GoogleFonts.nunito(
                  fontSize: 12, fontWeight: FontWeight.w700, color: FurPalsColors.textDark,
                )),
            const SizedBox(width: 3),
            const Icon(Icons.keyboard_arrow_down_rounded, size: 14, color: FurPalsColors.textMid),
          ],
        ),
      ),
    );
  }
}

// main feed
class HomeBody extends StatefulWidget {
  final ValueChanged<int> onNavTap;

  const HomeBody({super.key, required this.onNavTap});

  @override
  State<HomeBody> createState() => _HomeBodyState();
}

class _HomeBodyState extends State<HomeBody> {
  bool _hasNewNotif = true;

  // sample profile list
  final List<Map<String, dynamic>> _activeUsers = [
    {'emoji': '🐶', 'label': 'Buddy',  'online': true},
    {'emoji': '🐱', 'label': 'Luna',   'online': true},
    {'emoji': '🐰', 'label': 'Coco',   'online': false},
    {'emoji': '🐾', 'label': 'Mochi',  'online': true},
    {'emoji': '🦮', 'label': 'Daisy',  'online': false},
    {'emoji': '🐹', 'label': 'Peanut', 'online': true},
  ];

  // Sample posts shown in the feed
  final List<Map<String, dynamic>> _posts = [
    {
      'username': 'PetName', 'breed': 'Scottish Fold', 'emoji': '🐱',
      'bgStart': FurPalsColors.blush, 'bgEnd': FurPalsColors.peach,
      'likes': '130.9K', 'comments': '10K', 'shares': '5.5K',
      'caption': 'Cute 🩷', 'time': '4:10 AM', 'date': 'March 5, 2026',
      'avatarBg1': FurPalsColors.blush, 'avatarBg2': FurPalsColors.peach,
      'online': true,
    },
    {
      'username': 'fluffybuddyy', 'breed': 'Golden Retriever', 'emoji': '🐶',
      'bgStart': FurPalsColors.mint, 'bgEnd': FurPalsColors.butter,
      'likes': '8.1K', 'comments': '3.4K', 'shares': '1.2K',
      'caption': 'Morning zoomies! 🌿✨', 'time': '7:32 AM', 'date': 'March 5, 2026',
      'avatarBg1': FurPalsColors.mint, 'avatarBg2': FurPalsColors.lavender,
      'online': false,
    },
  ];
  String _s(Map<String, dynamic> m, String k) => (m[k] ?? '') as String;
  Color  _c(Map<String, dynamic> m, String k, Color fb) => m.containsKey(k) ? m[k] as Color : fb;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(  // bg 
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

  Widget _buildTopBar(BuildContext context) { // menu icon
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
                  boxShadow: const [BoxShadow(color: FurPalsColors.shadow, blurRadius: 10, offset: Offset(0, 3))],
                ),
                child: const Center(child: Icon(Icons.menu_rounded, size: 20, color: FurPalsColors.textDark)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Row(
              children: [
                Text('Mickaluvsyou', // username display in top bar
                    style: GoogleFonts.baloo2(
                      fontSize: 25,
                      fontWeight: FontWeight.w800,
                      color: FurPalsColors.textDark,
                    )),
                const SizedBox(width: 10),
                const Text('🐾', style: TextStyle(fontSize: 18)),
              ],
            ),
          ),
          GestureDetector(
            onTap: () async {
              setState(() => _hasNewNotif = false); // clear red dot
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NotificationScreen()),
              );
            },
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration( // notif icon
                    color: FurPalsColors.warmWhite,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [BoxShadow(color: Color(0x40F4738A), blurRadius: 12, offset: Offset(0, 4))],
                  ),
                  child: const Center(
                    child: Icon(Icons.favorite_rounded, color: FurPalsColors.heartRed, size: 20),
                  ),
                ),
                if (_hasNewNotif)
                  Positioned( // notfi red notice
                    top: -3, right: -3,
                    child: Container(
                      width: 12, height: 12,
                      decoration: BoxDecoration(
                        color: FurPalsColors.heartRed,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: const [BoxShadow(color: Color(0x55E53935), blurRadius: 4, offset: Offset(0, 1))],
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

  Widget _buildActiveUsersRow() { // profile list 
    return SizedBox(
      height: 100,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        itemCount: _activeUsers.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (_, i) => _buildUserAvatar(_activeUsers[i]),
      ),
    );
  }

  Widget _buildUserAvatar(Map<String, dynamic> user) {
    final bool   online = user['online'] as bool;
    final String emoji  = user['emoji']  as String;
    final String label  = user['label']  as String;

    return SizedBox(
      width: 64, // active status
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
              decoration: BoxDecoration( // profile avatar design
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                  colors: online
                      ? [FurPalsColors.blush, FurPalsColors.peach]
                      : [FurPalsColors.cream, FurPalsColors.warmWhite],
                ),
              ),
              child: Center(child: Text(emoji, style: const TextStyle(fontSize: 24))),
            ),
          ),
          const SizedBox(height: 4),
          Text(label,
              style: GoogleFonts.nunito(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: online ? FurPalsColors.textMid : FurPalsColors.textSoft,
              ),
              overflow: TextOverflow.ellipsis, maxLines: 1, textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildSearchBar() { // search bar
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 10),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFF0E4DC), width: 1.5),
          boxShadow: const [BoxShadow(color: FurPalsColors.shadow, blurRadius: 4, offset: Offset(0, 3))],
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
                    color: FurPalsColors.textSoft,
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                  border: InputBorder.none, isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
                style: GoogleFonts.nunito(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: FurPalsColors.black100,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeed() { // feed section
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      itemCount: _posts.length,
      separatorBuilder: (_, _) => const SizedBox(height: 14),
      itemBuilder: (_, i) => _buildPostCard(_posts[i]),
    );
  }

  Widget _buildPostCard(Map<String, dynamic> post) { // post card string
    final username = _s(post, 'username');
    final breed    = _s(post, 'breed');
    final emoji    = _s(post, 'emoji');
    final likes    = _s(post, 'likes');
    final comments = _s(post, 'comments');
    final shares   = _s(post, 'shares');
    final caption  = _s(post, 'caption');
    final time     = _s(post, 'time');
    final date     = _s(post, 'date');
    final bgStart  = _c(post, 'bgStart',   FurPalsColors.blush);
    final bgEnd    = _c(post, 'bgEnd',     FurPalsColors.peach);
    final av1      = _c(post, 'avatarBg1', FurPalsColors.blush);
    final av2      = _c(post, 'avatarBg2', FurPalsColors.peach);
    final bool online = (post['online'] as bool?) ?? false;

    return Container( // post card design
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: FurPalsColors.textSoft, blurRadius: 2, offset: Offset(0, 4))],
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
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: online ? FurPalsColors.onlineGreen : FurPalsColors.offlineGray,
                  ),
                  padding: const EdgeInsets.all(2.5),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(colors: [av1, av2]),
                    ),
                    child: Center(child: Text(emoji, style: const TextStyle(fontSize: 22))),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(username,
                          style: GoogleFonts.baloo2(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: FurPalsColors.textDark,
                            height: 1.1,
                          )),
                      const SizedBox(height: 2),
                      Text(breed,
                          style: GoogleFonts.nunito(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: FurPalsColors.textMid,
                          )),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => _showPostOptionsMenu(context, username),
                  child: const Icon(Icons.more_horiz_rounded, color: Colors.black, size: 22),
                ),
              ],
            ),
          ),
          Container(
            width: double.infinity, height: 220,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [bgStart, bgEnd],
              ),
            ),
            child: Center(child: Text(emoji, style: const TextStyle(fontSize: 90))),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => _showWhoLikedModal(context, likes),
                  child: _actionPill(Icons.favorite_outline, likes, FurPalsColors.creamwhite, FurPalsColors.heartRed),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _showCommentsModal(context, comments),
                  child: _actionPill(Icons.chat_bubble_outline, comments, FurPalsColors.creamwhite, FurPalsColors.textDark),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _showShareModal(context, username),
                  child: _actionPill(Icons.share_outlined, shares, FurPalsColors.creamwhite, FurPalsColors.blue),
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
                Text(caption,
                    style: GoogleFonts.nunito(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: FurPalsColors.textDark,
                    )),
                const SizedBox(height: 5),
                Row(
                  children: [
                    const Icon(Icons.access_time_rounded, size: 11, color: FurPalsColors.textSoft),
                    const SizedBox(width: 3),
                    Text(time,
                        style: GoogleFonts.nunito(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: FurPalsColors.textSoft,
                        )),
                    const SizedBox(width: 8),
                    const Icon(Icons.calendar_today_rounded, size: 11, color: FurPalsColors.textSoft),
                    const SizedBox(width: 3),
                    Text(date,
                        style: GoogleFonts.nunito(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: FurPalsColors.textSoft,
                        )),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
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
          const SizedBox(width: 5),
          Text(count,
              style: GoogleFonts.nunito(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: FurPalsColors.textDark,
              )),
        ],
      ),
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
  static const _audienceOptions = ['Feed', 'Friends', 'Public'];
  static const _privacyOptions = ['Only me', 'Friends', 'Everyone'];

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
            decoration: BoxDecoration(
              color: FurPalsColors.blush,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Text('New Post',
                    style: GoogleFonts.baloo2(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: FurPalsColors.textDark,
                    )),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                      color: FurPalsColors.blush,
                      borderRadius: BorderRadius.circular(10),
                    ),
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
                // Avatar — unchanged
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
                        'Username',
                        style: GoogleFonts.baloo2(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: FurPalsColors.textDark,
                        ),
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
                      const SizedBox(height: 15, width: 1,),
                    TextField(
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: "What's your pet up to?",
                          hintStyle: GoogleFonts.nunito(
                            color: FurPalsColors.textSoft,
                            fontSize: 14,
                          ),
                          border: InputBorder.none,
                        ),
                        style: GoogleFonts.nunito(
                          fontSize: 14,
                          color: FurPalsColors.black100,
                          fontWeight: FontWeight.w600,
                        ),
                        ),
                      
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
            child: Row(
              children: [
                _opt(Icons.image_rounded,       'Photo',    FurPalsColors.mint),
                const SizedBox(width: 10),
                _opt(Icons.videocam_rounded,    'Video',    FurPalsColors.lavender),
                const SizedBox(width: 10),
                _opt(Icons.location_on_rounded, 'Location', FurPalsColors.peach),
              ],
            ),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: const LinearGradient(colors: [FurPalsColors.pink, FurPalsColors.pinkLight]),
                  boxShadow: const [BoxShadow(color: Color(0x55F4738A), blurRadius: 14, offset: Offset(0, 6))],
                ),
                child: Center(
                  child: Text('Share Post',
                      style: GoogleFonts.baloo2(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      )),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _opt(IconData icon, String label, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: bg.withOpacity(0.6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: FurPalsColors.textMid),
          const SizedBox(width: 6),
          Text(label,
              style: GoogleFonts.nunito(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: FurPalsColors.textMid,
              )),
        ],
      ),
    );
  }
}

// Placeholder for empty screens

class LostFoundBody extends StatelessWidget {
  const LostFoundBody({super.key});

  @override
  Widget build(BuildContext context) => const _PlaceholderBody(
      emoji: '🔍', title: 'Lost & Found',
      subtitle: 'Help reunite pets with their families');
}

class PetsBody extends StatelessWidget {
  const PetsBody({super.key});

  @override
  Widget build(BuildContext context) => const _PlaceholderBody(
      emoji: '🐾', title: 'My Pets',
      subtitle: 'Manage your furry companions');
}

class ProfileBody extends StatelessWidget {
  const ProfileBody({super.key});

  @override
  Widget build(BuildContext context) => const _PlaceholderBody(
      emoji: '😊', title: 'Profile',
      subtitle: 'Your FurPals account');
}

class _PlaceholderBody extends StatelessWidget {
  final String emoji, title, subtitle;
  const _PlaceholderBody({
    required this.emoji, required this.title, required this.subtitle,
  });

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
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: FurPalsColors.textDark,
                )),
            const SizedBox(height: 6),
            Text(subtitle,
                style: GoogleFonts.nunito(
                  fontSize: 14,
                  color: FurPalsColors.textMid,
                  fontWeight: FontWeight.w600,
                )),
          ],
        ),
      ),
    );
  }
}