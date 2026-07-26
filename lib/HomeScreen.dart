import 'dart:convert';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geolocator/geolocator.dart';
import 'mainscreen.dart';
import 'AddPlantScreen.dart';
import 'ScanPlantScreen.dart';
import 'LearnScreen.dart';
import 'PlayScreen.dart';
import 'BadgesScreen.dart';
import 'Notification_service.dart';

class Homescreen extends StatefulWidget {
  const Homescreen({super.key});

  @override
  State<Homescreen> createState() => _HomescreenState();
}

class _HomescreenState extends State<Homescreen> {
  String userName = "Explorer";
  String userAvatar = "assests/sunflower.png";
  int currentPlantIndex = 0;
  int _selectedIndex = 0;

  Stream<QuerySnapshot>? _userDataStream;
  List<dynamic> _plantLibrary = [];
  StreamSubscription<String?>? _notificationSubscription;

  // --- Live Weather Variables ---
  String _temperature = "--";
  String _weatherAdvice = "Checking local skies...";
  IconData _weatherIcon = Icons.location_searching;
  Color _weatherColor = Colors.grey;
  String _cityName = "your area";

  final List<String> allStages = ["Seed", "Sprout", "Young", "Adult", "Bloom"];
  final List<String> avatarOptions = ["assests/green.png", "assests/recyclebin.png", "assests/rrr.png", "assests/eco.png"];

  @override
  void initState() {
    super.initState();
    _initStream();
    _loadPlantLibrary();
    _fetchLiveWeather();

    NotificationService.scheduleDailyScanReminder();

    _notificationSubscription = NotificationService.selectNotificationStream.stream.listen((String? payload) {
      if (payload == 'watering_reminder') {
        _showWateringDialog();
      }
    });

    _checkForNotificationLaunch();
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    super.dispose();
  }

