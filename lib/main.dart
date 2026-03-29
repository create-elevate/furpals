import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:furpals/lost&found.dart';
import 'package:furpals/lostfoundprofile.dart';
import 'package:furpals/signup.dart';
import 'package:furpals/login.dart';
import 'package:furpals/Homescreen.dart';
import 'package:furpals/splash_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:furpals/NotificationScreen.dart';
import 'package:furpals/petmanagement.dart';
import 'package:furpals/newappointment.dart';
import 'package:furpals/addevent.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await runZonedGuarded(() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.dumpErrorToConsole(details);
      // Optionally report to analytics
    };

    runApp(const MyApp());
  }, (error, stackTrace) {
    debugPrint('Uncaught zone error: $error');
    debugPrint('$stackTrace');
    // Optionally report to analytics/Crashlytics here.
  });
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
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignUpScreen(),
        '/home': (context) => const Homescreen(),
        '/notifications': (context) => const NotificationScreen(),
        '/lf':(context) => const LostFoundScreen(),
        '/lostandfoundprofile': (context)=> const LostFoundProfileScreen(pet: {},),
      
      '/petmanagement': (context) => const PetsScreen(),
    '/newappointment': (context) => const CalendarScreen(
  pets: [],
  existingAppointmentCount: 0,
),
    '/addevent': (context) => AddEventScreen(
  existingEventCount: 0,
  onAdd: (newEvent) {
    
  },
  onUpdate: (updatedEvent) {
    
  },
),  
      },
);
  }
}