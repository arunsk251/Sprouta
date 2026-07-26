import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'config_service.dart';

class QuizScreen extends StatefulWidget {
  final String userName;
  const QuizScreen({super.key, required this.userName});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int currentQuestion = 0;
  int score = 0;
  int? selectedOptionIndex;
  bool isChecked = false;

  bool isLoading = true;
  bool hasPlayedToday = false;
  bool isSaving = false;

  List<dynamic> questions = [];

  // Pulls the key safely from the hidden .env file!
  final String apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';

  @override
  void initState() {
    super.initState();
    _checkDailyStatusAndLoadQuiz();
  }

  // --- 1. CHECK IF PLAYED TODAY ---
  Future<void> _checkDailyStatusAndLoadQuiz() async {
    try {
      final query = await FirebaseFirestore.instance.collection('users').where('name', isEqualTo: widget.userName).get();
      if (query.docs.isNotEmpty) {
        String lastQuizDate = query.docs.first.data()['last_quiz_date'] ?? "";
        String today = DateTime.now().toIso8601String().split('T')[0];

        // Stop if they already played today
        if (lastQuizDate == today) {
          setState(() {
            hasPlayedToday = true;
            isLoading = false;
          });
          return;
        }
      }

      await _generateQuestions();
    } catch (e) {
      print("Error checking status: $e");
      _loadFallbackQuestions();
    }
  }

  // --- 2. GENERATE EXACTLY 4 QUESTIONS ---
  Future<void> _generateQuestions() async {
    try {
      // 1. Ask Firebase which model you should be using right now
      String dynamicModelName = await RemoteConfigService.getActiveAiModel();

// 2. Plug it into the GenerativeModel!
      final model = GenerativeModel(model: dynamicModelName, apiKey: apiKey);
      final prompt = '''
        Generate a JSON array of exactly 4 multiple-choice questions about plants, gardening, or nature suitable for beginners.
        Format exactly like this, returning ONLY a valid JSON array:
        [
          {
            "question": "What do plants need to make food?",
            "options": ["Candy", "Sunlight", "Soda", "Toys"],
            "answer": 1,
            "explanation": "Plants use sunlight to make their own food!"
          }
        ]
      ''';

      final response = await model.generateContent([Content.text(prompt)]);
      String text = response.text ?? "";

      // 🚨 BULLETPROOF JSON EXTRACTION 🚨
      // Ignore Gemma's chatty text. Find the start and end of the actual JSON array.
      int startIndex = text.indexOf('[');
      int endIndex = text.lastIndexOf(']');

      if (startIndex != -1 && endIndex != -1 && endIndex > startIndex) {
        // Extract strictly the JSON part
        String cleanJson = text.substring(startIndex, endIndex + 1);
        List<dynamic> aiQuestions = json.decode(cleanJson);

        // Ensure we have exactly 4 questions
        if (aiQuestions.length == 4) {
          setState(() {
            questions = aiQuestions;
            isLoading = false;
          });
        } else {
          _loadFallbackQuestions();
        }
      } else {
        print("Could not find JSON brackets in response.");
        _loadFallbackQuestions();
      }
    } catch (e) {
      print("AI Error: $e");
      _loadFallbackQuestions();
    }
  }

  // Guaranteed 4 questions if the AI or Internet fails
  void _loadFallbackQuestions() {
    setState(() {
      questions = [
        {
          "question": "What part of the plant absorbs water?",
          "options": ["Leaves", "Roots", "Flowers", "Stem"],
          "answer": 1,
          "explanation": "Roots act like straws to drink water from the soil!"
        },
        {
          "question": "Where do carrots grow?",
          "options": ["In trees", "On bushes", "Underground", "In the sky"],
          "answer": 2,
          "explanation": "Carrots are root vegetables, meaning they grow under the dirt!"
        },
        {
          "question": "What color are sunflowers usually?",
          "options": ["Purple", "Blue", "Yellow", "Pink"],
          "answer": 2,
          "explanation": "Sunflowers have big, bright yellow petals!"
        },
        {
          "question": "What helps plants grow besides water?",
          "options": ["Candy", "Sunlight", "Pizza", "Toys"],
          "answer": 1,
          "explanation": "Plants need sunlight for energy to grow tall!"
        }
      ];
      isLoading = false;
    });
  }

