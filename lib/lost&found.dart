import 'package:flutter/material.dart';
import 'package:furpals/lf_add_missing.dart';
import 'package:furpals/lostfoundprofile.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:furpals/NotificationScreen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:furpals/models.dart' as models;

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

// The background gradient 
const appBackgroundGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  stops: [0.0, 0.5, 1.0], 
  colors: [
    Color(0xFFFCDDE8), 
    Color(0xFFFFE8D2),
    Color(0xFFD4F0E4), 
  ],
);



// ── LOST & FOUND SCREEN ───────────────────────────────────────────────────────
class LostFoundScreen extends StatefulWidget {
  const LostFoundScreen({super.key});

  @override
  State<LostFoundScreen> createState() => _LostFoundScreenState();
}


class _LostFoundScreenState extends State<LostFoundScreen> {
  String _selectedFilter = 'ALL';
  String _currentUserName = 'FurPals User';
  final TextEditingController _searchController = TextEditingController();
  bool _hasNewNotif = true;
  List<models.LostPet> _lostPets = [];
  bool _isLoading = true;
  Set<String> _likedPets = Set<String>();
  // Dynamic filters based on posted pet types
  List<Map<String, dynamic>> get _dynamicFilters {
    final petTypes = <String>{};
    for (final pet in _lostPets) {
      petTypes.add(pet.type.toUpperCase());
    }

    final filters = <Map<String, dynamic>>[
      {'label': 'ALL', 'emoji': '🐾'},
    ];

    for (final type in petTypes) {
      filters.add({
        'label': type,
        'emoji': _emojiForPetType(type.toLowerCase()),
      });
    }

    return filters;
  }
  

  @override
  void initState() {
    super.initState();
    _setCurrentUserName();
    _fetchLostPets();
  }

  Future<void> _setCurrentUserName() async {
    final user = FirebaseAuth.instance.currentUser;
    setState(() {
      _currentUserName = user?.displayName?.trim().isNotEmpty == true
          ? user!.displayName!
          : (user?.email?.split('@').first ?? 'FurPals User');
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchLostPets() async {
    setState(() => _isLoading = true);
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('lost_pets')
          .orderBy('createdAt', descending: true)
          .get();

      _lostPets = snapshot.docs
          .map((doc) => models.LostPet.fromMap(doc.id, doc.data()))
          .toList();
    } catch (e) {
      // Handle error
      print('Error fetching lost pets: $e');
    } finally {
      setState(() => _isLoading = false);
    }
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

  // ── TOP BAR ───────────────────────────────────────────────────────────────
   Widget _buildTopBar(BuildContext context) { // menu icon
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
                  boxShadow: const [BoxShadow(color: FurPalsColors.shadow, blurRadius: 10, offset: Offset(0, 3))],
                ),
                child: const Center(child: Icon(Icons.menu_rounded, size: 20, color: FurPalsColors.textDark)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Row(
              children: [
                Text(_currentUserName, // username display in top bar
                    style: GoogleFonts.baloo2(
                      fontSize: 25,
                      fontWeight: FontWeight.w800,
                      color: FurPalsColors.textDark,
                    )),
                const SizedBox(width: 10),
                const Text('🐾', style: TextStyle(fontSize: 18)),
              ],
            ),
          ),
          GestureDetector(
            onTap: () async {
              setState(() => _hasNewNotif = false); // clear red dot
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NotificationScreen()),
              );
            },
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration( // notif icon
                    color: FurPalsColors.warmWhite,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [BoxShadow(color: Color(0x40F4738A), blurRadius: 12, offset: Offset(0, 4))],
                  ),
                  child: const Center(
                    child: Icon(Icons.favorite_rounded, color: FurPalsColors.heartRed, size: 20),
                  ),
                ),
                if (_hasNewNotif)
                  Positioned( // notfi red notice
                    top: -3, right: -3,
                    child: Container(
                      width: 12, height: 12,
                      decoration: BoxDecoration(
                        color: FurPalsColors.heartRed,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: const [BoxShadow(color: Color(0x55E53935), blurRadius: 4, offset: Offset(0, 1))],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  // ── TITLE ─────────────────────────────────────────────────────────────────
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

  // ── LOCATION ──────────────────────────────────────────────────────────────
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

  // ── SEARCH BAR ────────────────────────────────────────────────────────────
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

  // ── FILTER ROW ────────────────────────────────────────────────────────────
  Widget _buildFilterRow() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          ..._dynamicFilters.map((f) => _filterChip(f['label'] as String, f['emoji'] as String)),
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
      ),
    );
  }

  Widget _filterChip(String label, String emoji) {
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
            Text(emoji, style: const TextStyle(fontSize: 16)),
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

  String _emojiForPetType(String type) {
    final normalized = type.trim().toLowerCase();
    switch (normalized) {
      case 'dog':
        return '🐶';
      case 'cat':
        return '🐱';
      case 'bird':
        return '🐦';
      case 'fish':
        return '🐠';
      case 'rabbit':
      case 'bunny':
        return '🐰';
      case 'hamster':
        return '🐹';
      case 'reptile':
        return '🦎';
      case 'horse':
        return '🐴';
      case 'other':
        return '🐾';
      default:
        return '🐾';
    }
  }

  // ── PET GRID ──────────────────────────────────────────────────────────────
  Widget _buildPetGrid() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final filteredPets = _selectedFilter == 'ALL'
        ? _lostPets
        : _lostPets.where((pet) => pet.type.toUpperCase() == _selectedFilter).toList();

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 0.80,
      children: [
        _buildAddCard(),
        ...filteredPets.map((pet) => _buildPetCard(pet)),
      ],
    );
  }

