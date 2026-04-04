import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _C {
  static const gradientTop    = Color(0xFFF9C8D0);
  static const gradientMid    = Color(0xFFF7D9B5);
  static const gradientBottom = Color(0xFFC5E8E0);
  static const brown          = Color(0xFF6B4226);
  static const dark           = Color(0xFF111111);
  static const grey           = Color(0xFF999999);
  static const blue           = Color(0xFF2563EB);
  static const inputBg        = Color(0xFFCFE8E3);
  static const white          = Color(0xFFFFFFFF);
  static const btnTan         = Color(0xFFE8C9A0);
  static const btnClose       = Color(0xFFCCE8F0);
  static const modalBg        = Color(0xFFE8C9A0);
  static const error          = Color(0xFFC0392B);
  static const success        = Color(0xFF2D9E60);
}

// ── FIREBASE AUTH + FIRESTORE SERVICE ─────────────────────────────────────────
class _AuthService {
  static final _auth = FirebaseAuth.instance;
  static final _db   = FirebaseFirestore.instance;

  /// Creates a Firebase Auth user
  static Future<void> signUp({
    required String fullName,
    required String email,
    required String nickname,
    required String password,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final uid = credential.user!.uid;
    await credential.user!.updateDisplayName(fullName);
    await _db.collection('users').doc(uid).set({
      'uid':         uid,
      'fullName':    fullName,
      'username':    nickname,           // the @nickname shown in the app
      'email':       email,
      'photoURL':    '',                 // empty until they upload a photo
      'bio':         '',
      'isOnline':    true,
      'createdAt':   FieldValue.serverTimestamp(),
    });
  }
}

// ── SIGN UP SCREEN ─────────────────────────────────────────────────────────────
class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _nameCtrl  = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _nickCtrl  = TextEditingController();
  final _passCtrl  = TextEditingController();

  bool _showPass  = false;
  bool _isLoading = false;
  bool _eulaOk    = false;
  bool _termsOk   = false;
  bool _privacyOk = false;

  String? _nameErr, _emailErr, _nickErr, _passErr;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _nickCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  bool _validate() {
    setState(() {
      _nameErr  = _nameCtrl.text.trim().length < 2
          ? 'Please enter your full name.' : null;
      _emailErr = !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
          .hasMatch(_emailCtrl.text.trim())
          ? 'Please enter a valid email address.' : null;
      _nickErr  = _nickCtrl.text.trim().isEmpty
          ? 'Please enter a nickname.' : null;
      _passErr  = _passCtrl.text.length < 8
          ? 'Password must be at least 8 characters.' : null;
    });
    return _nameErr == null && _emailErr == null
        && _nickErr == null && _passErr == null;
  }

  Future<void> _setRememberMe(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('remember_me', value);
  }