  Future<Position?> _determinePosition() async {
    LocationPermission permission;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return null;
    }
    if (permission == LocationPermission.deniedForever) return null;

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please turn on your GPS for exact local weather! 📍")));
      return null;
    }

    return await Geolocator.getCurrentPosition();
  }

  Future<void> _fetchLiveWeather() async {
    try {
      final apiKey = dotenv.env['WEATHER_API_KEY'] ?? '';
      if (apiKey.isEmpty) return;

      Position? position = await _determinePosition();
      String query = position != null ? "${position.latitude},${position.longitude}" : "auto:ip";

      final url = Uri.parse('http://api.weatherapi.com/v1/current.json?key=$apiKey&q=$query');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final temp = data['current']['temp_c'].round().toString();
        final condition = data['current']['condition']['text'].toString().toLowerCase();

        final String fetchedCity = data['location']['name'] ?? "your area";

        final dynamic isDayData = data['current']['is_day'];
        final bool isDay = (isDayData == 1 || isDayData == '1');

        if (mounted) {
          setState(() {
            _temperature = temp;
            _cityName = fetchedCity;

            if (!isDay) {
              if (condition.contains('rain') || condition.contains('drizzle') || condition.contains('shower')) {
                _weatherAdvice = "It's $temp°C and rainy tonight! 🌧️ The plants are getting a midnight drink.";
                _weatherIcon = Icons.water_drop;
                _weatherColor = Colors.blue;
              } else if (condition.contains('cloud') || condition.contains('overcast')) {
                _weatherAdvice = "It's $temp°C and cloudy tonight. ☁️ Time for your plants to rest!";
                _weatherIcon = Icons.cloud;
                _weatherColor = Colors.blueGrey;
              } else {
                _weatherAdvice = "It's a clear $temp°C night! 🌙 The stars are out and it's time to rest.";
                _weatherIcon = Icons.nights_stay_rounded;
                _weatherColor = Colors.indigo;
              }
            } else {
              if (condition.contains('sun') || condition.contains('clear')) {
                _weatherAdvice = "It's a bright $temp°C! ☀️ Perfect time to give your plants some natural light.";
                _weatherIcon = Icons.wb_sunny_rounded;
                _weatherColor = Colors.orange;
              } else if (condition.contains('rain') || condition.contains('drizzle') || condition.contains('shower')) {
                _weatherAdvice = "It's $temp°C and rainy! 🌧️ Outdoor plants are getting a free drink today.";
                _weatherIcon = Icons.water_drop;
                _weatherColor = Colors.blue;
              } else {
                _weatherAdvice = "It's $temp°C and cloudy! ☁️ Make sure indoor plants are close to a window.";
                _weatherIcon = Icons.cloud;
                _weatherColor = Colors.blueGrey;
              }
            }
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() => _weatherAdvice = "Couldn't load weather right now. Check your connection!");
    }
  }

  Future<void> _checkForNotificationLaunch() async {
    final details = await NotificationService.getLaunchDetails();
    if (details != null && details.didNotificationLaunchApp) {
      if (details.notificationResponse?.payload == 'watering_reminder') {
        Future.delayed(const Duration(seconds: 1), () { if (mounted) _showWateringDialog(); });
      }
    }
  }

  Future<void> _initStream() async {
    final prefs = await SharedPreferences.getInstance();
    final storedName = prefs.getString('userName') ?? "Explorer";
    final storedAvatar = prefs.getString('userAvatar') ?? "assests/sunflower.png";

    setState(() {
      userName = storedName;
      userAvatar = storedAvatar;
      _userDataStream = FirebaseFirestore.instance.collection('users').where('name', isEqualTo: userName).snapshots();
    });
    _setupDailyReminder();
  }

  Future<void> _setupDailyReminder() async {
    try {
      final query = await FirebaseFirestore.instance.collection('users').where('name', isEqualTo: userName).get();
      if (query.docs.isNotEmpty) {
        String lastWatered = query.docs.first.data()['last_watered_date'] ?? "";
        String today = DateTime.now().toIso8601String().split('T')[0];
        NotificationService.scheduleDailyReminder(skipToday: lastWatered == today);
      } else {
        NotificationService.scheduleDailyReminder(skipToday: false);
      }
    } catch (e) { NotificationService.scheduleDailyReminder(skipToday: false); }
  }

  Future<void> _loadPlantLibrary() async {
    try {
      final String response = await rootBundle.loadString('assests/plant_data.json');
      setState(() => _plantLibrary = json.decode(response));
    } catch (e) {}
  }

  Map<String, String> _getPlantDetails(String plantType) {
    final defaultData = {"water": "Check soil moisture daily.", "feed": "Needs sunlight and care.", "size": "Varies by season."};
    if (_plantLibrary.isEmpty) return defaultData;
    try {
      final plantData = _plantLibrary.firstWhere((p) => p['name'] == plantType, orElse: () => defaultData);
      return {"water": plantData['water'], "feed": plantData['feed'], "size": plantData['size']};
    } catch (e) { return defaultData; }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: _selectedIndex == 0 ? _buildGardenBody() : _selectedIndex == 1 ? const LearnScreen() : _selectedIndex == 2 ? PlayScreen(userName: userName) : BadgesScreen(userName: userName),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) => setState(() => _selectedIndex = index),
        backgroundColor: Colors.white,
        elevation: 10,
        indicatorColor: const Color(0xFFE2F6F0),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.local_florist_outlined), selectedIcon: Icon(Icons.local_florist, color: Colors.green), label: 'Garden'),
          NavigationDestination(icon: Icon(Icons.menu_book_outlined), label: 'Learn'),
          NavigationDestination(icon: Icon(Icons.gamepad_outlined), label: 'Play'),
          NavigationDestination(icon: Icon(Icons.emoji_events_outlined), selectedIcon: Icon(Icons.emoji_events, color: Colors.amber), label: 'Badges'),
        ],
      ),
    );
  }

  Widget _buildGardenBody() {
    if (_userDataStream == null) return const Center(child: CircularProgressIndicator());

    // 🚨 RESPONSIVE FIX: Grab device dimensions here
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;

    return StreamBuilder<QuerySnapshot>(
      stream: _userDataStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text("User not found"));

        final userData = snapshot.data!.docs.first.data() as Map<String, dynamic>;

        if (userData.containsKey('avatar') && userData['avatar'] != userAvatar) {
          WidgetsBinding.instance.addPostFrameCallback((_) { if(mounted) setState(() => userAvatar = userData['avatar']); });
        }

        List<Map<String, dynamic>> myPlants = [];
        if (userData.containsKey('plants') && userData['plants'] != null) myPlants = List<Map<String, dynamic>>.from(userData['plants']);
        if (currentPlantIndex >= myPlants.length) currentPlantIndex = 0;

        final plant = myPlants.isNotEmpty ? myPlants[currentPlantIndex] : null;
        final String plantName = plant?['name'] ?? "No Plant";
        final String plantType = plant?['type'] ?? "Sunflower";
        final String plantStatus = plant?['status'] ?? "Unknown";
        final String plantStage = plant?['stage'] ?? "Seed";

        String plantImage = plant?['image'] ?? "assests/sunflower.png";

        bool isScanned = plantStatus != "Unknown";
        int currentStageLevel = _getStageIndex(plantStage);

        if (plantType.toLowerCase() == 'tomato') {
          List<String> tomatoStageImages = [
            'assests/1.png', 'assests/2.png', 'assests/3.png', 'assests/4.png', 'assests/5.png'
          ];
          if (currentStageLevel >= 0 && currentStageLevel < tomatoStageImages.length) {
            plantImage = tomatoStageImages[currentStageLevel];
          }
        }

        final details = _getPlantDetails(plantType);

        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(onTap: _showProfileEditor, child: Row(children: [CircleAvatar(radius: 22, backgroundImage: AssetImage(userAvatar), backgroundColor: Colors.white), const SizedBox(width: 12), Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(_getGreeting(), style: TextStyle(color: Colors.grey[600], fontSize: 14)), Text(userName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Color(0xFF0D1C2E)))]),])),
                    Row(children: [GestureDetector(onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AddPlantScreen())), child: _buildHeaderButton(Icons.add, const Color(0xFF2EF889))), const SizedBox(width: 10), GestureDetector(onTap: _handleLogout, child: _buildHeaderButton(Icons.logout, Colors.white))])
                  ],
                ),
                const SizedBox(height: 25),
                Center(child: myPlants.isEmpty ? const Text("Add a plant to start!", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)) : RichText(textAlign: TextAlign.center, text: TextSpan(style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF0D1C2E), height: 1.2), children: isScanned ? [TextSpan(text: "Your $plantType is\n"), TextSpan(text: "$plantStatus!", style: const TextStyle(color: Color(0xFF2EF889)))] : [const TextSpan(text: "Use Plant Doc\n"), const TextSpan(text: "to know status", style: TextStyle(color: Colors.grey, fontSize: 22))]))),
                const SizedBox(height: 25),
                Container(
                  // 🚨 RESPONSIVE FIX: Image now perfectly adapts to 45% of any screen height
                  height: screenHeight * 0.45,
                  width: double.infinity,
                  decoration: BoxDecoration(color: const Color(0xFFE8E6E1), borderRadius: BorderRadius.circular(30), image: DecorationImage(image: AssetImage(plantImage), fit: BoxFit.cover, alignment: Alignment.center), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5))]),
                  child: Stack(
                    children: [
                      Positioned(top: 20, left: 20, right: 20, child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)), child: Text(myPlants.isEmpty ? "0/0" : "${currentPlantIndex + 1}/${myPlants.length}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)))])),
                      // 🚨 RESPONSIVE FIX: Center arrows vertically relative to the container
                      if (currentPlantIndex > 0) Positioned(left: 15, top: (screenHeight * 0.45) / 2 - 18, child: GestureDetector(onTap: () => setState(() => currentPlantIndex--), child: const CircleAvatar(backgroundColor: Colors.white54, radius: 18, child: Icon(Icons.chevron_left, color: Colors.black54)))),
                      if (currentPlantIndex < myPlants.length - 1) Positioned(right: 15, top: (screenHeight * 0.45) / 2 - 18, child: GestureDetector(onTap: () => setState(() => currentPlantIndex++), child: const CircleAvatar(backgroundColor: Colors.white54, radius: 18, child: Icon(Icons.chevron_right, color: Colors.black54)))),
                      Positioned(
                          bottom: 0, left: 0, right: 0,
                          child: Container(
                            // 🚨 RESPONSIVE FIX: Timeline gradient adapts to 16% of height
                              height: screenHeight * 0.16,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                              decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.black.withOpacity(0.0), Colors.black.withOpacity(0.8)]), borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30))),
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.end, children: [Text(plantName.toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)), const SizedBox(height: 10), Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [_buildTimelineItem("SEED", 0 <= currentStageLevel), _buildTimelineLine(0 < currentStageLevel), _buildTimelineItem("SPROUT", 1 <= currentStageLevel), _buildTimelineLine(1 < currentStageLevel), _buildTimelineItem("YOUNG", 2 <= currentStageLevel), _buildTimelineLine(2 < currentStageLevel), _buildTimelineItem("ADULT", 3 <= currentStageLevel), _buildTimelineLine(3 < currentStageLevel), _buildTimelineItem("BLOOM", 4 <= currentStageLevel)])])
                          )
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 25),
                if (myPlants.isNotEmpty)
                  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // 🚨 RESPONSIVE FIX: Pass screenWidth to scale buttons perfectly
                        _buildActionCard(Icons.water_drop, "Water", const Color(0xFF2EF889), screenWidth, () => _showWateringDialog()),
                        _buildActionCard(Icons.sunny, "Feed", const Color(0xFFFFE0B2), screenWidth, () => _showPlantInfo("Sun & Food", details['feed']!, Icons.sunny, Colors.orange)),
                        _buildActionCard(Icons.update_rounded, "Update", const Color(0xFFE3F2FD), screenWidth, () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => ScanPlantScreen(plantIndex: currentPlantIndex, plants: myPlants, userName: userName, isPlantDoc: false)));
                        }),
                        _buildActionCard(Icons.medical_services_outlined, "Plant Doc", const Color(0xFFE0F2F1), screenWidth, () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => ScanPlantScreen(plantIndex: currentPlantIndex, plants: myPlants, userName: userName, isPlantDoc: true)));
                        }),
                      ]),
                const SizedBox(height: 30),
                if (myPlants.isNotEmpty) _buildWeatherWidget(),
                const SizedBox(height: 30),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildWeatherWidget() {
    return Container(
      width: double.infinity, padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: _weatherColor.withOpacity(0.1), borderRadius: BorderRadius.circular(25), border: Border.all(color: _weatherColor.withOpacity(0.5), width: 2)),
      child: Row(children: [
        Container(padding: const EdgeInsets.all(12), decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))]), child: Icon(_weatherIcon, color: _weatherColor, size: 28)),
        const SizedBox(width: 15),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text("Forecast in $_cityName", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0D1C2E))),
          const SizedBox(height: 6),
          Text(_weatherAdvice, style: const TextStyle(fontSize: 13, color: Colors.black87, height: 1.4))
        ])),
      ]),
    );
  }

  void _showProfileEditor() {
    TextEditingController nameController = TextEditingController(text: userName);
    String tempSelectedAvatar = userAvatar;
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: EdgeInsets.only(top: 30, left: 30, right: 30, bottom: MediaQuery.of(context).viewInsets.bottom + 30),
              decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("Edit Profile", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)), const SizedBox(height: 20), const Text("Choose your look:", style: TextStyle(color: Colors.grey, fontSize: 12)), const SizedBox(height: 15),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: avatarOptions.map((avatar) {
                    bool isSelected = tempSelectedAvatar == avatar;
                    return GestureDetector(onTap: () => setModalState(() => tempSelectedAvatar = avatar), child: Container(padding: const EdgeInsets.all(4), decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: isSelected ? const Color(0xFF2EF889) : Colors.transparent, width: 3)), child: CircleAvatar(radius: 25, backgroundImage: AssetImage(avatar), backgroundColor: Colors.grey[200])));
                  }).toList()),
                  const SizedBox(height: 30),
                  TextField(controller: nameController, decoration: InputDecoration(labelText: "Your Name", border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)), filled: true, fillColor: const Color(0xFFF5F7FA))),
                  const SizedBox(height: 30),
                  SizedBox(width: double.infinity, height: 50, child: ElevatedButton(onPressed: () async {
                    if (nameController.text.trim().isNotEmpty) { Navigator.pop(context); await _updateUserProfile(nameController.text.trim(), tempSelectedAvatar); }
                  }, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2EF889), foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))), child: const Text("Save Changes", style: TextStyle(fontWeight: FontWeight.bold))))
                ],
              ),
            );
          }
      ),
    );
  }

  Future<void> _updateUserProfile(String newName, String newAvatar) async {
    try {
      final query = await FirebaseFirestore.instance.collection('users').where('name', isEqualTo: userName).get();
      if (query.docs.isNotEmpty) {
        String docId = query.docs.first.id;
        await FirebaseFirestore.instance.collection('users').doc(docId).update({'name': newName, 'avatar': newAvatar});
        final prefs = await SharedPreferences.getInstance(); await prefs.setString('userName', newName); await prefs.setString('userAvatar', newAvatar);
        setState(() { userName = newName; userAvatar = newAvatar; _userDataStream = FirebaseFirestore.instance.collection('users').where('name', isEqualTo: newName).snapshots(); });
        if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Profile updated! 🌟")));
      }
    } catch (e) { if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"))); }
  }

  Future<void> _handleSnooze() async {
    try {
      final query = await FirebaseFirestore.instance.collection('users').where('name', isEqualTo: userName).get();
      if (query.docs.isNotEmpty) {
        String lastWateredDate = query.docs.first.data()['last_watered_date'] ?? "";
        String today = DateTime.now().toIso8601String().split('T')[0];

        if (lastWateredDate == today) {
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("You already watered them today! No need for a reminder. 💧"), backgroundColor: Colors.blue));
        } else {
          NotificationService.scheduleTwoHourReminder();
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Got it! We'll remind you in 2 hours. ⏰"), backgroundColor: Colors.orange));
        }
      }
    } catch (e) { print("Error checking before snooze: $e"); }
  }

  Future<void> _recordWatering() async {
    try {
      final query = await FirebaseFirestore.instance.collection('users').where('name', isEqualTo: userName).get();
      if (query.docs.isNotEmpty) {
        String docId = query.docs.first.id;
        Map<String, dynamic> data = query.docs.first.data();

        int currentPoints = data['points'] ?? 0;
        String lastWateredDate = data['last_watered_date'] ?? "";
        String today = DateTime.now().toIso8601String().split('T')[0];

        if (lastWateredDate != today) {
          await FirebaseFirestore.instance.collection('users').doc(docId).update({'points': currentPoints + 10, 'last_watered_date': today});
          NotificationService.scheduleDailyReminder(skipToday: true);
          NotificationService.cancelSnooze();
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Great job keeping them hydrated! +10 XP 🌟"), backgroundColor: Colors.green));
        } else {
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("You already watered them today! Good job! 💧"), backgroundColor: Colors.blue));
        }
      }
    } catch (e) { print("Error recording watering: $e"); }
  }

  void _showWateringDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(children: const [Icon(Icons.eco, color: Colors.green), SizedBox(width: 10), Text("Plant Check!", style: TextStyle(fontWeight: FontWeight.bold))]),
        content: const Text("Did you water your plants today?", style: TextStyle(fontSize: 16)),
        actionsPadding: const EdgeInsets.only(bottom: 15, right: 15, left: 15),
        actions: [
          TextButton(onPressed: () { Navigator.pop(context); _handleSnooze(); }, child: const Text("Remind me in 2hrs", style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold))),
          ElevatedButton(onPressed: () { Navigator.pop(context); _recordWatering(); }, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2EF889), foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))), child: const Text("Yes, I did!", style: TextStyle(fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  void _showPlantInfo(String title, String content, IconData icon, Color color) {
    showModalBottomSheet(
      context: context, backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(30), decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle), child: Icon(icon, color: color, size: 40)),
            const SizedBox(height: 20), Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10), Text(content, textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Colors.grey[600], height: 1.5)),
            const SizedBox(height: 30), SizedBox(width: double.infinity, height: 50, child: ElevatedButton(onPressed: () => Navigator.pop(context), style: ElevatedButton.styleFrom(backgroundColor: color, foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))), child: const Text("Got it!", style: TextStyle(fontWeight: FontWeight.bold))))
          ],
        ),
      ),
    );
  }

  Future<void> _handleLogout() async {
    final prefs = await SharedPreferences.getInstance(); await prefs.clear();
    if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const PlantBuddyLoginScreen()));
  }

  String _getGreeting() {
    var hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning,'; if (hour < 17) return 'Good Afternoon,';
    if (hour < 21) return 'Good Evening,'; return 'Good Night,';
  }

  int _getStageIndex(String currentStage) {
    String normalized = currentStage[0].toUpperCase() + currentStage.substring(1).toLowerCase();
    int index = allStages.indexOf(normalized); return index != -1 ? index : 0;
  }

  Widget _buildHeaderButton(IconData icon, Color color) { return Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color == const Color(0xFF2EF889) ? color : Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]), child: Icon(icon, color: color == const Color(0xFF2EF889) ? Colors.black : Colors.black87, size: 24)); }
  Widget _buildTimelineItem(String label, bool isActive) { return Column(mainAxisSize: MainAxisSize.min, children: [Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: isActive ? const Color(0xFF2EF889) : Colors.white24, shape: BoxShape.circle), child: Icon(isActive ? Icons.eco : Icons.circle, size: 12, color: isActive ? Colors.black : Colors.white60)), const SizedBox(height: 4), Text(label, style: TextStyle(fontSize: 8, color: isActive ? const Color(0xFF2EF889) : Colors.white60, fontWeight: FontWeight.bold))]); }
  Widget _buildTimelineLine(bool isActive) { return Expanded(child: Container(height: 2, color: isActive ? const Color(0xFF2EF889) : Colors.white24)); }

  // 🚨 RESPONSIVE FIX: Action cards now scale relative to screen width (16% width each)
  Widget _buildActionCard(IconData icon, String label, Color color, double screenWidth, VoidCallback onTap) {
    double cardSize = screenWidth * 0.16; // Perfectly scales
    if (cardSize < 55) cardSize = 55; // Safety minimum size

    return GestureDetector(onTap: onTap, child: Column(children: [Container(height: cardSize, width: cardSize, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(18)), child: Icon(icon, size: cardSize * 0.45, color: Colors.black87)), const SizedBox(height: 8), Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12))]));
  }
}