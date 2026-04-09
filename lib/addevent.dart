import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:furpals/models.dart';

class AddEventScreen extends StatefulWidget {
  final Function(PetEvent) onAdd;
  final Function(PetEvent) onUpdate; // ← separate callback for edits
  final PetEvent? eventToEdit;

  const AddEventScreen({
    super.key,
    required this.onAdd,
    required this.onUpdate,
    this.eventToEdit,
  });

  @override
  State<AddEventScreen> createState() => _AddEventScreenState();
}

class _AddEventScreenState extends State<AddEventScreen> with TickerProviderStateMixin {
  final _titleCtrl    = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _descCtrl     = TextEditingController();

  String _selectedCategory = 'Pet Fair';
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  int _selectedColorIndex  = 0;
  bool _usePhoto           = false;
  File? _pickedPhoto;
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  List<String> _categories = [
    'Pet Fair', 'Adoption', 'Grooming', 'Vet Visit', 'Training', 'Contest', 'Other',
  ];
  final _newCatCtrl = TextEditingController();

  final List<Map<String, Color>> _colorPairs = [
    {'c1': FurPalsColors.mint,            'c2': FurPalsColors.lavender},
    {'c1': FurPalsColors.peach,           'c2': FurPalsColors.butter},
    {'c1': FurPalsColors.blush,           'c2': FurPalsColors.peach},
    {'c1': FurPalsColors.lavender,        'c2': FurPalsColors.mint},
    {'c1': FurPalsColors.butter,          'c2': FurPalsColors.blush},
    {'c1': const Color(0xFFD0EEF9),       'c2': FurPalsColors.lavender},
    {'c1': const Color(0xFFFDE8C8),       'c2': const Color(0xFFFAD0E4)},
    {'c1': const Color(0xFFD0F0FF),       'c2': FurPalsColors.mint},
  ];

  bool get _isEditMode => widget.eventToEdit != null;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();

