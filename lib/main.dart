import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:furpals/calendar.dart';
import 'package:furpals/lost&found.dart';
import 'package:furpals/signup.dart';
import 'package:furpals/login.dart';
import 'package:furpals/Homescreen.dart';
import 'package:furpals/splash_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:furpals/NotificationScreen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});


   @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Furpals',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        textTheme: GoogleFonts.nunitoTextTheme(), 
      ),
      initialRoute: '/',
      routes: {
        '/':      (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
       '/signup': (context) => const SignUpScreen(),
    '/home': (context) => const Homescreen(),
    '/notifications': (context) => const NotificationScreen(),
    '/lost&found': (context) => const LostFoundScreen(),
    '/calendar': (context) => const CalendarScreen(),
      },
    );
  }
}

