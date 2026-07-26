import 'package:flutter/material.dart';
import 'QuizScreen.dart';

class PlayScreen extends StatelessWidget {
  final String userName;
  const PlayScreen({super.key, required this.userName});

  @override
  Widget build(BuildContext context) {
    // 🚨 RESPONSIVE FIX: Grab the device's screen height
    double screenHeight = MediaQuery.of(context).size.height;

    // Calculate dynamic height for the top game card (32% of the screen)
    double cardHeight = screenHeight * 0.32;
    // Safety check: Don't let it get too squished on very small phones
    if (cardHeight < 200) cardHeight = 200;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F7FA),
        elevation: 0,
        title: const Text("Garden Arcade", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 22)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // --- 1. TRIVIA GAME CARD ---
            GestureDetector(
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => QuizScreen(userName: userName)));
              },
              child: Container(
                height: cardHeight, // 🚨 RESPONSIVE FIX applied here
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(25),
                  image: const DecorationImage(
                    image: AssetImage('assests/sunflower.png'),
                    fit: BoxFit.cover,
                  ),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 15, offset: const Offset(0, 5))],
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(25),
                    gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black.withOpacity(0.8)]),
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Align(
                        alignment: Alignment.topRight,
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.3), shape: BoxShape.circle),
                          child: const Icon(Icons.play_arrow_rounded, color: Colors.white),
                        ),
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(color: Colors.amber, borderRadius: BorderRadius.circular(8)),
                            child: const Text("QUIZ", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10)),
                          ),
                          const SizedBox(width: 10),
                          const Text("4 Questions", style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 12)),
                        ],
                      ),
                      const SizedBox(height: 5),
                      const Text("Garden Trivia", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                      const Text("Test your plant knowledge!", style: TextStyle(color: Colors.white70, fontSize: 14)),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // --- 2. MATCHING GAME CARD ---
            // Because this is Expanded, it beautifully scales to fill the rest of the screen!
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.style, size: 50, color: Colors.grey[300]),
                    const SizedBox(height: 15),
                    Text("Plant Match", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[400])),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(20)),
                      child: Text("COMING SOON", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey[500])),
                    )
                  ],
                ),
              ),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}