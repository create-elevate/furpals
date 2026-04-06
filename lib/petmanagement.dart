import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:furpals/newappointment.dart';
import 'package:furpals/addevent.dart';
import 'package:furpals/eventdetail.dart';
import 'package:furpals/models.dart';
import 'package:furpals/NotificationScreen.dart';
import 'package:furpals/models.dart' as models;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

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
  static const textSoft    = Color(0x33000000);
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

// ── Sample data ───────────────────────────────────────────────────────────────
final List<Pet> samplePets = [
  Pet(id: 0, emoji: '🐱', name: 'Luna',  breed: 'Scottish Fold',   gender: 'Female',
      age: '2y 3m', weight: '3.2kg', vet: 'Dr. Santos', notes: 'Loves tuna. Allergic to dust.',
      online: true, vaccinations: [
        VaccinationRecord(name: 'Rabies',     date: 'Jan 2025', status: 'done'),
        VaccinationRecord(name: 'FVRCP',      date: 'Mar 2025', status: 'done'),
        VaccinationRecord(name: 'FeLV',       date: 'Jun 2025', status: 'done'),
        VaccinationRecord(name: 'Bordetella', date: 'Sep 2025', status: 'due'),
        VaccinationRecord(name: 'FIV',        date: 'Nov 2025', status: 'overdue'),
      ]),
  Pet(id: 1, emoji: '🐶', name: 'Buddy', breed: 'Golden Retriever', gender: 'Male',
      age: '4y', weight: '28kg', vet: 'Dr. Reyes', notes: 'Hip check every 6 months.',
      online: true, vaccinations: [
        VaccinationRecord(name: 'Rabies',        date: 'Feb 2025', status: 'done'),
        VaccinationRecord(name: 'DHPP',          date: 'Apr 2025', status: 'done'),
        VaccinationRecord(name: 'Leptospirosis', date: 'Jun 2025', status: 'done'),
        VaccinationRecord(name: 'Bordetella',    date: 'Dec 2025', status: 'due'),
      ]),
  Pet(id: 2, emoji: '🐰', name: 'Coco',  breed: 'Holland Lop',     gender: 'Female',
      age: '1y 6m', weight: '1.8kg', vet: 'Dr. Cruz', notes: 'Needs hay daily. Trim nails monthly.',
      online: false, vaccinations: [
        VaccinationRecord(name: 'Myxomatosis', date: 'Mar 2025', status: 'done'),
        VaccinationRecord(name: 'RHD',         date: 'May 2025', status: 'due'),
      ]),
  Pet(id: 3, emoji: '🐾', name: 'Mochi', breed: 'Persian Cat',     gender: 'Female',
      age: '3y', weight: '4.1kg', vet: 'Dr. Santos', notes: 'Long coat needs daily brushing.',
      online: true, vaccinations: [
        VaccinationRecord(name: 'Rabies', date: 'Jan 2025', status: 'done'),
        VaccinationRecord(name: 'FVRCP', date: 'Mar 2025', status: 'done'),
        VaccinationRecord(name: 'FeLV',  date: 'Nov 2025', status: 'due'),
      ]),
];

// ── Main Screen ───────────────────────────────────────────────────────────────
class PetsScreen extends StatefulWidget {
  const PetsScreen({super.key});
  @override
  State<PetsScreen> createState() => _PetsScreenState();
}

class _PetsScreenState extends State<PetsScreen> {
  List<Pet> _pets = List.from(samplePets);
  List<Appointment> _appointments = [];
  String _searchQuery = '';

  List<PetEvent> _events = [];

