import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

// ── Colors / gradient ────────────────────────────────────────────────────────
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
  static const shadow = Color(0x20B47864);
  static const heartRed = Color(0xFFE53935);
}

const appBackgroundGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  stops: [0.0, 0.5, 1.0],
  colors: [Color(0xFFFCDDE8), Color(0xFFFFE8D2), Color(0xFFD4F0E4)],
);

const _speciesOptions = ['Dog', 'Cat', 'Bird', 'Rabbit', 'Fish', 'Other'];

// ── myPetsScreen ─────────────────────────────────────────────────────────────
class myPetsScreen extends StatefulWidget {
  const myPetsScreen({super.key});

  @override
  State<myPetsScreen> createState() => _myPetsScreenState();
}

class _myPetsScreenState extends State<myPetsScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;
  final _searchCtrl = TextEditingController();

  List<Map<String, dynamic>> _pets = [];
  List<Map<String, dynamic>> _filtered = [];
  bool _isLoading = true;

  String get _currentUid => _auth.currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();
    _loadPets();
    _searchCtrl.addListener(_onSearch);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearch() {
    final q = _searchCtrl.text.trim().toLowerCase();
    setState(() {
      _filtered = q.isEmpty
          ? List.from(_pets)
          : _pets
              .where((p) =>
                  (p['name'] as String? ?? '').toLowerCase().contains(q) ||
                  (p['breed'] as String? ?? '').toLowerCase().contains(q) ||
                  (p['species'] as String? ?? '').toLowerCase().contains(q))
              .toList();
    });
  }

  Future<void> _loadPets() async {
    if (_currentUid.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      final snap = await _firestore
          .collection('users')
          .doc(_currentUid)
          .collection('pets')
          .orderBy('createdAt', descending: false)
          .get();
      if (mounted) {
        final list =
            snap.docs.map((d) => {'petId': d.id, ...d.data()}).toList();
        setState(() {
          _pets = list;
          _filtered = List.from(list);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Load pets error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Add pet sheet ─────────────────────────────────────────────────────────
  void _showAddPetSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddPetSheet(
        currentUid: _currentUid,
        firestore: _firestore,
        storage: _storage,
        onAdded: (newPet) {
          setState(() {
            _pets.add(newPet);
            _filtered = List.from(_pets);
          });
          _showSnack('${newPet['name']} added! 🐾', FurPalsColors.green);
        },
        onError: (msg) => _showSnack(msg, FurPalsColors.heartRed),
      ),
    );
  }

  // ── Pet detail sheet ──────────────────────────────────────────────────────
  void _showPetDetailSheet(Map<String, dynamic> pet) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PetDetailSheet(
        pet: pet,
        currentUid: _currentUid,
        firestore: _firestore,
        storage: _storage,
        onDeleted: (petId) {
          setState(() {
            _pets.removeWhere((p) => p['petId'] == petId);
            _filtered.removeWhere((p) => p['petId'] == petId);
          });
          _showSnack('Pet removed', FurPalsColors.textMid);
        },
        onUpdated: (updatedPet) {
          setState(() {
            final idx =
                _pets.indexWhere((p) => p['petId'] == updatedPet['petId']);
            if (idx >= 0) _pets[idx] = updatedPet;
            final fi =
                _filtered.indexWhere((p) => p['petId'] == updatedPet['petId']);
            if (fi >= 0) _filtered[fi] = updatedPet;
          });
          _showSnack('Pet updated 🐾', FurPalsColors.green);
        },
      ),
    );
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg,
            style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: appBackgroundGradient),
        child: SafeArea(
          bottom: false,
          child: DecoratedBox(
            decoration:
                BoxDecoration(color: Colors.white.withOpacity(0.45)),
            child: Column(
              children: [
                _buildAppBar(),
                _buildSearchBar(),
                Expanded(
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                              color: FurPalsColors.pink))
                      : _buildGrid(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
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
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  size: 18, color: FurPalsColors.textDark),
            ),
          ),
          const SizedBox(width: 12),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ShaderMask(
                shaderCallback: (b) => const LinearGradient(
                        colors: [FurPalsColors.pink, FurPalsColors.pinkLight])
                    .createShader(b),
                child: Text('My ',
                    style: GoogleFonts.baloo2(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: Colors.white)),
              ),
              ShaderMask(
                shaderCallback: (b) => const LinearGradient(
                        colors: [FurPalsColors.green, Color(0xFF3DA864)])
                    .createShader(b),
                child: Text('Pets',
                    style: GoogleFonts.baloo2(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: Colors.white)),
              ),
              const SizedBox(width: 6),
              const Text('🐾', style: TextStyle(fontSize: 18)),
            ],
          ),
          const Spacer(),
          if (_pets.isNotEmpty)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: FurPalsColors.blush,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const Icon(Icons.pets_rounded,
                      size: 14, color: FurPalsColors.pink),
                  const SizedBox(width: 4),
                  Text('${_pets.length}',
                      style: GoogleFonts.baloo2(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: FurPalsColors.pink)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFF0E4DC), width: 1.5),
          boxShadow: const [
            BoxShadow(
                color: FurPalsColors.shadow,
                blurRadius: 4,
                offset: Offset(0, 3))
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        child: Row(
          children: [
            const Icon(Icons.search_rounded,
                color: FurPalsColors.textSoft, size: 22),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _searchCtrl,
                decoration: InputDecoration(
                  hintText: 'Search pets...',
                  hintStyle: GoogleFonts.nunito(
                      color: FurPalsColors.textSoft,
                      fontSize: 13,
                      fontWeight: FontWeight.w500),
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
            if (_searchCtrl.text.isNotEmpty)
              GestureDetector(
                onTap: () {
                  _searchCtrl.clear();
                  setState(() => _filtered = List.from(_pets));
                },
                child: const Icon(Icons.close_rounded,
                    color: FurPalsColors.textMid, size: 18),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildGrid() {
    final colorPairs = [
      [const Color(0xFFF9C8D0), const Color(0xFFFFD9C0)],
      [const Color(0xFFC5EDD6), const Color(0xFFDDD0F5)],
      [const Color(0xFFFFD9C0), const Color(0xFFFFF3C4)],
      [const Color(0xFFDDD0F5), const Color(0xFFF9C8D0)],
    ];

    final itemCount = _filtered.length + 1;

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.68,
      ),
      itemCount: itemCount,
      itemBuilder: (_, i) {
        if (i == _filtered.length) {
          return _AddPetTile(onTap: _showAddPetSheet);
        }
        final pet = _filtered[i];
        final pair = colorPairs[i % colorPairs.length];
        return _PetCard(
          pet: pet,
          gradientColors: pair,
          onTap: () => _showPetDetailSheet(pet),
        );
      },
    );
  }
}

// ── Add Pet Sheet (standalone StatefulWidget) ─────────────────────────────────
class _AddPetSheet extends StatefulWidget {
  final String currentUid;
  final FirebaseFirestore firestore;
  final FirebaseStorage storage;
  final void Function(Map<String, dynamic> newPet) onAdded;
  final void Function(String msg) onError;

  const _AddPetSheet({
    required this.currentUid,
    required this.firestore,
    required this.storage,
    required this.onAdded,
    required this.onError,
  });

  @override
  State<_AddPetSheet> createState() => _AddPetSheetState();
}

class _AddPetSheetState extends State<_AddPetSheet> {
  final _nameCtrl = TextEditingController();
  final _breedCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _vetNameCtrl = TextEditingController();
  final _clinicCtrl = TextEditingController();
  final _ownerNameCtrl = TextEditingController();
  final _ownerPhoneCtrl = TextEditingController();
  final _allergyCtrl = TextEditingController();

  String _sex = 'Unknown';
  String _spayedNeutered = 'Unknown';
  DateTime? _birthday;
  File? _imageFile;
  List<String> _allergies = [];
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _breedCtrl.dispose();
    _ageCtrl.dispose();
    _weightCtrl.dispose();
    _vetNameCtrl.dispose();
    _clinicCtrl.dispose();
    _ownerNameCtrl.dispose();
    _ownerPhoneCtrl.dispose();
    _allergyCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickBirthday() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthday ?? now,
      firstDate: DateTime(now.year - 30),
      lastDate: now,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: FurPalsColors.pink,
            onPrimary: Colors.white,
            surface: FurPalsColors.warmWhite,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _birthday = picked);
  }

  void _addAllergy() {
    final a = _allergyCtrl.text.trim();
    if (a.isEmpty) return;
    setState(() {
      _allergies.add(a);
      _allergyCtrl.clear();
    });
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) {
      widget.onError('Please enter a pet name');
      return;
    }
    setState(() => _saving = true);

    try {
      // 1. Upload image separately — don't let it block the save
      String? photoURL;
      if (_imageFile != null) {
        try {
          final tempId = DateTime.now().millisecondsSinceEpoch.toString();
          final ref = widget.storage
              .ref()
              .child('pets/${widget.currentUid}/$tempId.jpg');
          await ref.putFile(
            _imageFile!,
            SettableMetadata(contentType: 'image/jpeg'),
          );
          photoURL = await ref.getDownloadURL();
        } catch (e) {
          debugPrint('Image upload failed (continuing without photo): $e');
          // Continue saving without photo rather than failing entirely
        }
      }

      // 2. Save to Firestore
      final data = {
        'name': _nameCtrl.text.trim(),
        'breed': _breedCtrl.text.trim(),
        'age': _ageCtrl.text.trim(),
        'weight': _weightCtrl.text.trim(),
        'sex': _sex,
        'spayedNeutered': _spayedNeutered,
        'birthday': _birthday != null
            ? _birthday!.toIso8601String().substring(0, 10)
            : null,
        'foodAllergies': _allergies,
        'vetName': _vetNameCtrl.text.trim(),
        'clinic': _clinicCtrl.text.trim(),
        'ownerName': _ownerNameCtrl.text.trim(),
        'ownerPhone': _ownerPhoneCtrl.text.trim(),
        'photoURL': photoURL,
        'createdAt': FieldValue.serverTimestamp(),
      };

      final docRef = await widget.firestore
          .collection('users')
          .doc(widget.currentUid)
          .collection('pets')
          .add(data);

      if (mounted) {
        widget.onAdded({'petId': docRef.id, ...data});
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('Add pet error: $e');
      if (mounted) widget.onError('Failed to add pet. Please try again.');
    }

    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: FurPalsColors.warmWhite,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        constraints:
            BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.92),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle + title
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                        color: FurPalsColors.blush,
                        borderRadius: BorderRadius.circular(2)),
                  ),
                  const SizedBox(height: 14),
                  Text('Add a Pet',
                      style: GoogleFonts.baloo2(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: FurPalsColors.textDark)),
                  const SizedBox(height: 4),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Photo picker ───────────────────────────────────
                    Center(
                      child: GestureDetector(
                        onTap: () async {
                          final picked = await ImagePicker().pickImage(
                              source: ImageSource.gallery, imageQuality: 80);
                          if (picked != null) {
                            setState(() => _imageFile = File(picked.path));
                          }
                        },
                        child: Container(
                          width: 90,
                          height: 90,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [
                                FurPalsColors.blush,
                                FurPalsColors.peach,
                                FurPalsColors.mint
                              ],
                            ),
                            boxShadow: const [
                              BoxShadow(
                                  color: FurPalsColors.shadow,
                                  blurRadius: 12,
                                  offset: Offset(0, 4))
                            ],
                          ),
                          padding: const EdgeInsets.all(3),
                          child: Container(
                            decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: FurPalsColors.cream),
                            child: _imageFile != null
                                ? ClipOval(
                                    child: Image.file(_imageFile!,
                                        fit: BoxFit.cover,
                                        width: 84,
                                        height: 84))
                                : const Center(
                                    child: Icon(Icons.add_a_photo_rounded,
                                        size: 32,
                                        color: FurPalsColors.pink)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Center(
                      child: Text('Tap to add photo',
                          style: GoogleFonts.nunito(
                              fontSize: 11,
                              color: FurPalsColors.textMid,
                              fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(height: 20),

                    // ── Section: Basic Info ───────────────────────────
                    _sectionLabel('🐾 Basic Info'),
                    const SizedBox(height: 10),
                    _editField(_nameCtrl, 'Pet Name *', Icons.pets_rounded),
                    const SizedBox(height: 10),
                    _editField(
                        _breedCtrl, 'Breed', Icons.category_rounded),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _editField(
                              _ageCtrl, 'Age (e.g. 2 yrs)',
                              Icons.cake_rounded),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _editField(
                              _weightCtrl, 'Weight (kg)',
                              Icons.monitor_weight_outlined,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Birthday picker
                    GestureDetector(
                      onTap: _pickBirthday,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: FurPalsColors.blush, width: 1.5),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 14),
                        child: Row(
                          children: [
                            const Icon(Icons.cake_outlined,
                                color: FurPalsColors.pink, size: 18),
                            const SizedBox(width: 10),
                            Text(
                              _birthday != null
                                  ? '${_birthday!.year}-${_birthday!.month.toString().padLeft(2, '0')}-${_birthday!.day.toString().padLeft(2, '0')}'
                                  : 'Birthday (tap to pick)',
                              style: GoogleFonts.nunito(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: _birthday != null
                                    ? FurPalsColors.textDark
                                    : FurPalsColors.textMid,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Sex dropdown
                    _dropdownField(
                      label: 'Sex',
                      icon: Icons.transgender_rounded,
                      value: _sex,
                      items: ['Male', 'Female', 'Unknown'],
                      onChanged: (v) => setState(() => _sex = v!),
                    ),
                    const SizedBox(height: 10),

                    // Spayed/Neutered dropdown + yes/no chips
                    _label('Spayed / Neutered'),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _dropdownField(
                            label: '',
                            icon: Icons.medical_services_outlined,
                            value: _spayedNeutered,
                            items: ['Spayed', 'Neutered', 'Unknown'],
                            onChanged: (v) =>
                                setState(() => _spayedNeutered = v!),
                            showLabel: false,
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Quick yes/no chips
                       
                      ],
                    ),
                    const SizedBox(height: 20),

                    // ── Section: Food Allergies ────────────────────────
                    _sectionLabel('🍖 Food Allergies'),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _editField(
                              _allergyCtrl, 'Add food allergy...',
                              Icons.no_meals_rounded),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: _addAllergy,
                          child: Container(
                            height: 48,
                            width: 48,
                            decoration: BoxDecoration(
                              color: FurPalsColors.pink,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(Icons.add_rounded,
                                color: Colors.white, size: 24),
                          ),
                        ),
                      ],
                    ),
                    if (_allergies.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _allergies
                            .map((a) => Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: FurPalsColors.blush,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(a,
                                          style: GoogleFonts.nunito(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              color: FurPalsColors.textDark)),
                                      const SizedBox(width: 6),
                                      GestureDetector(
                                        onTap: () => setState(
                                            () => _allergies.remove(a)),
                                        child: const Icon(
                                            Icons.close_rounded,
                                            size: 14,
                                            color: FurPalsColors.pink),
                                      ),
                                    ],
                                  ),
                                ))
                            .toList(),
                      ),
                    ],
                    const SizedBox(height: 20),

                    // ── Section: Vet Info ─────────────────────────────
                    _sectionLabel('🏥 Veterinarian Info'),
                    const SizedBox(height: 10),
                    _editField(
                        _vetNameCtrl, 'Veterinarian Name',
                        Icons.person_outlined),
                    const SizedBox(height: 10),
                    _editField(
                        _clinicCtrl, 'Clinic / Hospital',
                        Icons.local_hospital_outlined),
                    const SizedBox(height: 20),

                    // ── Section: Owner Info ───────────────────────────
                    _sectionLabel('👤 Owner Info'),
                    const SizedBox(height: 10),
                    _editField(
                        _ownerNameCtrl, 'Owner Full Name',
                        Icons.badge_outlined),
                    const SizedBox(height: 10),
                    _editField(
                        _ownerPhoneCtrl, 'Contact Number',
                        Icons.phone_outlined,
                        keyboardType: TextInputType.phone),
                    const SizedBox(height: 28),

                    // ── Save button ───────────────────────────────────
                    GestureDetector(
                      onTap: _saving ? null : _save,
                      child: Container(
                        width: double.infinity,
                        padding:
                            const EdgeInsets.symmetric(vertical: 15),
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
                          child: _saving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white))
                              : Text('Add Pet 🐾',
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
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: FurPalsColors.blush.withOpacity(0.4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(text,
          style: GoogleFonts.baloo2(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: FurPalsColors.textDark)),
    );
  }

  Widget _label(String text) => Align(
        alignment: Alignment.centerLeft,
        child: Text(text,
            style: GoogleFonts.nunito(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: FurPalsColors.textMid)),
      );

  Widget _yesNoChip(String val) {
    final sel = _spayedNeutered == val;
    return GestureDetector(
      onTap: () => setState(() => _spayedNeutered = val),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: sel ? FurPalsColors.pink : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: FurPalsColors.pink, width: 1.5),
        ),
        child: Text(val,
            style: GoogleFonts.nunito(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: sel ? Colors.white : FurPalsColors.pink)),
      ),
    );
  }

  Widget _dropdownField({
    required String label,
    required IconData icon,
    required String value,
    required List<String> items,
    required void Function(String?) onChanged,
    bool showLabel = true,
  }) {
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
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value,
                isDense: true,
                style: GoogleFonts.nunito(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: FurPalsColors.textDark),
                hint: showLabel
                    ? Text(label,
                        style: GoogleFonts.nunito(
                            color: FurPalsColors.textMid, fontSize: 13))
                    : null,
                items: items
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _editField(
    TextEditingController ctrl,
    String hint,
    IconData icon, {
    TextInputType keyboardType = TextInputType.text,
  }) {
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
              keyboardType: keyboardType,
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
}

// ── PetCard ───────────────────────────────────────────────────────────────────
class _PetCard extends StatelessWidget {
  final Map<String, dynamic> pet;
  final List<Color> gradientColors;
  final VoidCallback onTap;

  const _PetCard({
    required this.pet,
    required this.gradientColors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final photoURL = pet['photoURL'] as String?;
    final name = pet['name'] as String? ?? 'Pet Name';
    final breed = pet['breed'] as String? ?? '';
    final age = pet['age'] as String? ?? '';
    final gender = pet['sex'] as String? ?? pet['gender'] as String? ?? '';
    final species = pet['species'] as String? ?? '';
    final weight = pet['weight'] as String? ?? '';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
                color: FurPalsColors.shadow,
                blurRadius: 12,
                offset: Offset(0, 4))
          ],
        ),
        clipBehavior: Clip.hardEdge,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 130,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  photoURL != null && photoURL.isNotEmpty
                      ? Image.network(photoURL,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              _placeholder(gradientColors))
                      : _placeholder(gradientColors),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 22,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(20)),
                      ),
                    ),
                  ),
                  if (gender.isNotEmpty && gender != 'Unknown')
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: gender == 'Male'
                              ? const Color(0xFF90CAF9)
                              : FurPalsColors.pink,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withOpacity(0.15),
                                blurRadius: 6)
                          ],
                        ),
                        child: Icon(
                          gender == 'Male'
                              ? Icons.male_rounded
                              : Icons.female_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // AFTER:
Padding(
  padding: const EdgeInsets.fromLTRB(10, 2, 10, 10),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(name,
          style: GoogleFonts.baloo2(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: FurPalsColors.textDark,
              height: 1.2),
          overflow: TextOverflow.ellipsis,
          maxLines: 1),
      if (breed.isNotEmpty)
        Text(breed,
            style: GoogleFonts.nunito(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: FurPalsColors.textMid),
            overflow: TextOverflow.ellipsis,
            maxLines: 1),
      const SizedBox(height: 6),
      Row(
        children: [
          Expanded(
            child: _statPill(
              'Age',
              age.isNotEmpty ? age : '—',
              Icons.cake_rounded,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _statPill(
              'Wt',
              weight.isNotEmpty ? '${weight}kg' : '—',
              Icons.monitor_weight_outlined,
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
    );
  }

  // AFTER:
Widget _statPill(String label, String value, IconData icon) {
  return Container(
    padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 4),
    decoration: BoxDecoration(
      color: const Color(0xFFFFF0E8),
      borderRadius: BorderRadius.circular(50),
      border: Border.all(color: const Color(0xFFEDD9B3), width: 1),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 10, color: FurPalsColors.pink),
        const SizedBox(height: 1),
        Text(label,
            style: GoogleFonts.nunito(
                fontSize: 8,
                fontWeight: FontWeight.w700,
                color: FurPalsColors.textMid)),
        Text(value,
            style: GoogleFonts.baloo2(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: FurPalsColors.textDark),
            overflow: TextOverflow.ellipsis,
            maxLines: 1),
      ],
    ),
  );
}
  Widget _placeholder(List<Color> colors) {
    return Container(
      decoration: BoxDecoration(gradient: LinearGradient(colors: colors)),
      child:
          const Center(child: Icon(Icons.pets_rounded, color: Colors.white54, size: 48)),
    );
  }
}

// ── Add Pet tile — BIGGER paw (100×100) ──────────────────────────────────────
class _AddPetTile extends StatelessWidget {
  final VoidCallback onTap;
  const _AddPetTile({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: FurPalsColors.blush, width: 2),
          boxShadow: const [
            BoxShadow(
                color: FurPalsColors.shadow,
                blurRadius: 10,
                offset: Offset(0, 3))
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ── BIGGER paw: 100×100 ──────────────────────────────
            SizedBox(
              width: 100,
              height: 100,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: const Size(100, 100),
                    painter:
                        _PawPrintPainter(color: FurPalsColors.pink),
                  ),
                  const Icon(Icons.add_rounded,
                      color: Colors.white, size: 36),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text('Add Pet',
                style: GoogleFonts.baloo2(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: FurPalsColors.pink)),
            const SizedBox(height: 2),
            Text('Tap to add',
                style: GoogleFonts.nunito(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: FurPalsColors.textMid)),
          ],
        ),
      ),
    );
  }
}

