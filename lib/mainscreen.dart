import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'HomeScreen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'TeacherLoginScreen.dart';

class PlantBuddyLoginScreen extends StatefulWidget {
  const PlantBuddyLoginScreen({super.key});

  @override
  State<PlantBuddyLoginScreen> createState() => _PlantBuddyLoginScreenState();
}

class _PlantBuddyLoginScreenState extends State<PlantBuddyLoginScreen> {
  bool isLogin = true;
  bool isLoading = false;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();

  Future<void> handleSignUp() async {
    String name = _nameController.text.trim();
    String code = _codeController.text.trim();

    if (name.isEmpty || code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in all fields 🌱")),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final query = await FirebaseFirestore.instance
          .collection('users')
          .where('name', isEqualTo: name)
          .get();

      if (query.docs.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Explorer Name already taken! Try another.")),
        );
      } else {
        await FirebaseFirestore.instance.collection('users').add({
          'name': name,
          'code': code,
          'joinedAt': FieldValue.serverTimestamp(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Account created! Please Log In.")),
        );

        setState(() {
          isLogin = true;
          _codeController.clear();
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }

    setState(() => isLoading = false);
  }

  Future<void> handleLogin() async {
    String name = _nameController.text.trim();
    String code = _codeController.text.trim();

    if (name.isEmpty || code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter Name and Code 🌱")),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final query = await FirebaseFirestore.instance
          .collection('users')
          .where('name', isEqualTo: name)
          .where('code', isEqualTo: code)
          .get();

      if (query.docs.isNotEmpty) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', true);
        await prefs.setString('userName', name);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Welcome back, $name!")),
        );

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const Homescreen()),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Invalid Name or Secret Code.")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }

    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    // RESPONSIVE FIX: Get device dimensions
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    // RESPONSIVE FIX: Scale the logo based on screen height
    double logoSize = screenHeight * 0.15;
    if (logoSize < 100) logoSize = 100;
    if (logoSize > 160) logoSize = 160;

    // RESPONSIVE FIX: Button scales based on screen height
    double buttonHeight = screenHeight * 0.07;
    if (buttonHeight < 55) buttonHeight = 55;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Container(
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFE2F6F0),
              Color(0xFFF2FBF7),
              Colors.white,
            ],
            stops: [0.0, 0.4, 1.0],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(height: screenHeight * 0.05),

                  // --- LOGO SECTION ---
                  Container(
                    height: logoSize,
                    width: logoSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(15),
                    child: Image.asset('assests/logo.jpg'),
                  ),
                  SizedBox(height: screenHeight * 0.02),

                  const Text(
                    "Sprouta",
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0D1C2E),
                    ),
                  ),
                  const SizedBox(height: 8),

                  const Text(
                    "Grow together!",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                      letterSpacing: 0.5,
                    ),
                  ),

                  SizedBox(height: screenHeight * 0.04),

                  // --- MAIN LOGIN CARD ---
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 500),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24.0),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.all(Radius.circular(40)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 20,
                            offset: Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Toggle Switch
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F3F6),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () => setState(() => isLogin = true),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      decoration: BoxDecoration(
                                        color: isLogin ? Colors.white : Colors.transparent,
                                        borderRadius: BorderRadius.circular(10),
                                        boxShadow: isLogin
                                            ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))]
                                            : [],
                                      ),
                                      child: Center(child: Text("Log In", style: TextStyle(fontWeight: FontWeight.bold, color: isLogin ? Colors.black87 : Colors.grey))),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () => setState(() => isLogin = false),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      decoration: BoxDecoration(
                                        color: !isLogin ? Colors.white : Colors.transparent,
                                        borderRadius: BorderRadius.circular(10),
                                        boxShadow: !isLogin
                                            ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))]
                                            : [],
                                      ),
                                      child: Center(child: Text("Sign Up", style: TextStyle(fontWeight: FontWeight.bold, color: !isLogin ? Colors.black87 : Colors.grey))),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Inputs
                          _buildInputField(
                            controller: _nameController,
                            icon: Icons.account_circle_outlined,
                            hintText: "Explorer Name",
                            obscureText: false,
                          ),
                          const SizedBox(height: 16),

                          _buildInputField(
                            controller: _codeController,
                            icon: Icons.vpn_key_outlined,
                            hintText: "Secret Code",
                            obscureText: true,
                          ),
                          const SizedBox(height: 32),

                          // Button
                          SizedBox(
                            width: double.infinity,
                            height: buttonHeight,
                            child: ElevatedButton(
                              onPressed: isLoading
                                  ? null
                                  : (isLogin ? handleLogin : handleSignUp),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2EF889),
                                foregroundColor: Colors.black87,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              child: isLoading
                                  ? const CircularProgressIndicator(color: Colors.black87)
                                  : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    isLogin ? "Welcome Back" : "Start Growing",
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.arrow_forward, size: 20),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // --- 🚨 UPDATED: FORGOT CODE & TEACHER LOGIN ONLY ---
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 500),
                    child: Column(
                      children: [
                        // Forgot Secret Code
                        TextButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Recovery coming soon!")));
                          },
                          child: const Text(
                              "Forgot Secret Code?",
                              style: TextStyle(color: Color(0xFF7A8B99), fontWeight: FontWeight.w600, fontSize: 14)
                          ),
                        ),
                        const SizedBox(height: 10),

                        // OR Divider
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Expanded(child: Divider(color: Colors.grey[300], thickness: 1, endIndent: 15, indent: 30)),
                            Text("OR", style: TextStyle(color: Colors.grey[400], fontWeight: FontWeight.bold, fontSize: 12)),
                            Expanded(child: Divider(color: Colors.grey[300], thickness: 1, indent: 15, endIndent: 30)),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Teacher Login Button (Full Width)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const TeacherLoginScreen()),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFE2F6F0), // Light green
                              foregroundColor: const Color(0xFF0F766E), // Dark green text
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            ),
                            icon: const Icon(Icons.school_outlined, size: 20),
                            label: const Text("Teacher Login", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: screenHeight * 0.05), // Bottom spacing for safe area
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required IconData icon,
    required String hintText,
    required bool obscureText,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 20),
          prefixIcon: Icon(icon, color: Colors.grey[400]),
          hintText: hintText,
          hintStyle: TextStyle(color: Colors.grey[400], fontWeight: FontWeight.w500),
        ),
      ),
    );
  }
}