  List<Appointment> get _filteredAppts {
    final currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final ownerAppointments = _appointments.where((a) => a.ownerId == currentUid);
    if (_searchQuery.isEmpty) return ownerAppointments.toList();
    final q = _searchQuery.toLowerCase();
    return ownerAppointments.where((a) {
      final pet = _pets.firstWhere((p) => p.id == a.petId, orElse: () => _pets[0]);
      return a.title.toLowerCase().contains(q) ||
             pet.name.toLowerCase().contains(q) ||
             a.vet.toLowerCase().contains(q);
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacementNamed('/login');
      });
      return;
    }
    _loadData();
  }

  Future<void> _loadData() async {
    await _loadEvents();
    await _loadAppointments();
  }

  Future<void> _loadEvents() async {
    final snapshot = await FirebaseFirestore.instance.collection('events').orderBy('createdAt', descending: true).get();
    final events = snapshot.docs.map((doc) {
      final data = doc.data();
      final currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
      return PetEvent(
        id: doc.id,
        emoji: data['emoji'] ?? '🐾',
        title: data['title'] ?? '',
        location: data['location'] ?? '',
        date: data['date'] ?? '',
        time: data['time'] ?? '',
        category: data['category'] ?? '',
        description: data['description'] ?? '',
        color1: Color(data['color1'] ?? FurPalsColors.mint.value),
        color2: Color(data['color2'] ?? FurPalsColors.lavender.value),
        photoPath: data['photoPath'],
        photoUrl: data['photoUrl'],
        isOwner: data['ownerId'] == currentUid,
        ownerName: data['ownerName'] ?? '',
        ownerEmoji: data['ownerEmoji'] ?? '🐾',
        ownerId: data['ownerId'] ?? '',
        members: [],
      );
    }).toList();
    setState(() => _events = events);
  }

  Future<String?> _uploadEventPhoto(String localPath, String currentUid, String docId) async {
    try {
      final file = File(localPath);
      if (!file.existsSync()) return null;
      final extension = localPath.split('.').lastWhere((part) => part.isNotEmpty, orElse: () => 'jpg');
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('event_photos/$currentUid/$docId.$extension');
      final snapshot = await storageRef.putFile(file);
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      debugPrint('Event photo upload failed: $e');
      return null;
    }
  }

  Future<void> _loadAppointments() async {
    final currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    debugPrint('Loading appointments for uid: $currentUid');
    if (currentUid.isEmpty) {
      debugPrint('No user logged in, skipping appointment load');
      return;
    }
    try {
      final snapshot = await FirebaseFirestore.instance.collection('appointments').where('ownerId', isEqualTo: currentUid).get();
      debugPrint('Found ${snapshot.docs.length} appointments');
      final appointments = snapshot.docs.map((doc) {
        final data = doc.data();
        return Appointment(
          id: doc.id,
          petId: data['petId'] ?? 0,
          title: data['title'] ?? '',
          vet: data['vet'] ?? '',
          date: data['date'] ?? '',
          time: data['time'] ?? '',
          type: data['type'] ?? '',
          notes: data['notes'] ?? '',
          status: data['status'] ?? 'upcoming',
          ownerId: data['ownerId'] ?? '',
        );
      }).toList();
      // Sort by date descending (assuming date format allows comparison)
      appointments.sort((a, b) => b.date.compareTo(a.date));
      setState(() => _appointments = appointments);
      debugPrint('Loaded ${appointments.length} appointments');
    } catch (error) {
      debugPrint('Failed to load appointments: $error');
    }
  }

  void _addPet(Pet p)    => setState(() => _pets.add(p));
  void _updatePet(Pet p) => setState(() {
    final idx = _pets.indexWhere((x) => x.id == p.id);
    if (idx != -1) _pets[idx] = p;
  });
  void _addAppointment(Appointment a) async {
    final messenger = ScaffoldMessenger.of(context);
    debugPrint('Adding appointment with ownerId: ${a.ownerId}');
    if (a.ownerId.isEmpty) {
      debugPrint('ownerId is empty, cannot save');
      messenger.showSnackBar(SnackBar(
        content: Text('Unable to save appointment: not logged in.',
            style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
        backgroundColor: FurPalsColors.heartRed,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ));
      return;
    }
    try {
      final docRef = await FirebaseFirestore.instance.collection('appointments').add({
        'petId': a.petId,
        'title': a.title,
        'vet': a.vet,
        'date': a.date,
        'time': a.time,
        'type': a.type,
        'notes': a.notes,
        'status': a.status,
        'ownerId': a.ownerId,
        'createdAt': FieldValue.serverTimestamp(),
      });
      debugPrint('Appointment saved with ID: ${docRef.id}');
      final apptWithId = Appointment(
        id: docRef.id,
        petId: a.petId,
        title: a.title,
        vet: a.vet,
        date: a.date,
        time: a.time,
        type: a.type,
        notes: a.notes,
        status: a.status,
        ownerId: a.ownerId,
      );
      setState(() => _appointments.insert(0, apptWithId));
    } catch (error) {
      debugPrint('Appointment add failed: $error');
      messenger.showSnackBar(SnackBar(
        content: Text('Could not save appointment. Please check your connection and try again.',
            style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
        backgroundColor: FurPalsColors.heartRed,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ));
    }
  }
  void _updateAppointment(Appointment a) async {
    final messenger = ScaffoldMessenger.of(context);
    if (a.id.isEmpty) {
      messenger.showSnackBar(SnackBar(
        content: Text('Unable to save appointment: missing appointment ID.',
            style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
        backgroundColor: FurPalsColors.heartRed,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ));
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('appointments').doc(a.id).update({
        'petId': a.petId,
        'title': a.title,
        'vet': a.vet,
        'date': a.date,
        'time': a.time,
        'type': a.type,
        'notes': a.notes,
        'status': a.status,
      });
      setState(() {
        final idx = _appointments.indexWhere((x) => x.id == a.id);
        if (idx != -1) _appointments[idx] = a;
      });
    } catch (error) {
      debugPrint('Appointment update failed: $error');
      messenger.showSnackBar(SnackBar(
        content: Text('Could not save appointment. Please try again.',
            style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
        backgroundColor: FurPalsColors.heartRed,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ));
    }
  }

  void _deleteAppointment(String id) async {
    if (id.isEmpty) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await FirebaseFirestore.instance.collection('appointments').doc(id).delete();
      setState(() => _appointments.removeWhere((x) => x.id == id));
    } catch (error) {
      debugPrint('Appointment delete failed: $error');
      messenger.showSnackBar(SnackBar(
        content: Text('Could not delete appointment. Please try again.',
            style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
        backgroundColor: FurPalsColors.heartRed,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ));
    }
  }

  void _addEvent(PetEvent newEvent) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;
    final docRef = await FirebaseFirestore.instance.collection('events').add({
      'emoji': newEvent.emoji,
      'title': newEvent.title,
      'location': newEvent.location,
      'date': newEvent.date,
      'time': newEvent.time,
      'category': newEvent.category,
      'description': newEvent.description,
      'color1': newEvent.color1.value,
      'color2': newEvent.color2.value,
      'photoPath': newEvent.photoPath,
      'photoUrl': null,
      'ownerId': currentUser.uid,
      'ownerName': 'You',
      'ownerEmoji': '🐾',
      'members': [],
      'createdAt': FieldValue.serverTimestamp(),
    });

    String? uploadedUrl;
    if (newEvent.photoPath != null && newEvent.photoPath!.isNotEmpty) {
      uploadedUrl = await _uploadEventPhoto(newEvent.photoPath!, currentUser.uid, docRef.id);
      if (uploadedUrl != null) {
        await docRef.update({'photoUrl': uploadedUrl});
      }
    }

    final eventWithId = PetEvent(
      id: docRef.id,
      emoji: newEvent.emoji,
      title: newEvent.title,
      location: newEvent.location,
      date: newEvent.date,
      time: newEvent.time,
      category: newEvent.category,
      description: newEvent.description,
      color1: newEvent.color1,
      color2: newEvent.color2,
      photoPath: newEvent.photoPath,
      photoUrl: uploadedUrl,
      isOwner: true,
      ownerName: 'You',
      ownerEmoji: '🐾',
      ownerId: currentUser.uid,
      members: [],
    );
    setState(() => _events.insert(0, eventWithId));
  }

  void _updateEvent(PetEvent updated) async {
    String? photoUrl = updated.photoUrl;
    if (updated.photoPath != null && updated.photoPath!.isNotEmpty && !updated.photoPath!.startsWith('http')) {
      photoUrl = await _uploadEventPhoto(updated.photoPath!, updated.ownerId, updated.id);
    }

    await FirebaseFirestore.instance.collection('events').doc(updated.id).update({
      'emoji': updated.emoji,
      'title': updated.title,
      'location': updated.location,
      'date': updated.date,
      'time': updated.time,
      'category': updated.category,
      'description': updated.description,
      'color1': updated.color1.value,
      'color2': updated.color2.value,
      'photoPath': updated.photoPath,
      'photoUrl': photoUrl,
    });
    setState(() {
      final idx = _events.indexWhere((e) => e.id == updated.id);
      if (idx != -1) {
        _events[idx] = PetEvent(
        id: updated.id,
        emoji: updated.emoji,
        title: updated.title,
        location: updated.location,
        date: updated.date,
        time: updated.time,
        category: updated.category,
        description: updated.description,
        color1: updated.color1,
        color2: updated.color2,
        photoPath: updated.photoPath,
        photoUrl: photoUrl,
        isOwner: updated.isOwner,
        ownerName: updated.ownerName,
        ownerEmoji: updated.ownerEmoji,
        ownerId: updated.ownerId,
        members: updated.members,
      );
      }
    });
  }

  void _deleteEvent(String id) async {
    await FirebaseFirestore.instance.collection('events').doc(id).delete();
    setState(() => _events.removeWhere((e) => e.id == id));
  }

  void _openEventDetail(PetEvent event) {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => EventDetailScreen(
        event: event,
        onDelete: () => _deleteEvent(event.id),
        onEdit: (eventToEdit) {
          Navigator.pop(context);
          Navigator.push(context, MaterialPageRoute(
            builder: (_) => AddEventScreen(
              onAdd: _addEvent, onUpdate: _updateEvent,
              eventToEdit: eventToEdit,
            ),
          ));
        },
      ),
    ));
  }

  void _openPetProfile(Pet pet) {
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (_) => _PetProfileSheet(pet: pet, appointments: _appointments, onSave: _updatePet),
    );
  }

  void _openAddPet() {
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (_) => _AddPetSheet(existingCount: _pets.length, onAdd: _addPet),
    );
  }

  void _openAppointmentDetail(Appointment appointment, Pet pet) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black.withOpacity(0.50),
      useRootNavigator: true,
      transitionDuration: const Duration(milliseconds: 220),
      transitionBuilder: (_, anim, __, child) => ScaleTransition(
        scale: CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
        child: FadeTransition(opacity: anim, child: child),
      ),
      pageBuilder: (_, __, ___) => MediaQuery.removeViewInsets(
        removeBottom: true,
        context: context,
        child: Align(
          alignment: Alignment.center,
          child: _AppointmentDetailModal(
            appointment: appointment,
            pet: pet,
            onMarkDone: _updateAppointment,
            onEdit: (appt) {
              // 1. close the detail modal if it is still open
              if (Navigator.of(context, rootNavigator: true).canPop()) {
                Navigator.of(context, rootNavigator: true).pop();
              }
              // 2. open CalendarScreen with existing data pre-filled
              Future.delayed(const Duration(milliseconds: 150), () async {
                final result = await Navigator.push<Appointment>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CalendarScreen(
                      pets: _pets,
                      appointmentToEdit: appt, // ← pre-fills all fields
                    ),
                  ),
                );
                // 3. if user saved, update the list
                if (result != null) _updateAppointment(result);
              });
            },
            onDelete: () {
              if (Navigator.of(context, rootNavigator: true).canPop()) {
                Navigator.of(context, rootNavigator: true).pop();
              }
              _deleteAppointment(appointment.id);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('🗑️ Appointment deleted.', style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
                backgroundColor: FurPalsColors.heartRed,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ));
            },
          ),
        ),
      ),
    );
  }

  Future<void> _navigateToNewAppointment() async {
    final result = await Navigator.push<Appointment>(
      context,
      MaterialPageRoute(
        builder: (_) => CalendarScreen(pets: _pets),
      ),
    );
    if (result != null) _addAppointment(result);
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: models.appBackgroundGradient),
      child: SafeArea(
        bottom: false,
        child: Column(children: [
          _buildTopBar(),
          Expanded(
            child: Container(
              color: Colors.white.withOpacity(0.4),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
                children: [
                  _buildPetManagementTitle(),
                  const SizedBox(height: 12),
                  _buildSearchBar(),
                  const SizedBox(height: 18),
                  _buildEventsSection(),
                  const SizedBox(height: 18),
                  _buildAppointmentsSection(),
                ],
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildTopBar() {
    final user        = FirebaseAuth.instance.currentUser;
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
          child: Row(children: [
            Builder(
              builder: (ctx) => GestureDetector(
                onTap: () => Scaffold.of(ctx).openDrawer(),
                child: Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(color: FurPalsColors.shadow, blurRadius: 10, offset: Offset(0, 3))
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
              child: Row(children: [
                Flexible(
                  child: Text(displayName,
                    overflow: TextOverflow.ellipsis, maxLines: 1,
                    style: GoogleFonts.baloo2(
                      fontSize: 25, fontWeight: FontWeight.w800, color: FurPalsColors.textDark),
                  ),
                ),
                const SizedBox(width: 6),
                const Text('🐾', style: TextStyle(fontSize: 18)),
              ]),
            ),
            GestureDetector(
              onTap: () async {
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
                    decoration: BoxDecoration(
                      color: FurPalsColors.warmWhite,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [
                        BoxShadow(color: Color(0x40F4738A), blurRadius: 12, offset: Offset(0, 4))
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
                            BoxShadow(color: Color(0x55E53935), blurRadius: 4, offset: Offset(0, 1))
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ]),
        );
      },
    );
  }

  Widget _buildPetManagementTitle() {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      ShaderMask(
        shaderCallback: (b) => const LinearGradient(
            colors: [FurPalsColors.pink, FurPalsColors.pinkLight]).createShader(b),
        child: Text('Pet ',
            style: GoogleFonts.baloo2(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.white)),
      ),
      ShaderMask(
        shaderCallback: (b) => const LinearGradient(
            colors: [FurPalsColors.green, Color(0xFF3DA864)]).createShader(b),
        child: Text('Management',
            style: GoogleFonts.baloo2(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.white)),
      ),
      const SizedBox(width: 6),
      const Text('🐾', style: TextStyle(fontSize: 20)),
    ]);
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF0E4DC), width: 1.5),
        boxShadow: const [BoxShadow(color: FurPalsColors.shadow, blurRadius: 4, offset: Offset(0, 3))],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      child: Row(children: [
        const Icon(Icons.search_rounded, color: FurPalsColors.textSoft, size: 22),
        const SizedBox(width: 8),
        Expanded(child: TextField(
          onChanged: (v) => setState(() => _searchQuery = v),
          decoration: InputDecoration(
            hintText: 'Search pets or appointments...',
            hintStyle: GoogleFonts.nunito(
                color: FurPalsColors.textSoft, fontSize: 13, fontWeight: FontWeight.w500),
            border: InputBorder.none, isDense: true,
            contentPadding: const EdgeInsets.symmetric(vertical: 10),
          ),
          style: GoogleFonts.nunito(
              fontSize: 13, fontWeight: FontWeight.w600, color: FurPalsColors.textDark),
        )),
      ]),
    );
  }

  Widget _buildEventsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          _sectionLabel('Events'),
          const SizedBox(width: 6),
          const Icon(Icons.calendar_month_rounded, size: 16, color: FurPalsColors.textMid),
        ]),
        const SizedBox(height: 8),
        SizedBox(
          height: 200,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(
                  builder: (_) => AddEventScreen(
                    onAdd: _addEvent, onUpdate: _updateEvent,
                  ),
                )),
                child: Container(
                  width: 300, height: 200,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE0C8C0), width: 2),
                    color: Colors.white.withOpacity(0.6),
                  ),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Icon(Icons.add_rounded, color: FurPalsColors.pink, size: 36),
                    const SizedBox(height: 8),
                    Text('Add Event',
                        style: GoogleFonts.nunito(
                            fontSize: 13, fontWeight: FontWeight.w700, color: FurPalsColors.textMid)),
                  ]),
                ),
              ),
              ..._events.map((event) => GestureDetector(
                    onTap: () => _openEventDetail(event),
                    child: _buildEventCard(event),
                  )),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEventCard(PetEvent event) {
    return Container(
      width: 300, height: 200,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: (event.photoPath == null || event.photoPath!.isEmpty)
            ? LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: [event.color1, event.color2])
            : null,
      ),
      clipBehavior: Clip.hardEdge,
      child: Stack(children: [
        if (event.photoUrl != null && event.photoUrl!.isNotEmpty)
          Positioned.fill(
            child: Image.network(
              event.photoUrl!,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return const Center(child: CircularProgressIndicator());
              },
              errorBuilder: (_, __, ___) => Center(child: Text(event.emoji, style: const TextStyle(fontSize: 60))),
            ),
          ) else if (event.photoPath != null && event.photoPath!.isNotEmpty)
          Positioned.fill(child: Image.file(File(event.photoPath!), fit: BoxFit.cover))
        else
          Center(child: Text(event.emoji, style: const TextStyle(fontSize: 60))),
        if (event.isOwner)
          Positioned(top: 8, right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: FurPalsColors.pink, borderRadius: BorderRadius.circular(20)),
              child: Text('My Event',
                  style: GoogleFonts.nunito(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.white)),
            ),
          ),
        Positioned(
          bottom: 0, left: 0, right: 0,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.88),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(event.title,
                  style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w800, color: FurPalsColors.textDark),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 2),
              Text('${event.date} · ${event.location}',
                  style: GoogleFonts.nunito(fontSize: 11, fontWeight: FontWeight.w600, color: FurPalsColors.textMid),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: FurPalsColors.blush, borderRadius: BorderRadius.circular(20)),
                  child: Text(event.category,
                      style: GoogleFonts.nunito(fontSize: 9, fontWeight: FontWeight.w800, color: FurPalsColors.pink)),
                ),
                const Spacer(),
                const Icon(Icons.people_rounded, size: 11, color: FurPalsColors.textMid),
                const SizedBox(width: 3),
                Text('${event.members.length}',
                    style: GoogleFonts.nunito(fontSize: 10, fontWeight: FontWeight.w700, color: FurPalsColors.textMid)),
              ]),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _buildAppointmentsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          _sectionLabel('Appointments'),
          const Spacer(),
          GestureDetector(
            onTap: _navigateToNewAppointment,
            child: Container(
              width: 30, height: 30,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                gradient: const LinearGradient(
                    colors: [Color.fromARGB(255, 2, 2, 2), Color.fromARGB(255, 0, 0, 0)]),
              ),
              child: const Icon(Icons.add_rounded, color: Colors.white, size: 20),
            ),
          ),
        ]),
        const SizedBox(height: 10),
        if (_filteredAppts.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Text('No appointments found 🐾',
                  style: GoogleFonts.nunito(
                      fontSize: 13, fontWeight: FontWeight.w600, color: FurPalsColors.textSoft)),
            ),
          )
        else
          ..._filteredAppts.map((a) {
            final pet = _pets.firstWhere((p) => p.id == a.petId, orElse: () => _pets[0]);
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GestureDetector(
                onTap: () => _openAppointmentDetail(a, pet),
                child: _AppointmentCard(appointment: a, pet: pet),
              ),
            );
          }),
      ],
    );
  }

  Widget _sectionLabel(String text) => Text(text,
      style: GoogleFonts.baloo2(fontSize: 20, fontWeight: FontWeight.w800, color: FurPalsColors.textDark));
}

