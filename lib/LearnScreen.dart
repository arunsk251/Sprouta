import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:video_player/video_player.dart';

class LearnScreen extends StatefulWidget {
  const LearnScreen({super.key});

  @override
  State<LearnScreen> createState() => _LearnScreenState();
}

class _LearnScreenState extends State<LearnScreen> {
  int selectedPlantIndex = 0;
  String userName = "Explorer";
  Stream<QuerySnapshot>? _userDataStream;

  final List<String> allStages = ["Seed", "Sprout", "Young", "Adult", "Bloom"];

  final List<Map<String, dynamic>> guideData = [
    {
      "title": "Your Starter Kit",
      "subtitle": "7 Steps • Easy",
      "tag": "KIT",
      "tagColor": Colors.purple,
      "time": "5 min",
      "thumbnail": "assests/5.png",
      "steps": [
        {"title": "Prepare the Soil", "desc": "Take the cocopeat and add water slowly.", "video": "assests/Step_1.mp4"},
        {"title": "Mix the Soil", "desc": "Mix cocopeat with compost, Fill the pot with this mixture", "video": "assests/Step_2.mp4"},
        {"title": "Plant the Seeds", "desc": "Add 2–3 seeds into the soil, Water a little every day.", "video": "assests/Step_3.mp4"},
        {"title": "Watch It Grow", "desc": "In a few days, tiny sprouts will appear!", "video": "assests/Step_4.mp4"},
        {"title": "Give Support", "desc": "As the plant grows tall, tie it gently to a stick or rope.", "video": "assests/Step_5.mp4"},
        {"title": "Feed Your Plant", "desc": "Add booster mix after a few weeks.", "video": "assests/Step_6.mp4"},
        {"title": "Enjoy the Fruits", "desc": "Soon you will see flowers… then tomatoes!", "video": "assests/Step_7.mp4"}
      ]
    }
  ];

  @override
  void initState() {
    super.initState();
    _initStream();
  }

  Future<void> _initStream() async {
    final prefs = await SharedPreferences.getInstance();
    final storedName = prefs.getString('userName') ?? "Explorer";

    setState(() {
      userName = storedName;
      _userDataStream = FirebaseFirestore.instance
          .collection('users')
          .where('name', isEqualTo: userName)
          .snapshots();
    });
  }

  String _getQuoteForPlant(String plantType) {
    switch (plantType.toLowerCase()) {
      case 'sunflower': return "I follow the sun across the sky! Make sure I can see it.";
      case 'tomato': return "I get thirsty! Water me regularly to make my fruit juicy.";
      case 'fern': return "I love the shade and humidity. Keep my soil damp!";
      case 'cactus': return "I'm tough! Don't water me too often, I like it dry.";
      default: return "I'm growing every day! Thanks for taking care of me.";
    }
  }

  Color _getColorForPlant(String plantType) {
    switch (plantType.toLowerCase()) {
      case 'sunflower': return const Color(0xFFFFCDD2);
      case 'tomato': return const Color(0xFFFFCCBC);
      case 'fern': return const Color(0xFFC8E6C9);
      default: return const Color(0xFFE3F2FD);
    }
  }

  int _getStageIndex(String currentStage) {
    if (currentStage.isEmpty) return 0;
    String normalized = currentStage[0].toUpperCase() + currentStage.substring(1).toLowerCase();
    int index = allStages.indexOf(normalized);
    return index != -1 ? index : 0;
  }

  String _getDynamicImage(Map<String, dynamic> plant) {
    String pType = plant['type'] ?? "General";
    String pStage = plant['stage'] ?? "Seed";
    String pImage = plant['image'] ?? "assests/sunflower.png";

    if (pType.toLowerCase() == 'tomato') {
      int stageIndex = _getStageIndex(pStage);
      List<String> tomatoImages = [
        'assests/1.png',
        'assests/2.png',
        'assests/3.png',
        'assests/4.png',
        'assests/5.png'
      ];
      if (stageIndex >= 0 && stageIndex < tomatoImages.length) {
        return tomatoImages[stageIndex];
      }
    }
    return pImage;
  }

