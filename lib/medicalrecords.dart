import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// ─── FurPals design tokens (shared) ────────────────────────────────────────
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
  static const purple = Color(0xFF8B6FD4);
  static const blue = Color(0xFF448AFF);
}

const appBackgroundGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  stops: [0.0, 0.5, 1.0],
  colors: [Color(0xFFFCDDE8), Color(0xFFFFE8D2), Color(0xFFD4F0E4)],
);

// ─── Category config ────────────────────────────────────────────────────────
enum MedicalCategory { grooming, checkup, vaccine }

extension MedicalCategoryExt on MedicalCategory {
  String get label {
    switch (this) {
      case MedicalCategory.grooming: return 'Grooming';
      case MedicalCategory.checkup:  return 'Check-up';
      case MedicalCategory.vaccine:  return 'Vet Vaccine Visit';
    }
  }

  IconData get icon {
    switch (this) {
      case MedicalCategory.grooming: return Icons.content_cut_rounded;
      case MedicalCategory.checkup:  return Icons.medical_information_rounded;
      case MedicalCategory.vaccine:  return Icons.vaccines_rounded;
    }
  }

  Color get color {
    switch (this) {
      case MedicalCategory.grooming: return FurPalsColors.purple;
      case MedicalCategory.checkup:  return FurPalsColors.blue;
      case MedicalCategory.vaccine:  return FurPalsColors.green;
    }
  }

  Color get bgColor {
    switch (this) {
      case MedicalCategory.grooming: return FurPalsColors.lavender;
      case MedicalCategory.checkup:  return const Color(0xFFE3EDFF);
      case MedicalCategory.vaccine:  return FurPalsColors.mint;
    }
  }

  String get firestoreKey => name; // 'grooming' | 'checkup' | 'vaccine'
}

// ─── Screen ─────────────────────────────────────────────────────────────────
class MedicalRecordsScreen extends StatefulWidget {
  final String currentUid;
  final String petId;
  final String petName;

  const MedicalRecordsScreen({
    super.key,
    required this.currentUid,
    required this.petId,
    required this.petName,
  });

  @override
  State<MedicalRecordsScreen> createState() => _MedicalRecordsScreenState();
}

class _MedicalRecordsScreenState extends State<MedicalRecordsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  final _searchCtrl = TextEditingController();
  String _query = '';

  final _cats = MedicalCategory.values;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: _cats.length, vsync: this);
    _searchCtrl.addListener(() => setState(() => _query = _searchCtrl.text.trim().toLowerCase()));
  }

  @override
  void dispose() {
    _tab.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  CollectionReference _col(MedicalCategory cat) => FirebaseFirestore.instance
      .collection('users')
      .doc(widget.currentUid)
      .collection('pets')
      .doc(widget.petId)
      .collection('medical_${cat.firestoreKey}');

  void _showAddSheet(MedicalCategory cat) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddRecordSheet(
        category: cat,
        colRef: _col(cat),
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
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.45)),
            child: Column(
              children: [
                _buildAppBar(),
                _buildSearchBar(),
                _buildTabBar(),
                Expanded(
                  child: TabBarView(
                    controller: _tab,
                    children: _cats
                        .map((cat) => _RecordList(
                              colRef: _col(cat),
                              category: cat,
                              query: _query,
                            ))
                        .toList(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: AnimatedBuilder(
        animation: _tab,
        builder: (_, __) {
          final cat = _cats[_tab.index];
          return FloatingActionButton.extended(
            onPressed: () => _showAddSheet(cat),
            backgroundColor: cat.color,
            icon: const Icon(Icons.add_rounded, color: Colors.white),
            label: Text('Add ${cat.label}',
                style: GoogleFonts.baloo2(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Colors.white)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
          );
        },
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
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [BoxShadow(color: FurPalsColors.shadow, blurRadius: 10, offset: Offset(0, 3))],
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: FurPalsColors.textDark),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShaderMask(
                  shaderCallback: (b) => const LinearGradient(
                      colors: [Color(0xFF8B6FD4), Color(0xFF5DB87A)]).createShader(b),
                  child: Text('Medical Records',
                      style: GoogleFonts.baloo2(
                          fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white)),
                ),
                Text(widget.petName,
                    style: GoogleFonts.nunito(
                        fontSize: 12, fontWeight: FontWeight.w600, color: FurPalsColors.textMid)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: FurPalsColors.mint,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [BoxShadow(color: FurPalsColors.shadow, blurRadius: 8, offset: Offset(0, 2))],
            ),
            child: const Icon(Icons.folder_open_rounded, size: 20, color: FurPalsColors.green),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
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
            const Icon(Icons.search_rounded, color: FurPalsColors.textSoft, size: 22),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _searchCtrl,
                decoration: InputDecoration(
                  hintText: 'Search records...',
                  hintStyle: GoogleFonts.nunito(color: FurPalsColors.textSoft, fontSize: 13, fontWeight: FontWeight.w500),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
                style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w700, color: FurPalsColors.textDark),
              ),
            ),
            if (_query.isNotEmpty)
              GestureDetector(
                onTap: () { _searchCtrl.clear(); setState(() => _query = ''); },
                child: const Icon(Icons.close_rounded, color: FurPalsColors.textMid, size: 18),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: FurPalsColors.shadow, blurRadius: 6, offset: Offset(0, 2))],
      ),
      child: TabBar(
        controller: _tab,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: const LinearGradient(colors: [FurPalsColors.pink, FurPalsColors.pinkLight]),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelPadding: EdgeInsets.zero,
        tabs: _cats.map((cat) => Tab(
          height: 44,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(cat.icon, size: 14),
              const SizedBox(width: 4),
              Text(cat.label, style: GoogleFonts.nunito(fontSize: 11, fontWeight: FontWeight.w800)),
            ],
          ),
        )).toList(),
        labelColor: Colors.white,
        unselectedLabelColor: FurPalsColors.textMid,
      ),
    );
  }
}