// ── Appointment Detail Modal ──────────────────────────────────────────────────
class _AppointmentDetailModal extends StatelessWidget {
  final Appointment appointment;
  final Pet pet;
  final ValueChanged<Appointment>? onMarkDone;
  final ValueChanged<Appointment>? onEdit;
  final VoidCallback? onDelete;

  const _AppointmentDetailModal({
    required this.appointment,
    required this.pet,
    this.onMarkDone,
    this.onEdit,
    this.onDelete,
  });

  static const _modalBg  = Color(0xFFE8C9A0);
  static const _btnClose = Color(0xFFCCE8F0);
  static const _btnDone  = Color(0xFFC5EDD6);
  static const _dark     = Color(0xFF111111);

  @override
  Widget build(BuildContext context) {
    final screenH = MediaQuery.of(context).size.height;
    final screenW = MediaQuery.of(context).size.width;
    final bool isDone = appointment.status == 'done';

    final Color badgeFg;
    final String badgeLabel;
    final List<Color> heroColors;

    switch (appointment.status) {
      case 'today':
        badgeFg    = FurPalsColors.pink;
        badgeLabel = 'Today';
        heroColors = [FurPalsColors.blush, FurPalsColors.peach];
        break;
      case 'done':
        badgeFg    = FurPalsColors.green;
        badgeLabel = 'Done';
        heroColors = [FurPalsColors.mint, const Color(0xFFB8F0CC)];
        break;
      default:
        badgeFg    = FurPalsColors.purple;
        badgeLabel = 'Upcoming';
        heroColors = [FurPalsColors.lavender, const Color(0xFFF0EBFF)];
    }

    return Material(
      color: Colors.transparent,
      child: Container(
        width:  screenW * 0.88,
        height: screenH * 0.68,
        decoration: BoxDecoration(
          color: _modalBg,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: Colors.black, width: 2.5),
          boxShadow: const [
            BoxShadow(color: Colors.black, offset: Offset(5, 5), blurRadius: 0),
          ],
        ),
        child: Column(
          children: [

            // ── Title + Edit button ────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 20, 16, 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text('Appointment Detail',
                        style: GoogleFonts.baloo2(
                            fontSize: 18, fontWeight: FontWeight.w700, color: _dark)),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context, rootNavigator: true).pop();
                      Future.delayed(const Duration(milliseconds: 150), () {
                        onEdit?.call(appointment);
                      });
                    },
                    child: Container(
                      width: 38, height: 38,
                      decoration: BoxDecoration(
                        color: FurPalsColors.lavender,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.black, width: 1.5),
                      ),
                      child: const Icon(Icons.edit_rounded,
                          color: FurPalsColors.purple, size: 18),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          backgroundColor: FurPalsColors.warmWhite,
                          title: Text('Delete Appointment',
                              style: GoogleFonts.baloo2(fontWeight: FontWeight.w800, color: FurPalsColors.textDark, fontSize: 18)),
                          content: Text(
                            'Delete "${appointment.title}"? This cannot be undone.',
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
                                onDelete?.call();
                              },
                              child: Text('Delete', style: GoogleFonts.nunito(fontWeight: FontWeight.w800)),
                            ),
                          ],
                        ),
                      );
                    },
                    child: Container(
                      width: 38, height: 38,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFE2E2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.black, width: 1.5),
                      ),
                      child: const Icon(Icons.delete_rounded,
                          color: FurPalsColors.heartRed, size: 18),
                    ),
                  ),
                ],
              ),
            ),

            // ── White inner scrollable card ──────────────────────────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.black, width: 2),
                    boxShadow: const [
                      BoxShadow(color: Colors.black, offset: Offset(3, 3), blurRadius: 0),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Hero gradient card
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: heroColors),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 54, height: 54,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white.withOpacity(0.75),
                                    border: Border.all(color: Colors.white, width: 2),
                                  ),
                                  child: Center(child: Text(pet.emoji, style: const TextStyle(fontSize: 26))),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.75),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Text(badgeLabel,
                                            style: GoogleFonts.nunito(
                                                fontSize: 10, fontWeight: FontWeight.w800, color: badgeFg)),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(appointment.title,
                                          style: GoogleFonts.baloo2(
                                              fontSize: 16, fontWeight: FontWeight.w800,
                                              color: FurPalsColors.textDark, height: 1.15)),
                                      Text('${appointment.time}  ·  ${appointment.date}',
                                          style: GoogleFonts.nunito(
                                              fontSize: 11, fontWeight: FontWeight.w600,
                                              color: FurPalsColors.textMid)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 12),

                          _ModalDetailRow(icon: Icons.pets_rounded,           iconColor: FurPalsColors.pink,      iconBg: FurPalsColors.blush,    label: 'Pet',          value: '${pet.name}  ·  ${pet.breed}'),
                          const SizedBox(height: 8),
                          _ModalDetailRow(icon: Icons.local_hospital_rounded, iconColor: FurPalsColors.purple,    iconBg: FurPalsColors.lavender, label: 'Vet / Clinic', value: appointment.vet),
                          const SizedBox(height: 8),
                          _ModalDetailRow(icon: Icons.category_rounded,       iconColor: FurPalsColors.green,     iconBg: FurPalsColors.mint,     label: 'Type',         value: appointment.type),
                          const SizedBox(height: 8),
                          _ModalDetailRow(icon: Icons.calendar_today_rounded, iconColor: const Color(0xFFE9963A), iconBg: FurPalsColors.butter,   label: 'Date',         value: appointment.date),
                          const SizedBox(height: 8),
                          _ModalDetailRow(icon: Icons.access_time_rounded,    iconColor: FurPalsColors.blue,      iconBg: const Color(0xFFE3EDFF),label: 'Time',         value: appointment.time),

                          if (appointment.notes.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Text('NOTES',
                                style: GoogleFonts.nunito(
                                    fontSize: 11, fontWeight: FontWeight.w800,
                                    color: FurPalsColors.textMid, letterSpacing: 0.4)),
                            const SizedBox(height: 6),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: FurPalsColors.creamwhite,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFF0E4DC), width: 1.5),
                              ),
                              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                const Text('📝', style: TextStyle(fontSize: 14)),
                                const SizedBox(width: 8),
                                Expanded(child: Text(appointment.notes,
                                    style: GoogleFonts.nunito(
                                        fontSize: 12, fontWeight: FontWeight.w600,
                                        color: FurPalsColors.textMid, height: 1.5))),
                              ]),
                            ),
                          ],
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // ── Bottom buttons ─────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
              child: Row(
                children: [
                  // CLOSE
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.of(context, rootNavigator: true).pop(),
                      child: Container(
                        height: 50,
                        decoration: BoxDecoration(
                          color: _btnClose,
                          borderRadius: BorderRadius.circular(50),
                          border: Border.all(color: _dark, width: 2.5),
                          boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(3, 3), blurRadius: 0)],
                        ),
                        child: Center(child: Text('CLOSE',
                            style: GoogleFonts.baloo2(fontSize: 14, letterSpacing: 1.5, color: _dark))),
                      ),
                    ),
                  ),

                  const SizedBox(width: 10),

                  // DONE APPOINTMENT
                  Expanded(
                    flex: 2,
                    child: GestureDetector(
                      onTap: isDone
                          ? null
                          : () {
                              final updated = Appointment(
                                id:      appointment.id,
                                petId:   appointment.petId,
                                title:   appointment.title,
                                vet:     appointment.vet,
                                date:    appointment.date,
                                time:    appointment.time,
                                type:    appointment.type,
                                notes:   appointment.notes,
                                status:  'done',
                                ownerId: appointment.ownerId,
                              );
                              onMarkDone?.call(updated);
                              Navigator.of(context, rootNavigator: true).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('✅ Appointment marked as done!',
                                      style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
                                  backgroundColor: FurPalsColors.green,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14)),
                                ),
                              );
                            },
                      child: Container(
                        height: 50,
                        decoration: BoxDecoration(
                          color: isDone ? _btnDone : const Color(0xFFF9C8D0),
                          borderRadius: BorderRadius.circular(50),
                          border: Border.all(color: _dark, width: 2.5),
                          boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(3, 3), blurRadius: 0)],
                        ),
                        child: Center(
                          child: Text(
                            isDone ? '✅ ALREADY DONE' : 'DONE APPOINTMENT 🐾',
                            style: GoogleFonts.baloo2(fontSize: 13, letterSpacing: 0.8, color: _dark),
                          ),
                        ),
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

