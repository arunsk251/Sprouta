import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'mainscreen.dart';
import 'HomeScreen.dart';
import 'Notification_service.dart';
import 'SplashScreen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  // 1. Ensure Flutter bindings are initialized before calling async functions
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  // 2. Initialize Firebase and Notifications
  await Firebase.initializeApp();
  await NotificationService.init();

  // 3. Get SharedPreferences
  final prefs = await SharedPreferences.getInstance();

  // 🚨 THE FIX IS HERE: The '?? false' and '?? true' are required!
  // This tells Flutter: "If this is null, use false/true instead."
  final bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
  final bool isFirstTime = prefs.getBool('isFirstTime') ?? true;

  // 4. Run the app and pass the guaranteed boolean values
  runApp(MyApp(startHome: isLoggedIn, isFirstTime: isFirstTime));
}

class MyApp extends StatelessWidget {
  final bool startHome;
  final bool isFirstTime;

  // 🚨 Make sure the word 'required' is here for both variables!
  const MyApp({super.key, required this.startHome, required this.isFirstTime});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Plant Buddy',
      theme: ThemeData(
        primarySwatch: Colors.green,
        scaffoldBackgroundColor: Colors.white,
      ),
      // Pass the variables safely to the Splash Screen
      home: SplashScreen(startHome: startHome, isFirstTime: isFirstTime),
    );
  }
}