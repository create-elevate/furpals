import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:furpals/Homescreen.dart'; // FurPalsColors

class AddMissingPetScreen extends StatefulWidget {
  const AddMissingPetScreen({super.key});

  @override
  State<AddMissingPetScreen> createState() => _AddMissingPetScreenState();
}

class _AddMissingPetScreenState extends State<AddMissingPetScreen> {
  String _selectedType   = 'DOG';
  String? _selectedGender;

  final _petNameController    = TextEditingController();
  final _breedController      = TextEditingController();
  final _weightController     = TextEditingController();
  final _ageController        = TextEditingController();
  final _locationController   = TextEditingController();
  final _descController       = TextEditingController();

  final List<Map<String, dynamic>> _petTypes = [
    {'label': 'DOG',   'emoji': '🐶'},
    {'label': 'CAT',   'emoji': '🐱'},
    {'label': 'BIRD',  'emoji': '🦜'},
    {'label': 'OTHER', 'emoji': null},
  ];

  final List<String> _genders = ['Male', 'Female'];

  @override
  void dispose() {
    _petNameController.dispose();
    _breedController.dispose();
    _weightController.dispose();
    _ageController.dispose();
    _locationController.dispose();
    _descController.dispose();
    super.dispose();
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
                  Text('Add ',
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
                      onTap: () {},
                      child: Container(
                        width: double.infinity,
                        height: 140,
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
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 52, height: 52,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(Icons.photo_camera_outlined,
                                  size: 28,
                                  color: Colors.grey.shade400),
                            ),
                            const SizedBox(height: 8),
                            Text('Tap to add a photo of your pet',
                                style: GoogleFonts.nunito(
                                  fontSize: 12,
                                  color: Colors.grey.shade400,
                                  fontWeight: FontWeight.w600,
                                )),
                          ],
                        ),
                      ),
                    ),

                    Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 4, right: 2),
                        child: Text('Maximum of 5 photos',
                            style: GoogleFonts.nunito(
                              fontSize: 10,
                              color: FurPalsColors.textMid.withOpacity(0.5),
                            )),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ── PET TYPE ──────────────────────────────────────────
                    _fieldLabel('Identify Pet Type'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _petTypes.map((t) {
                        final label = t['label'] as String;
                        final emoji = t['emoji'] as String?;
                        final isSelected = _selectedType == label;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedType = label),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? FurPalsColors.blush
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected
                                    ? FurPalsColors.pink
                                    : Colors.grey.shade300,
                                width: 1.4,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (emoji != null) ...[
                                  Text(emoji,
                                      style: const TextStyle(fontSize: 16)),
                                  const SizedBox(width: 5),
                                ],
                                Text(label,
                                    style: GoogleFonts.nunito(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: isSelected
                                          ? FurPalsColors.pink
                                          : FurPalsColors.textDark,
                                    )),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
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
                            onTap: () {
                              // TODO: save logic
                              Navigator.pop(context);
                            },
                            child: Container(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                color: FurPalsColors.pink,
                                borderRadius: BorderRadius.circular(30),
                                boxShadow: const [
                                  BoxShadow(
                                      color: Color(0x55F4738A),
                                      blurRadius: 12,
                                      offset: Offset(0, 4)),
                                ],
                              ),
                              child: Center(
                                child: Text('Save',
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
        style: GoogleFonts.nunito(
            fontSize: 14, color: FurPalsColors.textDark),
        decoration: const InputDecoration(
          border: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }
}