// ─── Record list ─────────────────────────────────────────────────────────────
class _RecordList extends StatelessWidget {
  final CollectionReference colRef;
  final MedicalCategory category;
  final String query;

  const _RecordList({required this.colRef, required this.category, required this.query});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: colRef.orderBy('date', descending: true).snapshots(),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: FurPalsColors.pink));
        }
        final docs = snap.data?.docs ?? [];
        final filtered = query.isEmpty
            ? docs
            : docs.where((d) {
                final data = d.data() as Map<String, dynamic>;
                final title = (data['title'] as String? ?? '').toLowerCase();
                final notes = (data['notes'] as String? ?? '').toLowerCase();
                final vet   = (data['vet'] as String? ?? '').toLowerCase();
                return title.contains(query) || notes.contains(query) || vet.contains(query);
              }).toList();

        if (filtered.isEmpty) {
          return _emptyState(category);
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
          itemCount: filtered.length,
          itemBuilder: (_, i) {
            final data = filtered[i].data() as Map<String, dynamic>;
            return _RecordCard(
              docId: filtered[i].id,
              data: data,
              category: category,
              colRef: colRef,
            );
          },
        );
      },
    );
  }

  Widget _emptyState(MedicalCategory cat) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(color: cat.bgColor, shape: BoxShape.circle),
            child: Icon(cat.icon, size: 36, color: cat.color),
          ),
          const SizedBox(height: 16),
          Text('No ${cat.label} records yet',
              style: GoogleFonts.baloo2(fontSize: 16, fontWeight: FontWeight.w800, color: FurPalsColors.textDark)),
          const SizedBox(height: 6),
          Text('Tap the + button to add one',
              style: GoogleFonts.nunito(fontSize: 12, color: FurPalsColors.textMid)),
        ],
      ),
    );
  }
}

// ─── Record card ─────────────────────────────────────────────────────────────
class _RecordCard extends StatelessWidget {
  final String docId;
  final Map<String, dynamic> data;
  final MedicalCategory category;
  final CollectionReference colRef;

  const _RecordCard({
    required this.docId, required this.data,
    required this.category, required this.colRef,
  });

  void _showDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _RecordDetailSheet(
        docId: docId, data: data, category: category, colRef: colRef,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title  = data['title'] as String? ?? 'Record';
    final date   = data['date'] as String? ?? '';
    final vet    = data['vet'] as String? ?? '';
    final notes  = data['notes'] as String? ?? '';

    return GestureDetector(
      onTap: () => _showDetail(context),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [BoxShadow(color: FurPalsColors.shadow, blurRadius: 10, offset: Offset(0, 3))],
        ),
        child: Row(
          children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(color: category.bgColor, borderRadius: BorderRadius.circular(14)),
              child: Icon(category.icon, size: 22, color: category.color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.baloo2(fontSize: 14, fontWeight: FontWeight.w800, color: FurPalsColors.textDark)),
                  if (date.isNotEmpty)
                    Text(date, style: GoogleFonts.nunito(fontSize: 11, fontWeight: FontWeight.w600, color: category.color)),
                  if (vet.isNotEmpty)
                    Text(vet, style: GoogleFonts.nunito(fontSize: 11, color: FurPalsColors.textMid), overflow: TextOverflow.ellipsis),
                  if (notes.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(notes,
                        style: GoogleFonts.nunito(fontSize: 11, color: FurPalsColors.textMid),
                        maxLines: 2, overflow: TextOverflow.ellipsis),
                  ],
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: FurPalsColors.textMid, size: 20),
          ],
        ),
      ),
    );
  }
}

