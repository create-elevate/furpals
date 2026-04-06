import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:furpals/models.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CalendarScreen extends StatefulWidget {
  final List<Pet> pets;
  final Appointment? appointmentToEdit; // ← optional

  const CalendarScreen({
    super.key,
    required this.pets,
    this.appointmentToEdit,
  });

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedMonth = DateTime.now();
  DateTime _selectedDate = DateTime.now();

  final DraggableScrollableController _sheetController =
      DraggableScrollableController();

  static const int _pageMiddle = 1200;
  late PageController _pageController;

  int _selectedHour   = 0;
  int _selectedMinute = 0;
  bool _isAM          = true;

  late int _selectedPetId;
  String _type = '🏥 Vet Visit';
  final _titleController = TextEditingController();
  final _vetController   = TextEditingController();
  final _notesController = TextEditingController();

  final List<String> _types = [
    '🏥 Vet Visit', '✂️ Grooming', '💉 Vaccination', '🦷 Dental', '🧪 Lab Test',
  ];

  final List<String> _months = [
    'Jan','Feb','Mar','Apr','May','Jun',
    'Jul','Aug','Sep','Oct','Nov','Dec',
  ];

  final List<String> _fullMonths = [
    'January','February','March','April','May','June',
    'July','August','September','October','November','December',
  ];

  static const double _minChildSize  = 0.38;
  static const double _maxChildSize  = 1.0;
  static const double _initChildSize = 0.38;

  // true = editing existing, false = creating new
  bool get _isEditing => widget.appointmentToEdit != null;

  @override
  void initState() {
    super.initState();
    _selectedPetId = widget.pets.isNotEmpty ? widget.pets[0].id : 0;

    final appt = widget.appointmentToEdit;

    if (appt != null) {
      // ── Pre-fill all fields from the existing appointment ──────────────────
      _titleController.text = appt.title;
      _vetController.text   = appt.vet == 'TBD' ? '' : appt.vet;
      _notesController.text = appt.notes;
      _type                 = appt.type;
      _selectedPetId        = appt.petId;

      // Parse date string e.g. "Apr 5, 2026"
      try {
        final parts = appt.date.replaceAll(',', '').split(' ');
        final monthIdx = _months.indexWhere(
            (m) => m.toLowerCase() == parts[0].toLowerCase().substring(0, 3));
        final day  = int.parse(parts[1]);
        final year = int.parse(parts[2]);
        _selectedDate = DateTime(year, monthIdx + 1, day);
        _focusedMonth = DateTime(year, monthIdx + 1);
      } catch (_) {
        _selectedDate = DateTime.now();
        _focusedMonth = DateTime.now();
      }

      // Parse time string e.g. "10:00 AM"
      try {
        final timeParts = appt.time.split(' ');
        final hm        = timeParts[0].split(':');
        _isAM           = timeParts[1].toUpperCase() == 'AM';
        _selectedHour   = int.parse(hm[0]) % 12; // store 0-11
        _selectedMinute = int.parse(hm[1]);
      } catch (_) {
        _selectedHour   = 0;
        _selectedMinute = 0;
        _isAM           = true;
      }
    }

    // Jump page controller to the correct month
    final base = DateTime(2026, 3);
    final diff = (_focusedMonth.year - base.year) * 12 +
        (_focusedMonth.month - base.month);
    _pageController = PageController(initialPage: _pageMiddle + diff);
  }

  @override
  void dispose() {
    _sheetController.dispose();
    _pageController.dispose();
    _titleController.dispose();
    _vetController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _snapUp() => _sheetController.animateTo(
      _maxChildSize,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut);

  void _snapDown() => _sheetController.animateTo(
      _minChildSize,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut);

  String _monthName(int m) => _months[m - 1];

  void _stepDay(int delta) {
    final next = _selectedDate.add(Duration(days: delta));
    final base = DateTime(2026, 3);
    final diff = (next.year - base.year) * 12 + (next.month - base.month);
    setState(() {
      _selectedDate = next;
      _focusedMonth = DateTime(next.year, next.month);
    });
    _pageController.jumpToPage(_pageMiddle + diff);
  }

  void _stepHour(int delta) {
    setState(() {
      _selectedHour = (_selectedHour + delta + 12) % 12;
    });
  }

  void _stepMinute(int delta) {
    setState(() {
      _selectedMinute = (_selectedMinute + delta + 60) % 60;
    });
  }

  void _submit() {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Please enter a title',
            style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
        backgroundColor: FurPalsColors.textDark,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ));
      return;
    }

    final today      = DateTime.now();
    final dateStr    =
        '${_monthName(_selectedDate.month)} ${_selectedDate.day}, ${_selectedDate.year}';
    final minute     = _selectedMinute.toString().padLeft(2, '0');
    final ampm       = _isAM ? 'AM' : 'PM';
    final displayHour = _selectedHour == 0 ? 12 : _selectedHour;
    final timeStr    = '$displayHour:$minute $ampm';
    final isToday    = _selectedDate.year  == today.year &&
                       _selectedDate.month == today.month &&
                       _selectedDate.day   == today.day;

    final appt = Appointment(
      id:     _isEditing ? widget.appointmentToEdit!.id : '',
      petId:  _selectedPetId,
      title:  _titleController.text.trim(),
      vet:    _vetController.text.isEmpty ? 'TBD' : _vetController.text,
      date:   dateStr,
      time:   timeStr,
      type:   _type,
      notes:  _notesController.text,
      // Keep 'done' status if it was already done, otherwise recalculate
      status: (_isEditing && widget.appointmentToEdit!.status == 'done')
          ? 'done'
          : isToday ? 'today' : 'upcoming',
      ownerId: _isEditing ? widget.appointmentToEdit!.ownerId : FirebaseAuth.instance.currentUser?.uid ?? '',
    );

    Navigator.pop(context, appt);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCE8ED),
      body: SafeArea(
        child: Stack(
          children: [
            // ── CALENDAR ──────────────────────────────────────────────────────
            Column(
              children: [
                _buildTopBar(context),
                SizedBox(
                  height: 390,
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (page) {
                      final diff = page - _pageMiddle;
                      final base = DateTime(2026, 3);
                      setState(() {
                        _focusedMonth =
                            DateTime(base.year, base.month + diff);
                      });
                    },
                    itemBuilder: (context, index) {
                      final diff  = index - _pageMiddle;
                      final base  = DateTime(2026, 3);
                      final month = DateTime(base.year, base.month + diff);
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 12),
                            _buildMonthHeader(),
                            const SizedBox(height: 14),
                            _buildWeekdayRow(),
                            const SizedBox(height: 4),
                            _buildDayGridForMonth(month),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),

            // ── DRAGGABLE BOTTOM SHEET ────────────────────────────────────────
            DraggableScrollableSheet(
              controller: _sheetController,
              initialChildSize: _initChildSize,
              minChildSize: _minChildSize,
              maxChildSize: _maxChildSize,
              snap: true,
              snapSizes: const [_minChildSize, _maxChildSize],
              builder: (context, scrollController) {
                return Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(28)),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black12,
                          blurRadius: 16,
                          offset: Offset(0, -4)),
                    ],
                  ),
                  child: CustomScrollView(
                    controller: scrollController,
                    slivers: [
                      SliverToBoxAdapter(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Drag handle
                            GestureDetector(
                              onTap: () {
                                if (_sheetController.size < 0.6) {
                                  _snapUp();
                                } else {
                                  _snapDown();
                                }
                              },
                              child: Container(
                                width: double.infinity,
                                color: Colors.transparent,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                child: Center(
                                  child: Container(
                                    width: 48,
                                    height: 4,
                                    decoration: BoxDecoration(
                                      color: Colors.black87,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            // ── Form ──────────────────────────────────────────
                            Padding(
                              padding:
                                  const EdgeInsets.fromLTRB(20, 4, 20, 36),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildSheetHeader(),
                                  const SizedBox(height: 20),

                                  Text('PET',
                                      style: GoogleFonts.nunito(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                          color: FurPalsColors.textMid,
                                          letterSpacing: 0.3)),
                                  const SizedBox(height: 8),
                                  _buildPetSelector(),
                                  const SizedBox(height: 16),

                                  _formField('VET / CLINIC', _vetController,
                                      'Dr. Name or Clinic'),
                                  const SizedBox(height: 12),

                                  _dropdownField('TYPE', _type, _types,
                                      (v) => setState(() => _type = v!)),
                                  const SizedBox(height: 12),

                                  _formField(
                                      'NOTES',
                                      _notesController,
                                      'Any notes for this visit...',
                                      maxLines: 3),
                                  const SizedBox(height: 22),

                                  _buildDateTimeCard(),
                                  const SizedBox(height: 28),

                                  _buildSaveButton(),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
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
                      offset: Offset(0, 3))
                ],
              ),
              child: const Center(
                child: Icon(Icons.arrow_back_ios_new_rounded,
                    size: 16, color: FurPalsColors.textDark),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              // ← shows "Edit Appointment" when editing
              _isEditing ? 'Edit Appointment' : 'New Appointment',
              style: GoogleFonts.baloo2(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Colors.black),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthHeader() {
    return Row(
      children: [
        Text(
          '${_months[_focusedMonth.month - 1].toUpperCase()} ',
          style: GoogleFonts.josefinSans(
              fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        GestureDetector(
          onTap: _showYearPicker,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${_focusedMonth.year}',
                  style: GoogleFonts.josefinSans(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black)),
              const SizedBox(width: 2),
              const Icon(Icons.arrow_drop_down, color: Colors.black, size: 18),
            ],
          ),
        ),
      ],
    );
  }

  void _showYearPicker() {
    const int startYear = 2026;
    const int endYear   = 2026 + 20;
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Select Year',
                  style: GoogleFonts.nunito(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Colors.black87)),
              const SizedBox(height: 16),
              SizedBox(
                height: 260,
                width: double.maxFinite,
                child: GridView.builder(
                  itemCount: endYear - startYear + 1,
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                          childAspectRatio: 1.4),
                  itemBuilder: (context, index) {
                    final year       = startYear + index;
                    final isSelected = year == _focusedMonth.year;
                    return GestureDetector(
                      onTap: () {
                        final newMonth = DateTime(year, _focusedMonth.month);
                        final base     = DateTime(2026, 3);
                        final diff     = (newMonth.year - base.year) * 12 +
                            (newMonth.month - base.month);
                        setState(() {
                          _focusedMonth = newMonth;
                          _selectedDate = DateTime(
                              year, _selectedDate.month, _selectedDate.day);
                        });
                        _pageController.jumpToPage(_pageMiddle + diff);
                        Navigator.pop(context);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFFD4A96A)
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text('$year',
                              style: GoogleFonts.nunito(
                                fontSize: 13,
                                fontWeight: isSelected
                                    ? FontWeight.w900
                                    : FontWeight.w600,
                                color: isSelected
                                    ? Colors.white
                                    : Colors.black87,
                              )),
                        ),
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

  Widget _buildWeekdayRow() {
    const days = ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: days
          .map((d) => SizedBox(
                width: 36,
                child: Center(
                  child: Text(d,
                      style: GoogleFonts.nunito(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey.shade600)),
                ),
              ))
          .toList(),
    );
  }

  Widget _buildDayGridForMonth(DateTime month) {
    final firstDay    = DateTime(month.year, month.month, 1);
    final startOffset = firstDay.weekday - 1;
    final daysInMonth = DateUtils.getDaysInMonth(month.year, month.month);

    final List<Widget> cells = [];
    for (int i = 0; i < startOffset; i++) {
      cells.add(const SizedBox(width: 36, height: 40));
    }
    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(month.year, month.month, day);
      final isSelected = _selectedDate.year  == date.year &&
                         _selectedDate.month == date.month &&
                         _selectedDate.day   == date.day;
      cells.add(GestureDetector(
        onTap: () {
          setState(() => _selectedDate = date);
          _snapUp();
        },
        child: Container(
          width: 36, height: 44,
          margin: const EdgeInsets.symmetric(vertical: 2),
          decoration: isSelected
              ? const BoxDecoration(
                  color: Color(0xFFD4A96A), shape: BoxShape.circle)
              : null,
          child: Center(
            child: Text('$day',
                style: GoogleFonts.nunito(
                  fontSize: isSelected ? 16 : 15,
                  fontWeight:
                      isSelected ? FontWeight.w900 : FontWeight.w500,
                  color: isSelected ? Colors.white : Colors.black87,
                )),
          ),
        ),
      ));
    }
    while (cells.length % 7 != 0) {
      cells.add(const SizedBox(width: 36, height: 40));
    }

    final rows = <Widget>[];
    for (int i = 0; i < cells.length; i += 7) {
      rows.add(Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: cells.sublist(i, i + 7)));
    }
    return Column(children: rows);
  }

  Widget _buildSheetHeader() {
    return Row(
      children: [
        Container(
          width: 58, height: 58,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFFFCE8ED),
            border: Border.all(color: Colors.pink.shade100, width: 2),
          ),
          child: ClipOval(
            child: Image.asset(
              'assets/icons/calendar_pet_avatar.png',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const Center(
                  child: Text('🐱', style: TextStyle(fontSize: 28))),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: TextField(
            controller: _titleController,
            style: GoogleFonts.nunito(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: Colors.black87),
            decoration: InputDecoration(
              hintText: 'Appointment Title',
              hintStyle: GoogleFonts.nunito(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: Colors.grey.shade300),
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPetSelector() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: widget.pets.map((p) {
          final sel = p.id == _selectedPetId;
          return GestureDetector(
            onTap: () => setState(() => _selectedPetId = p.id),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: sel ? FurPalsColors.blush : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: sel ? FurPalsColors.pink : const Color(0xFFF0E4DC),
                  width: sel ? 2 : 1.5,
                ),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(p.emoji, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 6),
                Text(p.name,
                    style: GoogleFonts.nunito(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: sel
                            ? FurPalsColors.pink
                            : FurPalsColors.textDark)),
              ]),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDateTimeCard() {
    final dayNum   = _selectedDate.day.toString().padLeft(2, '0');
    final monthStr = _fullMonths[_selectedDate.month - 1];
    final yearStr  = '${_selectedDate.year}';
    final minStr   = _selectedMinute.toString().padLeft(2, '0');
    final hourStr  = _selectedHour.toString().padLeft(2, '0');

    return Container(
      decoration: BoxDecoration(
        color: FurPalsColors.cream,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF0E4DC), width: 1.5),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Date & Time',
              style: GoogleFonts.nunito(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: FurPalsColors.textDark)),
          const SizedBox(height: 14),

          // Date block
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFF0E4DC), width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('DATE',
                    style: GoogleFonts.nunito(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: FurPalsColors.textMid,
                        letterSpacing: 0.4)),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _arrowBtn(Icons.chevron_left_rounded,  () => _stepDay(-1)),
                    Column(
                      children: [
                        Text(dayNum,
                            style: GoogleFonts.nunito(
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                color: Colors.black87)),
                        Text('$monthStr $yearStr',
                            style: GoogleFonts.nunito(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade400)),
                      ],
                    ),
                    _arrowBtn(Icons.chevron_right_rounded, () => _stepDay(1)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Time block
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFF0E4DC), width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('TIME',
                    style: GoogleFonts.nunito(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: FurPalsColors.textMid,
                        letterSpacing: 0.4)),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _timeStepper(
                      value: hourStr,
                      onUp:   () => _stepHour(1),
                      onDown: () => _stepHour(-1),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(':',
                          style: GoogleFonts.nunito(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: Colors.grey.shade300)),
                    ),
                    _timeStepper(
                      value: minStr,
                      onUp:   () => _stepMinute(1),
                      onDown: () => _stepMinute(-1),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      children: [
                        _ampmBtn('AM', _isAM,  () => setState(() => _isAM = true)),
                        const SizedBox(height: 6),
                        _ampmBtn('PM', !_isAM, () => setState(() => _isAM = false)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _arrowBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28, height: 28,
        decoration: BoxDecoration(
          color: FurPalsColors.blush,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 20, color: FurPalsColors.pink),
      ),
    );
  }

  Widget _timeStepper({
    required String value,
    required VoidCallback onUp,
    required VoidCallback onDown,
  }) {
    return Column(
      children: [
        GestureDetector(
          onTap: onUp,
          child: Container(
            width: 32, height: 28,
            decoration: BoxDecoration(
              color: FurPalsColors.blush,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.keyboard_arrow_up_rounded,
                size: 20, color: FurPalsColors.pink),
          ),
        ),
        const SizedBox(height: 4),
        Text(value,
            style: GoogleFonts.nunito(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Colors.black87)),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: onDown,
          child: Container(
            width: 32, height: 28,
            decoration: BoxDecoration(
              color: FurPalsColors.blush,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.keyboard_arrow_down_rounded,
                size: 20, color: FurPalsColors.pink),
          ),
        ),
      ],
    );
  }

  Widget _ampmBtn(String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: active ? FurPalsColors.blush : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: active ? FurPalsColors.pink : const Color(0xFFF0E4DC),
            width: active ? 1.5 : 1,
          ),
        ),
        child: Text(label,
            style: GoogleFonts.nunito(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: active ? FurPalsColors.pink : Colors.grey.shade400)),
      ),
    );
  }

  Widget _buildSaveButton() {
    return GestureDetector(
      onTap: _submit,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
              colors: [FurPalsColors.pink, FurPalsColors.pinkLight]),
          boxShadow: const [
            BoxShadow(
                color: Color(0x55F4738A),
                blurRadius: 14,
                offset: Offset(0, 6))
          ],
        ),
        child: Center(
          child: Text(
            // ← label changes based on mode
            _isEditing ? 'SAVE CHANGES' : 'SAVE APPOINTMENT',
            style: GoogleFonts.baloo2(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: 1),
          ),
        ),
      ),
    );
  }
}

// ── Shared form helpers ───────────────────────────────────────────────────────
Widget _formField(
    String label, TextEditingController ctrl, String hint,
    {int maxLines = 1}) {
  return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(label,
        style: GoogleFonts.nunito(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: FurPalsColors.textMid,
            letterSpacing: 0.3)),
    const SizedBox(height: 5),
    TextField(
      controller: ctrl,
      maxLines: maxLines,
      style: GoogleFonts.nunito(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: FurPalsColors.textDark),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle:
            GoogleFonts.nunito(fontSize: 13, color: FurPalsColors.textSoft),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFF0E4DC), width: 1.5)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFF0E4DC), width: 1.5)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: FurPalsColors.pink, width: 1.5)),
      ),
    ),
  ]);
}

Widget _dropdownField(String label, String value, List<String> options,
    ValueChanged<String?> onChanged) {
  return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(label,
        style: GoogleFonts.nunito(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: FurPalsColors.textMid,
            letterSpacing: 0.3)),
    const SizedBox(height: 5),
    DropdownButtonFormField<String>(
      value: value,
      onChanged: onChanged,
      items: options
          .map((o) => DropdownMenuItem(
              value: o,
              child: Text(o,
                  style: GoogleFonts.nunito(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: FurPalsColors.textDark))))
          .toList(),
      decoration: InputDecoration(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFF0E4DC), width: 1.5)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFF0E4DC), width: 1.5)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: FurPalsColors.pink, width: 1.5)),
      ),
    ),
  ]);
}