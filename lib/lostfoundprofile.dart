import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:furpals/Homescreen.dart'; // FurPalsColors
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:furpals/lf_add_missing.dart';

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
  User? _currentUser;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _currentUser = FirebaseAuth.instance.currentUser;
  }

  @override
  void dispose() {
    _photoController.dispose();
    super.dispose();
  }

  bool get _isOwner => _currentUser?.uid == widget.pet['userId'];

  Future<void> _deletePost() async {
    if (!_isOwner) return;
    
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete Post?', style: GoogleFonts.baloo2(fontWeight: FontWeight.w800)),
        content: Text('This action cannot be undone.', style: GoogleFonts.nunito()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      setState(() => _isDeleting = true);
      await FirebaseFirestore.instance
          .collection('lost_pets')
          .doc(widget.pet['petId'])
          .delete();
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post deleted successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting post: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  void _editPost() {
    // Navigate to edit screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddMissingPetScreen(
          editMode: true,
          petData: widget.pet,
        ),
      ),
    ).then((updated) {
      if (updated == true && mounted) {
        Navigator.pop(context);
      }
    });
  }

  void _showOwnerActions() {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Choose your action',
                  style: GoogleFonts.baloo2(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: FurPalsColors.textDark,
                  )),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _editPost();
                },
                icon: const Icon(Icons.edit_rounded),
                label: const Text('Edit listing'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: FurPalsColors.blue,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _isDeleting ? null : () {
                  Navigator.pop(context);
                  _deletePost();
                },
                icon: const Icon(Icons.delete_rounded),
                label: const Text('Delete listing'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: FurPalsColors.heartRed,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel',
                    style: GoogleFonts.nunito(
                      color: FurPalsColors.textDark,
                      fontWeight: FontWeight.w700,
                    )),
              ),
            ],
          ),
        );
      },
    );
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

            // PHOTO SECTION 
            Stack(
              children: [

                // Photo area — no black edges
                GestureDetector(
                  onTap: photos.isNotEmpty ? () => _showFullScreenPhotos(context) : null,
                  child: Container(
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

            // PET INFO 
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
                    '${pet['breed'] ?? 'pet breed'}  |  ${pet['dateMissing'] as String? ?? 'Date Missing'}',
                    style: GoogleFonts.nunito(
                      fontSize: 13,
                      color: FurPalsColors.textMid,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 16),

                  //  STAT PILLS — equal width 
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

                  // OWNER NAME
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          pet['ownerName'] as String? ?? 'Owner Name',
                          style: GoogleFonts.baloo2(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: FurPalsColors.textDark,
                          ),
                        ),
                      ),
                      // Always show share icon; owner gets a pencil menu for edit/delete
                      Row(
                        children: [
                          // Share icon
                          GestureDetector(
                            onTap: () {},
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x11000000),
                                    blurRadius: 8,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Icon(Icons.reply_rounded,
                                  color: FurPalsColors.textDark, size: 20),
                            ),
                          ),
                          const SizedBox(width: 12),
                          if (!_isOwner) ...[
                            // Messenger — blue circle
                            GestureDetector(
                              onTap: () {},
                              child: Container(
                                width: 36, height: 36,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF1163EC),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.send_rounded,
                                    color: Colors.white, size: 20),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Phone — green circle
                            GestureDetector(
                              onTap: () {},
                              child: Container(
                                width: 36, height: 36,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF4CAF50),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.phone_rounded,
                                    color: Colors.white, size: 20),
                              ),
                            ),
                          ],
                          if (_isOwner) ...[
                            const SizedBox(width: 12),
                            GestureDetector(
                              onTap: _showOwnerActions,
                              child: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0x11000000),
                                      blurRadius: 8,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Icon(Icons.edit_rounded,
                                    size: 20, color: FurPalsColors.textDark),
                              ),
                            ),
                          ],
                        ],
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

  void _showFullScreenPhotos(BuildContext context) {
    final photos = (widget.pet['photos'] as List<dynamic>?) ?? [];
    if (photos.isEmpty) return;

    final PageController fullScreenController = PageController(initialPage: _currentPhoto);
    int displayPage = _currentPhoto;
    
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: StatefulBuilder(
          builder: (context, setState) => Scaffold(
            backgroundColor: Colors.black87,
            body: Stack(
              children: [
                PageView.builder(
                  controller: fullScreenController,
                  itemCount: photos.length,
                  onPageChanged: (index) {
                    setState(() => displayPage = index);
                  },
                  itemBuilder: (_, i) => Center(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Image.network(
                        photos[i] as String,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => Icon(
                          Icons.image_not_supported,
                          color: Colors.white.withOpacity(0.5),
                          size: 60,
                        ),
                      ),
                    ),
                  ),
                ),
                // Close button
                Positioned(
                  top: 16 + MediaQuery.of(context).padding.top,
                  left: 16,
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.black,
                        size: 24,
                      ),
                    ),
                  ),
                ),
                // Photo counter
                if (photos.length > 1)
                  Positioned(
                    top: 16 + MediaQuery.of(context).padding.top,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${displayPage + 1}/${photos.length}',
                        style: GoogleFonts.nunito(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }}