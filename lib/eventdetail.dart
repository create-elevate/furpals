import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:furpals/models.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:furpals/notification_service.dart';

class EventDetailScreen extends StatefulWidget {
  final PetEvent event;
  final VoidCallback? onDelete;
  final Function(PetEvent)? onEdit;
  final Function(List<EventMember>)? onMembersUpdated;

  const EventDetailScreen({
    super.key,
    required this.event,
    this.onDelete,
    this.onEdit,
    this.onMembersUpdated,
  });

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen>
    with TickerProviderStateMixin {
  bool _isAttending = false;
  bool _isNotified  = false;
  String _displayOwnerName = '';
  String _ownerPhotoURL = '';
  late List<EventMember> _members;
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;
  late AnimationController _attendCtrl;
  late Animation<double> _attendAnim;

  @override
  void initState() {
    super.initState();
    _members = List.from(widget.event.members);
    _isAttending = _members.any((member) => member.id == _currentUid);
    _displayOwnerName = widget.event.ownerName;
    
    if (widget.event.ownerId == _currentUid) {
      // If current user is the owner, use their own profile data
      _loadCurrentUserProfile();
    } else if (widget.event.ownerId.isNotEmpty && (_displayOwnerName.isEmpty || _displayOwnerName == 'You')) {
      _fetchOwnerName();
    }

    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();

    _attendCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _attendAnim = CurvedAnimation(parent: _attendCtrl, curve: Curves.elasticOut);
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _attendCtrl.dispose();
    super.dispose();
  }

  String get _currentUid => FirebaseAuth.instance.currentUser?.uid ?? '';

  Future<String> _currentUserName() async {
    final authUser = FirebaseAuth.instance.currentUser;
    if (authUser?.displayName?.trim().isNotEmpty ?? false) {
      return authUser!.displayName!;
    }
    if (_currentUid.isEmpty) return 'Friend';
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(_currentUid).get();
    final data = userDoc.data();
    return data?['fullName'] ?? data?['username'] ?? 'Friend';
  }

  Future<EventMember> _buildMemberData() async {
    final name = await _currentUserName();
    String emoji = '🐾';
    if (_currentUid.isNotEmpty) {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(_currentUid).get();
      final data = userDoc.data();
      if (data != null) {
        emoji = data['emoji'] ?? emoji;
      }
    }
    return EventMember(
      id: _currentUid,
      name: name,
      emoji: emoji,
      joinedDate: DateTime.now().toLocal().toString().split(' ').first,
    );
  }

  Future<void> _fetchOwnerName() async {
    if (widget.event.ownerId.isEmpty || widget.event.ownerId == _currentUid) return;
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(widget.event.ownerId).get();
      final data = doc.data();
      if (data != null) {
        final name = data['fullName'] ?? data['username'] ?? '';
        final photoURL = data['photoURL'] ?? '';
        if (name.isNotEmpty) {
          setState(() {
            _displayOwnerName = name;
            _ownerPhotoURL = photoURL;
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _loadCurrentUserProfile() async {
    if (_currentUid.isEmpty) return;
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(_currentUid).get();
      final data = doc.data();
      if (data != null) {
        final photoURL = data['photoURL'] ?? '';
        setState(() {
          _ownerPhotoURL = photoURL;
        });
      }
    } catch (_) {}
  }

  Future<void> _toggleAttend() async {
    if (_currentUid.isEmpty) return;
    final joining = !_isAttending;
    setState(() => _isAttending = joining);

    if (joining) {
      _attendCtrl.forward(from: 0);
    }

    final previousMembers = List<EventMember>.from(_members);
    if (joining) {
      final member = await _buildMemberData();
      _members.add(member);
    } else {
      _members.removeWhere((member) => member.id == _currentUid);
    }

    try {
      await FirebaseFirestore.instance.collection('events').doc(widget.event.id).update({
        'members': _members.map((member) => member.toMap()).toList(),
      });

      if (joining && widget.event.ownerId.isNotEmpty && widget.event.ownerId != _currentUid) {
        final username = await _currentUserName();
        await NotificationService.sendAttendanceNotification(
          toUserId: widget.event.ownerId,
          fromUserId: _currentUid,
          fromUsername: username,
          eventId: widget.event.id,
          eventTitle: widget.event.title,
        );
      }

      widget.onMembersUpdated?.call(List<EventMember>.from(_members));

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          joining ? "🎉 You're attending ${widget.event.title}!" : 'You are no longer attending this event.',
          style: GoogleFonts.nunito(fontWeight: FontWeight.w700),
        ),
        backgroundColor: joining ? FurPalsColors.green : FurPalsColors.textMid,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ));
    } catch (error) {
      debugPrint('Event attendance update failed: $error');
      setState(() {
        _members = previousMembers;
        _isAttending = !joining;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Could not save event attendance. Please try again.',
            style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
        backgroundColor: FurPalsColors.heartRed,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ));
    }
  }

  void _toggleNotify() {
    setState(() => _isNotified = !_isNotified);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(
        _isNotified ? '🔔 Notifications on for this event!' : '🔕 Notifications turned off.',
        style: GoogleFonts.nunito(fontWeight: FontWeight.w700),
      ),
      backgroundColor: _isNotified ? FurPalsColors.purple : FurPalsColors.textDark,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ));
  }

