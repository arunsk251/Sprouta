import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'config_service.dart';

class ScanPlantScreen extends StatefulWidget {
  final int plantIndex;
  final List<Map<String, dynamic>> plants;
  final String userName;
  final bool isPlantDoc;

  const ScanPlantScreen({
    super.key,
    required this.plantIndex,
    required this.plants,
    required this.userName,
    this.isPlantDoc = false,
  });

  @override
  State<ScanPlantScreen> createState() => _ScanPlantScreenState();
}

class _ScanPlantScreenState extends State<ScanPlantScreen> {
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  bool _isAnalyzing = false;

  final String apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';

  Future<void> _pickImage(ImageSource source) async {
    final XFile? pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() => _selectedImage = File(pickedFile.path));
    }
  }

  void _clearImage() => setState(() => _selectedImage = null);

  Future<void> _diagnosePlant() async {
    if (_selectedImage == null) return;
    if (apiKey.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("⚠️ Missing API Key!")));
      return;
    }

    setState(() => _isAnalyzing = true);

    try {
      // You can safely use your preferred gemma model here!
      // 1. Ask Firebase which model you should be using right now
      String dynamicModelName = await RemoteConfigService.getActiveAiModel();

// 2. Plug it into the GenerativeModel!
      final model = GenerativeModel(model: dynamicModelName, apiKey: apiKey);
      final imageBytes = await _selectedImage!.readAsBytes();

      // 🚨 UPDATED PROMPT: Much stricter formatting rules
      final String aiInstructions = widget.isPlantDoc
          ? "You are a Plant Doctor. Look at this plant and reply with exactly this format:\n"
          "STATUS: [Healthy, Thirsty, Sick, or Wilting]\n"
          "STAGE: [Seed, Sprout, Young, Adult, or Bloom]\n"
          "ADVICE: [Max 15 words of advice]"
          : "Look at this plant and reply with exactly this format:\n"
          "STAGE: [Seed, Sprout, Young, Adult, or Bloom]";

      final prompt = TextPart(aiInstructions);
      final content = [Content.multi([prompt, DataPart('image/jpeg', imageBytes)])];
      final response = await model.generateContent(content);
      final text = response.text ?? "";

      if (text.isEmpty) throw Exception("Empty AI response");

      // 🚨 BULLETPROOF PARSING LOGIC 🚨
      // We convert the whole response to uppercase and just look for our specific keywords!
      String rawText = text.toUpperCase();

      if (rawText.contains("NOT_A_PLANT") || rawText.contains("NOT A PLANT")) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("🚫 Not a plant! Try again."), backgroundColor: Colors.red));
        return;
      }

      if (widget.isPlantDoc) {
        // 1. Extract Status
        String aiStatus = "Healthy"; // Default
        if (rawText.contains("WILTING")) aiStatus = "Wilting";
        else if (rawText.contains("SICK")) aiStatus = "Sick";
        else if (rawText.contains("THIRSTY")) aiStatus = "Thirsty";
        else if (rawText.contains("HEALTHY")) aiStatus = "Healthy";

        // 2. Extract Stage
        String aiStage = "Young"; // Default
        if (rawText.contains("BLOOM")) aiStage = "Bloom";
        else if (rawText.contains("ADULT")) aiStage = "Adult";
        else if (rawText.contains("YOUNG")) aiStage = "Young";
        else if (rawText.contains("SPROUT")) aiStage = "Sprout";
        else if (rawText.contains("SEED")) aiStage = "Seed";

        // 3. Extract Advice (Everything after the word "ADVICE:")
        String aiAdvice = "Keep taking care of it!";
        if (rawText.contains("ADVICE:")) {
          // Find where "ADVICE:" starts, skip those 7 characters, and grab the rest
          aiAdvice = text.substring(text.toUpperCase().indexOf("ADVICE:") + 7).trim();
          // Clean up any weird markdown the AI might add
          aiAdvice = aiAdvice.replaceAll('```', '').replaceAll('"', '').trim();
        }

        if (mounted) _showDoctorReportDialog(aiStatus, aiStage, aiAdvice);
      } else {
        // 1. Extract Stage for Growth Update
        String aiStage = "Young"; // Default
        if (rawText.contains("BLOOM")) aiStage = "Bloom";
        else if (rawText.contains("ADULT")) aiStage = "Adult";
        else if (rawText.contains("YOUNG")) aiStage = "Young";
        else if (rawText.contains("SPROUT")) aiStage = "Sprout";
        else if (rawText.contains("SEED")) aiStage = "Seed";

        if (mounted) _showGrowthUpdateDialog(aiStage);
      }

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("AI Error: $e")));
    } finally {
      setState(() => _isAnalyzing = false);
    }
  }

  Future<void> _awardDailyScanXP() async {
    try {
      final query = await FirebaseFirestore.instance.collection('users').where('name', isEqualTo: widget.userName).get();
      if (query.docs.isNotEmpty) {
        String docId = query.docs.first.id;
        Map<String, dynamic> data = query.docs.first.data();

        int currentPoints = data['points'] ?? 0;
        String lastScanDate = data['last_scan_date'] ?? "";
        String today = DateTime.now().toIso8601String().split('T')[0];

        if (lastScanDate != today) {
          await FirebaseFirestore.instance.collection('users').doc(docId).update({
            'points': currentPoints + 15,
            'last_scan_date': today,
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Daily Scan Bonus! +15 XP 🔍🌟"), backgroundColor: Colors.purple)
            );
          }
        }
      }
    } catch (e) {
      print("Error awarding scan points: $e");
    }
  }

  Future<void> _updateFirebase(String status, String stage, String advice) async {
    if (widget.userName.isNotEmpty) {
      final querySnapshot = await FirebaseFirestore.instance.collection('users').where('name', isEqualTo: widget.userName).get();

      if (querySnapshot.docs.isNotEmpty) {
        final userDoc = querySnapshot.docs.first;
        List<dynamic> currentPlants = userDoc.data()['plants'] ?? [];

        if (widget.plantIndex < currentPlants.length) {
          currentPlants[widget.plantIndex]['status'] = status;
          currentPlants[widget.plantIndex]['stage'] = stage;
          currentPlants[widget.plantIndex]['last_advice'] = advice;

          await FirebaseFirestore.instance.collection('users').doc(userDoc.id).update({'plants': currentPlants});
        }
      }
    }
  }

  void _showDoctorReportDialog(String status, String stage, String advice) {
    bool isSaving = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Center(child: Text("📋 Plant Report", style: TextStyle(fontWeight: FontWeight.bold))),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("Status: $status", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.blue)),
                  const SizedBox(height: 10),
                  Text("Stage: $stage", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green)),
                  const SizedBox(height: 15),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.orange[50], borderRadius: BorderRadius.circular(10)),
                    child: Text("💡 Dr. Sprouta says:\n$advice", textAlign: TextAlign.center, style: const TextStyle(fontStyle: FontStyle.italic)),
                  ),
                ],
              ),
              actions: [
                if (isSaving)
                  const Center(child: Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator()))
                else
                  TextButton(
                    onPressed: () async {
                      setDialogState(() => isSaving = true);
                      await _updateFirebase(status, stage, advice);
                      if (mounted) {
                        Navigator.pop(context);
                        Navigator.pop(context);
                      }
                    },
                    child: const Text("Apply & Go Home", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  )
              ],
            );
          },
        );
      },
    );
  }

  void _showGrowthUpdateDialog(String newStage) {
    bool isSaving = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Center(child: Text("🌱 Growth Updated!", style: TextStyle(fontWeight: FontWeight.bold))),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("Your plant is now in the:", style: TextStyle(fontSize: 16)),
                  const SizedBox(height: 10),
                  Text(newStage.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: Colors.green)),
                  const SizedBox(height: 10),
                  const Text("stage!", style: TextStyle(fontSize: 16)),
                ],
              ),
              actions: [
                if (isSaving)
                  const Center(child: Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator()))
                else
                  ElevatedButton(
                    onPressed: () async {
                      setDialogState(() => isSaving = true);

                      final currentPlant = widget.plants[widget.plantIndex];
                      final existingStatus = currentPlant['status'] ?? 'Healthy';
                      final existingAdvice = currentPlant['last_advice'] ?? 'No advice yet.';

                      await _updateFirebase(existingStatus, newStage, existingAdvice);
                      await _awardDailyScanXP();

                      if (mounted) {
                        Navigator.pop(context);
                        Navigator.pop(context);
                      }
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2EF889), foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                    child: const Text("Awesome!", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  )
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(leading: const BackButton(color: Colors.black), backgroundColor: Colors.white, elevation: 0, title: Text(widget.isPlantDoc ? "Plant Doctor" : "Update Growth", style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold))),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            Text(widget.isPlantDoc ? "Let's fix it!" : "Let's track it!", style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF0D1C2E))),
            const SizedBox(height: 30),
            Expanded(child: _selectedImage == null ? _buildUploadUI(screenWidth, screenHeight) : _buildPreviewUI(screenWidth, screenHeight)),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadUI(double screenWidth, double screenHeight) {
    final plant = widget.plants[widget.plantIndex];
    final String prevStatus = plant['status'] ?? "Unknown";
    final String prevStage = plant['stage'] ?? "Unknown";
    final String prevAdvice = plant['last_advice'] ?? "No advice yet.";
    final bool hasReport = prevStatus != "Unknown";

    double avatarSize = screenHeight * 0.15;
    if (avatarSize < 100) avatarSize = 100;

    double optionBoxSize = screenWidth * 0.18;
    if (optionBoxSize < 65) optionBoxSize = 65;

    double buttonHeight = screenHeight * 0.065;
    if (buttonHeight < 50) buttonHeight = 50;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 5))]),
                  child: Column(children: [const Text("Hi friend! 👋", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)), const SizedBox(height: 5), Text(widget.isPlantDoc ? "Does your leaf look sad? Show me a picture!" : "Take a picture to track your plant's growth stage!", textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, color: Colors.grey))]),
                ),
              ),

              if (hasReport && widget.isPlantDoc)
                Padding(
                  padding: const EdgeInsets.only(top: 25, left: 24, right: 24),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.blue.withOpacity(0.3), width: 2),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.medical_information, color: Colors.blue),
                            const SizedBox(width: 8),
                            Text("Previous Scan Report", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blue[900])),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text("Status: $prevStatus", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        Text("Stage: $prevStage", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        const SizedBox(height: 8),
                        Text("💡 $prevAdvice", style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 13, color: Colors.black87)),
                      ],
                    ),
                  ),
                )
              else
                const SizedBox(height: 20),

              const SizedBox(height: 30),
              Container(height: avatarSize, width: avatarSize, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white, border: Border.all(color: Colors.green.withOpacity(0.2), width: 3), boxShadow: [BoxShadow(color: Colors.green.withOpacity(0.1), blurRadius: 30, offset: const Offset(0, 10))]), padding: const EdgeInsets.all(10.0), child: const CircleAvatar(backgroundColor: Colors.transparent, backgroundImage: AssetImage('assests/sunflower.png'))),

              const SizedBox(height: 40),
              Container(margin: const EdgeInsets.symmetric(horizontal: 24), width: double.infinity, padding: const EdgeInsets.all(30), decoration: BoxDecoration(color: const Color(0xFFF9FDFB), borderRadius: BorderRadius.circular(30), border: Border.all(color: const Color(0xFF2EF889), width: 2)), child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  _buildOptionButton(icon: Icons.camera_alt_rounded, color: const Color(0xFFE2F6F0), iconColor: Colors.green, size: optionBoxSize, onTap: () => _pickImage(ImageSource.camera)),
                  const SizedBox(width: 20),
                  _buildOptionButton(icon: Icons.photo_library_rounded, color: const Color(0xFFFFF3E0), iconColor: Colors.orange, size: optionBoxSize, onTap: () => _pickImage(ImageSource.gallery))
                ]),
                const SizedBox(height: 20),
                const Text("Tap to Snap", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 5),
                SizedBox(width: double.infinity, height: buttonHeight, child: ElevatedButton(onPressed: () => _pickImage(ImageSource.gallery), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2EF889), foregroundColor: Colors.black, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: const Text("Select Image", style: TextStyle(fontWeight: FontWeight.bold))))])),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPreviewUI(double screenWidth, double screenHeight) {
    double buttonHeight = screenHeight * 0.075;
    if (buttonHeight < 60) buttonHeight = 60;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
                children: [
                  Expanded(child: Stack(children: [Container(decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), image: DecorationImage(image: FileImage(_selectedImage!), fit: BoxFit.cover))), Positioned(top: 15, right: 15, child: GestureDetector(onTap: _clearImage, child: Container(padding: const EdgeInsets.all(8), decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle), child: const Icon(Icons.close, size: 20, color: Colors.black))))])),
                  const SizedBox(height: 30),
                  SizedBox(width: double.infinity, height: buttonHeight, child: ElevatedButton.icon(onPressed: _isAnalyzing ? null : _diagnosePlant, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2EF889), foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))), icon: _isAnalyzing ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.black)) : const Icon(Icons.medical_services_outlined), label: Text(_isAnalyzing ? "ANALYZING..." : (widget.isPlantDoc ? "DIAGNOSE PLANT!" : "ANALYZE GROWTH!"), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)))),
                  const SizedBox(height: 20)
                ]
            )
        ),
      ),
    );
  }

  Widget _buildOptionButton({required IconData icon, required Color color, required Color iconColor, required double size, required VoidCallback onTap}) {
    return GestureDetector(onTap: onTap, child: Container(height: size, width: size, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(18)), child: Icon(icon, color: iconColor, size: size * 0.4)));
  }
}