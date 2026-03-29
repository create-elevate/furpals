import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController    = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _rememberMe      = false;
  bool _isLoading       = false;
  bool _emailError      = false;
  bool _passwordError   = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ── LOG IN ─────────────────────────────────────────────────────────────────
  void _login() async {
    final email    = _emailController.text.trim();
    final password = _passwordController.text.trim();

    // Reset errors
    setState(() {
      _emailError    = false;
      _passwordError = false;
    });

    // Validate empty fields
    if (email.isEmpty && password.isEmpty) {
      setState(() { _emailError = true; _passwordError = true; });
      _showSnack('Please enter your email and password.');
      return;
    }
    if (email.isEmpty) {
      setState(() => _emailError = true);
      _showSnack('Please enter your email or username.');
      return;
    }
    if (password.isEmpty) {
      setState(() => _passwordError = true);
      _showSnack('Please enter your password.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update online status in Firestore
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .update({'isOnline': true});
      }

      if (_rememberMe) {
        await _setRememberMe(true);
      } else {
        await _clearRememberMe();
      }

      if (mounted) Navigator.pushReplacementNamed(context, '/home');

    } on FirebaseAuthException catch (e) {
      final msg = switch (e.code) {
        'invalid-credential'      => 'Invalid email or password. Please try again.',
        'user-not-found'          => 'No account found with that email.',
        'wrong-password'          => 'Incorrect password. Please try again.',
        'invalid-email'           => 'Please enter a valid email address.',
        'user-disabled'           => 'This account has been disabled.',
        'too-many-requests'       => 'Too many attempts. Please try again later.',
        'network-request-failed'  => 'No internet connection.',
        _                         => 'Login failed: ${e.message ?? e.code}',
      };

      // Highlight the correct field in red
      setState(() {
        if (['user-not-found', 'invalid-email', 'invalid-credential'].contains(e.code)) {
          _emailError = true;
        }
        if (['wrong-password', 'invalid-credential'].contains(e.code)) {
          _passwordError = true;
        }
      });

      if (mounted) _showSnack(msg);

    } catch (e) {
      if (mounted) _showSnack('Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _setRememberMe(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('remember_me', value);
  }

  Future<void> _clearRememberMe() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('remember_me');
  }

  void _showSnack(String msg, {Color color = const Color(0xFFE8445A)}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg,
            style: GoogleFonts.josefinSans(fontWeight: FontWeight.w600)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ── FORGOT PASSWORD ────────────────────────────────────────────────────────
  void _showForgotPassword() {
    final prefill = _emailController.text.trim();
    final forgotController = TextEditingController(text: prefill);
    bool sending = false;
    bool sent    = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModal) {
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40, height: 4,
                        decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(2)),
                      ),
                    ),
                    const SizedBox(height: 10),

                    if (!sent) ...[
                      Text('Forgot Password?',
                          style: GoogleFonts.josefinSans(
                              fontSize: 22, fontWeight: FontWeight.w900,
                              color: Colors.black87)),
                      const SizedBox(height: 6),
                      Text("Enter your email and we'll send you a reset link.",
                          style: GoogleFonts.josefinSans(
                              fontSize: 14, color: Colors.grey.shade500)),
                      const SizedBox(height: 10),

                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFD9EEF3),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            const Icon(Icons.email_outlined,
                                color: Colors.grey, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                controller: forgotController,
                                keyboardType: TextInputType.emailAddress,
                                style: GoogleFonts.josefinSans(fontSize: 14),
                                decoration: InputDecoration(
                                  hintText: 'Enter your email',
                                  hintStyle: GoogleFonts.josefinSans(
                                      color: Colors.grey.shade400),
                                  border: InputBorder.none,
                                  contentPadding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      SizedBox(
                        width: double.infinity, height: 52,
                        child: ElevatedButton(
                          onPressed: sending
                              ? null
                              : () async {
                                  final em = forgotController.text.trim();
                                  if (em.isEmpty || !em.contains('@')) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Please enter a valid email.',
                                            style: GoogleFonts.josefinSans()),
                                        backgroundColor: const Color(0xFFE8445A),
                                      ),
                                    );
                                    return;
                                  }
                                  setModal(() => sending = true);
                                  try {
                                    await FirebaseAuth.instance
                                        .sendPasswordResetEmail(email: em);
                                    setModal(() { sending = false; sent = true; });
                                  } on FirebaseAuthException catch (e) {
                                    setModal(() => sending = false);
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            e.code == 'user-not-found'
                                                ? 'No account found with that email.'
                                                : e.message ?? 'Error sending reset email.',
                                            style: GoogleFonts.josefinSans()),
                                          backgroundColor: const Color(0xFFE8445A),
                                        ),
                                      );
                                    }
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFEDD9B3),
                            foregroundColor: Colors.black87,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30)),
                          ),
                          child: sending
                              ? const SizedBox(
                                  width: 22, height: 22,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2.5, color: Colors.black54))
                              : Text('🐾  SEND RESET LINK',
                                  style: GoogleFonts.josefinSans(
                                      fontSize: 15, fontWeight: FontWeight.w900,
                                      letterSpacing: 1)),
                        ),
                      ),
                    ] else ...[
                      const SizedBox(height: 10),
                      Center(
                        child: Container(
                          width: 72, height: 72,
                          decoration: const BoxDecoration(
                              color: Color(0xFFEDD9B3), shape: BoxShape.circle),
                          child: const Icon(Icons.mark_email_read_outlined,
                              size: 36, color: Colors.black87),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Center(
                        child: Text('Check your email!',
                            style: GoogleFonts.josefinSans(
                                fontSize: 22, fontWeight: FontWeight.w900,
                                color: Colors.black87)),
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: Text(
                          'We sent a password reset link to\n${forgotController.text.trim()}',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.josefinSans(
                              fontSize: 14, color: Colors.grey.shade500),
                        ),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity, height: 52,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black87,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30)),
                          ),
                          child: Text('Got it!',
                              style: GoogleFonts.josefinSans(
                                  fontSize: 15, fontWeight: FontWeight.w900)),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    ).whenComplete(() => forgotController.dispose());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Column(
              children: [
                _buildTopSection(constraints.maxHeight * 0.38),
                Expanded(child: _buildBottomSection()),
              ],
            );
          },
        ),
      ),
    );
  }

  // ── TOP SECTION ────────────────────────────────────────────────────────────
  Widget _buildTopSection(double height) {
    return Container(
      width: double.infinity, height: height,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
          colors: [Color(0xFFFCDDE8), Color(0xFFFFE8D2), Color(0xFFD4F0E4)],
          stops: [0.0, 0.5, 1.0],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: CustomPaint(
              size: const Size(double.infinity, 40),
              painter: _CurveClipper(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 60, 28, 20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: 150, height: 150,
                  child: ClipOval(
                    child: Image.asset('assets/images/logo.png',
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const SizedBox()),
                  ),
                ),
                const SizedBox(width: 20),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('furpals',
                        style: GoogleFonts.modak(
                            fontSize: 36, color: const Color(0xFF5C3D1E),
                            letterSpacing: 1)),
                    Text('Hello, welcome!',
                        style: GoogleFonts.josefinSans(
                            fontSize: 16, fontWeight: FontWeight.w800,
                            color: const Color(0xFF5C3D1E))),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── BOTTOM SECTION ─────────────────────────────────────────────────────────
  Widget _buildBottomSection() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Center(
            child: Text('Enter To Log In',
                style: GoogleFonts.josefinSans(
                    fontSize: 22, fontWeight: FontWeight.w900,
                    color: Colors.black87)),
          ),
          const SizedBox(height: 12),

          Text('Email or Username',
              style: GoogleFonts.josefinSans(
                  fontSize: 13, fontWeight: FontWeight.w700,
                  color: Colors.black87)),
          const SizedBox(height: 8),
          _buildInputField(
            controller: _emailController,
            hint: 'Enter Email or Username',
            prefixAsset: 'assets/icons/email_icon.png',
            fallbackIcon: Icons.mail_outline,
            keyboardType: TextInputType.emailAddress,
            hasError: _emailError,
          ),
          const SizedBox(height: 10),

          Text('Enter password',
              style: GoogleFonts.josefinSans(
                  fontSize: 13, fontWeight: FontWeight.w700,
                  color: Colors.black87)),
          const SizedBox(height: 8),
          _buildPasswordField(hasError: _passwordError),
          const SizedBox(height: 12),

          // Remember me + Forgot password
          Row(
            children: [
              GestureDetector(
                onTap: () => setState(() => _rememberMe = !_rememberMe),
                child: Row(
                  children: [
                    Container(
                      width: 22, height: 22,
                      decoration: BoxDecoration(
                        color: _rememberMe
                            ? const Color(0xFFE8445A)
                            : Colors.grey.shade200,
                        shape: BoxShape.circle,
                      ),
                      child: _rememberMe
                          ? const Icon(Icons.check, color: Colors.white, size: 14)
                          : null,
                    ),
                    const SizedBox(width: 6),
                    Text('Remember me',
                        style: GoogleFonts.josefinSans(
                            fontSize: 13, color: Colors.black54)),
                  ],
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: _showForgotPassword,
                child: Text('Forgot password?',
                    style: GoogleFonts.josefinSans(
                        fontSize: 13, color: Colors.black54,
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // LOG IN button
          SizedBox(
            width: double.infinity, height: 58,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _login,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEBD6BE),
                foregroundColor: Colors.black87,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 24, height: 24,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.5, color: Colors.black54))
                  : Text('🐾  LOG IN',
                      style: GoogleFonts.holtwoodOneSc(
                          fontSize: 20, fontWeight: FontWeight.w900,
                          letterSpacing: 1.5)),
            ),
          ),
          const SizedBox(height: 10),

          // Sign up
          Center(
            child: GestureDetector(
              onTap: () => Navigator.pushNamed(context, '/signup'),
              child: RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: 'First time here?  ',
                      style: GoogleFonts.josefinSans(
                          fontSize: 13, color: Colors.grey.shade500),
                    ),
                    TextSpan(
                      text: 'SIGN UP',
                      style: GoogleFonts.josefinSans(
                          fontSize: 13, fontWeight: FontWeight.w900,
                          color: Colors.black87),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Divider
          Row(
            children: [
              Expanded(child: Divider(color: Colors.grey.shade300)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text('Or continue with',
                    style: GoogleFonts.josefinSans(
                        fontSize: 12, color: Colors.grey.shade400)),
              ),
              Expanded(child: Divider(color: Colors.grey.shade300)),
            ],
          ),
          const SizedBox(height: 10),

          // Social buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _socialButton(
                assetPath: 'assets/icons/facebook_icon.png',
                fallbackColor: const Color(0xFF1877F2),
                fallbackIcon: Icons.facebook,
                onTap: () {},
              ),
              const SizedBox(width: 16),
              _googleButton(),
            ],
          ),
        ],
      ),
    );
  }

  // ── INPUT FIELD ────────────────────────────────────────────────────────────
  Widget _buildInputField({
    required TextEditingController controller,
    required String hint,
    required String prefixAsset,
    required IconData fallbackIcon,
    TextInputType keyboardType = TextInputType.text,
    bool hasError = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: hasError ? const Color(0xFFFFE4E4) : const Color(0xFFD9EEF3),
        borderRadius: BorderRadius.circular(30),
        border: hasError
            ? Border.all(color: const Color(0xFFE8445A), width: 1.5)
            : null,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Image.asset(prefixAsset, width: 22, height: 22,
              errorBuilder: (_, __, ___) => Icon(fallbackIcon,
                  color: hasError ? const Color(0xFFE8445A) : Colors.black,
                  size: 22)),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: keyboardType,
              onChanged: (_) {
                if (_emailError || _passwordError) {
                  setState(() {
                    _emailError    = false;
                    _passwordError = false;
                  });
                }
              },
              style: GoogleFonts.josefinSans(fontSize: 14),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: GoogleFonts.josefinSans(
                    color: hasError
                        ? const Color(0xFFE8445A).withOpacity(0.6)
                        : Colors.grey.shade700,
                    fontSize: 14),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── PASSWORD FIELD ─────────────────────────────────────────────────────────
  Widget _buildPasswordField({bool hasError = false}) {
    return Container(
      decoration: BoxDecoration(
        color: hasError ? const Color(0xFFFFE4E4) : const Color(0xFFD9EEF3),
        borderRadius: BorderRadius.circular(30),
        border: hasError
            ? Border.all(color: const Color(0xFFE8445A), width: 1.5)
            : null,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Image.asset('assets/icons/password_icon.png', width: 22, height: 22,
              errorBuilder: (_, __, ___) => Icon(Icons.key_outlined,
                  color: hasError ? const Color(0xFFE8445A) : Colors.black,
                  size: 22)),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              onChanged: (_) {
                if (_passwordError) {
                  setState(() => _passwordError = false);
                }
              },
              style: GoogleFonts.josefinSans(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Enter password',
                hintStyle: GoogleFonts.josefinSans(
                    color: hasError
                        ? const Color(0xFFE8445A).withOpacity(0.6)
                        : Colors.grey.shade700,
                    fontSize: 14),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => _obscurePassword = !_obscurePassword),
            child: Icon(
              _obscurePassword
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              color: hasError ? const Color(0xFFE8445A) : Colors.grey.shade700,
              size: 22),
          ),
        ],
      ),
    );
  }

  // ── SOCIAL BUTTON ──────────────────────────────────────────────────────────
  Widget _socialButton({
    required String assetPath,
    required Color fallbackColor,
    required IconData fallbackIcon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 52, height: 52,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: Center(
          child: Image.asset(assetPath, width: 28, height: 28,
              errorBuilder: (_, __, ___) =>
                  Icon(fallbackIcon, color: fallbackColor, size: 30)),
        ),
      ),
    );
  }

  // ── GOOGLE BUTTON ──────────────────────────────────────────────────────────
  Widget _googleButton() {
    return GestureDetector(
      onTap: () {},
      child: Container(
        width: 52, height: 52,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: Center(
          child: SizedBox(
            width: 26, height: 26,
            child: CustomPaint(painter: _GoogleLogoPainter()),
          ),
        ),
      ),
    );
  }
}