  @override
  Widget build(BuildContext context) {
    if (_userDataStream == null) {
      return const Scaffold(backgroundColor: Colors.white, body: Center(child: CircularProgressIndicator()));
    }

    // 🚨 RESPONSIVE FIX: Get screen height for dynamic scaling
    double screenHeight = MediaQuery.of(context).size.height;

    return StreamBuilder<QuerySnapshot>(
        stream: _userDataStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Scaffold(backgroundColor: Colors.white, body: Center(child: CircularProgressIndicator()));
          }

          final userData = snapshot.data!.docs.first.data() as Map<String, dynamic>;
          List<Map<String, dynamic>> myPlants = [];

          if (userData.containsKey('plants') && userData['plants'] != null) {
            myPlants = List<Map<String, dynamic>>.from(userData['plants']);
          }

          if (myPlants.isEmpty) {
            myPlants.add({'name': 'Seedling', 'type': 'General', 'image': 'assests/sunflower.png', 'stage': 'Seed'});
          }

          if (selectedPlantIndex >= myPlants.length) selectedPlantIndex = 0;

          final activePlant = myPlants[selectedPlantIndex];
          final String pName = activePlant['name'] ?? "Plant";
          final String pType = activePlant['type'] ?? "General";
          final String pQuote = _getQuoteForPlant(pType);
          final String dynamicFeatureImage = _getDynamicImage(activePlant);

          return Scaffold(
            backgroundColor: Colors.white,
            appBar: AppBar(backgroundColor: Colors.white, elevation: 0, centerTitle: true, title: const Text("Sprouta Learn", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)), leading: const SizedBox()),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("My Garden Teachers", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),

                  SizedBox(
                    height: 100,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: myPlants.length,
                      separatorBuilder: (context, index) => const SizedBox(width: 20),
                      itemBuilder: (context, index) {
                        final plant = myPlants[index];
                        bool isSelected = selectedPlantIndex == index;
                        String dynamicAvatarImage = _getDynamicImage(plant);

                        return GestureDetector(
                          onTap: () => setState(() => selectedPlantIndex = index),
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(3),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: isSelected ? const Color(0xFF2EF889) : Colors.transparent, width: 3),
                                ),
                                child: CircleAvatar(
                                  radius: 30,
                                  backgroundColor: _getColorForPlant(plant['type'] ?? ''),
                                  backgroundImage: AssetImage(dynamicAvatarImage),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(plant['name'] ?? "Plant", style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal))
                            ],
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 30),

                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0,5))]),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          // 🚨 RESPONSIVE FIX: Banner takes 22% of screen height instead of hardcoded 180px
                            height: screenHeight * 0.22,
                            width: double.infinity,
                            decoration: BoxDecoration(
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                                image: DecorationImage(image: AssetImage(dynamicFeatureImage), fit: BoxFit.cover, alignment: Alignment.topCenter)
                            ),
                            child: Container(
                                padding: const EdgeInsets.all(15),
                                alignment: Alignment.bottomLeft,
                                decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black.withOpacity(0.7)])),
                                child: Text("$pName Says:", style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold))
                            )
                        ),
                        Padding(
                            padding: const EdgeInsets.all(20),
                            child: IntrinsicHeight(
                                child: Row(
                                    children: [
                                      Container(width: 4, color: const Color(0xFF2EF889)),
                                      const SizedBox(width: 15),
                                      Expanded(child: Text("\"$pQuote\"", style: const TextStyle(fontSize: 16, height: 1.4, fontStyle: FontStyle.italic)))
                                    ]
                                )
                            )
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: const [Text("Gardening Guides", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)), Text("NEW", style: TextStyle(color: Color(0xFF2EF889), fontWeight: FontWeight.bold, fontSize: 12))]),
                  const SizedBox(height: 15),

                  ...guideData.map((guide) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 15.0),
                      child: _buildGuideCard(
                          guide['title'], guide['subtitle'], guide['tag'], guide['tagColor'], guide['time'], guide['thumbnail'],
                          onTap: () {
                            showDialog(
                                context: context,
                                builder: (context) => GuideStepsPopup(
                                  guideTitle: guide['title'],
                                  guideTag: guide['tag'],
                                  steps: List<Map<String, String>>.from(guide['steps'].map((item) => Map<String, String>.from(item))),
                                )
                            );
                          }
                      ),
                    );
                  }).toList(),

                  const SizedBox(height: 80),
                ],
              ),
            ),
          );
        }
    );
  }

  Widget _buildGuideCard(String title, String subtitle, String tag, Color tagColor, String time, String imagePath, {required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey[100]!), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
        child: Row(
          children: [
            Container(height: 70, width: 70, decoration: BoxDecoration(borderRadius: BorderRadius.circular(15), image: DecorationImage(image: AssetImage(imagePath), fit: BoxFit.cover)), alignment: Alignment.bottomCenter, child: Container(width: double.infinity, color: Colors.black54, padding: const EdgeInsets.symmetric(vertical: 2), child: Text(time, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)))),
            const SizedBox(width: 15),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: tagColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Text(tag, style: TextStyle(color: tagColor, fontSize: 10, fontWeight: FontWeight.bold))), const SizedBox(height: 5), Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), Text(subtitle, style: TextStyle(color: Colors.grey[500], fontSize: 12))])),
            Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.grey[50]), child: const Icon(Icons.play_arrow_rounded, color: Colors.black))
          ],
        ),
      ),
    );
  }
}

