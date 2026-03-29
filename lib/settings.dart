import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:furpals/Homescreen.dart'; // FurPalsColors

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Toggle states
  bool _notifications    = true;
  bool _emailUpdates     = false;
  bool _locationAccess   = true;
  bool _privateAccount   = false;
  bool _showOnlineStatus = true;
  bool _darkMode         = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF5F2),
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(context),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    // ── ACCOUNT ─────────────────────────────────────────
                    _sectionLabel('Account'),
                    _settingsCard([
                      _navTile(
                        icon: Icons.person_rounded,
                        iconBg: FurPalsColors.blush,
                        iconColor: FurPalsColors.pink,
                        label: 'Edit Profile',
                        onTap: () {},
                      ),
                      _divider(),
                      _navTile(
                        icon: Icons.lock_rounded,
                        iconBg: const Color(0xFFDDD0F5),
                        iconColor: FurPalsColors.purple,
                        label: 'Change Password',
                        onTap: () {},
                      ),
                      _divider(),
                      _navTile(
                        icon: Icons.email_rounded,
                        iconBg: const Color(0xFFD4EBF2),
                        iconColor: FurPalsColors.blue,
                        label: 'Change Email',
                        onTap: () {},
                      ),
                      _divider(),
                      _navTile(
                        icon: Icons.phone_rounded,
                        iconBg: const Color(0xFFC5EDD6),
                        iconColor: FurPalsColors.green,
                        label: 'Phone Number',
                        onTap: () {},
                      ),
                    ]),

                    const SizedBox(height: 20),

                    // ── NOTIFICATIONS ────────────────────────────────────
                    _sectionLabel('Notifications'),
                    _settingsCard([
                      _toggleTile(
                        icon: Icons.notifications_rounded,
                        iconBg: const Color(0xFFFFF3C4),
                        iconColor: const Color(0xFFE6A817),
                        label: 'Push Notifications',
                        value: _notifications,
                        onChanged: (v) => setState(() => _notifications = v),
                      ),
                      _divider(),
                      _toggleTile(
                        icon: Icons.mail_rounded,
                        iconBg: FurPalsColors.blush,
                        iconColor: FurPalsColors.pink,
                        label: 'Email Updates',
                        value: _emailUpdates,
                        onChanged: (v) => setState(() => _emailUpdates = v),
                      ),
                    ]),

                    const SizedBox(height: 20),

                    // ── PRIVACY ──────────────────────────────────────────
                    _sectionLabel('Privacy'),
                    _settingsCard([
                      _toggleTile(
                        icon: Icons.visibility_rounded,
                        iconBg: const Color(0xFFDDD0F5),
                        iconColor: FurPalsColors.purple,
                        label: 'Private Account',
                        value: _privateAccount,
                        onChanged: (v) => setState(() => _privateAccount = v),
                      ),
                      _divider(),
                      _toggleTile(
                        icon: Icons.circle,
                        iconBg: const Color(0xFFC5EDD6),
                        iconColor: FurPalsColors.green,
                        label: 'Show Online Status',
                        value: _showOnlineStatus,
                        onChanged: (v) => setState(() => _showOnlineStatus = v),
                      ),
                      _divider(),
                      _toggleTile(
                        icon: Icons.location_on_rounded,
                        iconBg: const Color(0xFFFFD9C0),
                        iconColor: const Color(0xFFE07B39),
                        label: 'Location Access',
                        value: _locationAccess,
                        onChanged: (v) => setState(() => _locationAccess = v),
                      ),
                      _divider(),
                      _navTile(
                        icon: Icons.block_rounded,
                        iconBg: const Color(0xFFFFE4E4),
                        iconColor: FurPalsColors.heartRed,
                        label: 'Blocked Users',
                        onTap: () {},
                      ),
                    ]),

                    const SizedBox(height: 20),

                    // ── PREFERENCES ──────────────────────────────────────
                    _sectionLabel('Preferences'),
                    _settingsCard([
                      _navTile(
                        icon: Icons.language_rounded,
                        iconBg: const Color(0xFFD4EBF2),
                        iconColor: FurPalsColors.blue,
                        label: 'Language',
                        trailing: Text('English',
                            style: GoogleFonts.nunito(
                              fontSize: 13,
                              color: FurPalsColors.textMid,
                              fontWeight: FontWeight.w600,
                            )),
                        onTap: () {},
                      ),
                    ]),

                    const SizedBox(height: 20),

                    // ── SUPPORT ──────────────────────────────────────────
                    _sectionLabel('Support'),
                    _settingsCard([
                      _navTile(
                        icon: Icons.help_outline_rounded,
                        iconBg: const Color(0xFFDDD0F5),
                        iconColor: FurPalsColors.purple,
                        label: 'Help & Support',
                        onTap: () {},
                      ),
                      _divider(),
                      _navTile(
                        icon: Icons.star_rounded,
                        iconBg: const Color(0xFFFFF3C4),
                        iconColor: const Color(0xFFE6A817),
                        label: 'Rate the App',
                        onTap: () {},
                      ),
                    ]),

                    const SizedBox(height: 20),

                    // ── DANGER ZONE ───────────────────────────────────────
                    _sectionLabel('Account Actions'),
                    _settingsCard([
                      _navTile(
                        icon: Icons.logout_rounded,
                        iconBg: const Color(0xFFFFE4E4),
                        iconColor: FurPalsColors.heartRed,
                        label: 'Deactivate',
                        labelColor: FurPalsColors.heartRed,
                        onTap: () => _showLogoutDialog(context),
                        showChevron: false,
                      ),
                      _divider(),
                      _navTile(
                        icon: Icons.delete_forever_rounded,
                        iconBg: const Color(0xFFFFE4E4),
                        iconColor: FurPalsColors.heartRed,
                        label: 'Delete Account',
                        labelColor: FurPalsColors.heartRed,
                        onTap: () => _showDeleteDialog(context),
                        showChevron: false,
                      ),
                    ]),

                    const SizedBox(height: 32),

                    // Version
                    Center(
                      child: Text(
                        'FurPals v1.0.0',
                        style: GoogleFonts.nunito(
                          fontSize: 12,
                          color: FurPalsColors.textMid.withOpacity(0.5),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── TOP BAR ───────────────────────────────────────────────────────────────
  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(
                      color: FurPalsColors.shadow,
                      blurRadius: 10,
                      offset: Offset(0, 3)),
                ],
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  size: 18, color: FurPalsColors.textDark),
            ),
          ),
          const SizedBox(width: 14),
          Text(
            'Settings',
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

  // ── SECTION LABEL ─────────────────────────────────────────────────────────
  Widget _sectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        label.toUpperCase(),
        style: GoogleFonts.nunito(
          fontSize: 11,
          fontWeight: FontWeight.w900,
          color: FurPalsColors.textMid.withOpacity(0.6),
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  // ── WHITE CARD WRAPPER ────────────────────────────────────────────────────
  Widget _settingsCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
              color: FurPalsColors.shadow,
              blurRadius: 12,
              offset: Offset(0, 4)),
        ],
      ),
      child: Column(children: children),
    );
  }

  // ── NAV TILE ──────────────────────────────────────────────────────────────
  Widget _navTile({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String label,
    required VoidCallback onTap,
    Color? labelColor,
    Widget? trailing,
    bool showChevron = true,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.nunito(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: labelColor ?? FurPalsColors.textDark,
                ),
              ),
            ),
            if (trailing != null) ...[
              trailing,
              const SizedBox(width: 6),
            ],
            if (showChevron)
              Icon(Icons.chevron_right_rounded,
                  color: FurPalsColors.textMid.withOpacity(0.4), size: 20),
          ],
        ),
      ),
    );
  }

  // ── TOGGLE TILE ───────────────────────────────────────────────────────────
  Widget _toggleTile({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.nunito(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: FurPalsColors.textDark,
              ),
            ),
          ),
          CupertinoSwitch(
            value: value,
            onChanged: onChanged,
            activeColor: FurPalsColors.pink,
          ),
        ],
      ),
    );
  }

  // ── DIVIDER ───────────────────────────────────────────────────────────────
  Widget _divider() {
    return Padding(
      padding: const EdgeInsets.only(left: 66),
      child: Divider(
        height: 1,
        color: FurPalsColors.shadow.withOpacity(0.5),
      ),
    );
  }

  // ── LOGOUT DIALOG ─────────────────────────────────────────────────────────
  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Deactivate',
            style: GoogleFonts.baloo2(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: FurPalsColors.textDark,
            )),
        content: Text(
          'Are you sure you want to deactivate?',
          style: GoogleFonts.nunito(
              fontSize: 14, color: FurPalsColors.textMid),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel',
                style: GoogleFonts.nunito(
                    fontWeight: FontWeight.w700,
                    color: FurPalsColors.textMid)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.of(context).pushReplacementNamed('/login');
            },
            child: Text('Log Out',
                style: GoogleFonts.nunito(
                    fontWeight: FontWeight.w800,
                    color: FurPalsColors.heartRed)),
          ),
        ],
      ),
    );
  }

  // ── DELETE DIALOG ─────────────────────────────────────────────────────────
  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Delete Account',
            style: GoogleFonts.baloo2(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: FurPalsColors.heartRed,
            )),
        content: Text(
          'This action is permanent and cannot be undone. All your data will be deleted.',
          style: GoogleFonts.nunito(
              fontSize: 14, color: FurPalsColors.textMid),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel',
                style: GoogleFonts.nunito(
                    fontWeight: FontWeight.w700,
                    color: FurPalsColors.textMid)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Delete',
                style: GoogleFonts.nunito(
                    fontWeight: FontWeight.w800,
                    color: FurPalsColors.heartRed)),
          ),
        ],
      ),
    );
  }
}