// ── Modal Detail Row ──────────────────────────────────────────────────────────
class _ModalDetailRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor, iconBg;
  final String label, value;

  const _ModalDetailRow({
    required this.icon, required this.iconColor, required this.iconBg,
    required this.label, required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 34, height: 34,
          decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(10)),
          child: Center(child: Icon(icon, size: 16, color: iconColor)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: GoogleFonts.nunito(
                fontSize: 10, fontWeight: FontWeight.w700,
                color: FurPalsColors.textMid, letterSpacing: 0.3)),
            Text(value, style: GoogleFonts.nunito(
                fontSize: 13, fontWeight: FontWeight.w700, color: FurPalsColors.textDark),
                overflow: TextOverflow.ellipsis),
          ]),
        ),
      ],
    );
  }
}

// ── Appointment Card ──────────────────────────────────────────────────────────
class _AppointmentCard extends StatelessWidget {
  final Appointment appointment;
  final Pet pet;
  const _AppointmentCard({required this.appointment, required this.pet});

  @override
  Widget build(BuildContext context) {
    final Color badgeBg; final Color badgeFg; final String badgeLabel;
    switch (appointment.status) {
      case 'today':   badgeBg = const Color(0xFFFFF0F3); badgeFg = FurPalsColors.pink;   badgeLabel = 'Today';    break;
      case 'done':    badgeBg = FurPalsColors.mint;      badgeFg = FurPalsColors.green;  badgeLabel = 'Done';     break;
      default:        badgeBg = FurPalsColors.lavender;  badgeFg = FurPalsColors.purple; badgeLabel = 'Upcoming';
    }
    final avatarGrad = appointment.type.contains('Groom')
        ? [FurPalsColors.peach, FurPalsColors.butter]
        : [FurPalsColors.lavender, FurPalsColors.mint];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: FurPalsColors.shadow, blurRadius: 8, offset: Offset(0, 3))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
          child: Row(children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: avatarGrad)),
              padding: const EdgeInsets.all(2.5),
              child: Container(
                decoration: const BoxDecoration(shape: BoxShape.circle, color: FurPalsColors.warmWhite),
                child: Center(child: Text(pet.emoji, style: const TextStyle(fontSize: 22))),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(appointment.title,
                  style: GoogleFonts.baloo2(fontSize: 15, fontWeight: FontWeight.w800,
                      color: FurPalsColors.textDark, height: 1.15)),
              const SizedBox(height: 2),
              Text('${pet.name} · ${appointment.type}',
                  style: GoogleFonts.nunito(fontSize: 11, fontWeight: FontWeight.w600,
                      color: FurPalsColors.textMid)),
            ])),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: badgeBg, borderRadius: BorderRadius.circular(20)),
              child: Text(badgeLabel,
                  style: GoogleFonts.nunito(fontSize: 10, fontWeight: FontWeight.w800, color: badgeFg)),
            ),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 6),
          child: Wrap(spacing: 8, runSpacing: 6, children: [
            _pill(Icons.calendar_today_rounded, appointment.date,                             const Color(0xFFFFF0F3), FurPalsColors.pink),
            _pill(Icons.access_time_rounded,    appointment.time,                             const Color(0xFFF0EBFF), FurPalsColors.purple),
            _pill(Icons.location_on_rounded,    appointment.vet.split(' ').take(2).join(' '), const Color(0xFFEAF7F0), FurPalsColors.green),
          ]),
        ),
        if (appointment.notes.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 2, 14, 14),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(color: FurPalsColors.creamwhite, borderRadius: BorderRadius.circular(12)),
              child: Text('📝  ${appointment.notes}',
                  style: GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.w600, color: FurPalsColors.textMid)),
            ),
          )
        else
          const SizedBox(height: 8),
      ]),
    );
  }

  Widget _pill(IconData icon, String label, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 12, color: fg),
        const SizedBox(width: 5),
        Text(label, style: GoogleFonts.nunito(fontSize: 11, fontWeight: FontWeight.w700, color: FurPalsColors.textMid)),
      ]),
    );
  }
}

