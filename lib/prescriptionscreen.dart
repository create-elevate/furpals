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

// ─── Prescription status ─────────────────────────────────────────────────────
enum RxStatus { active, completed, discontinued }

extension RxStatusExt on RxStatus {
  String get label {
    switch (this) {
      case RxStatus.active:       return 'Active';
      case RxStatus.completed:    return 'Completed';
      case RxStatus.discontinued: return 'Discontinued';
    }
  }
  Color get color {
    switch (this) {
      case RxStatus.active:       return FurPalsColors.green;
      case RxStatus.completed:    return FurPalsColors.blue;
      case RxStatus.discontinued: return FurPalsColors.heartRed;
    }
  }
  Color get bgColor {
    switch (this) {
      case RxStatus.active:       return FurPalsColors.mint;
      case RxStatus.completed:    return const Color(0xFFE3EDFF);
      case RxStatus.discontinued: return const Color(0xFFFFE2E2);
    }
  }
  static RxStatus fromString(String? s) {
    switch (s) {
      case 'Active':       return RxStatus.active;
      case 'Completed':    return RxStatus.completed;
      case 'Discontinued': return RxStatus.discontinued;
      default:             return RxStatus.active;
    }
  }
}

// ─── Screen ─────────────────────────────────────────────────────────────────
class PrescriptionScreen extends StatefulWidget {
  final String currentUid;
  final String petId;
  final String petName;

  const PrescriptionScreen({
    super.key,
    required this.currentUid,
    required this.petId,
    required this.petName,
  });

  @override
  State<PrescriptionScreen> createState() => _PrescriptionScreenState();
}

class _PrescriptionScreenState extends State<PrescriptionScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  RxStatus? _filterStatus; // null = all

  CollectionReference get _col => FirebaseFirestore.instance
      .collection('users')
      .doc(widget.currentUid)
      .collection('pets')
      .doc(widget.petId)
      .collection('prescriptions');

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
      builder: (_) => _AddPrescriptionSheet(colRef: _col),
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
                _buildFilterChips(),
                Expanded(child: _buildList()),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddSheet,
        backgroundColor: FurPalsColors.purple,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text('Add Prescription', style: GoogleFonts.baloo2(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
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
            child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: FurPalsColors.textDark),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          ShaderMask(
            shaderCallback: (b) => const LinearGradient(colors: [FurPalsColors.purple, Color(0xFF6B4FC8)]).createShader(b),
            child: Text('Prescriptions', style: GoogleFonts.baloo2(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white)),
          ),
          Text(widget.petName, style: GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.w600, color: FurPalsColors.textMid)),
        ])),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: FurPalsColors.lavender,
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [BoxShadow(color: FurPalsColors.shadow, blurRadius: 8, offset: Offset(0, 2))],
          ),
          child: const Icon(Icons.receipt_long_rounded, size: 20, color: FurPalsColors.purple),
        ),
      ]),
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
        child: Row(children: [
          const Icon(Icons.search_rounded, color: FurPalsColors.textSoft, size: 22),
          const SizedBox(width: 8),
          Expanded(child: TextField(
            controller: _searchCtrl,
            decoration: InputDecoration(
              hintText: 'Search prescriptions...',
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

  Widget _buildFilterChips() {
    final all = [null, ...RxStatus.values];
    return SizedBox(
      height: 38,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: all.length,
        itemBuilder: (_, i) {
          final s = all[i];
          final selected = _filterStatus == s;
          final label = s == null ? 'All' : s.label;
          final color = s == null ? FurPalsColors.purple : s.color;
          return GestureDetector(
            onTap: () => setState(() => _filterStatus = s),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: selected ? color : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: selected ? color : const Color(0xFFF0E4DC), width: 1.5),
                boxShadow: selected ? [BoxShadow(color: color.withOpacity(0.3), blurRadius: 6, offset: const Offset(0, 2))] : null,
              ),
              child: Text(label, style: GoogleFonts.nunito(
                  fontSize: 12, fontWeight: FontWeight.w800,
                  color: selected ? Colors.white : FurPalsColors.textMid)),
            ),
          );
        },
      ),
    );
  }

  Widget _buildList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _col.orderBy('prescribedDate', descending: true).snapshots(),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: FurPalsColors.purple));
        }
        final docs = snap.data?.docs ?? [];

        // filter by status + search
        final filtered = docs.where((d) {
          final data = d.data() as Map<String, dynamic>;
          final status = RxStatusExt.fromString(data['status'] as String?);
          if (_filterStatus != null && status != _filterStatus) return false;
          if (_query.isNotEmpty) {
            final med = (data['medicationName'] as String? ?? '').toLowerCase();
            final cond = (data['condition'] as String? ?? '').toLowerCase();
            final vet  = (data['vet'] as String? ?? '').toLowerCase();
            return med.contains(_query) || cond.contains(_query) || vet.contains(_query);
          }
          return true;
        }).toList();

        if (filtered.isEmpty) {
          return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 80, height: 80,
              decoration: const BoxDecoration(color: FurPalsColors.lavender, shape: BoxShape.circle),
              child: const Icon(Icons.receipt_long_rounded, size: 36, color: FurPalsColors.purple)),
            const SizedBox(height: 16),
            Text('No prescriptions found',
                style: GoogleFonts.baloo2(fontSize: 16, fontWeight: FontWeight.w800, color: FurPalsColors.textDark)),
            const SizedBox(height: 6),
            Text('Tap the + button to add one',
                style: GoogleFonts.nunito(fontSize: 12, color: FurPalsColors.textMid)),
          ]));
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
          itemCount: filtered.length,
          itemBuilder: (_, i) {
            final data = filtered[i].data() as Map<String, dynamic>;
            return _PrescriptionCard(docId: filtered[i].id, data: data, colRef: _col);
          },
        );
      },
    );
  }
}

