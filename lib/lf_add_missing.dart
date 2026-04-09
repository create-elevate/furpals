import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:furpals/Homescreen.dart'; // FurPalsColors
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:furpals/models.dart' as models;

class AddMissingPetScreen extends StatefulWidget {
  final bool editMode;
  final Map<String, dynamic>? petData;
  
  const AddMissingPetScreen({
    super.key, 
    this.editMode = false,
    this.petData,
  });

  @override
  State<AddMissingPetScreen> createState() => _AddMissingPetScreenState();
}

class _AddMissingPetScreenState extends State<AddMissingPetScreen> {
  String _selectedType   = 'DOG';
  String? _selectedGender;
  String? _customTypeError;
  int _currentPhotoPage = 0;
  final ImagePicker _picker = ImagePicker();
  final PageController _photoPageController = PageController();
  final PageController _typePageController = PageController(viewportFraction: 0.75);
  final List<XFile> _selectedPhotos = [];
  final _petNameController    = TextEditingController();
  final _breedController      = TextEditingController();
  final _customTypeController = TextEditingController();
  final _weightController     = TextEditingController();
  final _ageController        = TextEditingController();
  final _locationController   = TextEditingController();
  final _descController       = TextEditingController();
  DateTime? _selectedDateMissing;
  List<String> _existingPhotos = [];
  bool _isUploading = false;
  final List<String> _genders = ['Male', 'Female'];

  @override
  void initState() {
    super.initState();
    if (widget.editMode && widget.petData != null) {
      _loadPetData();
    }
  }

  void _loadPetData() {
    final pet = widget.petData!;
    setState(() {
      _selectedType = pet['type'] ?? 'DOG';
      _petNameController.text = pet['name'] ?? '';
      _breedController.text = pet['breed'] ?? '';
      _selectedGender = pet['gender'];
      _weightController.text = pet['weight'] ?? '';
      _ageController.text = pet['age'] ?? '';
      _locationController.text = pet['location'] ?? '';
      _descController.text = pet['description'] ?? '';
      _selectedDateMissing = _parseDateMissing(pet['dateMissing']);
      // Load existing photos for display in edit mode
      if (pet['photos'] != null && pet['photos'] is List) {
        _existingPhotos = List<String>.from(pet['photos']);
      }
    });
  }