// ── Pet Profile Sheet ─────────────────────────────────────────────────────────
class _PetProfileSheet extends StatefulWidget {
  final Pet pet;
  final List<Appointment> appointments;
  final ValueChanged<Pet> onSave;
  const _PetProfileSheet({required this.pet, required this.appointments, required this.onSave});
  @override State<_PetProfileSheet> createState() => _PetProfileSheetState();
}

class _PetProfileSheetState extends State<_PetProfileSheet> {
  late TextEditingController _name, _breed, _age, _weight, _vet, _notes;
  late String _gender;

  @override
  void initState() {
    super.initState();
    final p = widget.pet;
    _name = TextEditingController(text: p.name); _breed = TextEditingController(text: p.breed);
    _age  = TextEditingController(text: p.age);  _weight = TextEditingController(text: p.weight);
    _vet  = TextEditingController(text: p.vet);  _notes  = TextEditingController(text: p.notes);
    _gender = p.gender;
  }

  @override
  void dispose() {
    for (final c in [_name,_breed,_age,_weight,_vet,_notes]) c.dispose();
    super.dispose();
  }

  void _save() {
    widget.onSave(Pet(
      id: widget.pet.id, emoji: widget.pet.emoji,
      name:   _name.text.isEmpty   ? widget.pet.name   : _name.text,
      breed:  _breed.text.isEmpty  ? widget.pet.breed  : _breed.text,
      gender: _gender,
      age:    _age.text.isEmpty    ? widget.pet.age    : _age.text,
      weight: _weight.text.isEmpty ? widget.pet.weight : _weight.text,
      vet:    _vet.text.isEmpty    ? widget.pet.vet    : _vet.text,
      notes:  _notes.text, online: widget.pet.online, vaccinations: widget.pet.vaccinations,
    ));
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('${_name.text} updated!', style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
      backgroundColor: FurPalsColors.green, behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.pet;
    final apptCount = widget.appointments.where((a) => a.petId == p.id).length;
    final vaccDone  = p.vaccinations.where((v) => v.status == 'done').length;
    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: const BoxDecoration(color: FurPalsColors.warmWhite, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      child: Column(children: [
        const SizedBox(height: 12),
        Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: FurPalsColors.blush, borderRadius: BorderRadius.circular(2)))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(children: [
            const Spacer(),
            GestureDetector(onTap: () => Navigator.pop(context),
              child: Container(width: 32, height: 32,
                  decoration: BoxDecoration(color: FurPalsColors.blush, borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.close_rounded, color: FurPalsColors.pink, size: 18))),
          ]),
        ),
        Expanded(child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(child: Column(children: [
              Container(width: 90, height: 90,
                decoration: const BoxDecoration(shape: BoxShape.circle,
                    gradient: LinearGradient(colors: [FurPalsColors.pink, FurPalsColors.pinkLight])),
                padding: const EdgeInsets.all(4),
                child: Container(
                  decoration: const BoxDecoration(shape: BoxShape.circle,
                      gradient: LinearGradient(colors: [FurPalsColors.blush, FurPalsColors.peach])),
                  child: Center(child: Text(p.emoji, style: const TextStyle(fontSize: 44))),
                )),
              const SizedBox(height: 10),
              Text(p.name, style: GoogleFonts.baloo2(fontSize: 24, fontWeight: FontWeight.w800, color: FurPalsColors.textDark)),
              Text('${p.breed} · ${p.gender}', style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w600, color: FurPalsColors.textMid)),
              const SizedBox(height: 8),
              Wrap(spacing: 8, children: [
                _tag(p.age, const Color(0xFFFFF0F3), FurPalsColors.pink),
                _tag(p.weight, FurPalsColors.mint, FurPalsColors.green),
                _tag(p.vet, FurPalsColors.lavender, FurPalsColors.purple),
              ]),
            ])),
            const SizedBox(height: 16),
            Row(children: [
              _statCard(p.age, 'Age'), const SizedBox(width: 10),
              _statCard(p.weight, 'Weight'), const SizedBox(width: 10),
              _statCard('$apptCount', 'Appts'), const SizedBox(width: 10),
              _statCard('$vaccDone/${p.vaccinations.length}', 'Vacc'),
            ]),
            const SizedBox(height: 18),
            _sheetLabel('💉 Vaccination Records'), const SizedBox(height: 8),
            ...p.vaccinations.map(_buildVaccRow),
            const SizedBox(height: 18),
            _sheetLabel('✏️ Edit Info'), const SizedBox(height: 10),
            _field('PET NAME', _name), const SizedBox(height: 12),
            Row(children: [Expanded(child: _field('BREED', _breed)), const SizedBox(width: 12), Expanded(child: _genderDropdown())]),
            const SizedBox(height: 12),
            Row(children: [Expanded(child: _field('AGE', _age)), const SizedBox(width: 12), Expanded(child: _field('WEIGHT', _weight))]),
            const SizedBox(height: 12),
            _field("VET'S NAME", _vet), const SizedBox(height: 12),
            _field('NOTES', _notes, maxLines: 2), const SizedBox(height: 20),
            _gradientBtn('Save Changes', _save),
          ]),
        )),
      ]),
    );
  }

  Widget _tag(String t, Color bg, Color fg) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
    child: Text(t, style: GoogleFonts.nunito(fontSize: 11, fontWeight: FontWeight.w800, color: fg)),
  );

  Widget _statCard(String val, String key) => Expanded(child: Container(
    padding: const EdgeInsets.symmetric(vertical: 12),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: FurPalsColors.shadow, blurRadius: 6, offset: Offset(0, 2))]),
    child: Column(children: [
      Text(val, style: GoogleFonts.baloo2(fontSize: 16, fontWeight: FontWeight.w800, color: FurPalsColors.textDark)),
      Text(key, style: GoogleFonts.nunito(fontSize: 10, fontWeight: FontWeight.w700, color: FurPalsColors.textMid)),
    ]),
  ));

  Widget _buildVaccRow(VaccinationRecord v) {
    final bg     = v.status == 'done' ? const Color(0xFFEAF7F0) : v.status == 'due' ? FurPalsColors.butter : const Color(0xFFFFE4E4);
    final chip   = v.status == 'done' ? 'Done' : v.status == 'due' ? 'Due' : 'Overdue';
    final chipBg = v.status == 'done' ? FurPalsColors.mint : v.status == 'due' ? FurPalsColors.butter : const Color(0xFFFFE4E4);
    final chipFg = v.status == 'done' ? FurPalsColors.green : v.status == 'due' ? const Color(0xFFB06A10) : FurPalsColors.heartRed;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
          boxShadow: const [BoxShadow(color: FurPalsColors.shadow, blurRadius: 4, offset: Offset(0, 1))]),
      child: Row(children: [
        Container(width: 34, height: 34, decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
          child: Center(child: Text(v.status == 'done' ? '✅' : v.status == 'due' ? '📅' : '⚠️', style: const TextStyle(fontSize: 16)))),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(v.name, style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w700, color: FurPalsColors.textDark)),
          Text(v.date, style: GoogleFonts.nunito(fontSize: 10, fontWeight: FontWeight.w600, color: FurPalsColors.textMid)),
        ])),
        Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(color: chipBg, borderRadius: BorderRadius.circular(20)),
          child: Text(chip, style: GoogleFonts.nunito(fontSize: 10, fontWeight: FontWeight.w800, color: chipFg))),
      ]),
    );
  }

  Widget _sheetLabel(String t) => Text(t, style: GoogleFonts.baloo2(fontSize: 14, fontWeight: FontWeight.w800, color: FurPalsColors.textDark));

  Widget _field(String label, TextEditingController ctrl, {int maxLines = 1}) => Column(
    crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: GoogleFonts.nunito(fontSize: 11, fontWeight: FontWeight.w800, color: FurPalsColors.textMid, letterSpacing: 0.3)),
      const SizedBox(height: 5),
      TextField(controller: ctrl, maxLines: maxLines,
        style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w600, color: FurPalsColors.textDark),
        decoration: InputDecoration(contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          filled: true, fillColor: Colors.white,
          border:        OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFF0E4DC), width: 1.5)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFF0E4DC), width: 1.5)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: FurPalsColors.pink, width: 1.5)))),
    ],
  );

  Widget _genderDropdown() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text('GENDER', style: GoogleFonts.nunito(fontSize: 11, fontWeight: FontWeight.w800, color: FurPalsColors.textMid, letterSpacing: 0.3)),
    const SizedBox(height: 5),
    DropdownButtonFormField<String>(value: _gender, onChanged: (v) => setState(() => _gender = v!),
      items: ['Female','Male'].map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
      style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w600, color: FurPalsColors.textDark),
      decoration: InputDecoration(contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        filled: true, fillColor: Colors.white,
        border:        OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFF0E4DC), width: 1.5)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFF0E4DC), width: 1.5)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: FurPalsColors.pink, width: 1.5)))),
  ]);
}