// ─── Prescription card ───────────────────────────────────────────────────────
class _PrescriptionCard extends StatelessWidget {
  final String docId;
  final Map<String, dynamic> data;
  final CollectionReference colRef;

  const _PrescriptionCard({required this.docId, required this.data, required this.colRef});

  void _showDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PrescriptionDetailSheet(docId: docId, data: data, colRef: colRef),
    );
  }

  @override
  Widget build(BuildContext context) {
    final med       = data['medicationName'] as String? ?? 'Medication';
    final dosage    = data['dosage'] as String? ?? '';
    final frequency = data['frequency'] as String? ?? '';
    final condition = data['condition'] as String? ?? '';
    final vet       = data['vet'] as String? ?? '';
    final startDate = data['prescribedDate'] as String? ?? '';
    final endDate   = data['endDate'] as String? ?? '';
    final status    = RxStatusExt.fromString(data['status'] as String?);
    final meds      = List<Map<String, dynamic>>.from(
      (data['medications'] as List?)?.map((e) => Map<String, dynamic>.from(e as Map)) ?? [],
    );

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
            // Header row
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(children: [
                Container(width: 48, height: 48,
                  decoration: BoxDecoration(color: status.bgColor, borderRadius: BorderRadius.circular(14)),
                  child: Icon(Icons.medication_rounded, size: 22, color: status.color)),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(med, style: GoogleFonts.baloo2(fontSize: 14, fontWeight: FontWeight.w800, color: FurPalsColors.textDark)),
                  if (condition.isNotEmpty)
                    Text(condition, style: GoogleFonts.nunito(fontSize: 11, color: FurPalsColors.textMid)),
                  if (dosage.isNotEmpty || frequency.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text('${dosage.isNotEmpty ? dosage : ''}${dosage.isNotEmpty && frequency.isNotEmpty ? ' · ' : ''}${frequency.isNotEmpty ? frequency : ''}',
                        style: GoogleFonts.nunito(fontSize: 11, fontWeight: FontWeight.w600, color: FurPalsColors.purple)),
                  ],
                ])),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: status.bgColor, borderRadius: BorderRadius.circular(20)),
                  child: Text(status.label, style: GoogleFonts.nunito(fontSize: 10, fontWeight: FontWeight.w800, color: status.color)),
                ),
              ]),
            ),
            // Bottom meta
            if (vet.isNotEmpty || startDate.isNotEmpty || endDate.isNotEmpty)
              Container(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                child: Row(children: [
                  if (startDate.isNotEmpty) ...[
                    const Icon(Icons.calendar_today_rounded, size: 12, color: FurPalsColors.textMid),
                    const SizedBox(width: 4),
                    Text(startDate, style: GoogleFonts.nunito(fontSize: 11, color: FurPalsColors.textMid)),
                    if (endDate.isNotEmpty) Text(' → $endDate', style: GoogleFonts.nunito(fontSize: 11, color: FurPalsColors.textMid)),
                  ],
                  const Spacer(),
                  if (vet.isNotEmpty) ...[
                    const Icon(Icons.person_outlined, size: 12, color: FurPalsColors.textMid),
                    const SizedBox(width: 4),
                    Flexible(child: Text(vet, style: GoogleFonts.nunito(fontSize: 11, color: FurPalsColors.textMid), overflow: TextOverflow.ellipsis)),
                  ],
                ]),
              ),
            // Medication list badges
            if (meds.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                child: Wrap(
                  spacing: 6, runSpacing: 6,
                  children: meds.map((m) {
                    final name = m['name'] as String? ?? '';
                    final dose = m['dosage'] as String? ?? '';
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: FurPalsColors.lavender, borderRadius: BorderRadius.circular(20)),
                      child: Text('$name${dose.isNotEmpty ? ' – $dose' : ''}',
                          style: GoogleFonts.nunito(fontSize: 10, fontWeight: FontWeight.w700, color: FurPalsColors.purple)),
                    );
                  }).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Add prescription sheet ───────────────────────────────────────────────────