// ─── Add record sheet ─────────────────────────────────────────────────────────
class _AddRecordSheet extends StatefulWidget {
  final MedicalCategory category;
  final CollectionReference colRef;

  const _AddRecordSheet({required this.category, required this.colRef});

  @override
  State<_AddRecordSheet> createState() => _AddRecordSheetState();
}

class _AddRecordSheetState extends State<_AddRecordSheet> {
  final _titleCtrl = TextEditingController();
  final _vetCtrl   = TextEditingController();
  final _clinicCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  DateTime? _date;
  bool _saving = false;

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? now,
      firstDate: DateTime(now.year - 20),
      lastDate: now,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(colorScheme: ColorScheme.light(primary: widget.category.color)),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    if (_titleCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Please enter a title', style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
        backgroundColor: FurPalsColors.heartRed,
      ));
      return;
    }
    setState(() => _saving = true);
    try {
      await widget.colRef.add({
        'title': _titleCtrl.text.trim(),
        'vet': _vetCtrl.text.trim(),
        'clinic': _clinicCtrl.text.trim(),
        'notes': _notesCtrl.text.trim(),
        'date': _date != null ? '${_date!.year}-${_date!.month.toString().padLeft(2,'0')}-${_date!.day.toString().padLeft(2,'0')}' : '',
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (mounted) Navigator.pop(context);
    } catch (e) {
      debugPrint('Save record error: $e');
    }
    if (mounted) setState(() => _saving = false);
  }

  @override
  void dispose() {
    _titleCtrl.dispose(); _vetCtrl.dispose();
    _clinicCtrl.dispose(); _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cat = widget.category;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: FurPalsColors.warmWhite,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.88),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(children: [
                Container(width: 40, height: 4,
                  decoration: BoxDecoration(color: FurPalsColors.blush, borderRadius: BorderRadius.circular(2))),
                const SizedBox(height: 14),
                Row(children: [
                  Container(width: 36, height: 36,
                    decoration: BoxDecoration(color: cat.bgColor, borderRadius: BorderRadius.circular(10)),
                    child: Icon(cat.icon, size: 18, color: cat.color)),
                  const SizedBox(width: 10),
                  Text('Add ${cat.label}',
                      style: GoogleFonts.baloo2(fontSize: 18, fontWeight: FontWeight.w800, color: FurPalsColors.textDark)),
                ]),
                const SizedBox(height: 8),
              ]),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _field(_titleCtrl, 'Title *', Icons.label_rounded),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: _pickDate,
                    child: Container(
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: FurPalsColors.blush, width: 1.5)),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      child: Row(children: [
                        Icon(Icons.calendar_today_rounded, color: cat.color, size: 18),
                        const SizedBox(width: 10),
                        Text(
                          _date != null
                              ? '${_date!.year}-${_date!.month.toString().padLeft(2,'0')}-${_date!.day.toString().padLeft(2,'0')}'
                              : 'Date (tap to pick)',
                          style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w700,
                              color: _date != null ? FurPalsColors.textDark : FurPalsColors.textMid),
                        ),
                      ]),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _field(_vetCtrl, 'Veterinarian', Icons.person_outlined),
                  const SizedBox(height: 10),
                  _field(_clinicCtrl, 'Clinic / Hospital', Icons.local_hospital_outlined),
                  const SizedBox(height: 10),
                  _field(_notesCtrl, 'Notes / Details', Icons.notes_rounded, maxLines: 4),
                  const SizedBox(height: 24),
                  GestureDetector(
                    onTap: _saving ? null : _save,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: cat.color,
                        boxShadow: [BoxShadow(color: cat.color.withOpacity(0.4), blurRadius: 14, offset: const Offset(0, 6))],
                      ),
                      child: Center(child: _saving
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : Text('Save Record', style: GoogleFonts.baloo2(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white))),
                    ),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String hint, IconData icon, {int maxLines = 1}) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
          border: Border.all(color: FurPalsColors.blush, width: 1.5)),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(padding: const EdgeInsets.only(top: 10),
            child: Icon(icon, color: FurPalsColors.pink, size: 18)),
        const SizedBox(width: 10),
        Expanded(child: TextField(
          controller: ctrl, maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.nunito(color: FurPalsColors.textMid, fontSize: 13),
            border: InputBorder.none, isDense: true,
            contentPadding: const EdgeInsets.symmetric(vertical: 10),
          ),
          style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w700, color: FurPalsColors.textDark),
        )),
      ]),
    );
  }
}