// ── Add Pet Sheet ─────────────────────────────────────────────────────────────
class _AddPetSheet extends StatefulWidget {
  final int existingCount; final ValueChanged<Pet> onAdd;
  const _AddPetSheet({required this.existingCount, required this.onAdd});
  @override State<_AddPetSheet> createState() => _AddPetSheetState();
}

class _AddPetSheetState extends State<_AddPetSheet> {
  final _emojis = ['🐱','🐶','🐰','🐾','🦮','🐹','🐦','🐠','🐢','🐍'];
  String _selectedEmoji = '🐱', _gender = 'Female';
  final _name = TextEditingController(), _breed = TextEditingController(),
        _age  = TextEditingController(), _weight = TextEditingController();

  @override void dispose() { for (final c in [_name,_breed,_age,_weight]) c.dispose(); super.dispose(); }

  void _submit() {
    if (_name.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Please enter a pet name 🐾', style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
        backgroundColor: FurPalsColors.textDark, behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))));
      return;
    }
    widget.onAdd(Pet(id: widget.existingCount, emoji: _selectedEmoji, name: _name.text.trim(),
      breed: _breed.text.isEmpty ? 'Unknown' : _breed.text, gender: _gender,
      age: _age.text.isEmpty ? '?' : _age.text, weight: _weight.text.isEmpty ? '?' : _weight.text,
      vet: 'TBD', notes: '', online: true, vaccinations: []));
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('🐾 ${_name.text} added!', style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
      backgroundColor: FurPalsColors.green, behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(color: FurPalsColors.warmWhite, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      child: Column(children: [
        const SizedBox(height: 12),
        Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: FurPalsColors.blush, borderRadius: BorderRadius.circular(2)))),
        Padding(padding: const EdgeInsets.fromLTRB(20, 12, 20, 0), child: Row(children: [
          Text('Add New Pet 🐾', style: GoogleFonts.baloo2(fontSize: 20, fontWeight: FontWeight.w800, color: FurPalsColors.textDark)),
          const Spacer(),
          GestureDetector(onTap: () => Navigator.pop(context),
            child: Container(width: 32, height: 32, decoration: BoxDecoration(color: FurPalsColors.blush, borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.close_rounded, color: FurPalsColors.pink, size: 18))),
        ])),
        Expanded(child: SingleChildScrollView(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('CHOOSE EMOJI', style: GoogleFonts.nunito(fontSize: 11, fontWeight: FontWeight.w800, color: FurPalsColors.textMid, letterSpacing: 0.3)),
          const SizedBox(height: 8),
          Wrap(spacing: 10, runSpacing: 10, children: _emojis.map((e) {
            final sel = e == _selectedEmoji;
            return GestureDetector(onTap: () => setState(() => _selectedEmoji = e),
              child: AnimatedContainer(duration: const Duration(milliseconds: 150), width: 44, height: 44,
                decoration: BoxDecoration(color: sel ? FurPalsColors.blush : Colors.white, borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: sel ? FurPalsColors.pink : const Color(0xFFF0E4DC), width: sel ? 2 : 1.5)),
                child: Center(child: Text(e, style: const TextStyle(fontSize: 22)))));
          }).toList()),
          const SizedBox(height: 16),
          _formField('PET NAME', _name, 'e.g. Fluffy'), const SizedBox(height: 12),
          Row(children: [Expanded(child: _formField('BREED', _breed, 'Breed')), const SizedBox(width: 12),
            Expanded(child: _dropdownField('GENDER', _gender, ['Female','Male'], (v) => setState(() => _gender = v!)))]),
          const SizedBox(height: 12),
          Row(children: [Expanded(child: _formField('AGE', _age, 'e.g. 1y 2m')), const SizedBox(width: 12),
            Expanded(child: _formField('WEIGHT', _weight, 'e.g. 4kg'))]),
          const SizedBox(height: 20),
          _gradientBtn('Add Pet 🐾', _submit),
        ]))),
      ]),
    );
  }
}

