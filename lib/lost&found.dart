import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:furpals/Homescreen.dart'; // FurPalsColors
import 'package:furpals/lostfoundprofile.dart';
import 'package:furpals/lf_add_missing.dart';

// LOST & FOUND SCREEN 
class LostFoundScreen extends StatefulWidget {
  const LostFoundScreen({super.key});

  @override
  State<LostFoundScreen> createState() => _LostFoundScreenState();
}

class _LostFoundScreenState extends State<LostFoundScreen> {
  String _selectedFilter = 'DOG';
  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, dynamic>> _filters = [
    {'label': 'DOG',  'asset': 'assets/icons/dog_filter.png'},
    {'label': 'CAT',  'asset': 'assets/icons/cat_filter.png'},
    {'label': 'BIRD', 'asset': 'assets/icons/bird_filter.png'},
  ];

  final List<Map<String, dynamic>> _pets = [
    {'name': 'Pet Name', 'breed': 'pet breed', 'age': 'Age', 'gender': 'Gender', 'liked': false, 'image': null},
    {'name': 'Pet Name', 'breed': 'pet breed', 'age': 'Age', 'gender': 'Gender', 'liked': false, 'image': null},
    {'name': 'Pet Name', 'breed': 'pet breed', 'age': 'Age', 'gender': 'Gender', 'liked': false, 'image': null},
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // NO Scaffold, NO bottomNavigationBar — MainShell handles those
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: appBackgroundGradient),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildTopBar(context),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 18),
                    _buildTitle(),
                    const SizedBox(height: 6),
                    _buildLocation(),
                    const SizedBox(height: 14),
                    _buildSearchBar(),
                    const SizedBox(height: 14),
                    _buildFilterRow(),
                    const SizedBox(height: 16),
                    _buildPetGrid(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // TOP BAR 
  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          Builder(
            builder: (ctx) => GestureDetector(
              onTap: () => Scaffold.of(ctx).openDrawer(),
              child: Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(color: FurPalsColors.shadow, blurRadius: 10, offset: Offset(0, 3)),
                  ],
                ),
                child: Image.asset(
                  'assets/icons/menu.png', width: 22, height: 22,
                  errorBuilder: (_, __, ___) =>
                      const Icon(Icons.menu_rounded, size: 20, color: FurPalsColors.textDark),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Row(
              children: [
                Text(
                  'Mickaluvsyou',
                  style: GoogleFonts.nunito(
                    fontSize: 17, fontWeight: FontWeight.w800, color: FurPalsColors.textDark,
                  ),
                ),
                const SizedBox(width: 6),
                Image.asset('assets/icons/paw_badge.png', width: 22, height: 22,
                    errorBuilder: (_, __, ___) =>
                        const Text('🐾', style: TextStyle(fontSize: 18))),
              ],
            ),
          ),
          Container(
            width: 40, height: 40,
            decoration: const BoxDecoration(
              color: FurPalsColors.heartRed, shape: BoxShape.circle,
            ),
            child: const Icon(Icons.favorite, color: Colors.white, size: 20),
          ),
        ],
      ),
    );
  }

  // TITLE 
  Widget _buildTitle() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text('Lost ', style: GoogleFonts.nunito(fontSize: 30, fontWeight: FontWeight.w900, color: FurPalsColors.pink)),
        Text('& Found ', style: GoogleFonts.nunito(fontSize: 30, fontWeight: FontWeight.w900, color: FurPalsColors.textDark)),
        Image.asset('assets/icons/paw_title.png', width: 28, height: 28,
            errorBuilder: (_, __, ___) => const Text('🐾', style: TextStyle(fontSize: 24))),
      ],
    );
  }

  //LOCATION 
  Widget _buildLocation() {
    return Row(
      children: [
        const Icon(Icons.location_on, color: FurPalsColors.pink, size: 17),
        const SizedBox(width: 4),
        Text('Current Location...',
            style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w700, color: FurPalsColors.textDark)),
      ],
    );
  }

  //  SEARCH BAR 
  Widget _buildSearchBar() {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: const [BoxShadow(color: FurPalsColors.shadow, blurRadius: 8, offset: Offset(0, 2))],
      ),
      child: TextField(
        controller: _searchController,
        style: GoogleFonts.nunito(fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Search Something...',
          hintStyle: GoogleFonts.nunito(color: FurPalsColors.textMid.withOpacity(0.5), fontSize: 14),
          prefixIcon: Icon(Icons.search, color: FurPalsColors.textMid.withOpacity(0.5), size: 22),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  // FILTER ROW 
  Widget _buildFilterRow() {
    return Row(
      children: [
        ..._filters.map((f) => _filterChip(f['label'] as String, f['asset'] as String)),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () {},
          child: Container(
            width: 34, height: 34,
            decoration: const BoxDecoration(color: FurPalsColors.textDark, shape: BoxShape.circle),
            child: const Icon(Icons.add, color: Colors.white, size: 20),
          ),
        ),
      ],
    );
  }

  Widget _filterChip(String label, String assetPath) {
    final bool isSelected = _selectedFilter == label;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? FurPalsColors.blush : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? FurPalsColors.pink : Colors.grey.shade300, width: 1.4,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(assetPath, width: 20, height: 20,
                errorBuilder: (_, __, ___) => const SizedBox(width: 20)),
            const SizedBox(width: 5),
            Text(label,
                style: GoogleFonts.nunito(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: isSelected ? FurPalsColors.pink : FurPalsColors.textDark)),
          ],
        ),
      ),
    );
  }

  // PET GRID 
  Widget _buildPetGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 0.80,
      children: [
        _buildAddCard(),
        ..._pets.map((pet) => _buildPetCard(pet)),
      ],
    );
  }

  Widget _buildAddCard() {
    return GestureDetector(
    onTap: () => Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddMissingPetScreen()),
    ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [BoxShadow(color: FurPalsColors.shadow, blurRadius: 8, offset: Offset(0, 2))],
        ),
        child: Center(
          child: Container(
            width: 44, height: 44,
            decoration: const BoxDecoration(color: FurPalsColors.blush, shape: BoxShape.circle),
            child: const Icon(Icons.add, size: 26, color: FurPalsColors.pink),
          ),
        ),
      ),
    );
  }

  Widget _buildPetCard(Map<String, dynamic> pet) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => LostFoundProfileScreen(pet: pet),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [BoxShadow(color: FurPalsColors.shadow, blurRadius: 8, offset: Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    child: Container(
                      width: double.infinity,
                      color: FurPalsColors.blush.withOpacity(0.4),
                      child: Center(
                        child: Icon(Icons.pets, size: 36, color: FurPalsColors.pink.withOpacity(0.4)),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8, right: 8,
                    child: GestureDetector(
                      onTap: () => setState(() => pet['liked'] = !(pet['liked'] as bool)),
                      child: Container(
                        width: 30, height: 30,
                        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                        child: Icon(
                          (pet['liked'] as bool) ? Icons.favorite : Icons.favorite_border,
                          size: 16, color: FurPalsColors.heartRed,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(pet['name'] as String,
                          style: GoogleFonts.nunito(
                              fontWeight: FontWeight.w800, fontSize: 12, color: FurPalsColors.textDark)),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text('(${pet['breed']})',
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.nunito(fontSize: 11, color: FurPalsColors.textMid)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text('${pet['age']} | ${pet['gender']}',
                      style: GoogleFonts.nunito(fontSize: 11, color: FurPalsColors.textMid)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}