// --- POPUP COMPONENT ---
class GuideStepsPopup extends StatefulWidget {
  final String guideTitle;
  final String guideTag;
  final List<Map<String, String>> steps;

  const GuideStepsPopup({super.key, required this.guideTitle, required this.guideTag, required this.steps});

  @override
  State<GuideStepsPopup> createState() => _GuideStepsPopupState();
}

class _GuideStepsPopupState extends State<GuideStepsPopup> {
  int currentStep = 0;
  VideoPlayerController? _videoController;

  @override
  void initState() {
    super.initState();
    _loadVideoForCurrentStep();
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  void _loadVideoForCurrentStep() {
    final String videoPath = widget.steps[currentStep]['video']!;
    _videoController?.dispose();

    _videoController = VideoPlayerController.asset(videoPath)
      ..initialize().then((_) {
        _videoController!.setVolume(0.0);
        _videoController!.setLooping(true);
        _videoController!.play();
        if (mounted) setState(() {});
      });
  }

  void _nextStep() {
    if (currentStep < widget.steps.length - 1) {
      setState(() {
        currentStep++;
        _loadVideoForCurrentStep();
      });
    } else {
      Navigator.pop(context);
    }
  }

  void _prevStep() {
    if (currentStep > 0) {
      setState(() {
        currentStep--;
        _loadVideoForCurrentStep();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final step = widget.steps[currentStep];
    double progress = (currentStep + 1) / widget.steps.length;

    // 🚨 RESPONSIVE FIX: Let the dialog dictate its own width natively instead of forcing it
    double screenHeight = MediaQuery.of(context).size.height;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        height: screenHeight * 0.85, // Keeps it comfortably within bounds
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30)),
        child: Column(
          children: [
            Expanded(
                flex: 55, // Adjusted flex so the text has more breathing room below
                child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                        child: Container(
                          width: double.infinity,
                          height: double.infinity,
                          color: Colors.black, // Sleek dark background for videos
                          child: _videoController != null && _videoController!.value.isInitialized
                              ? FittedBox(
                            // 🚨 RESPONSIVE FIX: 'contain' ensures the video is never cropped or distorted!
                            fit: BoxFit.contain,
                            child: SizedBox(
                              width: _videoController!.value.size.width,
                              height: _videoController!.value.size.height,
                              child: VideoPlayer(_videoController!),
                            ),
                          )
                              : const Center(child: CircularProgressIndicator(color: Color(0xFF2EF889))),
                        ),
                      ),

                      Positioned(
                          top: 15, right: 15,
                          child: GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.black.withOpacity(0.4), shape: BoxShape.circle), child: const Icon(Icons.close, color: Colors.white, size: 20))
                          )
                      ),

                      Positioned(
                          bottom: 15, right: 15,
                          child: GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => FullScreenVideoPage(videoPath: step['video']!),
                                  ),
                                );
                              },
                              child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(color: Colors.black.withOpacity(0.5), shape: BoxShape.circle),
                                  child: const Icon(Icons.fullscreen, color: Colors.white, size: 20)
                              )
                          )
                      ),
                    ]
                )
            ),

            Expanded(
                flex: 45, // More space for the text area
                // 🚨 RESPONSIVE FIX: SingleChildScrollView prevents the yellow bottom overflow tape!
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(color: const Color(0xFF2EF889).withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                                child: Text(widget.guideTag, style: const TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold))
                            ),
                            Text("Step ${currentStep + 1} of ${widget.steps.length}", style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 14)),
                          ],
                        ),
                        const SizedBox(height: 10),

                        Text(widget.guideTitle, style: TextStyle(color: Colors.grey[400], fontWeight: FontWeight.bold, fontSize: 12)),
                        const SizedBox(height: 5),
                        Text(step['title']!, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0D1C2E))),
                        const SizedBox(height: 8),
                        Text(step['desc']!, style: TextStyle(fontSize: 14, height: 1.4, color: Colors.grey[600])),

                        const SizedBox(height: 20), // Replaced spacer with fixed padding for the scroll view
                        ClipRRect(borderRadius: BorderRadius.circular(10), child: LinearProgressIndicator(value: progress, backgroundColor: Colors.grey[200], color: const Color(0xFF2EF889), minHeight: 6)),
                        const SizedBox(height: 15),

                        Row(
                            children: [
                              if (currentStep > 0) GestureDetector(onTap: _prevStep, child: Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.grey[100], shape: BoxShape.circle), child: const Icon(Icons.arrow_back, color: Colors.black))),
                              if (currentStep > 0) const SizedBox(width: 10),
                              Expanded(child: SizedBox(height: 50, child: ElevatedButton(onPressed: _nextStep, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2EF889), foregroundColor: Colors.black, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Text(currentStep == widget.steps.length - 1 ? "Finish!" : "Next Step", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)), if (currentStep != widget.steps.length - 1) ...[const SizedBox(width: 8), const Icon(Icons.arrow_forward_rounded, size: 20)]]))))
                            ]
                        )
                      ]
                  ),
                )
            )
          ],
        ),
      ),
    );
  }
}