  // --- 3. SAVE POINTS & LOCK ---
  Future<void> _saveScoreAndExit() async {
    setState(() => isSaving = true);
    try {
      final query = await FirebaseFirestore.instance.collection('users').where('name', isEqualTo: widget.userName).get();
      if (query.docs.isNotEmpty) {
        String docId = query.docs.first.id;
        int currentPoints = query.docs.first.data()['points'] ?? 0;
        String today = DateTime.now().toIso8601String().split('T')[0];

        await FirebaseFirestore.instance.collection('users').doc(docId).update({
          'points': currentPoints + score,
          'last_quiz_date': today,
        });
      }
    } catch (e) {
      print("Error saving quiz score: $e");
    }

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Quiz Complete! You earned $score XP! 🌟"), backgroundColor: Colors.amber)
      );
    }
  }

  void _checkAnswer() {
    if (selectedOptionIndex != null) {
      setState(() {
        isChecked = true;
        if (selectedOptionIndex == questions[currentQuestion]['answer']) {
          score += 5;
        }
      });
    }
  }

  void _nextQuestion() {
    if (currentQuestion < questions.length - 1) {
      setState(() {
        currentQuestion++;
        selectedOptionIndex = null;
        isChecked = false;
      });
    } else {
      _saveScoreAndExit();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.grey),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (!isLoading && !hasPlayedToday)
            Container(
              margin: const EdgeInsets.only(right: 20, top: 10, bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
              decoration: BoxDecoration(color: const Color(0xFFE0F2F1), borderRadius: BorderRadius.circular(20)),
              alignment: Alignment.center,
              child: Text("Score: $score", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
            )
        ],
      ),
      body: SafeArea(child: _buildBodyContent()),
    );
  }

  Widget _buildBodyContent() {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    if (isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            CircularProgressIndicator(color: Color(0xFF2EF889)),
            SizedBox(height: 20),
            Text("Dr. Sprouta is writing your 4 questions...", style: TextStyle(color: Colors.grey, fontSize: 16)),
          ],
        ),
      );
    }

    if (hasPlayedToday) {
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Padding(
            padding: const EdgeInsets.all(30.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                    Icons.check_circle_outline,
                    size: screenHeight * 0.12 < 80 ? 80 : screenHeight * 0.12,
                    color: Colors.green
                ),
                const SizedBox(height: 20),
                const Text("You're all caught up!", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                const Text("You have already completed today's Garden Trivia. Come back tomorrow for 4 fresh questions and up to 20 XP!", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 16, height: 1.5)),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  height: screenHeight * 0.075 < 55 ? 55 : screenHeight * 0.075,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2EF889), foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                    child: const Text("Back to Arcade", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                )
              ],
            ),
          ),
        ),
      );
    }

    if (isSaving) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF2EF889)));
    }

    final question = questions[currentQuestion];
    double progress = (currentQuestion + 1) / questions.length;
    bool isCorrect = selectedOptionIndex == question['answer'];

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.06, vertical: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Question ${currentQuestion + 1} of 4", style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                  Text("Max: 20 XP", style: TextStyle(color: Colors.amber[800], fontWeight: FontWeight.bold, fontSize: 12)),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(value: progress, backgroundColor: Colors.grey[200], color: const Color(0xFF2EF889), minHeight: 8),
              ),
              const SizedBox(height: 30),

              Text(question['question'], textAlign: TextAlign.center, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF0D1C2E))),

              const SizedBox(height: 30),

              if (isChecked)
                Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isCorrect ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: isCorrect ? Colors.green : Colors.red, width: 0.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(isCorrect ? Icons.check_circle : Icons.cancel, color: isCorrect ? Colors.green : Colors.red),
                          const SizedBox(width: 8),
                          Text(isCorrect ? "Correct! (+5 XP)" : "Oops, try this: (+0 XP)", style: TextStyle(fontWeight: FontWeight.bold, color: isCorrect ? Colors.green : Colors.red, fontSize: 16)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(question['explanation'], style: TextStyle(color: Colors.grey[800], height: 1.4)),
                    ],
                  ),
                ),

              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: List.generate(question['options'].length, (index) {
                      String option = question['options'][index];
                      bool isSelected = selectedOptionIndex == index;

                      Color bgColor = Colors.white;
                      Color borderColor = Colors.grey[200]!;
                      Color textColor = Colors.black87;

                      if (isChecked) {
                        if (index == question['answer']) {
                          bgColor = const Color(0xFF2EF889);
                          borderColor = Colors.transparent;
                          textColor = Colors.black;
                        } else if (isSelected && index != question['answer']) {
                          bgColor = const Color(0xFFFFCDD2);
                          borderColor = Colors.red;
                        }
                      } else if (isSelected) {
                        bgColor = const Color(0xFFE0F2F1);
                        borderColor = const Color(0xFF2EF889);
                      }

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: GestureDetector(
                          onTap: isChecked ? null : () => setState(() => selectedOptionIndex = index),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                            decoration: BoxDecoration(
                              color: bgColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: borderColor, width: 2),
                              boxShadow: [if (!isChecked) BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 5, offset: const Offset(0, 2))],
                            ),
                            alignment: Alignment.center,
                            child: Text(option, textAlign: TextAlign.center, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor)),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              SizedBox(
                height: screenHeight * 0.075 < 55 ? 55 : screenHeight * 0.075,
                child: ElevatedButton(
                  onPressed: selectedOptionIndex == null ? null : (isChecked ? _nextQuestion : _checkAnswer),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2EF889),
                    foregroundColor: Colors.black,
                    disabledBackgroundColor: Colors.grey[200],
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  child: Text(isChecked ? (currentQuestion == questions.length - 1 ? "Finish Quiz" : "Next Question") : "Check Answer", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}