// ── Paw print CustomPainter ───────────────────────────────────────────────────
class _PawPrintPainter extends CustomPainter {
  final Color color;
  const _PawPrintPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final w = size.width;
    final h = size.height;

    final mainPath = Path();
    mainPath.addRRect(RRect.fromRectAndCorners(
      Rect.fromCenter(
          center: Offset(w * 0.5, h * 0.62),
          width: w * 0.52,
          height: h * 0.42),
      topLeft: const Radius.circular(100),
      topRight: const Radius.circular(100),
      bottomLeft: const Radius.circular(100),
      bottomRight: const Radius.circular(100),
    ));
    canvas.drawPath(mainPath, paint);

    final toePositions = [
      Offset(w * 0.18, h * 0.32),
      Offset(w * 0.37, h * 0.22),
      Offset(w * 0.63, h * 0.22),
      Offset(w * 0.82, h * 0.32),
    ];
    for (final pos in toePositions) {
      canvas.drawOval(
        Rect.fromCenter(center: pos, width: w * 0.17, height: h * 0.20),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_PawPrintPainter old) => old.color != color;
}

// ── Pet detail / edit sheet ───────────────────────────────────────────────────
class _PetDetailSheet extends StatefulWidget {
  final Map<String, dynamic> pet;
  final String currentUid;
  final FirebaseFirestore firestore;
  final FirebaseStorage storage;
  final void Function(String petId) onDeleted;
  final void Function(Map<String, dynamic> updated) onUpdated;