// ─── Detail / edit sheet ──────────────────────────────────────────────────────
class _RecordDetailSheet extends StatefulWidget {
  final String docId;
  final Map<String, dynamic> data;
  final MedicalCategory category;
  final CollectionReference colRef;

  const _RecordDetailSheet({required this.docId, required this.data, required this.category, required this.colRef});

  @override
  State<_RecordDetailSheet> createState() => _RecordDetailSheetState();
}

class _RecordDetailSheetState extends State<_RecordDetailSheet> {
  late TextEditingController _titleCtrl;
  late TextEditingController _vetCtrl;
  late TextEditingController _clinicCtrl;
  late TextEditingController _notesCtrl;
  DateTime? _date;
  bool _saving = false, _deleting = false, _editing = false;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.data['title'] ?? '');
    _vetCtrl   = TextEditingController(text: widget.data['vet'] ?? '');
    _clinicCtrl = TextEditingController(text: widget.data['clinic'] ?? '');
    _notesCtrl = TextEditingController(text: widget.data['notes'] ?? '');
    final ds = widget.data['date'] as String?;
    if (ds != null && ds.isNotEmpty) _date = DateTime.tryParse(ds);
  }

  @override
  void dispose() {
    _titleCtrl.dispose(); _vetCtrl.dispose(); _clinicCtrl.dispose(); _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(context: context, initialDate: _date ?? now,
        firstDate: DateTime(now.year - 20), lastDate: now,
        builder: (ctx, child) => Theme(
            data: Theme.of(ctx).copyWith(colorScheme: ColorScheme.light(primary: widget.category.color)),
            child: child!));
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await widget.colRef.doc(widget.docId).update({
      'title': _titleCtrl.text.trim(),
      'vet': _vetCtrl.text.trim(),
      'clinic': _clinicCtrl.text.trim(),
      'notes': _notesCtrl.text.trim(),
      'date': _date != null ? '${_date!.year}-${_date!.month.toString().padLeft(2,'0')}-${_date!.day.toString().padLeft(2,'0')}' : '',
    });
    if (mounted) { setState(() { _saving = false; _editing = false; }); }
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Delete Record?', style: GoogleFonts.baloo2(fontWeight: FontWeight.w800, color: FurPalsColors.textDark)),
          content: Text('This action cannot be undone.', style: GoogleFonts.nunito(fontSize: 13, color: FurPalsColors.textMid)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false),
                child: Text('Cancel', style: GoogleFonts.nunito(color: FurPalsColors.textMid, fontWeight: FontWeight.w700))),
            TextButton(onPressed: () => Navigator.pop(context, true),
                child: Text('Delete', style: GoogleFonts.nunito(color: FurPalsColors.heartRed, fontWeight: FontWeight.w800))),
          ],
        ));
    if (ok != true) return;
    setState(() => _deleting = true);
    await widget.colRef.doc(widget.docId).delete();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final cat = widget.category;
    final dateStr = _date != null
        ? '${_date!.year}-${_date!.month.toString().padLeft(2,'0')}-${_date!.day.toString().padLeft(2,'0')}'
        : '';

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(color: FurPalsColors.warmWhite, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.88),
        child: Column(children: [
          Padding(padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Column(children: [
              Container(width: 40, height: 4,
                  decoration: BoxDecoration(color: FurPalsColors.blush, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 14),
              Row(children: [
                Container(width: 36, height: 36,
                    decoration: BoxDecoration(color: cat.bgColor, borderRadius: BorderRadius.circular(10)),
                    child: Icon(cat.icon, size: 18, color: cat.color)),
                const SizedBox(width: 10),
                Expanded(child: Text(cat.label,
                    style: GoogleFonts.baloo2(fontSize: 18, fontWeight: FontWeight.w800, color: FurPalsColors.textDark))),
                IconButton(
                  icon: Icon(_editing ? Icons.close_rounded : Icons.edit_rounded, color: cat.color),
                  onPressed: () => setState(() => _editing = !_editing),
                ),
              ]),
            ]),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              child: _editing ? _editForm(cat, dateStr) : _viewForm(cat, dateStr),
            ),
          ),
          if (_editing) Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            child: Row(children: [
              Expanded(child: GestureDetector(
                onTap: _deleting ? null : _delete,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: FurPalsColors.heartRed, width: 1.5)),
                  child: Center(child: _deleting
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: FurPalsColors.heartRed))
                      : Text('Delete', style: GoogleFonts.baloo2(fontSize: 14, fontWeight: FontWeight.w800, color: FurPalsColors.heartRed))),
                ),
              )),
              const SizedBox(width: 10),
              Expanded(child: GestureDetector(
                onTap: _saving ? null : _save,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  decoration: BoxDecoration(color: cat.color, borderRadius: BorderRadius.circular(14)),
                  child: Center(child: _saving
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text('Save', style: GoogleFonts.baloo2(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white))),
                ),
              )),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _viewForm(MedicalCategory cat, String dateStr) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _viewRow('Title', _titleCtrl.text, Icons.label_rounded, cat),
      if (dateStr.isNotEmpty) _viewRow('Date', dateStr, Icons.calendar_today_rounded, cat),
      if (_vetCtrl.text.isNotEmpty) _viewRow('Veterinarian', _vetCtrl.text, Icons.person_outlined, cat),
      if (_clinicCtrl.text.isNotEmpty) _viewRow('Clinic', _clinicCtrl.text, Icons.local_hospital_outlined, cat),
      if (_notesCtrl.text.isNotEmpty) ...[
        const SizedBox(height: 8),
        Text('NOTES', style: GoogleFonts.nunito(fontSize: 10, fontWeight: FontWeight.w800, color: FurPalsColors.textMid, letterSpacing: 0.4)),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFF0E4DC), width: 1.5)),
          child: Text(_notesCtrl.text, style: GoogleFonts.nunito(fontSize: 13, color: FurPalsColors.textDark)),
        ),
      ],
    ]);
  }

  Widget _viewRow(String label, String value, IconData icon, MedicalCategory cat) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(children: [
        Container(width: 36, height: 36,
            decoration: BoxDecoration(color: cat.bgColor, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, size: 16, color: cat.color)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: GoogleFonts.nunito(fontSize: 10, fontWeight: FontWeight.w700, color: FurPalsColors.textMid)),
          Text(value, style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w700, color: FurPalsColors.textDark)),
        ])),
      ]),
    );
  }

  Widget _editForm(MedicalCategory cat, String dateStr) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _field(_titleCtrl, 'Title *', Icons.label_rounded),
      const SizedBox(height: 10),
      GestureDetector(
        onTap: _pickDate,
        child: Container(
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
              border: Border.all(color: FurPalsColors.blush, width: 1.5)),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(children: [
            Icon(Icons.calendar_today_rounded, color: cat.color, size: 18),
            const SizedBox(width: 10),
            Text(dateStr.isNotEmpty ? dateStr : 'Date (tap to pick)',
                style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w700,
                    color: dateStr.isNotEmpty ? FurPalsColors.textDark : FurPalsColors.textMid)),
          ]),
        ),
      ),
      const SizedBox(height: 10),
      _field(_vetCtrl, 'Veterinarian', Icons.person_outlined),
      const SizedBox(height: 10),
      _field(_clinicCtrl, 'Clinic / Hospital', Icons.local_hospital_outlined),
      const SizedBox(height: 10),
      _field(_notesCtrl, 'Notes / Details', Icons.notes_rounded, maxLines: 4),
    ]);
  }

  Widget _field(TextEditingController ctrl, String hint, IconData icon, {int maxLines = 1}) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
          border: Border.all(color: FurPalsColors.blush, width: 1.5)),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(padding: const EdgeInsets.only(top: 10),
            child: Icon(icon, color: FurPalsColors.pink, size: 18)),
        const SizedBox(width: 10),
        Expanded(child: TextField(
          controller: ctrl, maxLines: maxLines,
          decoration: InputDecoration(hintText: hint,
              hintStyle: GoogleFonts.nunito(color: FurPalsColors.textMid, fontSize: 13),
              border: InputBorder.none, isDense: true, contentPadding: const EdgeInsets.symmetric(vertical: 10)),
          style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w700, color: FurPalsColors.textDark),
        )),
      ]),
    );
  }
}