import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:furpals/lf_add_missing.dart';
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
import 'package:furpals/profilescreen.dart';
import 'package:furpals/mypets.dart';
import 'package:furpals/medicalrecords.dart';
import 'package:furpals/vaccinationcard.dart';
import 'package:furpals/prescriptionscreen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:furpals/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await runZonedGuarded(() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Initialize notifications
    await NotificationService.initialize();

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
        '/missing': (context) => const AddMissingPetScreen(),
      '/petmanagement': (context) => const PetsScreen(),
    '/newappointment': (context) => const CalendarScreen(
  pets: [],

),
    '/addevent': (context) => AddEventScreen(

  onAdd: (newEvent) {
    
  },
  onUpdate: (updatedEvent) {
    
  },
),  
    '/profilescreen': (context) => const ProfileScreen(),
    '/mypets': (context) => const myPetsScreen(),
    '/medicalrecords': (context) {
  final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>? ?? {};
  return MedicalRecordsScreen(
    currentUid: args['currentUid'] as String? ?? '',
    petId: args['petId'] as String? ?? '',
    petName: args['petName'] as String? ?? '',
  );
},
'/vaccinationcard': (context) {
  final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>? ?? {};
  return VaccinationCardScreen(
    currentUid: args['currentUid'] as String? ?? '',
    petId: args['petId'] as String? ?? '',
    petName: args['petName'] as String? ?? '',
  );
},
'/prescriptionscreen': (context) {
  final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>? ?? {};
  return PrescriptionScreen(
    currentUid: args['currentUid'] as String? ?? '',
    petId: args['petId'] as String? ?? '',
    petName: args['petName'] as String? ?? '',
  );
},
      },
    
    );
 
 

  }
}