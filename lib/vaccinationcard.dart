import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// ─── FurPals design tokens ───────────────────────────────────────────────────
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

// ─── Screen ─────────────────────────────────────────────────────────────────
class VaccinationCardScreen extends StatefulWidget {
  final String currentUid;
  final String petId;
  final String petName;

  const VaccinationCardScreen({
    super.key,
    required this.currentUid,
    required this.petId,
    required this.petName,
  });

  @override
  State<VaccinationCardScreen> createState() => _VaccinationCardScreenState();
}

class _VaccinationCardScreenState extends State<VaccinationCardScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  CollectionReference get _col => FirebaseFirestore.instance
      .collection('users')
      .doc(widget.currentUid)
      .collection('pets')
      .doc(widget.petId)
      .collection('vaccinations');

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() => setState(() => _query = _searchCtrl.text.trim().toLowerCase()));
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _showAddSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddVaccineSheet(colRef: _col),
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
                Expanded(child: _buildList()),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddSheet,
        backgroundColor: FurPalsColors.green,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text('Add Vaccine', style: GoogleFonts.baloo2(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
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
                      colors: [FurPalsColors.green, Color(0xFF3DA864)]).createShader(b),
                  child: Text('Vaccination Card',
                      style: GoogleFonts.baloo2(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white)),
                ),
                Text(widget.petName,
                    style: GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.w600, color: FurPalsColors.textMid)),
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
            child: const Icon(Icons.vaccines_rounded, size: 20, color: FurPalsColors.green),
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
          boxShadow: const [BoxShadow(color: FurPalsColors.shadow, blurRadius: 4, offset: Offset(0, 3))],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        child: Row(children: [
          const Icon(Icons.search_rounded, color: FurPalsColors.textSoft, size: 22),
          const SizedBox(width: 8),
          Expanded(child: TextField(
            controller: _searchCtrl,
            decoration: InputDecoration(
              hintText: 'Search vaccines...',
              hintStyle: GoogleFonts.nunito(color: FurPalsColors.textSoft, fontSize: 13, fontWeight: FontWeight.w500),
              border: InputBorder.none, isDense: true, contentPadding: const EdgeInsets.symmetric(vertical: 10),
            ),
            style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w700, color: FurPalsColors.textDark),
          )),
          if (_query.isNotEmpty)
            GestureDetector(
              onTap: () { _searchCtrl.clear(); setState(() => _query = ''); },
              child: const Icon(Icons.close_rounded, color: FurPalsColors.textMid, size: 18),
            ),
        ]),
      ),
    );
  }

  Widget _buildList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _col.orderBy('dateGiven', descending: true).snapshots(),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: FurPalsColors.green));
        }
        final docs = snap.data?.docs ?? [];
        final filtered = _query.isEmpty
            ? docs
            : docs.where((d) {
                final data = d.data() as Map<String, dynamic>;
                return (data['vaccineName'] as String? ?? '').toLowerCase().contains(_query) ||
                    (data['brand'] as String? ?? '').toLowerCase().contains(_query) ||
                    (data['vet'] as String? ?? '').toLowerCase().contains(_query);
              }).toList();

        if (filtered.isEmpty) {
          return Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                width: 80, height: 80,
                decoration: const BoxDecoration(color: FurPalsColors.mint, shape: BoxShape.circle),
                child: const Icon(Icons.vaccines_rounded, size: 36, color: FurPalsColors.green),
              ),
              const SizedBox(height: 16),
              Text('No vaccine records yet',
                  style: GoogleFonts.baloo2(fontSize: 16, fontWeight: FontWeight.w800, color: FurPalsColors.textDark)),
              const SizedBox(height: 6),
              Text('Tap the + button to add a vaccine',
                  style: GoogleFonts.nunito(fontSize: 12, color: FurPalsColors.textMid)),
            ]),
          );
        }

        return Column(
          children: [
            // Summary header
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [FurPalsColors.green, Color(0xFF3DA864)]),
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [BoxShadow(color: FurPalsColors.shadow, blurRadius: 8, offset: Offset(0, 3))],
              ),
              child: Row(children: [
                const Icon(Icons.verified_rounded, color: Colors.white, size: 24),
                const SizedBox(width: 10),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('${docs.length} Vaccine${docs.length == 1 ? '' : 's'} on Record',
                      style: GoogleFonts.baloo2(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white)),
                  Text("${widget.petName}'s vaccination history",
                      style: GoogleFonts.nunito(fontSize: 11, color: Colors.white.withOpacity(0.85))),
                ])),
              ]),
            ),

            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                itemCount: filtered.length,
                itemBuilder: (_, i) {
                  final data = filtered[i].data() as Map<String, dynamic>;
                  return _VaccineCard(docId: filtered[i].id, data: data, colRef: _col);
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

// ─── Vaccine card ─────────────────────────────────────────────────────────────
class _VaccineCard extends StatelessWidget {
  final String docId;
  final Map<String, dynamic> data;
  final CollectionReference colRef;

  const _VaccineCard({required this.docId, required this.data, required this.colRef});

  void _showDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _VaccineDetailSheet(docId: docId, data: data, colRef: colRef),
    );
  }

  Color get _statusColor {
    final due = data['nextDueDate'] as String?;
    if (due == null || due.isEmpty) return FurPalsColors.green;
    final dueDate = DateTime.tryParse(due);
    if (dueDate == null) return FurPalsColors.green;
    final now = DateTime.now();
    if (dueDate.isBefore(now)) return FurPalsColors.heartRed;
    if (dueDate.difference(now).inDays <= 30) return const Color(0xFFE9963A);
    return FurPalsColors.green;
  }

  String get _statusLabel {
    final due = data['nextDueDate'] as String?;
    if (due == null || due.isEmpty) return 'Up to date';
    final dueDate = DateTime.tryParse(due);
    if (dueDate == null) return 'Up to date';
    final now = DateTime.now();
    if (dueDate.isBefore(now)) return 'Overdue';
    if (dueDate.difference(now).inDays <= 30) return 'Due soon';
    return 'Up to date';
  }

  @override
  Widget build(BuildContext context) {
    final name    = data['vaccineName'] as String? ?? 'Vaccine';
    final brand   = data['brand'] as String? ?? '';
    final given   = data['dateGiven'] as String? ?? '';
    final nextDue = data['nextDueDate'] as String? ?? '';
    final vet     = data['vet'] as String? ?? '';
    final lot     = data['lotNumber'] as String? ?? '';

    final sc = _statusColor;
    final sl = _statusLabel;

    return GestureDetector(
      onTap: () => _showDetail(context),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [BoxShadow(color: FurPalsColors.shadow, blurRadius: 10, offset: Offset(0, 3))],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 48, height: 48,
                    decoration: BoxDecoration(
                      color: sc.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(Icons.vaccines_rounded, size: 22, color: sc),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(name, style: GoogleFonts.baloo2(fontSize: 14, fontWeight: FontWeight.w800, color: FurPalsColors.textDark)),
                      if (brand.isNotEmpty)
                        Text(brand, style: GoogleFonts.nunito(fontSize: 11, color: FurPalsColors.textMid)),
                      if (given.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text('Given: $given', style: GoogleFonts.nunito(fontSize: 11, fontWeight: FontWeight.w600, color: FurPalsColors.green)),
                      ],
                    ]),
                  ),
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: sc.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(sl, style: GoogleFonts.nunito(fontSize: 10, fontWeight: FontWeight.w800, color: sc)),
                    ),
                    if (nextDue.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text('Due: $nextDue', style: GoogleFonts.nunito(fontSize: 10, color: FurPalsColors.textMid)),
                    ],
                  ]),
                ],
              ),
            ),
            if (vet.isNotEmpty || lot.isNotEmpty)
              Container(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                child: Row(children: [
                  if (vet.isNotEmpty) ...[
                    const Icon(Icons.person_outlined, size: 12, color: FurPalsColors.textMid),
                    const SizedBox(width: 4),
                    Expanded(child: Text(vet, style: GoogleFonts.nunito(fontSize: 11, color: FurPalsColors.textMid), overflow: TextOverflow.ellipsis)),
                  ],
                  if (lot.isNotEmpty)
                    Text('Lot: $lot', style: GoogleFonts.nunito(fontSize: 10, color: FurPalsColors.textMid)),
                ]),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Add vaccine sheet ───────────────────────────────────────────────────────
class _AddVaccineSheet extends StatefulWidget {
  final CollectionReference colRef;
  const _AddVaccineSheet({required this.colRef});

  @override
  State<_AddVaccineSheet> createState() => _AddVaccineSheetState();
}

class _AddVaccineSheetState extends State<_AddVaccineSheet> {
  final _nameCtrl   = TextEditingController();
  final _brandCtrl  = TextEditingController();
  final _vetCtrl    = TextEditingController();
  final _clinicCtrl = TextEditingController();
  final _lotCtrl    = TextEditingController();
  final _notesCtrl  = TextEditingController();
  DateTime? _dateGiven;
  DateTime? _nextDue;
  bool _saving = false;

  Future<void> _pick(bool isGiven) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: isGiven ? (_dateGiven ?? now) : (_nextDue ?? now),
      firstDate: isGiven ? DateTime(now.year - 20) : now.subtract(const Duration(days: 1)),
      lastDate: isGiven ? now : DateTime(now.year + 10),
      builder: (ctx, child) => Theme(data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: FurPalsColors.green)), child: child!),
    );
    if (picked != null) setState(() => isGiven ? _dateGiven = picked : _nextDue = picked);
  }

  String _fmt(DateTime? d) => d == null ? '' : '${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Please enter vaccine name', style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
        backgroundColor: FurPalsColors.heartRed,
      ));
      return;
    }
    setState(() => _saving = true);
    try {
      await widget.colRef.add({
        'vaccineName': _nameCtrl.text.trim(),
        'brand': _brandCtrl.text.trim(),
        'vet': _vetCtrl.text.trim(),
        'clinic': _clinicCtrl.text.trim(),
        'lotNumber': _lotCtrl.text.trim(),
        'notes': _notesCtrl.text.trim(),
        'dateGiven': _fmt(_dateGiven),
        'nextDueDate': _fmt(_nextDue),
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (mounted) Navigator.pop(context);
    } catch (e) { debugPrint('Save vaccine error: $e'); }
    if (mounted) setState(() => _saving = false);
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _brandCtrl.dispose(); _vetCtrl.dispose();
    _clinicCtrl.dispose(); _lotCtrl.dispose(); _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: FurPalsColors.warmWhite,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.92),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Padding(padding: const EdgeInsets.fromLTRB(20, 16, 20, 0), child: Column(children: [
            Container(width: 40, height: 4,
                decoration: BoxDecoration(color: FurPalsColors.blush, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 14),
            Row(children: [
              Container(width: 36, height: 36,
                  decoration: BoxDecoration(color: FurPalsColors.mint, borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.vaccines_rounded, size: 18, color: FurPalsColors.green)),
              const SizedBox(width: 10),
              Text('Add Vaccine Record', style: GoogleFonts.baloo2(fontSize: 18, fontWeight: FontWeight.w800, color: FurPalsColors.textDark)),
            ]),
            const SizedBox(height: 8),
          ])),
          Expanded(child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _field(_nameCtrl, 'Vaccine Name *', Icons.label_rounded),
              const SizedBox(height: 10),
              _field(_brandCtrl, 'Brand / Manufacturer', Icons.science_outlined),
              const SizedBox(height: 10),
              _field(_lotCtrl, 'Lot Number', Icons.numbers_rounded),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(child: _datePicker('Date Given', _dateGiven, () => _pick(true), FurPalsColors.green)),
                const SizedBox(width: 10),
                Expanded(child: _datePicker('Next Due Date', _nextDue, () => _pick(false), const Color(0xFFE9963A))),
              ]),
              const SizedBox(height: 10),
              _field(_vetCtrl, 'Veterinarian', Icons.person_outlined),
              const SizedBox(height: 10),
              _field(_clinicCtrl, 'Clinic / Hospital', Icons.local_hospital_outlined),
              const SizedBox(height: 10),
              _field(_notesCtrl, 'Notes', Icons.notes_rounded, maxLines: 3),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: _saving ? null : _save,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: FurPalsColors.green,
                    boxShadow: [BoxShadow(color: FurPalsColors.green.withOpacity(0.4), blurRadius: 14, offset: const Offset(0, 6))],
                  ),
                  child: Center(child: _saving
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text('Save Vaccine Record', style: GoogleFonts.baloo2(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white))),
                ),
              ),
            ]),
          )),
        ]),
      ),
    );
  }

  Widget _datePicker(String label, DateTime? val, VoidCallback onTap, Color color) {
    final str = _fmt(val);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
            border: Border.all(color: FurPalsColors.blush, width: 1.5)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: GoogleFonts.nunito(fontSize: 10, fontWeight: FontWeight.w700, color: FurPalsColors.textMid)),
          const SizedBox(height: 4),
          Row(children: [
            Icon(Icons.calendar_today_rounded, size: 14, color: color),
            const SizedBox(width: 6),
            Expanded(child: Text(str.isNotEmpty ? str : 'Tap to pick',
                style: GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.w700,
                    color: str.isNotEmpty ? FurPalsColors.textDark : FurPalsColors.textMid),
                overflow: TextOverflow.ellipsis)),
          ]),
        ]),
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
          decoration: InputDecoration(hintText: hint,
              hintStyle: GoogleFonts.nunito(color: FurPalsColors.textMid, fontSize: 13),
              border: InputBorder.none, isDense: true, contentPadding: const EdgeInsets.symmetric(vertical: 10)),
          style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w700, color: FurPalsColors.textDark),
        )),
      ]),
    );
  }
}

