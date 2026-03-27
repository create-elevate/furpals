import 'package:flutter/material.dart';

// TODO: Uncomment when ready to navigate
// import '../login/login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // Controllers 
  late final AnimationController _logoCtrl;
  late final AnimationController _titleCtrl;
  late final AnimationController _floatCtrl;
  late final AnimationController _exitCtrl;

  // Animations 
  late final Animation<double> _logoScale;
  late final Animation<double> _logoFade;
  late final Animation<double> _titleFade;
  late final Animation<Offset> _titleSlide;
  late final Animation<double> _float;
  late final Animation<double> _exitFade;

  //  Config 
  static const Duration _splashDuration = Duration(seconds: 3);

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _runSequence();
  }

  void _setupAnimations() {
    _floatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
    _float = Tween<double>(begin: -10, end: 10).animate(
      CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut),
    );

    _logoCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _logoScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoCtrl, curve: Curves.elasticOut),
    );
    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoCtrl,
        curve: const Interval(0.0, 0.4, curve: Curves.easeIn),
      ),
    );

    _titleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _titleFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _titleCtrl, curve: Curves.easeIn),
    );
    _titleSlide = Tween<Offset>(
      begin: const Offset(0, 0.35),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _titleCtrl, curve: Curves.easeOut),
    );

    _exitCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _exitFade = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _exitCtrl, curve: Curves.easeIn),
    );
  }

  Future<void> _runSequence() async {
    await Future.delayed(const Duration(milliseconds: 300));
    _logoCtrl.forward();

    await Future.delayed(const Duration(milliseconds: 600));
    _titleCtrl.forward();

    await Future.delayed(_splashDuration);
    await _navigateToNext();
  }

  Future<void> _navigateToNext() async {
    if (!mounted) return;
    _floatCtrl.stop();
    await _exitCtrl.forward();
    if (!mounted) return;

    Navigator.of(context).pushReplacementNamed('/login');
  }

  @override
  void dispose() {
    _logoCtrl.dispose();
    _titleCtrl.dispose();
    _floatCtrl.dispose();
    _exitCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: _exitFade,
        builder: (_, child) => Opacity(
          opacity: _exitFade.value,
          child: child,
        ),
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFFFCDDE8),
                  Color(0xFFFFE8D2),
                  Color(0xFFD4F0E4)
              ],
              stops: [
                0.0,
                0.5,
                1.0,
              ],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Title 
              AnimatedBuilder(
                animation: _titleCtrl,
                builder: (_, _) => FadeTransition(
                  opacity: _titleFade,
                  child: SlideTransition(
                    position: _titleSlide,
                    child: const _FurpalsTitle(),
                  ),
                ),
              ),

              const SizedBox(height: 48),

              // Logo 
              AnimatedBuilder(
                animation: Listenable.merge([_logoCtrl, _floatCtrl]),
                builder: (_, _) => FadeTransition(
                  opacity: _logoFade,
                  child: ScaleTransition(
                    scale: _logoScale,
                    child: Transform.translate(
                      offset: Offset(0, _float.value),
                      child: const _Logo(),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

//  "furpals" title — Modak font
class _FurpalsTitle extends StatelessWidget {
  const _FurpalsTitle();

  @override
  Widget build(BuildContext context) {
    return const Text(
      'Furpals',
      style: TextStyle(
        fontFamily: 'Modak', // ← Modak for the title
        fontSize: 85,
        letterSpacing: 1.0,
        color: Color(0xFF7A5C3E),
      ),
    );
  }
}

// Logo
class _Logo extends StatelessWidget {
  const _Logo();

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/logo.png',
      width: 278,
      height: 278,
      fit: BoxFit.contain,
    );
  }
}