// ── Shared form helpers ───────────────────────────────────────────────────────
Widget _formField(String label, TextEditingController ctrl, String hint, {int maxLines = 1}) {
  return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(label, style: GoogleFonts.nunito(fontSize: 11, fontWeight: FontWeight.w800, color: FurPalsColors.textMid, letterSpacing: 0.3)),
    const SizedBox(height: 5),
    TextField(controller: ctrl, maxLines: maxLines,
      style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w600, color: FurPalsColors.textDark),
      decoration: InputDecoration(hintText: hint, hintStyle: GoogleFonts.nunito(fontSize: 13, color: FurPalsColors.textSoft),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11), filled: true, fillColor: Colors.white,
        border:        OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFF0E4DC), width: 1.5)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFF0E4DC), width: 1.5)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: FurPalsColors.pink, width: 1.5)))),
  ]);
}

Widget _dropdownField(String label, String value, List<String> options, ValueChanged<String?> onChanged) {
  return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(label, style: GoogleFonts.nunito(fontSize: 11, fontWeight: FontWeight.w800, color: FurPalsColors.textMid, letterSpacing: 0.3)),
    const SizedBox(height: 5),
    DropdownButtonFormField<String>(value: value, onChanged: onChanged,
      items: options.map((o) => DropdownMenuItem(value: o,
          child: Text(o, style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w600, color: FurPalsColors.textDark)))).toList(),
      decoration: InputDecoration(contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        filled: true, fillColor: Colors.white,
        border:        OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFF0E4DC), width: 1.5)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFF0E4DC), width: 1.5)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: FurPalsColors.pink, width: 1.5)))),
  ]);
}

Widget _gradientBtn(String label, VoidCallback onTap) {
  return GestureDetector(onTap: onTap,
    child: Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(colors: [FurPalsColors.pink, FurPalsColors.pinkLight]),
        boxShadow: const [BoxShadow(color: Color(0x55F4738A), blurRadius: 14, offset: Offset(0, 6))]),
      child: Center(child: Text(label, style: GoogleFonts.baloo2(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)))));
}