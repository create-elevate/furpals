import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:furpals/signup.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {

  late final AnimationController _headerCtrl;
  late final AnimationController _cardCtrl;
  late final AnimationController _fieldCtrl;
  late final AnimationController _buttonCtrl;


  late final Animation<double> _headerFade;
  late final Animation<Offset> _headerSlide;
  late final Animation<double> _cardFade;
  late final Animation<Offset> _cardSlide;
  late final Animation<double> _field1Fade;
  late final Animation<Offset> _field1Slide;
  late final Animation<double> _field2Fade;
  late final Animation<Offset> _field2Slide;
  late final Animation<double> _buttonFade;
  late final Animation<Offset> _buttonSlide;
  late final Animation<double> _socialFade;

 
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberMe = false;
  bool _isLoading = false;

  
  static const Color _fieldFillColor = Color(0xFFEEF4F8);
  static const Color _fieldFocusedBorderColor = Color(0xFFD4A96A);
  static const Color _socialBorderColor = Colors.black;
  static const double _loginButtonWidth = 180;
  static const double _loginButtonHeight = 54;
  

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _runSequence();
  }

  void _setupAnimations() {
    _headerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _headerFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _headerCtrl, curve: Curves.easeIn),
    );
    _headerSlide = Tween<Offset>(
      begin: const Offset(0, -0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _headerCtrl, curve: Curves.easeOut));

    _cardCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _cardFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _cardCtrl, curve: Curves.easeIn),
    );
    _cardSlide = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _cardCtrl, curve: Curves.easeOut));

    _fieldCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _field1Fade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _fieldCtrl,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );
    _field1Slide = Tween<Offset>(
      begin: const Offset(0.3, 0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _fieldCtrl,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );
    _field2Fade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _fieldCtrl,
        curve: const Interval(0.3, 1.0, curve: Curves.easeIn),
      ),
    );
    _field2Slide = Tween<Offset>(
      begin: const Offset(0.3, 0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _fieldCtrl,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
      ),
    );

    _buttonCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _buttonFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _buttonCtrl,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );
    _buttonSlide = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _buttonCtrl,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
      ),
    );
    _socialFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _buttonCtrl,
        curve: const Interval(0.4, 1.0, curve: Curves.easeIn),
      ),
    );
  }

  Future<void> _runSequence() async {
    await Future.delayed(const Duration(milliseconds: 100));
    _headerCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 250));
    _cardCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 300));
    _fieldCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 400));
    _buttonCtrl.forward();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 2)); // need i replace with real auth
    if (mounted) setState(() => _isLoading = false);
    Navigator.of(context).pushReplacementNamed('/home'); 
    //navigate to home
  }

  @override
  void dispose() {
    _headerCtrl.dispose();
    _cardCtrl.dispose();
    _fieldCtrl.dispose();
    _buttonCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Container(
        //tricolor gradient background 
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: [0.0, 0.5, 1.0],
            colors: [
              Color(0xFFFCDDE8), // 0%   — pink
              Color(0xFFFFE8D2), // 50%  — peach
              Color(0xFFD4F0E4), // 100% — mint green
            ],
          ),
        ),
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Column(
            children: [
              
              _buildHeader(),

              // white card expand
              Expanded(child: _buildCard()),
            ],
          ),
        ),
      ),
    );
  }

  // header login
  Widget _buildHeader() {
    return AnimatedBuilder(
      animation: _headerCtrl,
      builder: (_, _) => FadeTransition(
        opacity: _headerFade,
        child: SlideTransition(
          position: _headerSlide,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.only(
                left: 24,
                right: 24,
                top: 16,
                bottom: 24,
              ),
              child: Row(
                children: [
                  Image.asset(
                    'assets/images/logo.png',
                    width: 130,
                    height: 130,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'furpals',
                        style: GoogleFonts.modak(
                          fontSize: 40,
                          color: const Color(0xFF3A2510),
                          shadows: const [
                            Shadow(
                              blurRadius: 0,
                              offset: Offset(1, 2),
                              color: Color(0x40000000),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        'Hello, welcome!',
                        style: GoogleFonts.lilitaOne(
                          fontSize: 16,
                          color: const Color(0xFF3A2510),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // white card 
  Widget _buildCard() {
    return AnimatedBuilder(
      animation: _cardCtrl,
      builder: (_, child) => FadeTransition(
        opacity: _cardFade,
        child: SlideTransition(position: _cardSlide, child: child),
      ),
      child: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(80),
            topRight: Radius.circular(80),
          ),
          border: Border(
            top: BorderSide(color: Colors.black, width: 1.5),
            left: BorderSide(color: Colors.black, width: 1.5),
            right: BorderSide(color: Colors.black, width: 1.5),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(28, 32, 28, 24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                //title
                Center(
                  child: Text(
                    'Enter To Log In',
                    style: GoogleFonts.josefinSans(
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                      color: const Color(0xFF3A2510),
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                // email field
                AnimatedBuilder(
                  animation: _fieldCtrl,
                  builder: (_, _) => FadeTransition(
                    opacity: _field1Fade,
                    child: SlideTransition(
                      position: _field1Slide,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Email or Username',
                            style: GoogleFonts.josefinSans(
                              fontSize: 16,
                              color: const Color(0xFF000000),
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildTextField(
                            controller: _emailCtrl,
                            hint: 'Enter Email or Username',
                            prefixIcon: Icons.email_outlined,
                            validator: (v) =>
                                v == null || v.isEmpty ? 'Required' : null,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // password field
                AnimatedBuilder(
                  animation: _fieldCtrl,
                  builder: (_, _) => FadeTransition(
                    opacity: _field2Fade,
                    child: SlideTransition(
                      position: _field2Slide,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Enter password',
                            style: GoogleFonts.josefinSans(
                              fontSize: 16,
                              color: const Color(0xFF000000),
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildTextField(
                            controller: _passwordCtrl,
                            hint: 'Enter Password',
                            prefixIcon: Icons.lock_outline,
                            obscure: _obscurePassword,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: const Color(0xFF9B8070),
                                size: 20,
                              ),
                              onPressed: () => setState(
                                  () => _obscurePassword = !_obscurePassword),
                            ),
                            validator: (v) =>
                                v == null || v.isEmpty ? 'Required' : null,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // remember me at forgot pass
                AnimatedBuilder(
                  animation: _buttonCtrl,
                  builder: (_, _) => FadeTransition(
                    opacity: _buttonFade,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // remember me
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () => setState(
                                  () => _rememberMe = !_rememberMe),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  color: _rememberMe
                                      ? const Color(0xFFD4A96A)
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: _rememberMe
                                        ? const Color(0xFFD4A96A)
                                        : const Color(0xFFCCBBAA),
                                    width: 2,
                                  ),
                                ),
                                child: _rememberMe
                                    ? const Icon(Icons.check,
                                        size: 14, color: Colors.white)
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Remember me',
                              style: GoogleFonts.josefinSans(
                                fontSize: 13,
                                color: const Color(0xFF6B4C36),
                              ),
                            ),
                          ],
                        ),

                        // forgot password
                        GestureDetector(
                          onTap: () {
                            // TODO: Navigator.of(context).pushNamed('/forgot-password');
                            //navigate to FG
                          },
                          child: Text(
                            'Forgot password?',
                            style: GoogleFonts.josefinSans(
                              fontSize: 13,
                              color: const Color(0xFF6B4C36),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                //log in btn
                AnimatedBuilder(
                  animation: _buttonCtrl,
                  builder: (_, _) => FadeTransition(
                    opacity: _buttonFade,
                    child: SlideTransition(
                      position: _buttonSlide,
                      child: Center(
                        child: SizedBox(
                          width: _loginButtonWidth,
                          height: _loginButtonHeight,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleLogin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFEBD6BE),
                              foregroundColor: const Color(0xFF3A2510),
                              disabledBackgroundColor:
                                  const Color(0xFFD4A96A).withOpacity(0.6),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(32),
                              ),
                              elevation: 3,
                              shadowColor:
                                  const Color(0xFFD4A96A).withOpacity(0.5),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: Color(0xFF3A2510),
                                    ),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.pets,
                                          size: 18,
                                          color: Color(0xFF3A2510)),
                                      const SizedBox(width: 6),
                                      Text(
                                        'LOG IN',
                                        style: GoogleFonts.holtwoodOneSc(
                                          fontSize: 16,
                                          letterSpacing: 1.5,
                                          color: const Color(0xFF3A2510),
                                          
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // sign up btn
                AnimatedBuilder(
                  animation: _buttonCtrl,
                  builder: (_, _) => FadeTransition(
                    opacity: _buttonFade,
                    child: Center(
                      child: GestureDetector(
                        onTap: () =>
                            Navigator.of(context).pushNamed('/signup'),
                        child: RichText(
                          text: TextSpan(
                            style: GoogleFonts.josefinSans(
                              fontSize: 13,
                              color: const Color(0xFF9B8070),
                            ),
                            children: [
                              const TextSpan(text: 'First time here?  '),
                              TextSpan(
                                text: 'SIGN UP',
                                style: GoogleFonts.josefinSans(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 13,
                                  color: const Color(0xFF3A2510),
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // continue 
                AnimatedBuilder(
                  animation: _buttonCtrl,
                  builder: (_, _) => FadeTransition(
                    opacity: _socialFade,
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Expanded(
                                child: Divider(color: Color(0xFFCCBBAA))),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              child: Text(
                                'Or continue with',
                                style: GoogleFonts.josefinSans(
                                  fontSize: 12,
                                  color: const Color(0xFF9B8070),
                                ),
                              ),
                            ),
                            const Expanded(
                                child: Divider(color: Color(0xFFCCBBAA))),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Social buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Facebook
                            _SocialButton(
                              onTap: () {
                                // TODO: Facebook login
                              },
                              child: Container(
                                width: 52,
                                height: 52,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: _socialBorderColor,
                                    width: 1.5,
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.asset(
                                    'assets/images/fb_icon.png',
                                    width: 40,
                                    height: 40,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(width: 20),

                            // Google
                            _SocialButton(
                              onTap: () {
                                // TODO: Google login
                              },
                              child: Container(
                                width: 52,
                                height: 52,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: _socialBorderColor,
                                    width: 1.5,
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.asset(
                                    'assets/images/google_icon.png',
                                    width: 30,
                                    height: 30,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData prefixIcon,
    bool obscure = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      validator: validator,
      style: const TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 14,
        color: Color(0xFF3A2510),
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 14,
          color: Color(0xFFB0A090),
        ),
        prefixIcon:
            Icon(prefixIcon, color: const Color(0xFF9B8070), size: 20),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: _fieldFillColor,
        contentPadding:
            const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(32),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(32),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(32),
          borderSide: BorderSide(
            color: _fieldFocusedBorderColor,
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(32),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(32),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
      ),
    );
  }
}

// ── Social button with press effect ─────────────────────────────────────────
class _SocialButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const _SocialButton({required this.child, required this.onTap});

  @override
  State<_SocialButton> createState() => _SocialButtonState();
}

class _SocialButtonState extends State<_SocialButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 0.9,
      upperBound: 1.0,
      value: 1.0,
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.reverse(),
      onTapUp: (_) {
        _ctrl.forward();
        widget.onTap();
      },
      onTapCancel: () => _ctrl.forward(),
      child: ScaleTransition(scale: _ctrl, child: widget.child),
    );
  }
}