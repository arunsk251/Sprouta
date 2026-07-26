import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'HomeScreen.dart'; // Ensure this matches your filename

class AddPlantScreen extends StatefulWidget {
  const AddPlantScreen({super.key});

  @override
  State<AddPlantScreen> createState() => _AddPlantScreenState();
}

class _AddPlantScreenState extends State<AddPlantScreen> {
  String selectedPlant = "Tomato";
  final TextEditingController _plantNameController = TextEditingController();
  bool isLoading = false;

  final List<Map<String, dynamic>> plantTypes = [
    {'name': 'Tomato', 'desc': 'Yummy red snacks.', 'image': 'assests/5.png', 'isAvailable': true},
    {'name': 'Sunflower', 'desc': 'Loves the sun!', 'image': 'assests/logo.jpg', 'isAvailable': false},
    {'name': 'Spinach', 'desc': 'Leafy greens.', 'image': 'assests/logo.jpg','isAvailable': false},
  ];

  Future<void> _savePlantToFirebase() async {
    String plantName = _plantNameController.text.trim();
    if (plantName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please name your plant! 🌱")));
      return;
    }

    setState(() => isLoading = true);

    try {
      String plantImage = plantTypes.firstWhere(
            (plant) => plant['name'] == selectedPlant,
        orElse: () => plantTypes[0],
      )['image'] as String;

      final prefs = await SharedPreferences.getInstance();
      final String? userName = prefs.getString('userName');

      if (userName != null) {
        final querySnapshot = await FirebaseFirestore.instance
            .collection('users')
            .where('name', isEqualTo: userName)
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          final userDocId = querySnapshot.docs.first.id;

          final newPlantData = {
            'name': plantName,
            'type': selectedPlant,
            'image': plantImage,
            'level': 1,
            'xp': 0,
            'status': 'Unknown',
            'stage': 'Seed',
            'dateAdded': Timestamp.now(),
          };

          await FirebaseFirestore.instance.collection('users').doc(userDocId).update({
            'plants': FieldValue.arrayUnion([newPlantData])
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Plant added successfully! 🍅")));
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const Homescreen()),
                  (route) => false,
            );
          }
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // 🚨 RESPONSIVE FIX: Get device dimensions to scale UI perfectly
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    // Calculate dynamic sizes for the cards to fit any screen
    double cardHeight = screenHeight * 0.25;
    if (cardHeight < 190) cardHeight = 190; // Prevent cards from getting too tiny on small phones

    double cardWidth = screenWidth * 0.35;
    if (cardWidth < 120) cardWidth = 120;

    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.06, vertical: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.topLeft,
                child: IconButton(
                  icon: const Icon(Icons.close, size: 30),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              const Center(child: Text("Add New Plant", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold))),
              const SizedBox(height: 30),

              const Center(child: Text("1. PICK A SEED", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, letterSpacing: 1.2))),
              const SizedBox(height: 20),

              // 🚨 RESPONSIVE FIX: Height adapts to screen size instead of hardcoded 180
              SizedBox(
                height: cardHeight,
                child: Center(
                  child: ListView.builder(
                    shrinkWrap: true,
                    scrollDirection: Axis.horizontal,
                    itemCount: plantTypes.length,
                    itemBuilder: (context, index) {
                      final plant = plantTypes[index];
                      final bool isAvailable = plant['isAvailable'] as bool;
                      final isSelected = selectedPlant == plant['name'];

                      return GestureDetector(
                        onTap: isAvailable ? () => setState(() => selectedPlant = plant['name'] as String) : null,
                        child: Container(
                          // 🚨 RESPONSIVE FIX: Width adapts to show exactly ~2.5 cards on any screen
                          width: cardWidth,
                          margin: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(
                            color: isAvailable
                                ? (isSelected ? const Color(0xFFE8F8F5) : Colors.white)
                                : const Color(0xFFC0C9C6),
                            border: Border.all(
                              color: isAvailable
                                  ? (isSelected ? const Color(0xFF2EF889) : Colors.grey[200]!)
                                  : Colors.transparent,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Stack(
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    // 🚨 RESPONSIVE FIX: Expanded allows the image to scale organically
                                    Expanded(
                                      child: Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          Opacity(
                                            opacity: isAvailable ? 1.0 : 0.6,
                                            child: Image.asset(plant['image'] as String, fit: BoxFit.contain),
                                          ),
                                          if (!isAvailable)
                                            Positioned(
                                              bottom: 0,
                                              right: 0,
                                              child: Container(
                                                padding: const EdgeInsets.all(4),
                                                decoration: const BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: Color(0xFFC0C9C6),
                                                ),
                                                child: const Icon(Icons.lock, size: 14, color: Colors.white),
                                              ),
                                            )
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 12),

                                    // The Title
                                    Text(
                                      plant['name'] as String,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: isAvailable ? Colors.black : Colors.black54
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 4),

                                    // Description or Coming Soon Pill (Fixed height so cards stay aligned)
                                    SizedBox(
                                      height: 24,
                                      child: Center(
                                        child: isAvailable
                                            ? Text(
                                            plant['desc'] as String,
                                            textAlign: TextAlign.center,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(fontSize: 10, color: Colors.grey[600])
                                        )
                                            : Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                              color: const Color(0xFF8A9A95),
                                              borderRadius: BorderRadius.circular(12)
                                          ),
                                          child: const Text("COMING SOON", style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                                        ),
                                      ),
                                    )
                                  ],
                                ),
                              ),

                              if (isSelected && isAvailable)
                                const Positioned(
                                    top: 12, right: 12,
                                    child: Icon(Icons.check_circle, color: Color(0xFF2EF889), size: 20)
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

              const SizedBox(height: 40),
              const Center(child: Text("2. NAME IT", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, letterSpacing: 1.2))),
              const SizedBox(height: 20),

              TextField(
                controller: _plantNameController,
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  hintText: "e.g. Tommy",
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                  prefixIcon: const Icon(Icons.edit, color: Colors.grey),
                ),
              ),

              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                // 🚨 RESPONSIVE FIX: Button scales to 7.5% of height (min 55px)
                height: screenHeight * 0.075 < 55 ? 55 : screenHeight * 0.075,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _savePlantToFirebase,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2EF889),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    elevation: 5,
                    shadowColor: const Color(0xFF2EF889).withOpacity(0.4),
                  ),
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("SPROUT  Plant It!", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}