  void _kickMember(EventMember member) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: FurPalsColors.warmWhite,
        title: Text('Remove Member',
            style: GoogleFonts.baloo2(fontWeight: FontWeight.w800, color: FurPalsColors.textDark, fontSize: 18)),
        content: RichText(
          text: TextSpan(
            style: GoogleFonts.nunito(fontSize: 13, color: FurPalsColors.textMid, fontWeight: FontWeight.w600),
            children: [
              const TextSpan(text: 'Are you sure you want to remove '),
              TextSpan(text: member.name, style: const TextStyle(color: FurPalsColors.pink, fontWeight: FontWeight.w800)),
              const TextSpan(text: ' from this event?'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.nunito(color: FurPalsColors.textMid, fontWeight: FontWeight.w700)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: FurPalsColors.heartRed,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            onPressed: () async {
              setState(() => _members.removeWhere((m) => m.id == member.id));
              try {
                await FirebaseFirestore.instance.collection('events').doc(widget.event.id).update({
                  'members': _members.map((member) => member.toMap()).toList(),
                });
                widget.onMembersUpdated?.call(List<EventMember>.from(_members));
              } catch (_) {
                setState(() => _members.add(member));
              }
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('${member.name} removed from event.',
                    style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
                backgroundColor: FurPalsColors.heartRed,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ));
            },
            child: Text('Remove', style: GoogleFonts.nunito(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: FurPalsColors.warmWhite,
        title: Text('Delete Event',
            style: GoogleFonts.baloo2(fontWeight: FontWeight.w800, color: FurPalsColors.textDark, fontSize: 18)),
        content: Text(
          'This will permanently delete "${widget.event.title}". This cannot be undone.',
          style: GoogleFonts.nunito(fontSize: 13, color: FurPalsColors.textMid, fontWeight: FontWeight.w600),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.nunito(color: FurPalsColors.textMid, fontWeight: FontWeight.w700)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: FurPalsColors.heartRed,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
              widget.onDelete?.call();
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('🗑️ Event deleted.',
                    style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
                backgroundColor: FurPalsColors.heartRed,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ));
            },
            child: Text('Delete', style: GoogleFonts.nunito(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FurPalsColors.warmWhite,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: Stack(children: [
          CustomScrollView(
            slivers: [
              _buildHeroSliver(),
              SliverToBoxAdapter(
                child: Column(children: [
                  _buildInfoSection(),
                  _buildDetailsSection(),
                  if (!widget.event.isOwner) _buildAttendeeActions(),
                  _buildMembersSection(),
                  if (widget.event.isOwner) _buildOwnerActions(),
                  const SizedBox(height: 100),
                ]),
              ),
            ],
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 16,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [BoxShadow(color: FurPalsColors.shadow, blurRadius: 10, offset: Offset(0, 3))],
                ),
                child: const Center(child: Icon(Icons.arrow_back_rounded, size: 20, color: FurPalsColors.textDark)),
              ),
            ),
          ),
          // ← Edit/delete top-right icons removed
        ]),
      ),
    );
  }