// ─── Vaccine detail sheet ─────────────────────────────────────────────────────
class _VaccineDetailSheet extends StatefulWidget {
  final String docId;
  final Map<String, dynamic> data;
  final CollectionReference colRef;

  const _VaccineDetailSheet({required this.docId, required this.data, required this.colRef});

  @override
  State<_VaccineDetailSheet> createState() => _VaccineDetailSheetState();
}

class _VaccineDetailSheetState extends State<_VaccineDetailSheet> {
  late TextEditingController _nameCtrl, _brandCtrl, _vetCtrl, _clinicCtrl, _lotCtrl, _notesCtrl;
  DateTime? _dateGiven, _nextDue;
  bool _saving = false, _deleting = false, _editing = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl   = TextEditingController(text: widget.data['vaccineName'] ?? '');
    _brandCtrl  = TextEditingController(text: widget.data['brand'] ?? '');
    _vetCtrl    = TextEditingController(text: widget.data['vet'] ?? '');
    _clinicCtrl = TextEditingController(text: widget.data['clinic'] ?? '');
    _lotCtrl    = TextEditingController(text: widget.data['lotNumber'] ?? '');
    _notesCtrl  = TextEditingController(text: widget.data['notes'] ?? '');
    final dg = widget.data['dateGiven'] as String?;
    final nd = widget.data['nextDueDate'] as String?;
    if (dg != null && dg.isNotEmpty) _dateGiven = DateTime.tryParse(dg);
    if (nd != null && nd.isNotEmpty) _nextDue = DateTime.tryParse(nd);
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _brandCtrl.dispose(); _vetCtrl.dispose();
    _clinicCtrl.dispose(); _lotCtrl.dispose(); _notesCtrl.dispose();
    super.dispose();
  }

  String _fmt(DateTime? d) => d == null ? '' : '${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';

  Future<void> _pick(bool isGiven) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: isGiven ? (_dateGiven ?? now) : (_nextDue ?? now),
      firstDate: isGiven ? DateTime(now.year - 20) : now.subtract(const Duration(days: 1)),
      lastDate: isGiven ? now : DateTime(now.year + 10),
      builder: (ctx, child) => Theme(data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: FurPalsColors.green)), child: child!),
    );
    if (picked != null) setState(() => isGiven ? _dateGiven = picked : _nextDue = picked);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await widget.colRef.doc(widget.docId).update({
      'vaccineName': _nameCtrl.text.trim(),
      'brand': _brandCtrl.text.trim(),
      'vet': _vetCtrl.text.trim(),
      'clinic': _clinicCtrl.text.trim(),
      'lotNumber': _lotCtrl.text.trim(),
      'notes': _notesCtrl.text.trim(),
      'dateGiven': _fmt(_dateGiven),
      'nextDueDate': _fmt(_nextDue),
    });
    if (mounted) setState(() { _saving = false; _editing = false; });
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Delete Vaccine Record?', style: GoogleFonts.baloo2(fontWeight: FontWeight.w800, color: FurPalsColors.textDark)),
          content: Text('This cannot be undone.', style: GoogleFonts.nunito(fontSize: 13, color: FurPalsColors.textMid)),
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
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(color: FurPalsColors.warmWhite, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.88),
        child: Column(children: [
          Padding(padding: const EdgeInsets.fromLTRB(20, 16, 20, 0), child: Column(children: [
            Container(width: 40, height: 4,
                decoration: BoxDecoration(color: FurPalsColors.blush, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 14),
            Row(children: [
              Container(width: 36, height: 36,
                  decoration: BoxDecoration(color: FurPalsColors.mint, borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.vaccines_rounded, size: 18, color: FurPalsColors.green)),
              const SizedBox(width: 10),
              Expanded(child: Text('Vaccine Record',
                  style: GoogleFonts.baloo2(fontSize: 18, fontWeight: FontWeight.w800, color: FurPalsColors.textDark))),
              IconButton(
                icon: Icon(_editing ? Icons.close_rounded : Icons.edit_rounded, color: FurPalsColors.green),
                onPressed: () => setState(() => _editing = !_editing),
              ),
            ]),
          ])),
          Expanded(child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            child: _editing ? _editForm() : _viewForm(),
          )),
          if (_editing) Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            child: Row(children: [
              Expanded(child: GestureDetector(
                onTap: _deleting ? null : _delete,
                child: Container(padding: const EdgeInsets.symmetric(vertical: 13),
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
                child: Container(padding: const EdgeInsets.symmetric(vertical: 13),
                  decoration: BoxDecoration(color: FurPalsColors.green, borderRadius: BorderRadius.circular(14)),
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

  Widget _viewForm() {
    final dgStr = _fmt(_dateGiven);
    final ndStr = _fmt(_nextDue);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _viewRow('Vaccine Name', _nameCtrl.text, Icons.label_rounded),
      if (_brandCtrl.text.isNotEmpty) _viewRow('Brand', _brandCtrl.text, Icons.science_outlined),
      if (_lotCtrl.text.isNotEmpty) _viewRow('Lot Number', _lotCtrl.text, Icons.numbers_rounded),
      if (dgStr.isNotEmpty) _viewRow('Date Given', dgStr, Icons.calendar_today_rounded),
      if (ndStr.isNotEmpty) _viewRow('Next Due Date', ndStr, Icons.event_rounded),
      if (_vetCtrl.text.isNotEmpty) _viewRow('Veterinarian', _vetCtrl.text, Icons.person_outlined),
      if (_clinicCtrl.text.isNotEmpty) _viewRow('Clinic', _clinicCtrl.text, Icons.local_hospital_outlined),
      if (_notesCtrl.text.isNotEmpty) ...[
        const SizedBox(height: 8),
        Text('NOTES', style: GoogleFonts.nunito(fontSize: 10, fontWeight: FontWeight.w800, color: FurPalsColors.textMid, letterSpacing: 0.4)),
        const SizedBox(height: 8),
        Container(width: double.infinity, padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFF0E4DC), width: 1.5)),
          child: Text(_notesCtrl.text, style: GoogleFonts.nunito(fontSize: 13, color: FurPalsColors.textDark))),
      ],
    ]);
  }

  Widget _viewRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(children: [
        Container(width: 36, height: 36,
            decoration: BoxDecoration(color: FurPalsColors.mint, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, size: 16, color: FurPalsColors.green)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: GoogleFonts.nunito(fontSize: 10, fontWeight: FontWeight.w700, color: FurPalsColors.textMid)),
          Text(value, style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w700, color: FurPalsColors.textDark)),
        ])),
      ]),
    );
  }

  Widget _editForm() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _field(_nameCtrl, 'Vaccine Name *', Icons.label_rounded),
      const SizedBox(height: 10),
      _field(_brandCtrl, 'Brand / Manufacturer', Icons.science_outlined),
      const SizedBox(height: 10),
      _field(_lotCtrl, 'Lot Number', Icons.numbers_rounded),
      const SizedBox(height: 10),
      Row(children: [
        Expanded(child: _datePicker('Date Given', _dateGiven, () => _pick(true), FurPalsColors.green)),
        const SizedBox(width: 10),
        Expanded(child: _datePicker('Next Due Date', _nextDue, () => _pick(false), const Color(0xFFE9963A))),
      ]),
      const SizedBox(height: 10),
      _field(_vetCtrl, 'Veterinarian', Icons.person_outlined),
      const SizedBox(height: 10),
      _field(_clinicCtrl, 'Clinic / Hospital', Icons.local_hospital_outlined),
      const SizedBox(height: 10),
      _field(_notesCtrl, 'Notes', Icons.notes_rounded, maxLines: 3),
    ]);
  }

  Widget _datePicker(String label, DateTime? val, VoidCallback onTap, Color color) {
    final str = _fmt(val);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
            border: Border.all(color: FurPalsColors.blush, width: 1.5)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: GoogleFonts.nunito(fontSize: 10, fontWeight: FontWeight.w700, color: FurPalsColors.textMid)),
          const SizedBox(height: 4),
          Row(children: [
            Icon(Icons.calendar_today_rounded, size: 14, color: color),
            const SizedBox(width: 6),
            Expanded(child: Text(str.isNotEmpty ? str : 'Tap to pick',
                style: GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.w700,
                    color: str.isNotEmpty ? FurPalsColors.textDark : FurPalsColors.textMid),
                overflow: TextOverflow.ellipsis)),
          ]),
        ]),
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
        Expanded(child: TextField(controller: ctrl, maxLines: maxLines,
          decoration: InputDecoration(hintText: hint,
              hintStyle: GoogleFonts.nunito(color: FurPalsColors.textMid, fontSize: 13),
              border: InputBorder.none, isDense: true, contentPadding: const EdgeInsets.symmetric(vertical: 10)),
          style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w700, color: FurPalsColors.textDark),
        )),
      ]),
    );
  }
}