// THE FULLSCREEN VIDEO PAGE
class FullScreenVideoPage extends StatefulWidget {
  final String videoPath;
  const FullScreenVideoPage({super.key, required this.videoPath});

  @override
  State<FullScreenVideoPage> createState() => _FullScreenVideoPageState();
}

class _FullScreenVideoPageState extends State<FullScreenVideoPage> {
  late VideoPlayerController _fullScreenController;

  @override
  void initState() {
    super.initState();
    _fullScreenController = VideoPlayerController.asset(widget.videoPath)
      ..initialize().then((_) {
        _fullScreenController.setVolume(1.0);
        _fullScreenController.setLooping(true);
        _fullScreenController.play();
        if (mounted) setState(() {});
      });
  }

  @override
  void dispose() {
    _fullScreenController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            SizedBox.expand(
              child: _fullScreenController.value.isInitialized
                  ? FittedBox(
                // 🚨 RESPONSIVE FIX: 'contain' prevents cropping on tall 20:9 devices
                fit: BoxFit.contain,
                child: SizedBox(
                  width: _fullScreenController.value.size.width,
                  height: _fullScreenController.value.size.height,
                  child: VideoPlayer(_fullScreenController),
                ),
              )
                  : const Center(child: CircularProgressIndicator(color: Color(0xFF2EF889))),
            ),

            Positioned(
              top: 20,
              left: 20,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}