  Widget _buildHeroSliver() {
    return SliverAppBar(
      expandedHeight: 260,
      automaticallyImplyLeading: false,
      pinned: false,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(fit: StackFit.expand, children: [
          if (widget.event.photoUrl != null && widget.event.photoUrl!.isNotEmpty)
            Image.network(
              widget.event.photoUrl!,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return const Center(child: CircularProgressIndicator());
              },
              errorBuilder: (_, __, ___) => Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                    colors: [widget.event.color1, widget.event.color2],
                  ),
                ),
                child: Center(child: Text(widget.event.emoji, style: const TextStyle(fontSize: 90))),
              ),
            ) else if (widget.event.photoPath != null && widget.event.photoPath!.isNotEmpty && File(widget.event.photoPath!).existsSync())
            Image.file(File(widget.event.photoPath!), fit: BoxFit.cover)
          else
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                  colors: [widget.event.color1, widget.event.color2],
                ),
              ),
              child: Center(child: Text(widget.event.emoji, style: const TextStyle(fontSize: 90))),
            ),
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              height: 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter, end: Alignment.topCenter,
                  colors: [FurPalsColors.warmWhite, FurPalsColors.warmWhite.withOpacity(0)],
                ),
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 0, right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [BoxShadow(color: FurPalsColors.shadow, blurRadius: 8)],
                ),
                child: Text(widget.event.category,
                    style: GoogleFonts.nunito(fontSize: 11, fontWeight: FontWeight.w800, color: FurPalsColors.pink)),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildInfoSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(widget.event.title,
            style: GoogleFonts.baloo2(fontSize: 26, fontWeight: FontWeight.w900, color: FurPalsColors.textDark, height: 1.1)),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: FurPalsColors.blush.withOpacity(0.4),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: FurPalsColors.blush, width: 1.5),
          ),
          child: Row(children: [
            GestureDetector(
              onTap: () {
                // TODO: Navigate to owner's profile when ProfileScreen supports userId parameter
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Profile view coming soon! 👤',
                        style: GoogleFonts.nunito(fontWeight: FontWeight.w600)),
                    backgroundColor: FurPalsColors.pink,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              child: Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: FurPalsColors.pink.withOpacity(0.3), width: 2),
                ),
                child: ClipOval(
                  child: _ownerPhotoURL.isNotEmpty
                      ? Image.network(
                          _ownerPhotoURL,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: FurPalsColors.cream,
                            child: Center(child: Text(widget.event.ownerEmoji, style: const TextStyle(fontSize: 18))),
                          ),
                        )
                      : Container(
                          color: FurPalsColors.cream,
                          child: Center(child: Text(widget.event.ownerEmoji, style: const TextStyle(fontSize: 18))),
                        ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Created by', style: GoogleFonts.nunito(fontSize: 10, fontWeight: FontWeight.w600, color: FurPalsColors.textMid)),
              GestureDetector(
                onTap: () {
                  // TODO: Navigate to owner's profile when ProfileScreen supports userId parameter
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Profile view coming soon! 👤',
                          style: GoogleFonts.nunito(fontWeight: FontWeight.w600)),
                      backgroundColor: FurPalsColors.pink,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                child: Text(
                  widget.event.ownerId == FirebaseAuth.instance.currentUser?.uid
                      ? 'You'
                      : (_displayOwnerName.isNotEmpty ? _displayOwnerName : 'Friend'),
                  style: GoogleFonts.nunito(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: FurPalsColors.pink,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ]),
            const Spacer(),
            if (widget.event.isOwner)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: FurPalsColors.pink, borderRadius: BorderRadius.circular(20)),
                child: Text('You', style: GoogleFonts.nunito(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white)),
              ),
          ]),
        ),
      ]),
    );
  }

  Widget _buildDetailsSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Wrap(spacing: 8, runSpacing: 8, children: [
          _infoPill(Icons.calendar_today_rounded, widget.event.date,     const Color(0xFFFFF0F3), FurPalsColors.pink),
          _infoPill(Icons.access_time_rounded,    widget.event.time,     const Color(0xFFF0EBFF), FurPalsColors.purple),
          _infoPill(Icons.location_on_rounded,    widget.event.location, const Color(0xFFEAF7F0), FurPalsColors.green),
        ]),
        if (widget.event.description.isNotEmpty) ...[
          const SizedBox(height: 16),
          _sectionLabel(' About this Event'),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: FurPalsColors.creamwhite,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFF0E4DC), width: 1.5),
            ),
            child: Text(widget.event.description,
                style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w600, color: FurPalsColors.textMid, height: 1.6)),
          ),
        ],
      ]),
    );
  }

  Widget _buildAttendeeActions() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _sectionLabel('🎟️ Your Status'),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(
            child: GestureDetector(
              onTap: _toggleAttend,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: _isAttending ? const LinearGradient(colors: [FurPalsColors.green, Color(0xFF3DA864)]) : null,
                  color: _isAttending ? null : Colors.white,
                  border: Border.all(color: _isAttending ? Colors.transparent : const Color(0xFFF0E4DC), width: 1.5),
                  boxShadow: _isAttending
                      ? [const BoxShadow(color: Color(0x4A5DB87A), blurRadius: 12, offset: Offset(0, 4))]
                      : [const BoxShadow(color: FurPalsColors.shadow, blurRadius: 4, offset: Offset(0, 2))],
                ),
                child: Center(child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text(_isAttending ? '✅' : '🎟️', style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 6),
                  Text(_isAttending ? "I'm Going!" : 'Attend',
                      style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w800,
                          color: _isAttending ? Colors.white : FurPalsColors.textDark)),
                ])),
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: _toggleNotify,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 52, height: 52,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: _isNotified ? FurPalsColors.lavender : Colors.white,
                border: Border.all(color: _isNotified ? FurPalsColors.purple : const Color(0xFFF0E4DC), width: 1.5),
                boxShadow: _isNotified
                    ? [const BoxShadow(color: Color(0x408B6FD4), blurRadius: 10, offset: Offset(0, 3))]
                    : [const BoxShadow(color: FurPalsColors.shadow, blurRadius: 4, offset: Offset(0, 2))],
              ),
              child: Center(child: Icon(
                _isNotified ? Icons.notifications_active_rounded : Icons.notifications_outlined,
                color: _isNotified ? FurPalsColors.purple : FurPalsColors.textSoft,
                size: 22,
              )),
            ),
          ),
        ]),
        if (_isAttending || _isNotified) ...[
          const SizedBox(height: 8),
          Wrap(spacing: 8, children: [
            if (_isAttending) _statusChip('✅ Attending', const Color(0xFFEAF7F0), FurPalsColors.green),
            if (_isNotified)  _statusChip('🔔 Notified',  FurPalsColors.lavender,  FurPalsColors.purple),
          ]),
        ],
      ]),
    );
  }

  Widget _statusChip(String label, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: GoogleFonts.nunito(fontSize: 11, fontWeight: FontWeight.w700, color: fg)),
    );
  }

  Widget _buildMembersSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          _sectionLabel('🐾 Members'),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(color: FurPalsColors.blush, borderRadius: BorderRadius.circular(20)),
            child: Text('${_members.length}',
                style: GoogleFonts.nunito(fontSize: 11, fontWeight: FontWeight.w800, color: FurPalsColors.pink)),
          ),
        ]),
        const SizedBox(height: 10),
        if (_members.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFF0E4DC), width: 1.5),
            ),
            child: Column(children: [
              const Text('🐾', style: TextStyle(fontSize: 32)),
              const SizedBox(height: 6),
              Text('No members yet',
                  style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w600, color: FurPalsColors.textSoft)),
            ]),
          )
        else
          ...List.generate(_members.length, (i) => _buildMemberTile(_members[i], i)),
      ]),
    );
  }

  Widget _buildMemberTile(EventMember member, int index) {
    final gradients = [
      [FurPalsColors.blush,    FurPalsColors.peach],
      [FurPalsColors.mint,     FurPalsColors.lavender],
      [FurPalsColors.lavender, FurPalsColors.butter],
      [FurPalsColors.peach,    FurPalsColors.butter],
    ];
    final grad = gradients[index % gradients.length];

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: FurPalsColors.shadow, blurRadius: 6, offset: Offset(0, 2))],
      ),
      child: Row(children: [
        Container(
          width: 42, height: 42,
          decoration: BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: grad)),
          child: Center(child: Text(member.emoji, style: const TextStyle(fontSize: 20))),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(member.name,
              style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w800, color: FurPalsColors.textDark)),
          Text('Joined ${member.joinedDate}',
              style: GoogleFonts.nunito(fontSize: 11, fontWeight: FontWeight.w600, color: FurPalsColors.textMid)),
        ])),
        if (widget.event.isOwner)
          GestureDetector(
            onTap: () => _kickMember(member),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFFEEEE),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: FurPalsColors.heartRed.withOpacity(0.3), width: 1),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.remove_circle_outline_rounded, size: 13, color: FurPalsColors.heartRed),
                const SizedBox(width: 4),
                Text('Kick', style: GoogleFonts.nunito(fontSize: 11, fontWeight: FontWeight.w700, color: FurPalsColors.heartRed)),
              ]),
            ),
          ),
      ]),
    );
  }

  Widget _buildOwnerActions() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _sectionLabel('Manage Event'),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (widget.onEdit != null) {
                  widget.onEdit!(widget.event);
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: const LinearGradient(colors: [FurPalsColors.purple, Color(0xFF7B5FC4)]),
                  boxShadow: const [BoxShadow(color: Color(0x408B6FD4), blurRadius: 12, offset: Offset(0, 4))],
                ),
                child: Center(child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.edit_rounded, color: Colors.white, size: 16),
                  const SizedBox(width: 6),
                  Text('Edit Event', style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white)),
                ])),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: _confirmDelete,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.white,
                  border: Border.all(color: FurPalsColors.heartRed.withOpacity(0.4), width: 1.5),
                  boxShadow: const [BoxShadow(color: FurPalsColors.shadow, blurRadius: 6, offset: Offset(0, 2))],
                ),
                child: Center(child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.delete_rounded, color: FurPalsColors.heartRed, size: 16),
                  const SizedBox(width: 6),
                  Text('Delete', style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w800, color: FurPalsColors.heartRed)),
                ])),
              ),
            ),
          ),
        ]),
      ]),
    );
  }

  Widget _sectionLabel(String text) =>
      Text(text, style: GoogleFonts.baloo2(fontSize: 16, fontWeight: FontWeight.w800, color: FurPalsColors.textDark));

  Widget _infoPill(IconData icon, String label, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 13, color: fg),
        const SizedBox(width: 6),
        Text(label, style: GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.w700, color: FurPalsColors.textMid)),
      ]),
    );
  }
}