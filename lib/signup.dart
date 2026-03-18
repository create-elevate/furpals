import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';     // wala ka muna gagalawin dito  sa screen ate lyka kase my aayusin pa ako
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

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
class _AuthService { // backend service

  // this need to change to real server 
  static const _baseUrl = 'https://your-api.com/api';

  static Future<String> signUp({ // string required in input 
    required String fullName,
    required String email,
    required String nickname,
    required String password,
  }) async {
    final url = Uri.parse('$_baseUrl/auth/signup');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json', 
        'Accept':       'application/json', 
      },
      body: jsonEncode({
        'fullName': fullName,
        'email':    email,
        'nickname': nickname,
        'password': password,
        'agreements': {
          'eula':    true,
          'terms':   true,
          'privacy': true,
        },
      }),
    );
    
final body = jsonDecode(response.body) as Map<String, dynamic>; 
if (response.statusCode == 200 || response.statusCode == 201) {  // 200 or 201 ("OK" or "Created")
      return body['userId'] ?? 'unknown';
    }
    throw body['message'] ?? 'Sign up failed. Please try again.'; // server return if error
  }
}

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key}); 
  
  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}
class _SignUpScreenState extends State<SignUpScreen> {

  final _nameCtrl  = TextEditingController();   // hold what the user typed in each field
  final _emailCtrl = TextEditingController();
  final _nickCtrl  = TextEditingController();
  final _passCtrl  = TextEditingController();

  bool _showPass  = false; 
  bool _isLoading = false; 
  bool _eulaOk    = true;  
  bool _termsOk   = true;
  bool _privacyOk = true;

  String? _nameErr, _emailErr, _nickErr, _passErr; //Error messages the red thing

  @override
  void dispose() { // clear if closed
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _nickCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }
// input requirements
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