class _AddPrescriptionSheet extends StatefulWidget {
  final CollectionReference colRef;
  const _AddPrescriptionSheet({required this.colRef});

  @override
  State<_AddPrescriptionSheet> createState() => _AddPrescriptionSheetState();
}

class _AddPrescriptionSheetState extends State<_AddPrescriptionSheet> {
  final _medNameCtrl  = TextEditingController();
  final _dosageCtrl   = TextEditingController();
  final _freqCtrl     = TextEditingController();
  final _condCtrl     = TextEditingController();
  final _vetCtrl      = TextEditingController();
  final _clinicCtrl   = TextEditingController();
  final _instrCtrl    = TextEditingController();
  final _notesCtrl    = TextEditingController();
  final _refillCtrl   = TextEditingController();

  // Additional meds
  final _addMedNameCtrl   = TextEditingController();
  final _addMedDosageCtrl = TextEditingController();
  List<Map<String, String>> _additionalMeds = [];

  DateTime? _startDate;
  DateTime? _endDate;
  String _status = 'Active';
  bool _saving = false;

  String _fmt(DateTime? d) => d == null ? '' : '${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';

  Future<void> _pick(bool isStart) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? (_startDate ?? now) : (_endDate ?? now),
      firstDate: DateTime(now.year - 10),
      lastDate: DateTime(now.year + 10),
      builder: (ctx, child) => Theme(data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: FurPalsColors.purple)), child: child!),
    );
    if (picked != null) setState(() => isStart ? _startDate = picked : _endDate = picked);
  }

  void _addMed() {
    final name = _addMedNameCtrl.text.trim();
    if (name.isEmpty) return;
    setState(() {
      _additionalMeds.add({'name': name, 'dosage': _addMedDosageCtrl.text.trim()});
      _addMedNameCtrl.clear();
      _addMedDosageCtrl.clear();
    });
  }

  Future<void> _save() async {
    if (_medNameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Please enter a medication name', style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
        backgroundColor: FurPalsColors.heartRed,
      ));
      return;
    }
    setState(() => _saving = true);
    try {
      await widget.colRef.add({
        'medicationName': _medNameCtrl.text.trim(),
        'dosage': _dosageCtrl.text.trim(),
        'frequency': _freqCtrl.text.trim(),
        'condition': _condCtrl.text.trim(),
        'vet': _vetCtrl.text.trim(),
        'clinic': _clinicCtrl.text.trim(),
        'instructions': _instrCtrl.text.trim(),
        'notes': _notesCtrl.text.trim(),
        'refills': _refillCtrl.text.trim(),
        'medications': _additionalMeds,
        'prescribedDate': _fmt(_startDate),
        'endDate': _fmt(_endDate),
        'status': _status,
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (mounted) Navigator.pop(context);
    } catch (e) { debugPrint('Save prescription error: $e'); }
    if (mounted) setState(() => _saving = false);
  }

  @override
  void dispose() {
    _medNameCtrl.dispose(); _dosageCtrl.dispose(); _freqCtrl.dispose();
    _condCtrl.dispose(); _vetCtrl.dispose(); _clinicCtrl.dispose();
    _instrCtrl.dispose(); _notesCtrl.dispose(); _refillCtrl.dispose();
    _addMedNameCtrl.dispose(); _addMedDosageCtrl.dispose();
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
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.95),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Padding(padding: const EdgeInsets.fromLTRB(20, 16, 20, 0), child: Column(children: [
            Container(width: 40, height: 4,
                decoration: BoxDecoration(color: FurPalsColors.blush, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 14),
            Row(children: [
              Container(width: 36, height: 36,
                  decoration: BoxDecoration(color: FurPalsColors.lavender, borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.receipt_long_rounded, size: 18, color: FurPalsColors.purple)),
              const SizedBox(width: 10),
              Text('Add Prescription', style: GoogleFonts.baloo2(fontSize: 18, fontWeight: FontWeight.w800, color: FurPalsColors.textDark)),
            ]),
            const SizedBox(height: 8),
          ])),
          Expanded(child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

              _sectionLabel('Medication', Icons.medication_rounded, FurPalsColors.purple, FurPalsColors.lavender),
              const SizedBox(height: 10),
              _field(_medNameCtrl, 'Medication Name *', Icons.label_rounded),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(child: _field(_dosageCtrl, 'Dosage (e.g. 5mg)', Icons.compress_rounded)),
                const SizedBox(width: 10),
                Expanded(child: _field(_freqCtrl, 'Frequency', Icons.schedule_rounded)),
              ]),
              const SizedBox(height: 10),
              _field(_refillCtrl, 'Refills', Icons.refresh_rounded),
              const SizedBox(height: 10),
              _field(_condCtrl, 'Condition / Diagnosis', Icons.healing_rounded),
              const SizedBox(height: 10),
              _field(_instrCtrl, 'Instructions', Icons.info_outlined, maxLines: 3),

              const SizedBox(height: 16),
              _sectionLabel('Additional Medications', Icons.add_box_rounded, FurPalsColors.blue, const Color(0xFFE3EDFF)),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(child: _field(_addMedNameCtrl, 'Medication name', Icons.medication_outlined)),
                const SizedBox(width: 6),
                SizedBox(width: 100, child: _field(_addMedDosageCtrl, 'Dosage', Icons.compress_rounded)),
                const SizedBox(width: 6),
                GestureDetector(onTap: _addMed,
                  child: Container(height: 48, width: 48,
                    decoration: BoxDecoration(color: FurPalsColors.purple, borderRadius: BorderRadius.circular(14)),
                    child: const Icon(Icons.add_rounded, color: Colors.white, size: 22))),
              ]),
              if (_additionalMeds.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(spacing: 8, runSpacing: 8,
                  children: _additionalMeds.map((m) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: FurPalsColors.lavender, borderRadius: BorderRadius.circular(20)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Text('${m['name']}${(m['dosage'] ?? '').isNotEmpty ? ' – ${m['dosage']}' : ''}',
                          style: GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.w700, color: FurPalsColors.purple)),
                      const SizedBox(width: 6),
                      GestureDetector(onTap: () => setState(() => _additionalMeds.remove(m)),
                          child: const Icon(Icons.close_rounded, size: 14, color: FurPalsColors.purple)),
                    ]),
                  )).toList()),
              ],

              const SizedBox(height: 16),
              _sectionLabel('Dates & Status', Icons.calendar_today_rounded, const Color(0xFFE9963A), FurPalsColors.butter),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(child: _datePicker('Start Date', _startDate, () => _pick(true), FurPalsColors.purple)),
                const SizedBox(width: 10),
                Expanded(child: _datePicker('End Date', _endDate, () => _pick(false), const Color(0xFFE9963A))),
              ]),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: FurPalsColors.blush, width: 1.5)),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                child: Row(children: [
                  const Icon(Icons.flag_rounded, color: FurPalsColors.pink, size: 18),
                  const SizedBox(width: 10),
                  Expanded(child: DropdownButtonHideUnderline(child: DropdownButton<String>(
                    value: _status, isDense: true,
                    style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w700, color: FurPalsColors.textDark),
                    items: ['Active', 'Completed', 'Discontinued'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                    onChanged: (v) => setState(() => _status = v!),
                  ))),
                ]),
              ),

              const SizedBox(height: 16),
              _sectionLabel('Veterinarian', Icons.person_outlined, FurPalsColors.green, FurPalsColors.mint),
              const SizedBox(height: 10),
              _field(_vetCtrl, 'Veterinarian Name', Icons.person_outlined),
              const SizedBox(height: 10),
              _field(_clinicCtrl, 'Clinic / Hospital', Icons.local_hospital_outlined),
              const SizedBox(height: 10),
              _field(_notesCtrl, 'Additional Notes', Icons.notes_rounded, maxLines: 3),

              const SizedBox(height: 24),
              GestureDetector(
                onTap: _saving ? null : _save,
                child: Container(
                  width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 15),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16), color: FurPalsColors.purple,
                    boxShadow: [BoxShadow(color: FurPalsColors.purple.withOpacity(0.4), blurRadius: 14, offset: const Offset(0, 6))],
                  ),
                  child: Center(child: _saving
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text('Save Prescription', style: GoogleFonts.baloo2(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white))),
                ),
              ),
            ]),
          )),
        ]),
      ),
    );
  }

  Widget _sectionLabel(String text, IconData icon, Color color, Color bg) {
    return Row(children: [
      Container(width: 28, height: 28, decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, size: 14, color: color)),
      const SizedBox(width: 8),
      Text(text, style: GoogleFonts.baloo2(fontSize: 13, fontWeight: FontWeight.w800, color: FurPalsColors.textDark)),
    ]);
  }

  Widget _datePicker(String label, DateTime? val, VoidCallback onTap, Color color) {
    final str = _fmt(val);
    return GestureDetector(onTap: onTap,
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
        Padding(padding: const EdgeInsets.only(top: 10), child: Icon(icon, color: FurPalsColors.pink, size: 18)),
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

// ─── Prescription detail sheet ────────────────────────────────────────────────
class _PrescriptionDetailSheet extends StatefulWidget {
  final String docId;
  final Map<String, dynamic> data;
  final CollectionReference colRef;

  const _PrescriptionDetailSheet({required this.docId, required this.data, required this.colRef});

  @override
  State<_PrescriptionDetailSheet> createState() => _PrescriptionDetailSheetState();
}

class _PrescriptionDetailSheetState extends State<_PrescriptionDetailSheet> {
  late Map<String, dynamic> _data;
  bool _deleting = false;

  @override
  void initState() {
    super.initState();
    _data = Map<String, dynamic>.from(widget.data);
  }

  Future<void> _changeStatus(String newStatus) async {
    await widget.colRef.doc(widget.docId).update({'status': newStatus});
    setState(() => _data['status'] = newStatus);
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Delete Prescription?', style: GoogleFonts.baloo2(fontWeight: FontWeight.w800, color: FurPalsColors.textDark)),
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
    final med       = _data['medicationName'] as String? ?? 'Medication';
    final dosage    = _data['dosage'] as String? ?? '';
    final freq      = _data['frequency'] as String? ?? '';
    final cond      = _data['condition'] as String? ?? '';
    final vet       = _data['vet'] as String? ?? '';
    final clinic    = _data['clinic'] as String? ?? '';
    final instr     = _data['instructions'] as String? ?? '';
    final notes     = _data['notes'] as String? ?? '';
    final refills   = _data['refills'] as String? ?? '';
    final start     = _data['prescribedDate'] as String? ?? '';
    final end       = _data['endDate'] as String? ?? '';
    final status    = RxStatusExt.fromString(_data['status'] as String?);
    final meds      = List<Map<String, dynamic>>.from(
      (_data['medications'] as List?)?.map((e) => Map<String, dynamic>.from(e as Map)) ?? [],
    );

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
                  decoration: BoxDecoration(color: status.bgColor, borderRadius: BorderRadius.circular(10)),
                  child: Icon(Icons.receipt_long_rounded, size: 18, color: status.color)),
              const SizedBox(width: 10),
              Expanded(child: Text(med,
                  style: GoogleFonts.baloo2(fontSize: 18, fontWeight: FontWeight.w800, color: FurPalsColors.textDark))),
              // Quick status toggle
              PopupMenuButton<String>(
                icon: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: status.bgColor, borderRadius: BorderRadius.circular(20)),
                  child: Text(status.label, style: GoogleFonts.nunito(fontSize: 10, fontWeight: FontWeight.w800, color: status.color)),
                ),
                onSelected: _changeStatus,
                itemBuilder: (_) => ['Active', 'Completed', 'Discontinued']
                    .map((s) => PopupMenuItem(value: s, child: Text(s, style: GoogleFonts.nunito(fontWeight: FontWeight.w700))))
                    .toList(),
              ),
            ]),
          ])),
          Expanded(child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (cond.isNotEmpty) _viewRow('Condition', cond, Icons.healing_rounded, FurPalsColors.purple, FurPalsColors.lavender),
              if (dosage.isNotEmpty) _viewRow('Dosage', dosage, Icons.compress_rounded, FurPalsColors.purple, FurPalsColors.lavender),
              if (freq.isNotEmpty) _viewRow('Frequency', freq, Icons.schedule_rounded, FurPalsColors.purple, FurPalsColors.lavender),
              if (refills.isNotEmpty) _viewRow('Refills', refills, Icons.refresh_rounded, FurPalsColors.purple, FurPalsColors.lavender),
              if (start.isNotEmpty) _viewRow('Start Date', start, Icons.calendar_today_rounded, const Color(0xFFE9963A), FurPalsColors.butter),
              if (end.isNotEmpty) _viewRow('End Date', end, Icons.event_rounded, const Color(0xFFE9963A), FurPalsColors.butter),
              if (vet.isNotEmpty) _viewRow('Veterinarian', vet, Icons.person_outlined, FurPalsColors.green, FurPalsColors.mint),
              if (clinic.isNotEmpty) _viewRow('Clinic', clinic, Icons.local_hospital_outlined, FurPalsColors.green, FurPalsColors.mint),
              if (meds.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text('ADDITIONAL MEDICATIONS', style: GoogleFonts.nunito(fontSize: 10, fontWeight: FontWeight.w800, color: FurPalsColors.textMid, letterSpacing: 0.4)),
                const SizedBox(height: 8),
                ...meds.map((m) => Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: FurPalsColors.lavender, width: 1.5)),
                  child: Row(children: [
                    const Icon(Icons.medication_outlined, size: 16, color: FurPalsColors.purple),
                    const SizedBox(width: 10),
                    Expanded(child: Text(m['name'] as String? ?? '', style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w700, color: FurPalsColors.textDark))),
                    if ((m['dosage'] as String? ?? '').isNotEmpty)
                      Text(m['dosage'] as String, style: GoogleFonts.nunito(fontSize: 12, color: FurPalsColors.textMid)),
                  ]),
                )),
              ],
              if (instr.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text('INSTRUCTIONS', style: GoogleFonts.nunito(fontSize: 10, fontWeight: FontWeight.w800, color: FurPalsColors.textMid, letterSpacing: 0.4)),
                const SizedBox(height: 8),
                Container(width: double.infinity, padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFF0E4DC), width: 1.5)),
                  child: Text(instr, style: GoogleFonts.nunito(fontSize: 13, color: FurPalsColors.textDark))),
              ],
              if (notes.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text('NOTES', style: GoogleFonts.nunito(fontSize: 10, fontWeight: FontWeight.w800, color: FurPalsColors.textMid, letterSpacing: 0.4)),
                const SizedBox(height: 8),
                Container(width: double.infinity, padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFF0E4DC), width: 1.5)),
                  child: Text(notes, style: GoogleFonts.nunito(fontSize: 13, color: FurPalsColors.textDark))),
              ],
              const SizedBox(height: 20),
              GestureDetector(onTap: _deleting ? null : _delete,
                child: Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 13),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: FurPalsColors.heartRed, width: 1.5)),
                  child: Center(child: _deleting
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: FurPalsColors.heartRed))
                      : Text('Delete Prescription', style: GoogleFonts.baloo2(fontSize: 14, fontWeight: FontWeight.w800, color: FurPalsColors.heartRed))),
                ),
              ),
            ]),
          )),
        ]),
      ),
    );
  }

  Widget _viewRow(String label, String value, IconData icon, Color color, Color bg) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(children: [
        Container(width: 36, height: 36, decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, size: 16, color: color)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: GoogleFonts.nunito(fontSize: 10, fontWeight: FontWeight.w700, color: FurPalsColors.textMid)),
          Text(value, style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w700, color: FurPalsColors.textDark)),
        ])),
      ]),
    );
  }
}