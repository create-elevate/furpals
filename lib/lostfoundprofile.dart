import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:furpals/Homescreen.dart'; // FurPalsColors

class LostFoundProfileScreen extends StatefulWidget {
  final Map<String, dynamic> pet;
  const LostFoundProfileScreen({super.key, required this.pet});

  @override
  State<LostFoundProfileScreen> createState() => _LostFoundProfileScreenState();
}

class _LostFoundProfileScreenState extends State<LostFoundProfileScreen> {
  bool _liked = false;
  int _currentPhoto = 0;
  final PageController _photoController = PageController();

  @override
  void dispose() {
    _photoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pet = widget.pet;
    final List<dynamic> photos = (pet['photos'] as List<dynamic>?) ?? [];
    final int dotCount = photos.isEmpty ? 3 : photos.length;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── PHOTO SECTION ─────────────────────────────────────────────
            Stack(
              children: [

                // Photo area — no black edges
                Container(
                  height: 320,
                  width: double.infinity,
                  color: FurPalsColors.blush.withOpacity(0.4),
                  child: photos.isEmpty
                      ? Center(
                          child: Icon(Icons.pets,
                              size: 80,
                              color: FurPalsColors.pink.withOpacity(0.4)),
                        )
                      : PageView.builder(
                          controller: _photoController,
                          itemCount: photos.length,
                          onPageChanged: (i) =>
                              setState(() => _currentPhoto = i),
                          itemBuilder: (_, i) => Image.network(
                            photos[i] as String,
                            fit: BoxFit.cover,
                            width: double.infinity,
                          ),
                        ),
                ),

                // Back button
                Positioned(
                  top: MediaQuery.of(context).padding.top + 8,
                  left: 16,
                  child: GestureDetector(
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
                ),

                // Dot indicators
                Positioned(
                  bottom: 50,
                  left: 0, right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(dotCount, (i) {
                      final isActive = i == _currentPhoto;
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: 10, height: 10,
                        decoration: BoxDecoration(
                          color: isActive
                              ? Colors.white
                              : Colors.white.withOpacity(0.5),
                          shape: BoxShape.circle,
                        ),
                      );
                    }),
                  ),
                ),

                // White rounded top — covers the photo bottom edge
                Positioned(
                  bottom: 0,
                  left: 0, right: 0,
                  child: Container(
                    height: 40,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(40)),
                    ),
                  ),
                ),
              ],
            ),

            // ── PET INFO ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // Pet Name + Heart
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          pet['name'] as String? ?? 'Pet Name',
                          style: GoogleFonts.baloo2(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: FurPalsColors.textDark,
                            height: 1.1,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => setState(() => _liked = !_liked),
                        child: Icon(
                          _liked
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          color: _liked
                              ? FurPalsColors.heartRed
                              : Colors.grey.shade300,
                          size: 26,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 2),

                  // Breed | Date Missing
                  Text(
                    '${pet['breed'] ?? 'pet breed'}  |  Date Missing',
                    style: GoogleFonts.nunito(
                      fontSize: 13,
                      color: FurPalsColors.textMid,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── STAT PILLS — equal width ───────────────────────────
                  Row(
                    children: [
                      Expanded(child: _statPill('Age',    pet['age']    as String? ?? '0')),
                      const SizedBox(width: 10),
                      Expanded(child: _statPill('Gender', pet['gender'] as String? ?? '-')),
                      const SizedBox(width: 10),
                      Expanded(child: _statPill('Weight', pet['weight'] as String? ?? '0')),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // ── OWNER NAME + CONTACT ICONS ────────────────────────
                  Row(
                    children: [
                      Text(
                        pet['ownerName'] as String? ?? 'Owner Name',
                        style: GoogleFonts.baloo2(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: FurPalsColors.textDark,
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Share icon
                      GestureDetector(
                        onTap: () {},
                        child: const Icon(Icons.reply_rounded,
                            color: FurPalsColors.textDark, size: 26),
                      ),
                      const SizedBox(width: 8),
                      // Messenger — blue circle
                      GestureDetector(
                        onTap: () {},
                        child: Container(
                          width: 30, height: 30,
                          decoration: const BoxDecoration(
                            color: Color(0xFF1163EC),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.send_rounded,
                              color: Colors.white, size: 15),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Phone — green circle
                      GestureDetector(
                        onTap: () {},
                        child: Container(
                          width: 30, height: 30,
                          decoration: const BoxDecoration(
                            color: Color(0xFF4CAF50),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.phone_rounded,
                              color: Colors.white, size: 15),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 6),

                  // Location
                  Row(
                    children: [
                      const Icon(Icons.location_on,
                          color: FurPalsColors.heartRed, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        pet['location'] as String? ?? 'Last Location...',
                        style: GoogleFonts.nunito(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: FurPalsColors.textDark,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Description
                  Text(
                    pet['description'] as String? ?? 'Tell me something...',
                    style: GoogleFonts.nunito(
                      fontSize: 14,
                      color: FurPalsColors.textMid,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statPill(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFEDD9B3),
        borderRadius: BorderRadius.circular(50),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: GoogleFonts.nunito(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: FurPalsColors.textMid,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.baloo2(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: FurPalsColors.textDark,
            ),
          ),
        ],
      ),
    );
  }
}