  Future<void> _onSubmit() async { // create acc btn part
    if (!_validate()) {     // checking if field are correct input
      _showToast('Almost there! Please fill in all required fields 🐾', isError: true);
      return;
    }
    // checking if agree in legal agree
    if (!_eulaOk || !_termsOk || !_privacyOk) {
      _showToast('Please agree to all legal agreements.', isError: true);
      return;
    }
    setState(() => _isLoading = true);// loading 

    try {
      final userId = await _AuthService.signUp(  // sending data to server
        fullName: _nameCtrl.text.trim(),
        email:    _emailCtrl.text.trim().toLowerCase(),
        nickname: _nickCtrl.text.trim(),
        password: _passCtrl.text,
      );
      // success/ accept
      if (mounted) {
        _showToast('🐾 Welcome to furpals! (ID: $userId)');
        Navigator.of(context).pushReplacementNamed('/home');
      }
    } catch (e) {
      if (mounted) _showToast(e.toString(), isError: true);
      
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  //snack bar for accept or error message 
  void _showToast(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message,
          style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
        backgroundColor: isError ? _C.error : _C.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(50)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
  // legal agree frame content and function
  void _openLegal(String title, String content) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _LegalModal(title: title, content: content),
    );
  }
  @override // bg whole frame
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

  Widget _buildHeader() { // logo and title
    return Row(
      children: [
        Image.asset(
                    'assets/images/logo.png',
                    width: 130,
                    height: 130,
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('furpals',
                style: GoogleFonts.modak(
                  fontSize: 50, color: const Color(0xFF4A3728),),),
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

  Widget _buildFormCard() { // create acc content
    return _Card(
      child: Column(
        children: [
          Text('Create Account',
            style: GoogleFonts.josefinSans(fontSize: 24, fontWeight: FontWeight.w700, color: _C.dark, )),
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
            onToggleVisibility: () =>
                setState(() => _showPass = !_showPass),
            onChanged: (_) => setState(() => _passErr = null),
          ),
          const SizedBox(height: 30),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Already have an account? ',
                style: GoogleFonts.nunito(
                  fontSize: 14, fontWeight: FontWeight.w500,
                  color: _C.grey)),
              GestureDetector(
                onTap: () {
                  Navigator.of(context).pushNamed('/login');
                },
                child: Text('LOG IN', // log in btn
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

  Widget _buildLegalCard() { // legal agree frame
    return _Card(
      child: Column(
        children: [
          Text('Legal Agreements',
            style: GoogleFonts.josefinSans(fontSize: 22, fontWeight: FontWeight.w700, color: _C.dark)),
          const SizedBox(height: 16),

          _LegalRow(
            checked: _eulaOk,
            onToggle: () => setState(() => _eulaOk = !_eulaOk),
            linkText: 'End User License Agreement (EULA)',
            onLinkTap: () => _openLegal(
              'End-user License Agreement', _eulaText),
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

  Widget _buildCreateButton() { // create btn
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
            BoxShadow(
              color: Colors.black,
              offset: Offset(3, 3),
              blurRadius: 0,
            ),
          ],
        ),
        child: Center( 
          child: _isLoading
              ? const SizedBox(
                  width: 24, height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5, color: Colors.black54))
              : Text('CREATE ACCOUNT',
                  style: GoogleFonts.holtwoodOneSc(
                    fontSize: 17, letterSpacing: 3, color: _C.dark)),
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget { // create acc frame
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
          BoxShadow(
            color: Colors.black,
            offset: Offset(3, 3),
            blurRadius: 0,
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(22, 28, 22, 20),
      child: child,
    );
  }
}

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
            color: const Color (0xFF4A3728)),),
        const SizedBox(height: 6),

        // input box
        Container(
          height: 54,
          decoration: BoxDecoration(
            color: const Color (0xFFD6EBF0),
            borderRadius: BorderRadius.circular(50),
            border: Border.all( // this thing show when error input
              color: errorText != null ? _C.error : Colors.transparent,
              width: 2,
            ),
          ),
          child: Row(
            children: [
              // password icon
              Padding(
                padding: const EdgeInsets.only(left: 16, right: 10),
                child: Icon(icon, size: 22,
                  color: const Color(0xFF444444)),
              ),

              // Text input 
              Expanded(
                child: TextField(
                  controller: controller,
                  onChanged: onChanged,
                  obscureText: isPassword && !isVisible,
                  keyboardType: keyboardType,
                  style: GoogleFonts.nunito(
                    fontSize: 15, fontWeight: FontWeight.w600,
                    color: _C.dark),
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: GoogleFonts.baloo2(
                      fontSize: 15, fontWeight: FontWeight.w500,
                      color: _C.grey),
                    border: InputBorder.none, 
                    isDense: true,
                    contentPadding:
                      const EdgeInsets.symmetric(vertical: 4),
                  ),
                ),
              ),
              if (showEye)    // Eye icon 
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

        // Red error text below the field
        if (errorText != null) ...[
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 14),
            child: Text(errorText!,
              style: GoogleFonts.nunito(
                fontSize: 12, fontWeight: FontWeight.w700,
                color: _C.error)),
          ),
        ],
      ],
    );
  }
}

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
  Widget build(BuildContext context) { // legala agree content
    return GestureDetector(
      onTap: onToggle, 
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          AnimatedContainer( // black + checkmark 
            duration: const Duration(milliseconds: 180),
            width: 36, height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: checked ? _C.dark : _C.white,
              border: Border.all(color: _C.dark, width: 2.5),
            ),
            child: checked
                ? const Icon(Icons.check,
                    color: Colors.white, size: 20)
                : null,
          ),
          const SizedBox(width: 14), // agree text with link
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
                      decorationColor: _C.blue,
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = onLinkTap,
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
// frame for legal agree 
class _LegalModal extends StatelessWidget {
  final String title, content;
  const _LegalModal({required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.80,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          Container(// White header with title
            padding: const EdgeInsets.fromLTRB(22, 20, 22, 14),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(
                  color: Color(0xFFEEEEEE), width: 1.5)),
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(28)),
            ),
            child: Text(title,
              textAlign: TextAlign.center,
              style: GoogleFonts.baloo2(
                fontSize: 18, color: _C.dark)),
          ),

          // content frame
          Expanded(
            child: Container(
              color: _C.modalBg,
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      padding: const EdgeInsets.all(18),
                      child: SingleChildScrollView(
                        child: Text(content,
                          style: GoogleFonts.nunito(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF555555),
                            height: 1.7)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // close btn
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: double.infinity,
                      height: 50,
                      decoration: BoxDecoration(
                        color: _C.btnClose,
                        borderRadius: BorderRadius.circular(50),
                        border: Border.all(
                          color: _C.dark, width: 2.5),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black,
                            offset: Offset(2, 2),
                            blurRadius: 0,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text('CLOSE',
                          style: GoogleFonts.baloo2(
                            fontSize: 16, letterSpacing: 2,
                            color: _C.dark)),
                      ),
                    ),
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

const _eulaText = '''
1. Acceptance of Terms
By creating an account on furpals, you agree to be bound by this End-User License Agreement. If you do not agree, please do not use the application.

2. License Grant
furpals grants you a limited, non-exclusive, non-transferable license to use the application solely for personal, non-commercial purposes.

3. Restrictions
You may not copy, modify, distribute, sell, or lease any part of our services. Reverse engineering or extracting source code is prohibited.

4. Content Ownership
You retain ownership of content you post. By posting, you grant furpals a license to display and distribute your content within the platform.

5. Termination
This license terminates if you violate any of these restrictions. Upon termination you must cease all use of the application.

6. Disclaimer
The application is provided "as is" without warranties of any kind, either express or implied.
''';

const _termsText = '''
1. Eligibility
You must be at least 13 years old to use furpals. By using our services, you represent that you meet this requirement.

2. Your Account
You are responsible for maintaining the confidentiality of your account credentials and for all activities under your account.

3. Community Guidelines
Be kind and respectful to all pet lovers. Content promoting animal abuse, harassment, or hate speech will result in immediate account termination.

4. Prohibited Activities
Spamming, phishing, impersonating other users, or attempting to access other accounts are strictly prohibited.

5. Modifications
We reserve the right to modify these terms at any time. Continued use constitutes acceptance of updated terms.
''';

const _privacyText = '''
1. Information We Collect
We collect information you provide (name, email, nickname) and usage data to improve our service.

2. How We Use It
Your information personalizes furpals, enables notifications, and helps us improve features.

3. Data Sharing
We do not sell your personal data. We may share anonymized data for analytics purposes.

4. Data Security
We implement industry-standard security measures to protect your data.

5. Your Rights
You may request access to, correction of, or deletion of your data at any time by contacting support.

6. Cookies
We use cookies to maintain your session and preferences.
''';