  Future<void> _onSubmit() async {
    if (!_validate()) {
      _showToast('Almost there! Please fill in all required fields 🐾', isError: true);
      return;
    }
    if (!_eulaOk || !_termsOk || !_privacyOk) {
      _showToast('Please agree to all legal agreements.', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _AuthService.signUp(
        fullName: _nameCtrl.text.trim(),
        email:    _emailCtrl.text.trim().toLowerCase(),
        nickname: _nickCtrl.text.trim(),
        password: _passCtrl.text,
      );

      await _setRememberMe(true);

      if (mounted) {
        _showToast('🐾 Welcome to FurPals, ${_nameCtrl.text.trim()}!');
        Navigator.of(context).pushReplacementNamed('/home');
      }
    } on FirebaseAuthException catch (e) {
      // Firebase gives specific error codes we can show clearly
      final msg = switch (e.code) {
        'email-already-in-use' => 'That email is already registered. Try logging in.',
        'weak-password'        => 'Password is too weak. Use at least 8 characters.',
        'invalid-email'        => 'Please enter a valid email address.',
        _                      => e.message ?? 'Sign up failed. Please try again.',
      };
      if (mounted) _showToast(msg, isError: true);
    } catch (e) {
      if (mounted) _showToast(e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showToast(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message,
            style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
        backgroundColor: isError ? _C.error : _C.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

 void _openLegal(String title, String content) {
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: '',
    barrierColor: Colors.black.withOpacity(0.5),
    useRootNavigator: true,
    transitionDuration: const Duration(milliseconds: 220),
    transitionBuilder: (_, anim, __, child) => ScaleTransition(
      scale: CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
      child: FadeTransition(opacity: anim, child: child),
    ),
    pageBuilder: (_, __, ___) => MediaQuery.removeViewInsets(
      removeBottom: true,
      context: context,
      child: Align(
        alignment: Alignment.center,
        child: _LegalModal(title: title, content: content),
      ),
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: [0.0, 0.45, 1.0],
            colors: [_C.gradientTop, _C.gradientMid, _C.gradientBottom],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 20),
                _buildFormCard(),
                const SizedBox(height: 20),
                _buildLegalCard(),
                const SizedBox(height: 20),
                _buildCreateButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Image.asset('assets/images/logo.png', width: 130, height: 130),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('furpals',
                  style: GoogleFonts.modak(fontSize: 50, color: const Color(0xFF4A3728))),
              Text(
                'Enter your details below to create your account and get started',
                style: GoogleFonts.josefinSans(
                    fontSize: 13, fontWeight: FontWeight.w600,
                    color: const Color(0xFF000000), height: 1.45),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFormCard() {
    return _Card(
      child: Column(
        children: [
          Text('Create Account',
              style: GoogleFonts.josefinSans(
                  fontSize: 24, fontWeight: FontWeight.w700, color: _C.dark)),
          const SizedBox(height: 15),

          _Field(
            label: 'Full Name',
            hint: 'Enter full name',
            icon: Icons.person_outline,
            controller: _nameCtrl,
            errorText: _nameErr,
            onChanged: (_) => setState(() => _nameErr = null),
          ),
          const SizedBox(height: 15),

          _Field(
            label: 'Email',
            hint: 'Enter Email',
            icon: Icons.mail_outline,
            controller: _emailCtrl,
            errorText: _emailErr,
            keyboardType: TextInputType.emailAddress,
            onChanged: (_) => setState(() => _emailErr = null),
          ),
          const SizedBox(height: 15),

          _Field(
            label: 'Nickname',
            hint: 'Enter Nickname',
            icon: Icons.person_outline,
            controller: _nickCtrl,
            errorText: _nickErr,
            onChanged: (_) => setState(() => _nickErr = null),
          ),
          const SizedBox(height: 15),

          _Field(
            label: 'Password',
            hint: 'Enter your password',
            icon: Icons.key_outlined,
            controller: _passCtrl,
            errorText: _passErr,
            isPassword: true,
            showEye: true,
            isVisible: _showPass,
            onToggleVisibility: () => setState(() => _showPass = !_showPass),
            onChanged: (_) => setState(() => _passErr = null),
          ),
          const SizedBox(height: 30),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Already have an account? ',
                  style: GoogleFonts.nunito(
                      fontSize: 14, fontWeight: FontWeight.w500, color: _C.grey)),
              GestureDetector(
                onTap: () => Navigator.of(context).pushNamed('/login'),
                child: Text('LOG IN',
                    style: GoogleFonts.holtwoodOneSc(
                        fontSize: 14, fontWeight: FontWeight.w900,
                        color: _C.dark, letterSpacing: .5)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegalCard() {
    return _Card(
      child: Column(
        children: [
          Text('Legal Agreements',
              style: GoogleFonts.josefinSans(
                  fontSize: 22, fontWeight: FontWeight.w700, color: _C.dark)),
          const SizedBox(height: 16),

          _LegalRow(
            checked: _eulaOk,
            onToggle: () => setState(() => _eulaOk = !_eulaOk),
            linkText: 'End User License Agreement (EULA)',
            onLinkTap: () => _openLegal('End-user License Agreement', _eulaText),
          ),
          const SizedBox(height: 14),

          _LegalRow(
            checked: _termsOk,
            onToggle: () => setState(() => _termsOk = !_termsOk),
            linkText: 'Terms of use',
            onLinkTap: () => _openLegal('Terms of Use', _termsText),
          ),
          const SizedBox(height: 14),

          _LegalRow(
            checked: _privacyOk,
            onToggle: () => setState(() => _privacyOk = !_privacyOk),
            linkText: 'Privacy Policy',
            onLinkTap: () => _openLegal('Privacy Policy', _privacyText),
          ),
        ],
      ),
    );
  }

  Widget _buildCreateButton() {
    return GestureDetector(
      onTap: _isLoading ? null : _onSubmit,
      child: Container(
        width: double.infinity,
        height: 60,
        decoration: BoxDecoration(
          color: _C.btnTan,
          borderRadius: BorderRadius.circular(50),
          border: Border.all(color: Colors.black, width: 2.5),
          boxShadow: const [
            BoxShadow(color: Colors.black, offset: Offset(3, 3), blurRadius: 0),
          ],
        ),
        child: Center(
          child: _isLoading
              ? const SizedBox(
                  width: 24, height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.black54))
              : Text('CREATE ACCOUNT',
                  style: GoogleFonts.holtwoodOneSc(
                      fontSize: 17, letterSpacing: 3, color: _C.dark)),
        ),
      ),
    );
  }
}

// ── REUSABLE CARD ──────────────────────────────────────────────────────────────
class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _C.white,
        borderRadius: BorderRadius.circular(60),
        border: Border.all(color: Colors.black, width: 2.5),
        boxShadow: const [
          BoxShadow(color: Colors.black, offset: Offset(3, 3), blurRadius: 0),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(22, 28, 22, 20),
      child: child,
    );
  }
}

// ── REUSABLE INPUT FIELD ──────────────────────────────────────────────────────
class _Field extends StatelessWidget {
  final String label, hint;
  final IconData icon;
  final TextEditingController controller;
  final String? errorText;
  final bool isPassword, showEye, isVisible;
  final VoidCallback? onToggleVisibility;
  final ValueChanged<String>? onChanged;
  final TextInputType keyboardType;

  const _Field({
    required this.label,
    required this.hint,
    required this.icon,
    required this.controller,
    this.errorText,
    this.isPassword = false,
    this.showEye = false,
    this.isVisible = false,
    this.onToggleVisibility,
    this.onChanged,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.baloo2(
                fontSize: 15, fontWeight: FontWeight.w700,
                color: const Color(0xFF4A3728))),
        const SizedBox(height: 6),

        Container(
          height: 54,
          decoration: BoxDecoration(
            color: const Color(0xFFD6EBF0),
            borderRadius: BorderRadius.circular(50),
            border: Border.all(
                color: errorText != null ? _C.error : Colors.transparent,
                width: 2),
          ),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 16, right: 10),
                child: Icon(icon, size: 22, color: const Color(0xFF444444)),
              ),
              Expanded(
                child: TextField(
                  controller: controller,
                  onChanged: onChanged,
                  obscureText: isPassword && !isVisible,
                  keyboardType: keyboardType,
                  style: GoogleFonts.nunito(
                      fontSize: 15, fontWeight: FontWeight.w600, color: _C.dark),
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: GoogleFonts.baloo2(
                        fontSize: 15, fontWeight: FontWeight.w500, color: _C.grey),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 4),
                  ),
                ),
              ),
              if (showEye)
                GestureDetector(
                  onTap: onToggleVisibility,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 14),
                    child: Icon(
                      isVisible
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      size: 22, color: const Color(0xFF777777)),
                  ),
                ),
            ],
          ),
        ),

        if (errorText != null) ...[
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 14),
            child: Text(errorText!,
                style: GoogleFonts.nunito(
                    fontSize: 12, fontWeight: FontWeight.w700, color: _C.error)),
          ),
        ],
      ],
    );
  }
}