  DateTime? _parseDateMissing(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is Timestamp) return value.toDate();
    if (value is String) {
      final parsed = DateTime.tryParse(value);
      if (parsed != null) return parsed;
      final parts = value.split(RegExp(r'[-\/]'));
      if (parts.length == 3) {
        final year = int.tryParse(parts[0]);
        final month = int.tryParse(parts[1]);
        final day = int.tryParse(parts[2]);
        if (year != null && month != null && day != null) {
          return DateTime(year, month, day);
        }
      }
    }
    return null;
  }

  final List<Map<String, dynamic>> _petTypes = [
    {'label': 'DOG',     'emoji': '🐶'},
    {'label': 'CAT',     'emoji': '🐱'},
    {'label': 'BIRD',    'emoji': '🐦'},
    {'label': 'FISH',    'emoji': '🐠'},
    {'label': 'RABBIT',  'emoji': '🐰'},
    {'label': 'HAMSTER', 'emoji': '🐹'},
    {'label': 'REPTILE', 'emoji': '🦎'},
    {'label': 'HORSE',   'emoji': '🐴'},
    {'label': 'OTHER',   'emoji': '🐾'},
  ];

  List<String> get _allPhotos {
    if (widget.editMode) {
      return [..._existingPhotos, ..._selectedPhotos.map((xfile) => xfile.path)];
    }
    return _selectedPhotos.map((xfile) => xfile.path).toList();
  }

  bool get _hasPhotos => widget.editMode ? _existingPhotos.isNotEmpty || _selectedPhotos.isNotEmpty : _selectedPhotos.isNotEmpty;

  @override
  void dispose() {
    _photoPageController.dispose();
    _typePageController.dispose();
    _petNameController.dispose();
    _breedController.dispose();
    _customTypeController.dispose();
    _weightController.dispose();
    _ageController.dispose();
    _locationController.dispose();
    _descController.dispose();
    super.dispose();
  }

  // Let the user choose up to 6 images for the pet listing.
  // If they try to add more than 6, show a warning and do not exceed the limit.
  Future<void> _selectPhotos() async {
    final remaining = 6 - _selectedPhotos.length;
    if (remaining == 0) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You can upload a maximum of 6 photos.')),
      );
      return;
    }

    final picked = await _picker.pickMultiImage(imageQuality: 60);
    if (picked.isEmpty) return;

    if (_selectedPhotos.length + picked.length > 6) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You can only add up to 6 photos.')),
      );
    }

    setState(() {
      _selectedPhotos.addAll(picked.take(remaining));
      _currentPhotoPage = 0;
      if (_selectedPhotos.isNotEmpty) {
        _photoPageController.jumpToPage(0);
      }
    });
  }

  // Upload selected pet photos to Firebase Storage and return their download URLs.
  Future<List<String>> _uploadPhotos() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];

    // Start with existing photos
    List<String> allPhotoUrls = List.from(_existingPhotos);

    // Only upload new photos
    if (_selectedPhotos.isNotEmpty) {
      final storage = FirebaseStorage.instance;

      final uploadTasks = _selectedPhotos.map((photo) async {
        try {
          final fileName = '${DateTime.now().millisecondsSinceEpoch}_${photo.name}';
          final ref = storage.ref('lost_pets/${user.uid}/$fileName');
          final bytes = await photo.readAsBytes();
          final task = ref.putData(bytes);
          await task;
          final downloadUrl = await ref.getDownloadURL();
          print('Successfully uploaded photo: $downloadUrl');
          return downloadUrl;
        } catch (e) {
          print('Error uploading photo: $e');
          return null;
        }
      }).toList();

      final uploadResults = await Future.wait(uploadTasks);
      allPhotoUrls.addAll(uploadResults.whereType<String>());
    }

    return allPhotoUrls;
  }

  Future<void> _savePet() async { 
    if (_petNameController.text.isEmpty ||
        _breedController.text.isEmpty ||
        _locationController.text.isEmpty ||
        _descController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields')),
      );
      return;
    }