// ── GOOGLE LOGO PAINTER ────────────────────────────────────────────────────────
class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w / 2, h / 2);
    final radius = w / 2;

    canvas.clipPath(Path()..addOval(Rect.fromCircle(center: center, radius: radius)));
    canvas.drawCircle(center, radius, Paint()..color = Colors.white);

    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawArc(rect, 2.3, 1.6, true, Paint()..color = const Color(0xFF4285F4));
    canvas.drawArc(rect, 3.9, 1.6, true, Paint()..color = const Color(0xFFEA4335));
    canvas.drawArc(rect, 5.5, 0.85, true, Paint()..color = const Color(0xFFFBBC05));
    canvas.drawArc(rect, 0.0, 1.15, true, Paint()..color = const Color(0xFF34A853));
    canvas.drawCircle(center, radius * 0.55, Paint()..color = Colors.white);
    canvas.drawRect(
      Rect.fromLTWH(center.dx - radius * 0.05, center.dy - radius * 0.18,
          radius * 1.05, radius * 0.36),
      Paint()..color = Colors.white,
    );
    canvas.drawRect(
      Rect.fromLTWH(center.dx + radius * 0.18, center.dy - radius * 0.18,
          radius * 0.82, radius * 0.36),
      Paint()..color = const Color(0xFF34A853),
    );
    canvas.drawCircle(center, radius * 0.48, Paint()..color = Colors.white);
    canvas.drawCircle(center, radius * 0.45, Paint()..color = Colors.white);
    canvas.drawRect(
      Rect.fromLTWH(center.dx, center.dy - radius * 0.16,
          radius * 0.9, radius * 0.32),
      Paint()..color = const Color(0xFF4285F4),
    );
  }

  @override
  bool shouldRepaint(_) => false;
}

// ── CURVE PAINTER ──────────────────────────────────────────────────────────────
class _CurveClipper extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final fillPath = Path();
    fillPath.moveTo(0, size.height);
    fillPath.quadraticBezierTo(size.width / 2, -size.height, size.width, size.height);
    fillPath.lineTo(size.width, size.height);
    fillPath.close();
    canvas.drawPath(fillPath, Paint()..color = Colors.white);

    final strokePath = Path();
    strokePath.moveTo(0, size.height);
    strokePath.quadraticBezierTo(size.width / 2, -size.height, size.width, size.height);
    canvas.drawPath(
      strokePath,
      Paint()
        ..color = Colors.black87
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_) => false;
}