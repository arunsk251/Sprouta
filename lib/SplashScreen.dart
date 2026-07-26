import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'mainscreen.dart';
import 'HomeScreen.dart';
import 'OnboardingScreen.dart'; // <--- NEW IMPORT

class SplashScreen extends StatefulWidget {
  final bool startHome;
  final bool isFirstTime; // <--- NEW PARAMETER

  const SplashScreen({super.key, required this.startHome, required this.isFirstTime});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late VideoPlayerController _controller;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();

    _controller = VideoPlayerController.asset('assests/ss_vid.mp4')
      ..initialize().then((_) {
        setState(() {});
        _controller.play();
      });

    _controller.addListener(() {
      if (_controller.value.isInitialized &&
          !_controller.value.isPlaying &&
          _controller.value.position >= _controller.value.duration) {

        if (!_hasNavigated) {
          _hasNavigated = true;
          _navigateToNextScreen();
        }
      }
    });
  }

  void _navigateToNextScreen() {
    // 🚨 THE NEW NAVIGATION LOGIC 🚨
    Widget nextScreen;

    if (widget.isFirstTime) {
      nextScreen = const OnboardingScreen(); // Show Guide
    } else if (widget.startHome) {
      nextScreen = const Homescreen(); // Show Home
    } else {
      nextScreen = const PlantBuddyLoginScreen(); // Show Login
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => nextScreen),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Match this to your video's background color
      body: Center(
        child: _controller.value.isInitialized
            ? SizedBox(
          // Change this number to make the logo bigger or smaller!
          // 250 is usually a great size for a centered logo.
          width: 300,
          child: AspectRatio(
            // This keeps the video from stretching or squishing
            aspectRatio: _controller.value.aspectRatio,
            child: VideoPlayer(_controller),
          ),
        )
            : const SizedBox(),
      ),
    );
  }
}