// If the user chooses OTHER, require a custom pet type description.
      if (_selectedType == 'OTHER' && _customTypeController.text.trim().isEmpty) {
      setState(() => _customTypeError = 'Please enter a custom pet type');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a custom pet type for Other.')),
      );
      return;
    }

    try {
      final user = FirebaseAuth.instance.currentUser;
      print('Current user: ${user?.uid}, email: ${user?.email}, displayName: ${user?.displayName}');
      
      if (user == null) {
        print('User is null - not authenticated');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please log in to add a pet')),
        );
        return;
      }

      setState(() => _isUploading = true);
      final photoUrls = await _uploadPhotos();
      print('Uploaded ${photoUrls.length} photos: $photoUrls');

      // Use the custom pet type text when OTHER is selected, otherwise use the selected label.
      final typeValue = _selectedType == 'OTHER' && _customTypeController.text.trim().isNotEmpty
          ? _customTypeController.text.trim()
          : _selectedType;
      if (_customTypeError != null) {
        setState(() => _customTypeError = null);
      }

      final lostPet = models.LostPet(
        id: '', // Will be set by Firestore
        type: typeValue,
        name: _petNameController.text.trim(),
        breed: _breedController.text.trim(),
        gender: _selectedGender,
        weight: _weightController.text.isNotEmpty ? _weightController.text.trim() : null,
        age: _ageController.text.isNotEmpty ? _ageController.text.trim() : null,
        location: _locationController.text.trim(),
        description: _descController.text.trim(),
        photoUrls: photoUrls,
        createdAt: DateTime.now(),
        dateMissing: _selectedDateMissing,
        userId: user.uid,
        posterName: user.displayName ?? '',
      );

      print('Attempting to save lost pet with userId: ${user.uid}');
      print('Lost pet data: ${lostPet.toMap()}');

      if (widget.editMode && widget.petData != null) {
        // Update existing pet
        await FirebaseFirestore.instance
            .collection('lost_pets')
            .doc(widget.petData!['petId'])
            .update(lostPet.toMap());
        print('Successfully updated lost pet');
      } else {
        // Create new pet
        await FirebaseFirestore.instance
            .collection('lost_pets')
            .add(lostPet.toMap());
        print('Successfully saved lost pet with ${photoUrls.length} photos');
      }

      if (!mounted) return;
      setState(() => _isUploading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.editMode ? 'Pet updated successfully!' : 'Pet added successfully!')),
      );
      Navigator.pop(context, true); // Return true to indicate success
    } catch (e) {
      print('Error saving lost pet: $e');
      print('Error type: ${e.runtimeType}');
      if (e is FirebaseException) {
        print('Firebase error code: ${e.code}');
        print('Firebase error message: ${e.message}');
      }
      
      if (!mounted) return;
      setState(() => _isUploading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding pet: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCE8ED),
      body: SafeArea(
        child: Column(
          children: [

            // ── TOP BAR ───────────────────────────────────────────────────
            Padding(
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
                  const SizedBox(width: 12),
                  Text(widget.editMode ? 'Edit ' : 'Add ',
                      style: GoogleFonts.baloo2(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: FurPalsColors.textDark,
                      )),
                  Text('Missing Pet',
                      style: GoogleFonts.baloo2(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: FurPalsColors.pink,
                      )),
                  const Spacer(),
                  const Icon(Icons.edit_rounded,
                      color: FurPalsColors.textDark, size: 20),
                ],
              ),
            ),

            // ── SCROLLABLE FORM ───────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    // ── PHOTO PICKER ──────────────────────────────────────
                    GestureDetector(
                      onTap: _selectPhotos,
                      child: Container(
                        width: double.infinity,
                        height: 240,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: const [
                            BoxShadow(
                                color: FurPalsColors.shadow,
                                blurRadius: 8,
                                offset: Offset(0, 2)),
                          ],
                        ),
                        child: !_hasPhotos
                            ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 52,
                                    height: 52,
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Icon(Icons.photo_camera_outlined,
                                        size: 28,
                                        color: Colors.grey.shade400),
                                  ),
                                  const SizedBox(height: 8),
                                  Text('Tap to add photos of your pet',
                                      style: GoogleFonts.nunito(
                                        fontSize: 12,
                                        color: Colors.grey.shade400,
                                        fontWeight: FontWeight.w600,
                                      )),
                                ],
                              )
                            : Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: PageView.builder(
                                      controller: _photoPageController,
                                      itemCount: _allPhotos.length,
                                      onPageChanged: (index) => setState(() => _currentPhotoPage = index),
                                      itemBuilder: (context, index) {
                                        final photoPath = _allPhotos[index];
                                        return Container(
                                          color: Colors.grey.shade100,
                                          child: Center(
                                            child: photoPath.startsWith('http')
                                                ? Image.network(
                                                    photoPath,
                                                    width: double.infinity,
                                                    height: double.infinity,
                                                    fit: BoxFit.contain,
                                                    errorBuilder: (context, error, stackTrace) => const Center(
                                                      child: Icon(
                                                        Icons.broken_image,
                                                        size: 40,
                                                        color: Colors.grey,
                                                      ),
                                                    ),
                                                  )
                                                : Image.file(
                                                    File(photoPath),
                                                    width: double.infinity,
                                                    height: double.infinity,
                                                    fit: BoxFit.contain,
                                                    errorBuilder: (context, error, stackTrace) => const Center(
                                                      child: Icon(
                                                        Icons.broken_image,
                                                        size: 40,
                                                        color: Colors.grey,
                                                      ),
                                                    ),
                                                  ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          if (_currentPhotoPage < _existingPhotos.length) {
                                            // Deleting existing photo
                                            _existingPhotos.removeAt(_currentPhotoPage);
                                          } else {
                                            // Deleting new photo
                                            int newPhotoIndex = _currentPhotoPage - _existingPhotos.length;
                                            _selectedPhotos.removeAt(newPhotoIndex);
                                          }
                                          if (_allPhotos.isEmpty) {
                                            _currentPhotoPage = 0;
                                          } else if (_currentPhotoPage >= _allPhotos.length) {
                                            _currentPhotoPage = _allPhotos.length - 1;
                                            _photoPageController.jumpToPage(_currentPhotoPage);
                                          }
                                        });
                                      },
                                      child: Container(
                                        width: 28,
                                        height: 28,
                                        decoration: const BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.close, size: 16),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 12,
                                    left: 12,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.35),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        '${_currentPhotoPage + 1}/${_allPhotos.length}',
                                        style: GoogleFonts.nunito(
                                          fontSize: 12,
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),

                    if (_hasPhotos)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            _allPhotos.length,
                            (index) => Container(
                              width: 8,
                              height: 8,
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              decoration: BoxDecoration(
                                color: _currentPhotoPage == index
                                    ? FurPalsColors.pink
                                    : FurPalsColors.textMid.withOpacity(0.3),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ),
                      ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 4, right: 2),
                        child: Text('Maximum of 6 photos (${_allPhotos.length}/6)',
                            style: GoogleFonts.nunito(
                              fontSize: 10,
                              color: FurPalsColors.textMid.withOpacity(0.5),
                            )),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ── PET TYPE ──────────────────────────────────────────
                    _fieldLabel('Swipe to choose pet type'),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 80,
                      child: PageView.builder(
                        controller: _typePageController,
                        itemCount: _petTypes.length,
                        onPageChanged: (index) {
                          setState(() {
                            _selectedType = _petTypes[index]['label'] as String;
                            if (_selectedType != 'OTHER') {
                              _customTypeController.clear();
                            }
                          });
                        },
                        itemBuilder: (context, index) {
                          final petType = _petTypes[index];
                          final label = petType['label'] as String;
                          final emoji = petType['emoji'] as String?;
                          final isSelected = _selectedType == label;
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedType = label;
                                if (label != 'OTHER') {
                                  _customTypeController.clear();
                                }
                                _typePageController.animateToPage(
                                  index,
                                  duration: const Duration(milliseconds: 250),
                                  curve: Curves.easeOut,
                                );
                              });
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 6),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                decoration: BoxDecoration(
                                  color: isSelected ? FurPalsColors.blush : Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isSelected ? FurPalsColors.pink : Colors.grey.shade300,
                                    width: isSelected ? 1.8 : 1.2,
                                  ),
                                  boxShadow: isSelected
                                      ? const [BoxShadow(color: Color(0x1AF4738A), blurRadius: 10, offset: Offset(0, 3))]
                                      : null,
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    if (emoji != null) ...[
                                      Text(emoji, style: const TextStyle(fontSize: 20)),
                                      const SizedBox(height: 4),
                                    ],
                                    Text(
                                      label,
                                      style: GoogleFonts.nunito(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        color: isSelected ? FurPalsColors.pink : FurPalsColors.textDark,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        _petTypes.length,
                        (index) => Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            color: _selectedType == _petTypes[index]['label'] ? FurPalsColors.pink : FurPalsColors.textMid.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                    if (_selectedType == 'OTHER') ...[
                      const SizedBox(height: 12),
                      _fieldLabel('Custom pet type'),
                      _inputField(
                        controller: _customTypeController,
                        hintText: 'Describe the pet type',
                        errorText: _customTypeError,
                        onChanged: (_) {
                          if (_customTypeError != null) {
                            setState(() => _customTypeError = null);
                          }
                        },
                      ),
                    ],
                    const SizedBox(height: 16),
                    // ── DATE MISSING ──────────────────────────────────────
                    _fieldLabel('Date Pet Went Missing'),
                    GestureDetector(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _selectedDateMissing ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          setState(() => _selectedDateMissing = picked);
                        }
                      },
                      child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFFD4EBF2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                _selectedDateMissing != null
                                    ? '${_selectedDateMissing!.day}/${_selectedDateMissing!.month}/${_selectedDateMissing!.year}'
                                    : 'Select date',
                                style: GoogleFonts.nunito(
                                  fontSize: 14,
                                  color: _selectedDateMissing != null
                                      ? FurPalsColors.textDark
                                      : FurPalsColors.textMid.withOpacity(0.5),
                                ),
                              ),
                            ),
                            Icon(
                              Icons.calendar_today,
                              size: 18,
                              color: FurPalsColors.textMid.withOpacity(0.5),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // ── PET NAME ──────────────────────────────────────────
                    _fieldLabel('Pet Name'),
                    _inputField(controller: _petNameController),

                    const SizedBox(height: 16),

                    // ── PET BREED ─────────────────────────────────────────
                    _fieldLabel('Pet Breed'),
                    _inputField(controller: _breedController),

                    const SizedBox(height: 16),

                    // ── GENDER ────────────────────────────────────────────
                    _fieldLabel('Gender'),
                    Container(
                      height: 48,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD4EBF2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedGender,
                          hint: Text('',
                              style: GoogleFonts.nunito(
                                fontSize: 14,
                                color: FurPalsColors.textMid,
                              )),
                          isExpanded: true,
                          icon: const Icon(Icons.keyboard_arrow_down_rounded,
                              color: FurPalsColors.textMid),
                          items: _genders
                              .map((g) => DropdownMenuItem(
                                    value: g,
                                    child: Text(g,
                                        style: GoogleFonts.nunito(
                                          fontSize: 14,
                                          color: FurPalsColors.textDark,
                                          fontWeight: FontWeight.w600,
                                        )),
                                  ))
                              .toList(),
                          onChanged: (v) =>
                              setState(() => _selectedGender = v),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ── WEIGHT + AGE side by side ─────────────────────────
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _fieldLabel('Weight'),
                              Row(
                                children: [
                                  Expanded(
                                    child: _inputField(
                                      controller: _weightController,
                                      keyboardType: TextInputType.number,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text('kg',
                                      style: GoogleFonts.nunito(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: FurPalsColors.textMid,
                                      )),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _fieldLabel('Age'),
                              _inputField(
                                controller: _ageController,
                                keyboardType: TextInputType.number,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // ── LOCATION ──────────────────────────────────────────
                    _fieldLabel('Location'),
                    _inputField(controller: _locationController),

                    const SizedBox(height: 16),

                    // ── DESCRIPTION ───────────────────────────────────────
                    _fieldLabel('Description'),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFD4EBF2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          TextField(
                            controller: _descController,
                            maxLines: 5,
                            maxLength: 500,
                            style: GoogleFonts.nunito(
                                fontSize: 14,
                                color: FurPalsColors.textDark),
                            decoration: InputDecoration(
                              hintText: 'Tell me something...',
                              hintStyle: GoogleFonts.nunito(
                                  fontSize: 14,
                                  color:
                                      FurPalsColors.textMid.withOpacity(0.5)),
                              border: InputBorder.none,
                              isDense: true,
                              counterText: '',
                            ),
                          ),
                          ValueListenableBuilder(
                            valueListenable: _descController,
                            builder: (_, v, __) => Text(
                              '${v.text.length}/500 words max',
                              style: GoogleFonts.nunito(
                                fontSize: 10,
                                color: FurPalsColors.textMid.withOpacity(0.5),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    // ── BUTTONS ───────────────────────────────────────────
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(
                                    color: FurPalsColors.pink, width: 1.5),
                              ),
                              child: Center(
                                child: Text('Cancel',
                                    style: GoogleFonts.nunito(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: FurPalsColors.pink,
                                    )),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: _isUploading ? null : _savePet,
                            child: Container(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                color: _isUploading ? Colors.grey : FurPalsColors.pink,
                                borderRadius: BorderRadius.circular(30),
                                boxShadow: _isUploading ? null : const [
                                  BoxShadow(
                                      color: Color(0x55F4738A),
                                      blurRadius: 12,
                                      offset: Offset(0, 4)),
                                ],
                              ),
                              child: Center(
                                child: _isUploading
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                        ),
                                      )
                                    : Text(widget.editMode ? 'Update' : 'Save',
                                        style: GoogleFonts.nunito(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white,
                                        )),
                              ),
                            ),
                          ),
                        ),
                      ],
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

  // ── HELPERS ───────────────────────────────────────────────────────────────
  Widget _fieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(label,
          style: GoogleFonts.nunito(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: FurPalsColors.textDark,
          )),
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    String? hintText,
    String? errorText,
    ValueChanged<String>? onChanged,
  }) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: const Color(0xFFD4EBF2),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        onChanged: onChanged,
        style: GoogleFonts.nunito(
            fontSize: 14, color: FurPalsColors.textDark),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: GoogleFonts.nunito(
            fontSize: 14,
            color: FurPalsColors.textMid.withOpacity(0.5),
          ),
          errorText: errorText,
          border: InputBorder.none,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }
}