  Widget _buildAddCard() {
    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddMissingPetScreen()),
        );
        // Refresh the list after returning
        _fetchLostPets();
      },
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

  Widget _buildPetCard(models.LostPet pet) {
    final isLiked = _likedPets.contains(pet.id);
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => LostFoundProfileScreen(
              pet: {
                'petId': pet.id,
                'userId': pet.userId,
                'photos': pet.photoUrls,
                'name': pet.name,
                'breed': pet.breed,
                'age': pet.age ?? '0',
                'gender': pet.gender ?? '-',
                'weight': pet.weight ?? '0',
                'ownerName': pet.posterName.isNotEmpty ? pet.posterName : 'Unknown Owner',
                'location': pet.location,
                'description': pet.description,
                'type': pet.type,
                'dateMissing': pet.dateMissing?.toString().split(' ')[0] ?? 'Unknown',
              },
            ),
          ),
        );
      },
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
                    child: pet.photoUrls.isNotEmpty
                        ? Image.network(
                            pet.photoUrls.first,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Center(
                                child: CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null,
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(FurPalsColors.pink),
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              print('Error loading image: $error');
                              return Center(
                                child: Icon(
                                  Icons.pets,
                                  size: 36,
                                  color: FurPalsColors.pink.withOpacity(0.4),
                                ),
                              );
                            },
                          )
                        : Center(
                            child: Icon(
                              Icons.pets,
                              size: 36,
                              color: FurPalsColors.pink.withOpacity(0.4),
                            ),
                          ),
                  ),
                ),
                Positioned(
                  top: 8, right: 8,
                  child: GestureDetector(
                    onTap: () => setState(() {
                      if (isLiked) {
                        _likedPets.remove(pet.id);
                      } else {
                        _likedPets.add(pet.id);
                      }
                    }),
                    child: Container(
                      width: 30, height: 30,
                      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                      child: Icon(
                        isLiked ? Icons.favorite : Icons.favorite_border,
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
                    Text(
                      _emojiForPetType(pet.type),
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(width: 6),
                    Text(pet.name,
                        style: GoogleFonts.nunito(
                            fontWeight: FontWeight.w800, fontSize: 12, color: FurPalsColors.textDark)),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text('(${pet.breed})',
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.nunito(fontSize: 11, color: FurPalsColors.textMid)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: FurPalsColors.pink.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    pet.type.toUpperCase(),
                    style: GoogleFonts.nunito(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: FurPalsColors.pink,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text('${pet.age ?? 'Unknown age'} | ${pet.gender ?? 'Unknown gender'}',
                    style: GoogleFonts.nunito(fontSize: 11, color: FurPalsColors.textMid)),
                if (pet.posterName.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text('Posted by ${pet.posterName}',
                      style: GoogleFonts.nunito(fontSize: 10, color: FurPalsColors.textMid.withOpacity(0.8))),
                ],
              ],
            ),
          ),
        ],
      ),
    ));
  }
}