// ── LEGAL ROW ─────────────────────────────────────────────────────────────────
class _LegalRow extends StatelessWidget {
  final bool checked;
  final VoidCallback onToggle, onLinkTap;
  final String linkText;

  const _LegalRow({
    required this.checked,
    required this.onToggle,
    required this.linkText,
    required this.onLinkTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 36, height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: checked ? _C.dark : _C.white,
              border: Border.all(color: _C.dark, width: 2.5),
            ),
            child: checked
                ? const Icon(Icons.check, color: Colors.white, size: 20)
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: GoogleFonts.nunito(
                    fontSize: 14, fontWeight: FontWeight.w600,
                    color: const Color(0xFF333333)),
                children: [
                  const TextSpan(text: 'I agree to the '),
                  TextSpan(
                    text: linkText,
                    style: GoogleFonts.nunito(
                        fontSize: 14, fontWeight: FontWeight.w700,
                        color: _C.blue,
                        decoration: TextDecoration.underline,
                        decorationColor: _C.blue),
                    recognizer: TapGestureRecognizer()..onTap = onLinkTap,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── LEGAL MODAL ───────────────────────────────────────────────────────────────
class _LegalModal extends StatelessWidget {
  final String title, content;
  const _LegalModal({required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth  = MediaQuery.of(context).size.width;

    return Material(
      color: Colors.transparent,
      child: Container(
        width: screenWidth * 0.88,
        height: screenHeight * 0.68,
        decoration: BoxDecoration(
          color: _C.modalBg,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: Colors.black, width: 2.5),
          boxShadow: const [
            BoxShadow(color: Colors.black, offset: Offset(5, 5), blurRadius: 0),
          ],
        ),
        child: Column(
          children: [
            // ── Title ─────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 22, 22, 12),
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: GoogleFonts.baloo2(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: _C.dark,
                ),
              ),
            ),

            // ── White scrollable content card ──────────────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.black, width: 2),
                    boxShadow: const [
                      BoxShadow(color: Colors.black, offset: Offset(3, 3), blurRadius: 0),
                    ],
                  ),
                  padding: const EdgeInsets.all(18),
                  child: SingleChildScrollView(
                    child: _LegalText(content: content),
                  ),
                ),
              ),
            ),

            // ── CLOSE button ───────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: double.infinity,
                  height: 52,
                  decoration: BoxDecoration(
                    color: _C.btnClose,
                    borderRadius: BorderRadius.circular(50),
                    border: Border.all(color: _C.dark, width: 2.5),
                    boxShadow: const [
                      BoxShadow(color: Colors.black, offset: Offset(3, 3), blurRadius: 0),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      'CLOSE',
                      style: GoogleFonts.baloo2(
                        fontSize: 16,
                        letterSpacing: 2,
                        color: _C.dark,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LegalText extends StatelessWidget {
  final String content;
  const _LegalText({required this.content});

  static final _headingRx = RegExp(r'^\d+\.?\s+\S');

  @override
  Widget build(BuildContext context) {
    final lines = content.split('\n');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: lines.map((line) {
        final trimmed = line.trim();

        if (trimmed.isEmpty) {
          return const SizedBox(height: 6);
        }

        final isHeading = _headingRx.hasMatch(trimmed);

        return Padding(
          padding: const EdgeInsets.only(bottom: 2),
          child: Text(
            trimmed,
            textAlign: TextAlign.justify,
            style: GoogleFonts.nunito(
              fontSize: 13.5,
              fontWeight: isHeading ? FontWeight.w800 : FontWeight.w500,
              color: isHeading
                  ? const Color(0xFF222222)
                  : const Color(0xFF555555),
              height: 1.5,
              letterSpacing: isHeading ? 0.2 : 0,
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── LEGAL TEXT ─────────────────────────────────────────────────────────────────
const _eulaText = '''
Last Updated: March 01, 2026

This End User License Agreement is between you and MRLD Tech Solutions and explains how you may use the FurPals mobile application.

By downloading or using FurPals, you agree to follow this Agreement. If you do not agree, please do not use the app.





1. License to Use
We grant you a limited, personal, non-exclusive, and non-transferable right to use FurPals for personal and non-commercial purposes only.

You do not own the app. You are only permitted to use it in accordance with this Agreement.






2. Restrictions
You agree that you will not:

- Use the app for illegal, abusive, or harmful activities

- Share your login credentials with others

- Access accounts that do not belong to you

Violation of these rules may result in account suspension or termination.





3. Accounts
You must provide accurate information when creating an account and keep your login credentials secure. You are responsible for all activities under your account.






4. Updates
We may release updates to improve performance, security, or features such as pet profiles and messaging. Some updates may be required to continue using the app.






5. Ownership
All rights to FurPals, including its design, logo, features, and system, belong to MRLD Tech Solutions. Unauthorized use is prohibited.






6. Disclaimer
FurPals is provided “as is.”
We do not guarantee that the app will always be uninterrupted, secure, or error-free.





7. Limitation of Liability
We are not responsible for user interactions, content shared within the app, or decisions made based on such content.





8. Termination
You may stop using FurPals at any time. We may suspend or remove accounts that violate this Agreement.





9. Governing Law
This Agreement shall be governed by and construed in accordance with the laws of the Republic of the Philippines, including but not limited to the Civil Code of the Philippines (Republic Act No. 386), the Electronic Commerce Act of 2000 (Republic Act No. 8792), the Data Privacy Act of 2012 (Republic Act No. 10173) and its Implementing Rules and Regulations, the Cybercrime Prevention Act of 2012 (Republic Act No. 10175), the Intellectual Property Code of the Philippines (Republic Act No. 8293), and all other applicable laws, rules, regulations, and issuances of relevant Philippine government authorities.





10. Contact
MRLD Tech Solutions
Dasmariñas City, Cavite, Philippines
mrldtechsolutions.support@gmail.com
''';

const _termsText = '''
Last Updated: March 01, 2026

FurPals is a social media and pet management platform designed for pets and furparents.

By using FurPals, you agree to these Terms and the Community Guidelines below.





1. Purpose of the App

FurPals allows users to:

- Create and manage pet profiles
- Share pet-related updates and photos
- Connect and message other furparents
- Store and organize pet information

The platform is intended for personal use only.





2. User Accounts

You agree to:

- Provide truthful and accurate information
- Maintain the security of your account
- Take responsibility for all activities under your account

We may suspend or terminate accounts that violate these Terms.






3. User Content
You are responsible for the content you post, including photos, captions, and messages.

By posting content, you grant FurPals permission to display and distribute it within the platform for normal operation.





4. Compliance
All users must follow the Community Guidelines. Failure to comply may result in content removal or account suspension.






5. Service Availability
We strive to maintain reliable service. However, temporary downtime may occur due to maintenance or technical issues.






6. Disclaimer
FurPals provides a platform for connection and sharing.

We do not guarantee the accuracy of user-generated content or advice shared by users.






7. Termination
We reserve the right to suspend or permanently terminate accounts that violate these Terms.






8. Governing Law
This Agreement shall be governed by and construed in accordance with the laws of the Republic of the Philippines, including but not limited to the Civil Code of the Philippines (Republic Act No. 386), the Electronic Commerce Act of 2000 (Republic Act No. 8792), the Data Privacy Act of 2012 (Republic Act No. 10173) and its Implementing Rules and Regulations, the Cybercrime Prevention Act of 2012 (Republic Act No. 10175), the Intellectual Property Code of the Philippines (Republic Act No. 8293), and all other applicable laws, rules, regulations, and issuances of relevant Philippine government authorities.
Any dispute, claim, or controversy arising out of or in connection with this Agreement shall be subject to the exclusive jurisdiction of the proper courts of the Republic of the Philippines.






9. Contact
MRLD Tech Solutions
Dasmariñas City, Cavite, Philippines
mrldtechsolutions.support@gmail.com

''';

const _privacyText = '''
Last Updated: March 01, 2026

This Privacy Policy explains how FurPals collects, uses, and protects your personal information.

By using FurPals, you agree to this Privacy Policy.






1. Information We Collect
We may collect:
  - Name
  - Email address
  - Profile details
  - Pet information such as name, breed, age, and photos
  - Messages and posts

We may also collect basic app usage data through service providers.






2. How We Use Information
We use information to:

  - Create and manage accounts
  - Enable pet profiles and social interaction
  - Improve app features
  - Maintain security
  - Respond to support inquiries

We do not sell your personal data.






3. Data Sharing
We may use trusted third-party services for hosting and authentication. We may disclose information if required by law.






4. Data Security
We implement reasonable safeguards to protect your information.

However, no online platform can guarantee complete security.






5. Your Rights
You may request to access, update, or delete your personal information by contacting us.






6. Data Privacy Act of 2012
FurPals complies with the Data Privacy Act of 2012 of the Philippines. We process personal data according to the principles of transparency, legitimate purpose, and proportionality.





7. Changes to This Policy
We may update this policy when necessary. Continued use of the app indicates acceptance of the updated policy.

8. Contact
MRLD Tech Solutions
Dasmariñas City, Cavite, Philippines
mrldtechsolutions.support@gmail.com
''';