  const _PetDetailSheet({
    required this.pet,
    required this.currentUid,
    required this.firestore,
    required this.storage,
    required this.onDeleted,
    required this.onUpdated,
  });

  @override
  State<_PetDetailSheet> createState() => _PetDetailSheetState();
}

class _PetDetailSheetState extends State<_PetDetailSheet> {
  late TextEditingController _nameCtrl;
  late TextEditingController _breedCtrl;
  late TextEditingController _ageCtrl;
  late TextEditingController _weightCtrl;
  late TextEditingController _vetNameCtrl;
  late TextEditingController _clinicCtrl;
  late TextEditingController _ownerNameCtrl;
  late TextEditingController _ownerPhoneCtrl;
  late TextEditingController _allergyCtrl;

  late String _sex;
  late String _spayedNeutered;
  DateTime? _birthday;
  List<String> _allergies = [];
  File? _newImageFile;
  bool _saving = false;
  bool _deleting = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.pet['name'] ?? '');
    _breedCtrl = TextEditingController(text: widget.pet['breed'] ?? '');
    _ageCtrl = TextEditingController(text: widget.pet['age'] ?? '');
    _weightCtrl = TextEditingController(text: widget.pet['weight'] ?? '');
    _vetNameCtrl = TextEditingController(text: widget.pet['vetName'] ?? '');
    _clinicCtrl = TextEditingController(text: widget.pet['clinic'] ?? '');
    _ownerNameCtrl = TextEditingController(text: widget.pet['ownerName'] ?? '');
    _ownerPhoneCtrl =
        TextEditingController(text: widget.pet['ownerPhone'] ?? '');
    _allergyCtrl = TextEditingController();
    _sex = widget.pet['sex'] ?? widget.pet['gender'] ?? 'Unknown';
    final rawSN = widget.pet['spayedNeutered'] ?? 'Unknown';
_spayedNeutered = ['Spayed', 'Neutered', 'Unknown'].contains(rawSN) ? rawSN : 'Unknown';
    final bd = widget.pet['birthday'] as String?;
    if (bd != null && bd.isNotEmpty) {
      _birthday = DateTime.tryParse(bd);
    }
    _allergies =
        List<String>.from(widget.pet['foodAllergies'] as List? ?? []);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _breedCtrl.dispose();
    _ageCtrl.dispose();
    _weightCtrl.dispose();
    _vetNameCtrl.dispose();
    _clinicCtrl.dispose();
    _ownerNameCtrl.dispose();
    _ownerPhoneCtrl.dispose();
    _allergyCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickBirthday() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthday ?? now,
      firstDate: DateTime(now.year - 30),
      lastDate: now,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: FurPalsColors.pink,
            onPrimary: Colors.white,
            surface: FurPalsColors.warmWhite,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _birthday = picked);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      String? photoURL = widget.pet['photoURL'] as String?;
      if (_newImageFile != null) {
        try {
          final ref = widget.storage
              .ref()
              .child(
                  'pets/${widget.currentUid}/${widget.pet['petId']}.jpg');
          await ref.putFile(
              _newImageFile!, SettableMetadata(contentType: 'image/jpeg'));
          photoURL = await ref.getDownloadURL();
        } catch (e) {
          debugPrint('Photo update failed: $e');
        }
      }

      final data = {
        'name': _nameCtrl.text.trim(),
        'breed': _breedCtrl.text.trim(),
        'age': _ageCtrl.text.trim(),
        'weight': _weightCtrl.text.trim(),
        'sex': _sex,
        'spayedNeutered': _spayedNeutered,
        'birthday': _birthday != null
            ? _birthday!.toIso8601String().substring(0, 10)
            : null,
        'foodAllergies': _allergies,
        'vetName': _vetNameCtrl.text.trim(),
        'clinic': _clinicCtrl.text.trim(),
        'ownerName': _ownerNameCtrl.text.trim(),
        'ownerPhone': _ownerPhoneCtrl.text.trim(),
        if (photoURL != null) 'photoURL': photoURL,
      };

      await widget.firestore
          .collection('users')
          .doc(widget.currentUid)
          .collection('pets')
          .doc(widget.pet['petId'] as String)
          .update(data);

      if (mounted) {
        widget.onUpdated({...widget.pet, ...data});
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('Save error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to save',
              style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
          backgroundColor: FurPalsColors.heartRed,
        ));
      }
    }
    if (mounted) setState(() => _saving = false);
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Remove Pet?',
            style: GoogleFonts.baloo2(
                fontWeight: FontWeight.w800,
                color: FurPalsColors.textDark)),
        content: Text(
            'Are you sure you want to remove ${widget.pet['name']}?',
            style: GoogleFonts.nunito(
                fontSize: 13, color: FurPalsColors.textMid)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel',
                style: GoogleFonts.nunito(
                    color: FurPalsColors.textMid,
                    fontWeight: FontWeight.w700)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Remove',
                style: GoogleFonts.nunito(
                    color: FurPalsColors.heartRed,
                    fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    setState(() => _deleting = true);
    try {
      await widget.firestore
          .collection('users')
          .doc(widget.currentUid)
          .collection('pets')
          .doc(widget.pet['petId'] as String)
          .delete();
      if (mounted) {
        widget.onDeleted(widget.pet['petId'] as String);
        Navigator.pop(context);
      }
    } catch (_) {}
    if (mounted) setState(() => _deleting = false);
  }

  @override
  Widget build(BuildContext context) {
    final photoURL = _newImageFile != null
        ? null
        : widget.pet['photoURL'] as String?;

    return Container(
      decoration: const BoxDecoration(
        color: FurPalsColors.warmWhite,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      constraints:
          BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.92),
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: FurPalsColors.blush,
                      borderRadius: BorderRadius.circular(2)),
                ),
                const SizedBox(height: 14),
                Text('Pet Details',
                    style: GoogleFonts.baloo2(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: FurPalsColors.textDark)),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar
                  Center(
                    child: GestureDetector(
                      onTap: () async {
                        final picked = await ImagePicker().pickImage(
                            source: ImageSource.gallery, imageQuality: 80);
                        if (picked != null) {
                          setState(() => _newImageFile = File(picked.path));
                        }
                      },
                      child: Stack(
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(colors: [
                                FurPalsColors.pink,
                                FurPalsColors.pinkLight,
                                FurPalsColors.mint
                              ]),
                            ),
                            padding: const EdgeInsets.all(3),
                            child: Container(
                              decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: FurPalsColors.cream),
                              child: _newImageFile != null
                                  ? ClipOval(
                                      child: Image.file(_newImageFile!,
                                          fit: BoxFit.cover,
                                          width: 94,
                                          height: 94))
                                  : (photoURL != null && photoURL.isNotEmpty
                                      ? ClipOval(
                                          child: Image.network(photoURL,
                                              fit: BoxFit.cover,
                                              width: 94,
                                              height: 94))
                                      : const Center(
                                          child: Icon(Icons.pets_rounded,
                                              size: 44,
                                              color: FurPalsColors.pink))),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                  color: FurPalsColors.pink,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: Colors.white, width: 2)),
                              child: const Icon(Icons.edit_rounded,
                                  color: Colors.white, size: 14),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  _sectionLabel('🐾 Basic Info'),
                  const SizedBox(height: 10),
                  _field(_nameCtrl, 'Pet Name', Icons.pets_rounded),
                  const SizedBox(height: 10),
                  _field(_breedCtrl, 'Breed', Icons.category_rounded),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                          child: _field(
                              _ageCtrl, 'Age', Icons.cake_rounded)),
                      const SizedBox(width: 10),
                      Expanded(
                          child: _field(_weightCtrl, 'Weight (kg)',
                              Icons.monitor_weight_outlined,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true))),
                    ],
                  ),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: _pickBirthday,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border:
                            Border.all(color: FurPalsColors.blush, width: 1.5),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 14),
                      child: Row(
                        children: [
                          const Icon(Icons.cake_outlined,
                              color: FurPalsColors.pink, size: 18),
                          const SizedBox(width: 10),
                          Text(
                            _birthday != null
                                ? '${_birthday!.year}-${_birthday!.month.toString().padLeft(2, '0')}-${_birthday!.day.toString().padLeft(2, '0')}'
                                : 'Birthday (tap to pick)',
                            style: GoogleFonts.nunito(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: _birthday != null
                                    ? FurPalsColors.textDark
                                    : FurPalsColors.textMid),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _dropdownField(
                    label: 'Sex',
                    icon: Icons.transgender_rounded,
                    value: _sex,
                    items: ['Male', 'Female', 'Unknown'],
                    onChanged: (v) => setState(() => _sex = v!),
                  ),
                  const SizedBox(height: 10),
                  _label('Spayed / Neutered'),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _dropdownField(
                          label: '',
                          icon: Icons.medical_services_outlined,
                          value: _spayedNeutered,
                          items: ['Spayed', 'Neutered', 'Unknown'],
                          onChanged: (v) =>
                              setState(() => _spayedNeutered = v!),
                          showLabel: false,
                        ),
                      ),
                      const SizedBox(width: 10),
                      
                    ],
                  ),
                  const SizedBox(height: 20),

                  _sectionLabel('🍖 Food Allergies'),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _field(_allergyCtrl, 'Add food allergy...',
                            Icons.no_meals_rounded),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () {
                          final a = _allergyCtrl.text.trim();
                          if (a.isEmpty) return;
                          setState(() {
                            _allergies.add(a);
                            _allergyCtrl.clear();
                          });
                        },
                        child: Container(
                          height: 48,
                          width: 48,
                          decoration: BoxDecoration(
                            color: FurPalsColors.pink,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.add_rounded,
                              color: Colors.white, size: 24),
                        ),
                      ),
                    ],
                  ),
                  if (_allergies.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _allergies
                          .map((a) => Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: FurPalsColors.blush,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(a,
                                        style: GoogleFonts.nunito(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: FurPalsColors.textDark)),
                                    const SizedBox(width: 6),
                                    GestureDetector(
                                      onTap: () =>
                                          setState(() => _allergies.remove(a)),
                                      child: const Icon(Icons.close_rounded,
                                          size: 14,
                                          color: FurPalsColors.pink),
                                    ),
                                  ],
                                ),
                              ))
                          .toList(),
                    ),
                  ],
                  const SizedBox(height: 20),

                  _sectionLabel('🏥 Veterinarian Info'),
                  const SizedBox(height: 10),
                  _field(_vetNameCtrl, 'Veterinarian Name',
                      Icons.person_outlined),
                  const SizedBox(height: 10),
                  _field(_clinicCtrl, 'Clinic / Hospital',
                      Icons.local_hospital_outlined),
                  const SizedBox(height: 20),

                  _sectionLabel('👤 Owner Info'),
                  const SizedBox(height: 10),
                  _field(_ownerNameCtrl, 'Owner Full Name',
                      Icons.badge_outlined),
                  const SizedBox(height: 10),
                  _field(_ownerPhoneCtrl, 'Contact Number',
                      Icons.phone_outlined,
                      keyboardType: TextInputType.phone),
                  const SizedBox(height: 28),

                  GestureDetector(
                    onTap: _saving ? null : _save,
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
                        child: _saving
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
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: _deleting ? null : _delete,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: FurPalsColors.heartRed, width: 1.5),
                      ),
                      child: Center(
                        child: _deleting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: FurPalsColors.heartRed))
                            : Text('Remove Pet',
                                style: GoogleFonts.baloo2(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: FurPalsColors.heartRed)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: FurPalsColors.blush.withOpacity(0.4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(text,
          style: GoogleFonts.baloo2(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: FurPalsColors.textDark)),
    );
  }

  Widget _label(String text) => Align(
        alignment: Alignment.centerLeft,
        child: Text(text,
            style: GoogleFonts.nunito(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: FurPalsColors.textMid)),
      );

  Widget _yesNoChip(String val) {
    final sel = _spayedNeutered == val;
    return GestureDetector(
      onTap: () => setState(() => _spayedNeutered = val),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: sel ? FurPalsColors.pink : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: FurPalsColors.pink, width: 1.5),
        ),
        child: Text(val,
            style: GoogleFonts.nunito(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: sel ? Colors.white : FurPalsColors.pink)),
      ),
    );
  }

  Widget _dropdownField({
    required String label,
    required IconData icon,
    required String value,
    required List<String> items,
    required void Function(String?) onChanged,
    bool showLabel = true,
  }) {
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
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value,
                isDense: true,
                style: GoogleFonts.nunito(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: FurPalsColors.textDark),
                items: items
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _field(
    TextEditingController ctrl,
    String hint,
    IconData icon, {
    TextInputType keyboardType = TextInputType.text,
  }) {
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
              keyboardType: keyboardType,
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
}