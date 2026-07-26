import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BadgesScreen extends StatelessWidget {
  final String userName;
  const BadgesScreen({super.key, required this.userName});

  // --- BADGE DATA ---
  final List<Map<String, dynamic>> badges = const [
    {"name": "Seedling", "points": 0, "icon": Icons.eco_outlined, "color": Colors.brown},
    {"name": "Sprout Saver", "points": 50, "icon": Icons.local_florist, "color": Colors.green},
    {"name": "Water Warrior", "points": 100, "icon": Icons.water_drop, "color": Colors.blue},
    {"name": "Green Thumb", "points": 250, "icon": Icons.nature_people, "color": Colors.teal},
    {"name": "Garden Master", "points": 500, "icon": Icons.emoji_events, "color": Colors.amber},
  ];

  @override
  Widget build(BuildContext context) {
    // 🚨 RESPONSIVE FIX: Grab device dimensions
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    // 🚨 RESPONSIVE FIX: Calculate Grid layout dynamically
    // If it's a tablet (width > 600), show 3 columns. Otherwise, 2 columns.
    int columns = screenWidth > 600 ? 3 : 2;
    double horizontalPadding = 40; // 20 left + 20 right
    double spacing = 15;

    // Calculate the exact width of one card
    double availableWidth = screenWidth - horizontalPadding - (spacing * (columns - 1));
    double itemWidth = availableWidth / columns;

    // Card height is always 18% of the screen height (keeps it looking premium, never stretched)
    double itemHeight = screenHeight * 0.18;
    if (itemHeight < 140) itemHeight = 140; // Safety floor for tiny phones

    // Generate the perfect aspect ratio for this specific device
    double dynamicAspectRatio = itemWidth / itemHeight;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F7FA),
        elevation: 0,
        title: const Text("Your Badges", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 22)),
      ),
      body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('users').where('name', isEqualTo: userName).snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

            int currentPoints = 0;
            if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
              final data = snapshot.data!.docs.first.data() as Map<String, dynamic>;
              currentPoints = data['points'] ?? 0;
            }

            Map<String, dynamic>? nextBadge;
            for (var badge in badges) {
              if (badge['points'] > currentPoints) {
                nextBadge = badge;
                break;
              }
            }

            return Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- POINTS HEADER ---
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF2EF889), Color(0xFF1CB063)]),
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [BoxShadow(color: Colors.green.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Total Points", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                            Text("$currentPoints XP", style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                          child: const Icon(Icons.stars_rounded, color: Colors.white, size: 40),
                        )
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // --- PROGRESS TO NEXT BADGE ---
                  if (nextBadge != null) ...[
                    Text("Next Milestone: ${nextBadge['name']} (${nextBadge['points']} XP)", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: currentPoints / nextBadge['points'],
                        backgroundColor: Colors.grey[300],
                        color: const Color(0xFF2EF889),
                        minHeight: 12,
                      ),
                    ),
                    const SizedBox(height: 30),
                  ],

                  const Text("Achievement Board", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0D1C2E))),
                  const SizedBox(height: 15),

                  // --- BADGES GRID ---
                  Expanded(
                    child: GridView.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        // 🚨 RESPONSIVE FIX: Injects our calculated dynamic values here
                        crossAxisCount: columns,
                        crossAxisSpacing: spacing,
                        mainAxisSpacing: spacing,
                        childAspectRatio: dynamicAspectRatio,
                      ),
                      itemCount: badges.length,
                      itemBuilder: (context, index) {
                        final badge = badges[index];
                        bool isUnlocked = currentPoints >= badge['points'];

                        return Container(
                          decoration: BoxDecoration(
                            color: isUnlocked ? Colors.white : Colors.grey[200],
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: isUnlocked ? badge['color'].withOpacity(0.5) : Colors.transparent, width: 2),
                            boxShadow: isUnlocked ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))] : [],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                  isUnlocked ? badge['icon'] : Icons.lock_outline,
                                  size: 50,
                                  color: isUnlocked ? badge['color'] : Colors.grey[400]
                              ),
                              const SizedBox(height: 10),
                              Text(
                                  badge['name'],
                                  style: TextStyle(fontWeight: FontWeight.bold, color: isUnlocked ? Colors.black87 : Colors.grey[500], fontSize: 14)
                              ),
                              const SizedBox(height: 5),
                              Text(
                                  "${badge['points']} XP",
                                  style: TextStyle(color: isUnlocked ? badge['color'] : Colors.grey[400], fontWeight: FontWeight.bold, fontSize: 12)
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          }
      ),
    );
  }
}