import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:furpals/NotificationScreen.dart';
import 'package:furpals/Homescreen.dart';

//colorsssssssss
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
  static const textSoft    = Color(0x66000000);
  static const pink        = Color(0xFFF4738A);
  static const pinkLight   = Color(0xFFFF9AB0);
  static const green       = Color(0xFF5DB87A);
  static const purple      = Color(0xFF8B6FD4);
  static const shadow      = Color(0x20B47864);
  static const creamwhite  = Color(0xFFF9E9D5);
  static const blue        = Color(0xFF448AFF);
  static const heartRed    = Color(0xFFE53935);
  static const black100    = Color(0xFF000000);
}

const appBackgroundGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  stops: [0.0, 0.5, 1.0],
  colors: [Color(0xFFFCDDE8), Color(0xFFFFE8D2), Color(0xFFD4F0E4)],
);

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedMonth = DateTime(2026, 3);
  DateTime _selectedDate = DateTime(2026, 3, 23);

  final DraggableScrollableController _sheetController =
      DraggableScrollableController();

  // Large page count centered at middle so user can swipe infinitely
  static const int _pageMiddle = 1200;
  late PageController _pageController;

  late FixedExtentScrollController _monthController;
  late FixedExtentScrollController _hourController;
  late FixedExtentScrollController _minuteController;
  late FixedExtentScrollController _ampmController;

  int _selectedMonthIdx = 2;
  int _selectedHour     = 11;
  int _selectedMinute   = 0;
  int _selectedAmPm     = 1;

  final TextEditingController _titleController      = TextEditingController();
  final TextEditingController _dogNameController    = TextEditingController();
  final TextEditingController _doctorNameController = TextEditingController();
  final TextEditingController _noteController       = TextEditingController();

  final List<String> _months = [
    'Jan','Feb','Mar','Apr','May','Jun',
    'Jul','Aug','Sep','Oct','Nov','Dec',
  ];

  static const double _minChildSize  = 0.38;
  static const double _maxChildSize  = 1.0;
  static const double _initChildSize = 0.38;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _pageMiddle);
    _monthController  = FixedExtentScrollController(initialItem: _selectedMonthIdx);
    _hourController   = FixedExtentScrollController(initialItem: _selectedHour);
    _minuteController = FixedExtentScrollController(initialItem: _selectedMinute);
    _ampmController   = FixedExtentScrollController(initialItem: _selectedAmPm);
  }

  @override
  void dispose() {
    _sheetController.dispose();
    _pageController.dispose();
    _monthController.dispose();
    _hourController.dispose();
    _minuteController.dispose();
    _ampmController.dispose();
    _titleController.dispose();
    _dogNameController.dispose();
    _doctorNameController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _snapUp() {
    _sheetController.animateTo(
      _maxChildSize,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  void _snapDown() {
    _sheetController.animateTo(
      _minChildSize,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCE8ED),
      body: SafeArea(
        child: Stack(
          children: [
            // CALENDAR (behind sheet)
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
                        _focusedMonth = DateTime(
                          base.year,
                          base.month + diff,
                        );
                      });
                    },
                    itemBuilder: (context, index) {
                      final diff = index - _pageMiddle;
                      final base = DateTime(2026, 3);
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

            // DRAGGABLE BOTTOM SHEET 
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
                            //  DRAG HANDLE (tap or drag to snap) 
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

                            // FORM 
                            Padding(
                              padding:
                                  const EdgeInsets.fromLTRB(20, 4, 20, 36),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildSheetHeader(),
                                  const SizedBox(height: 20),
                                  _buildTextField(
                                    controller: _dogNameController,
                                    hint: "Dog's full name",
                                    assetIcon: 'assets/icons/dog_input.png',
                                    fallbackEmoji: '🐶',
                                    bgColor: const Color(0xFFEDD9B3),
                                  ),
                                  const SizedBox(height: 12),
                                  _buildTextField(
                                    controller: _doctorNameController,
                                    hint: "Doctor's Name",
                                    assetIcon:
                                        'assets/icons/doctor_input.png',
                                    fallbackEmoji: '👨‍⚕️',
                                    bgColor: const Color(0xFFD4EBF2),
                                  ),
                                  const SizedBox(height: 16),
                                  Text('Add Note',
                                      style: GoogleFonts.nunito(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.black87)),
                                  const SizedBox(height: 8),
                                  _buildNoteField(),
                                  const SizedBox(height: 22),
                                  Text('Date and Time',
                                      style: GoogleFonts.nunito(
                                          fontSize: 17,
                                          fontWeight: FontWeight.w900,
                                          color: Colors.black87)),
                                  const SizedBox(height: 14),
                                  _buildDateTimePicker(),
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

  //  TOP BAR 
 Widget _buildTopBar (BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: () =>Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const Homescreen()),),
            child: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [BoxShadow(color: FurPalsColors.shadow, blurRadius: 10, offset: Offset(0, 3))],
              ),
              child: const Center(child: Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: FurPalsColors.textDark)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Row(
              children: [
                Text('Calendar', // username display in top bar
                    style: GoogleFonts.baloo2(
                      fontSize: 25,
                      fontWeight: FontWeight.w800,
                      color: Colors.black,
                    )),
              ],
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () {},
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.08), blurRadius: 6)
                ],
              ),
              child: Row(
                children: [
                  Image.asset('assets/icons/draft.png',
                      width: 16, height: 16,
                      errorBuilder: (_, __, ___) => const Icon(
                          Icons.save_outlined,
                          size: 16,
                          color: Colors.black87)),
                  const SizedBox(width: 5),
                  Text('Draft',
                      style: GoogleFonts.nunito(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  //CALENDAR GRID 
  Widget _buildMonthHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Text(
              '${_months[_focusedMonth.month - 1].toUpperCase()} ',
              style: GoogleFonts.josefinSans(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87),
            ),
            //TAPPABLE YEAR 
            GestureDetector(
              onTap: _showYearPicker,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
               
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${_focusedMonth.year}',
                      style: GoogleFonts.josefinSans(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black),
                    ),
                    const SizedBox(width: 2),
                    const Icon(Icons.arrow_drop_down,
                        color: Colors.black, size: 18),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(), // chevrons removed — use swipe gesture
      ],
    );
  }

  void _showYearPicker() {
    final int currentYear = _focusedMonth.year;
    // Show 10 years before and after current year
    final int startYear = currentYear - 10;
    final int endYear   = currentYear + 10;

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Select Year',
                  style: GoogleFonts.holtwoodOneSc(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 260,
                  width: double.maxFinite,
                  child: GridView.builder(
                    itemCount: endYear - startYear + 1,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      childAspectRatio: 1.4,
                    ),
                    itemBuilder: (context, index) {
                      final year = startYear + index;
                      final isSelected = year == _focusedMonth.year;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _focusedMonth =
                                DateTime(year, _focusedMonth.month);
                          });
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
                            child: Text(
                              '$year',
                              style: GoogleFonts.nunito(
                                fontSize: 13,
                                fontWeight: isSelected
                                    ? FontWeight.w900
                                    : FontWeight.w600,
                                color: isSelected
                                    ? Colors.white
                                    : Colors.black87,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
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

  Widget _buildDayGrid() => _buildDayGridForMonth(_focusedMonth);

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
      final isSelected = _selectedDate.year  == date.year  &&
                         _selectedDate.month == date.month &&
                         _selectedDate.day   == date.day;

      cells.add(GestureDetector(
        onTap: () {
          setState(() => _selectedDate = date);
          _snapUp();
        },
        child: Container(
          width: 36,
          height: 44,
          margin: const EdgeInsets.symmetric(vertical: 2),
          decoration: isSelected
              ? const BoxDecoration(
                  color: Color(0xFFD4A96A), shape: BoxShape.circle)
              : null,
          child: Center(
            child: Text('$day',
                style: GoogleFonts.nunito(
                  fontSize: isSelected ? 16 : 15,
                  fontWeight: isSelected ? FontWeight.w900 : FontWeight.w500,
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
        children: cells.sublist(i, i + 7),
      ));
    }
    return Column(children: rows);
  }

  // SHEET WIDGETS 
  Widget _buildSheetHeader() {
    return Row(
      children: [
        Container(
          width: 58,
          height: 58,
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
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: Colors.black87),
            decoration: InputDecoration(
              hintText: 'Title',
              hintStyle: GoogleFonts.nunito(
                  fontSize: 26,
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required String assetIcon,
    required String fallbackEmoji,
    required Color bgColor,
  }) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
          color: bgColor, borderRadius: BorderRadius.circular(30)),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Image.asset(assetIcon, width: 22, height: 22,
              errorBuilder: (_, __, ___) =>
                  Text(fallbackEmoji, style: const TextStyle(fontSize: 20))),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              style: GoogleFonts.nunito(
                  fontSize: 14, color: Colors.brown.shade700),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: GoogleFonts.nunito(
                    color: Colors.brown.shade300, fontSize: 14),
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoteField() {
    return Container(
      height: 110,
      decoration: BoxDecoration(
          color: const Color(0xFFEDD9B3),
          borderRadius: BorderRadius.circular(16)),
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
      child: TextField(
        controller: _noteController,
        maxLines: null,
        expands: true,
        style: GoogleFonts.nunito(fontSize: 14),
        decoration: const InputDecoration(border: InputBorder.none),
      ),
    );
  }

  Widget _buildDateTimePicker() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _pickerColumn('Month', _monthController, _months,
            (i) => setState(() => _selectedMonthIdx = i)),
        _pickerColumn(
            'Hour',
            _hourController,
            List.generate(12, (i) => '${i + 1}'.padLeft(2, '0')),
            (i) => setState(() => _selectedHour = i)),
        _pickerColumn(
            'Minute',
            _minuteController,
            List.generate(60, (i) => '$i'.padLeft(2, '0')),
            (i) => setState(() => _selectedMinute = i)),
        _pickerColumn('', _ampmController, ['AM', 'PM'],
            (i) => setState(() => _selectedAmPm = i)),
      ],
    );
  }

  Widget _pickerColumn(
    String label,
    FixedExtentScrollController controller,
    List<String> items,
    ValueChanged<int> onChanged,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label.isNotEmpty) ...[
          Text(
            label,
            style: GoogleFonts.nunito(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 6),
        ] else
          const SizedBox(height: 21), // align with labeled columns
        SizedBox(
          height: 96, // exactly 3 items × 32px itemExtent
          width: 60,
          child: ListWheelScrollView.useDelegate(
            controller: controller,
            itemExtent: 32,
            perspective: 0.004,
            diameterRatio: 1.8,
            physics: const FixedExtentScrollPhysics(),
            onSelectedItemChanged: onChanged,
            childDelegate: ListWheelChildBuilderDelegate(
              childCount: items.length,
              builder: (context, index) {
                final isSelected = controller.hasClients &&
                    controller.selectedItem == index;
                return Center(
                  child: Text(
                    items[index],
                    style: GoogleFonts.nunito(
                      fontSize: isSelected ? 20 : 14,
                      fontWeight:
                          isSelected ? FontWeight.w900 : FontWeight.w400,
                      color: isSelected
                          ? Colors.black87
                          : Colors.grey.shade400,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return Center(
      child: GestureDetector(
        onTap: () {
          // TODO: wire up save logic
        },
        child: Container(
          width: 200,
          height: 52,
          decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(30)),
          child: Center(
            child: Text('SAVE',
                style: GoogleFonts.nunito(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 2)),
          ),
        ),
      ),
    );
  }
}