    // ── Pre-fill if editing ──
    final e = widget.eventToEdit;
    if (e != null) {
      _titleCtrl.text    = e.title;
      _locationCtrl.text = e.location;
      _descCtrl.text     = e.description;
      _selectedCategory  = e.category;

      final matchIdx = _colorPairs.indexWhere(
        (p) => p['c1'] == e.color1 && p['c2'] == e.color2,
      );
      _selectedColorIndex = matchIdx >= 0 ? matchIdx : 0;

      if (e.photoPath != null && e.photoPath!.isNotEmpty) {
        _usePhoto    = true;
        _pickedPhoto = File(e.photoPath!);
      }

      _selectedDate = _parseDate(e.date);
      _selectedTime = _parseTime(e.time);

      if (!_categories.contains(e.category)) {
        _categories.insert(_categories.length - 1, e.category);
      }
    }
  }

  DateTime? _parseDate(String dateStr) {
    try {
      final months = {
        'Jan': 1, 'Feb': 2, 'Mar': 3, 'Apr': 4, 'May': 5, 'Jun': 6,
        'Jul': 7, 'Aug': 8, 'Sep': 9, 'Oct': 10, 'Nov': 11, 'Dec': 12,
      };
      final parts = dateStr.replaceAll(',', '').split(' ');
      final month = months[parts[0]] ?? 1;
      final day   = int.tryParse(parts[1]) ?? 1;
      final year  = parts.length >= 3 ? (int.tryParse(parts[2]) ?? DateTime.now().year) : DateTime.now().year;
      return DateTime(year, month, day);
    } catch (_) { return null; }
  }

  TimeOfDay? _parseTime(String timeStr) {
    try {
      final parts  = timeStr.split(' ');
      final hm     = parts[0].split(':');
      int hour     = int.parse(hm[0]);
      final minute = int.parse(hm[1]);
      final isPm   = parts.length > 1 && parts[1].toUpperCase() == 'PM';
      if (isPm && hour != 12) hour += 12;
      if (!isPm && hour == 12) hour = 0;
      return TimeOfDay(hour: hour, minute: minute);
    } catch (_) { return null; }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _locationCtrl.dispose();
    _descCtrl.dispose();
    _newCatCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime(2026, 1, 1),
      firstDate: DateTime(2026, 1, 1),
      lastDate: DateTime(2046, 12, 31),
      initialEntryMode: DatePickerEntryMode.calendarOnly,
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
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: FurPalsColors.pink,
            onPrimary: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  Future<void> _pickPhoto() async {
    try {
      final picker = ImagePicker();
      final file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
      if (file != null) {
        setState(() => _pickedPhoto = File(file.path));
      }
    } catch (e) {
      _showSnack('Failed to pick image: $e');
    }
  }

  String get _dateLabel {
    if (_selectedDate == null) return 'Pick a date';
    final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${months[_selectedDate!.month - 1]} ${_selectedDate!.day}, ${_selectedDate!.year}';
  }

  String get _timeLabel {
    if (_selectedTime == null) return 'Pick a time';
    final h      = _selectedTime!.hourOfPeriod == 0 ? 12 : _selectedTime!.hourOfPeriod;
    final m      = _selectedTime!.minute.toString().padLeft(2, '0');
    final period = _selectedTime!.period == DayPeriod.am ? 'AM' : 'PM';
    return '$h:$m $period';
  }

  void _showAddCategoryDialog() {
    _newCatCtrl.clear();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: FurPalsColors.warmWhite,
        title: Text('New Category',
            style: GoogleFonts.baloo2(fontWeight: FontWeight.w800, color: FurPalsColors.textDark)),
        content: TextField(
          controller: _newCatCtrl,
          autofocus: true,
          style: GoogleFonts.nunito(fontWeight: FontWeight.w600, color: FurPalsColors.textDark),
          decoration: InputDecoration(
            hintText: 'e.g. Spa Day',
            hintStyle: GoogleFonts.nunito(color: FurPalsColors.textSoft),
            filled: true, fillColor: Colors.white,
            border:        OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFF0E4DC))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFF0E4DC))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: FurPalsColors.pink, width: 1.5)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.nunito(color: FurPalsColors.textMid, fontWeight: FontWeight.w700)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: FurPalsColors.pink,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            onPressed: () {
              final val = _newCatCtrl.text.trim();
              if (val.isNotEmpty && !_categories.contains(val)) {
                setState(() {
                  _categories.insert(_categories.length - 1, val);
                  _selectedCategory = val;
                });
              }
              Navigator.pop(ctx);
            },
            child: Text('Add', style: GoogleFonts.nunito(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  void _submit() {
    if (_titleCtrl.text.trim().isEmpty)    { _showSnack('Please enter an event title 🐾'); return; }
    if (_locationCtrl.text.trim().isEmpty) { _showSnack('Please enter a location 📍'); return; }
    if (_selectedDate == null)             { _showSnack('Please pick a date 📅'); return; }
    if (_selectedTime == null)             { _showSnack('Please pick a time 🕐'); return; }

    final colors = _colorPairs[_selectedColorIndex];

    final result = PetEvent(
      id:          _isEditMode ? widget.eventToEdit!.id : '',
      emoji:       _isEditMode ? widget.eventToEdit!.emoji : '🐾',
      title:       _titleCtrl.text.trim(),
      location:    _locationCtrl.text.trim(),
      date:        _dateLabel,
      time:        _timeLabel,
      category:    _selectedCategory,
      description: _descCtrl.text.trim(),
      color1:      colors['c1']!,
      color2:      colors['c2']!,
      photoPath:   _usePhoto ? _pickedPhoto?.path : null,
      isOwner:     true,
      ownerName:   _isEditMode ? widget.eventToEdit!.ownerName : 'You',
      ownerEmoji:  _isEditMode ? widget.eventToEdit!.ownerEmoji : '🐾',
      ownerId:     _isEditMode ? widget.eventToEdit!.ownerId : '',
      members:     _isEditMode ? widget.eventToEdit!.members : [],
    );

    if (_isEditMode) {
      widget.onUpdate(result);
    } else {
      widget.onAdd(result);
    }

    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(
        _isEditMode
            ? '"${_titleCtrl.text.trim()}" updated!'
            : '"${_titleCtrl.text.trim()}" event added!',
        style: GoogleFonts.nunito(fontWeight: FontWeight.w700),
      ),
      backgroundColor: FurPalsColors.green,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ));
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
      backgroundColor: FurPalsColors.textDark,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: appBackgroundGradient),
        child: SafeArea(
          bottom: false,
          child: FadeTransition(
            opacity: _fadeAnim,
            child: Column(children: [
              _buildTopBar(),
              Expanded(
                child: Container(
                  color: Colors.white.withOpacity(0.4),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                    children: [
                      _buildPreviewCard(),
                      const SizedBox(height: 20),
                      _buildSection('Card Appearance', _buildCardAppearance()),
                      const SizedBox(height: 18),
                      _buildSection('Details', _buildDetailsForm()),
                      const SizedBox(height: 18),
                      _buildSection('Date & Time', _buildDateTimeRow()),
                      const SizedBox(height: 18),
                      _buildSection('🏷️ Category', _buildCategoryChips()),
                      const SizedBox(height: 24),
                      _buildSubmitButton(),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(children: [
        GestureDetector(
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
        const SizedBox(width: 12),
        Text(
          _isEditMode ? 'Edit Event' : 'Add Event',
          style: GoogleFonts.baloo2(fontSize: 22, fontWeight: FontWeight.w900, color: FurPalsColors.textDark),
        ),
      ]),
    );
  }

  Widget _buildPreviewCard() {
    final colors   = _colorPairs[_selectedColorIndex];
    final title    = _titleCtrl.text.isEmpty    ? 'Event Title' : _titleCtrl.text;
    final location = _locationCtrl.text.isEmpty ? 'Location'    : _locationCtrl.text;
    final dateStr  = _selectedDate == null      ? 'Date'        : _dateLabel;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Preview',
            style: GoogleFonts.baloo2(fontSize: 14, fontWeight: FontWeight.w800, color: FurPalsColors.textDark)),
        const SizedBox(height: 8),
        AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: double.infinity, height: 160,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: (_usePhoto && _pickedPhoto != null)
                ? null
                : LinearGradient(
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                    colors: [colors['c1']!, colors['c2']!],
                  ),
            boxShadow: const [BoxShadow(color: FurPalsColors.shadow, blurRadius: 14, offset: Offset(0, 4))],
          ),
          clipBehavior: Clip.hardEdge,
          child: Stack(children: [
            if (_usePhoto && _pickedPhoto != null)
              Positioned.fill(child: Image.file(_pickedPhoto!, fit: BoxFit.cover))
            else if (_usePhoto)
              Container(
                color: FurPalsColors.creamwhite,
                child: const Center(child: Icon(Icons.add_photo_alternate_rounded, size: 48, color: FurPalsColors.textSoft)),
              ),
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.78),
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Row(children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(title,
                        style: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w800, color: FurPalsColors.textDark),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text('$dateStr · $location',
                        style: GoogleFonts.nunito(fontSize: 11, fontWeight: FontWeight.w600, color: FurPalsColors.textMid),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                  ])),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: FurPalsColors.blush, borderRadius: BorderRadius.circular(20)),
                    child: Text(_selectedCategory,
                        style: GoogleFonts.nunito(fontSize: 9, fontWeight: FontWeight.w800, color: FurPalsColors.pink)),
                  ),
                ]),
              ),
            ),
          ]),
        ),
      ],
    );
  }

  Widget _buildCardAppearance() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          _toggleChip(label: '🎨 Color', selected: !_usePhoto, onTap: () => setState(() => _usePhoto = false)),
          const SizedBox(width: 10),
          _toggleChip(label: '📸 Photo', selected: _usePhoto,  onTap: () => setState(() => _usePhoto = true)),
        ]),
        const SizedBox(height: 14),
        if (!_usePhoto) ...[
          Text('Pick a color pair:',
              style: GoogleFonts.nunito(fontSize: 11, fontWeight: FontWeight.w700, color: FurPalsColors.textMid)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10, runSpacing: 10,
            children: List.generate(_colorPairs.length, (i) {
              final selected = i == _selectedColorIndex;
              final pair = _colorPairs[i];
              return GestureDetector(
                onTap: () => setState(() => _selectedColorIndex = i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft, end: Alignment.bottomRight,
                      colors: [pair['c1']!, pair['c2']!],
                    ),
                    border: Border.all(color: selected ? FurPalsColors.pink : Colors.transparent, width: 2.5),
                    boxShadow: selected
                        ? [const BoxShadow(color: Color(0x40F4738A), blurRadius: 8, offset: Offset(0, 2))]
                        : [const BoxShadow(color: FurPalsColors.shadow, blurRadius: 4, offset: Offset(0, 1))],
                  ),
                  child: selected ? const Center(child: Icon(Icons.check_rounded, color: FurPalsColors.textDark, size: 18)) : null,
                ),
              );
            }),
          ),
        ],
        if (_usePhoto)
          GestureDetector(
            onTap: _pickPhoto,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: double.infinity, height: 90,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _pickedPhoto != null ? FurPalsColors.pink : const Color(0xFFF0E4DC),
                  width: 1.5,
                ),
                boxShadow: const [BoxShadow(color: FurPalsColors.shadow, blurRadius: 4, offset: Offset(0, 2))],
              ),
              clipBehavior: Clip.hardEdge,
              child: _pickedPhoto != null
                  ? Stack(fit: StackFit.expand, children: [
                      Image.file(_pickedPhoto!, fit: BoxFit.cover),
                      Positioned(top: 6, right: 6,
                        child: GestureDetector(
                          onTap: () => setState(() => _pickedPhoto = null),
                          child: Container(
                            width: 26, height: 26,
                            decoration: BoxDecoration(color: FurPalsColors.textDark.withOpacity(0.65), shape: BoxShape.circle),
                            child: const Icon(Icons.close_rounded, size: 14, color: Colors.white),
                          ),
                        ),
                      ),
                      Positioned(bottom: 6, right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: FurPalsColors.pink, borderRadius: BorderRadius.circular(20)),
                          child: Text('Change', style: GoogleFonts.nunito(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white)),
                        ),
                      ),
                    ])
                  : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const Icon(Icons.add_photo_alternate_rounded, size: 28, color: FurPalsColors.pink),
                      const SizedBox(height: 4),
                      Text('Tap to upload photo',
                          style: GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.w600, color: FurPalsColors.textMid)),
                    ]),
            ),
          ),
      ],
    );
  }

  Widget _toggleChip({required String label, required bool selected, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? FurPalsColors.pink : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? FurPalsColors.pink : const Color(0xFFF0E4DC), width: 1.5),
          boxShadow: selected ? [const BoxShadow(color: Color(0x40F4738A), blurRadius: 8, offset: Offset(0, 2))] : [],
        ),
        child: Text(label,
            style: GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.w700,
                color: selected ? Colors.white : FurPalsColors.textMid)),
      ),
    );
  }

  Widget _buildDetailsForm() {
    return Column(children: [
      _inputField('EVENT TITLE',            _titleCtrl,    'e.g. Dog Fair 2026',        Icons.event_rounded),
      const SizedBox(height: 12),
      _inputField('LOCATION',               _locationCtrl, 'e.g. SM Mall of Asia',      Icons.location_on_rounded),
      const SizedBox(height: 12),
      _inputField('DESCRIPTION (optional)', _descCtrl,     'What\'s this event about?', Icons.notes_rounded, maxLines: 3),
    ]);
  }

  Widget _inputField(String label, TextEditingController ctrl, String hint, IconData icon, {int maxLines = 1}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: GoogleFonts.nunito(fontSize: 11, fontWeight: FontWeight.w800, color: FurPalsColors.textMid, letterSpacing: 0.3)),
      const SizedBox(height: 5),
      TextField(
        controller: ctrl, maxLines: maxLines,
        onChanged: (_) => setState(() {}),
        style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w600, color: FurPalsColors.textDark),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.nunito(fontSize: 13, color: FurPalsColors.textSoft),
          prefixIcon: Icon(icon, size: 18, color: FurPalsColors.pink),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          filled: true, fillColor: Colors.white,
          border:        OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFF0E4DC), width: 1.5)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFF0E4DC), width: 1.5)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: FurPalsColors.pink, width: 1.5)),
        ),
      ),
    ]);
  }

  Widget _buildDateTimeRow() {
    return Row(children: [
      Expanded(child: _pickerTile(
        icon: Icons.calendar_today_rounded, label: _dateLabel,
        color: FurPalsColors.pink, bg: const Color(0xFFFFF0F3),
        onTap: _pickDate, isSet: _selectedDate != null,
      )),
      const SizedBox(width: 12),
      Expanded(child: _pickerTile(
        icon: Icons.access_time_rounded, label: _timeLabel,
        color: FurPalsColors.purple, bg: const Color(0xFFF0EBFF),
        onTap: _pickTime, isSet: _selectedTime != null,
      )),
    ]);
  }

  Widget _pickerTile({
    required IconData icon, required String label,
    required Color color, required Color bg,
    required VoidCallback onTap, required bool isSet,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: isSet ? bg : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isSet ? color.withOpacity(0.4) : const Color(0xFFF0E4DC), width: 1.5),
          boxShadow: const [BoxShadow(color: FurPalsColors.shadow, blurRadius: 4, offset: Offset(0, 2))],
        ),
        child: Row(children: [
          Icon(icon, size: 16, color: isSet ? color : FurPalsColors.textSoft),
          const SizedBox(width: 8),
          Expanded(child: Text(label,
            style: GoogleFonts.nunito(
              fontSize: 12,
              fontWeight: isSet ? FontWeight.w700 : FontWeight.w500,
              color: isSet ? FurPalsColors.textDark : FurPalsColors.textSoft,
            ),
            overflow: TextOverflow.ellipsis,
          )),
        ]),
      ),
    );
  }

  Widget _buildCategoryChips() {
    return Wrap(
      spacing: 8, runSpacing: 8,
      children: [
        ..._categories.map((cat) {
          final selected = cat == _selectedCategory;
          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = cat),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: selected ? FurPalsColors.pink : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: selected ? FurPalsColors.pink : const Color(0xFFF0E4DC), width: 1.5),
                boxShadow: selected
                    ? [const BoxShadow(color: Color(0x40F4738A), blurRadius: 8, offset: Offset(0, 2))]
                    : [const BoxShadow(color: FurPalsColors.shadow, blurRadius: 3, offset: Offset(0, 1))],
              ),
              child: Text(cat,
                  style: GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.w700,
                      color: selected ? Colors.white : FurPalsColors.textMid)),
            ),
          );
        }),
        GestureDetector(
          onTap: _showAddCategoryDialog,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: FurPalsColors.pink, width: 1.5),
              boxShadow: const [BoxShadow(color: FurPalsColors.shadow, blurRadius: 3, offset: Offset(0, 1))],
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.add_rounded, size: 14, color: FurPalsColors.pink),
              const SizedBox(width: 4),
              Text('Add', style: GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.w700, color: FurPalsColors.pink)),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return GestureDetector(
      onTap: _submit,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: const LinearGradient(colors: [FurPalsColors.pink, FurPalsColors.pinkLight]),
          boxShadow: const [BoxShadow(color: Color(0x55F4738A), blurRadius: 16, offset: Offset(0, 6))],
        ),
        child: Center(child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(_isEditMode ? '' : '', style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 8),
          Text(
            _isEditMode ? 'Save Changes' : 'Create Event',
            style: GoogleFonts.baloo2(fontSize: 17, fontWeight: FontWeight.w800, color: Colors.white),
          ),
        ])),
      ),
    );
  }

  Widget _buildSection(String title, Widget child) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: FurPalsColors.shadow, blurRadius: 6, offset: Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: GoogleFonts.baloo2(fontSize: 14, fontWeight: FontWeight.w800, color: FurPalsColors.textDark)),
        const SizedBox(height: 12),
        child,
      ]),
    );
  }
}