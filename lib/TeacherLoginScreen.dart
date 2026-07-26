import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'TeacherSignUpScreen.dart';
import 'TeacherDashboardScreen.dart';

class TeacherLoginScreen extends StatefulWidget {
  const TeacherLoginScreen({super.key});

  @override
  State<TeacherLoginScreen> createState() => _TeacherLoginScreenState();
}

class _TeacherLoginScreenState extends State<TeacherLoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool isLoading = false;

  Future<void> handleTeacherLogin() async {
    // 🚨 FIX: Force lowercase so it perfectly matches the database
    String email = _emailController.text.trim().toLowerCase();
    String password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter your Email and Password.")),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final query = await FirebaseFirestore.instance
          .collection('teachers')
          .where('email', isEqualTo: email)
          .where('password', isEqualTo: password)
          .get();

      if (query.docs.isNotEmpty) {
        String teacherName = query.docs.first['name'];
        String schoolName = query.docs.first['school'];

        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', true);
        await prefs.setBool('isTeacher', true);
        await prefs.setString('userName', teacherName);
        await prefs.setString('schoolName', schoolName);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Welcome back, $teacherName!", style: const TextStyle(fontWeight: FontWeight.bold)), backgroundColor: Colors.green),
          );

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const TeacherDashboardScreen()),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Invalid Email or Password.")),
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
    double screenHeight = MediaQuery.of(context).size.height;
    double buttonHeight = screenHeight * 0.07;
    if (buttonHeight < 55) buttonHeight = 55;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 450),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 40),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(40),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10)),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(height: 8, width: 50, decoration: BoxDecoration(color: const Color(0xFF2EF889), borderRadius: BorderRadius.circular(10))),
                    const SizedBox(height: 30),
                    const Text("Sprouta for\nTeachers", textAlign: TextAlign.center, style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: Color(0xFF0D1C2E), height: 1.1)),
                    const SizedBox(height: 15),
                    const Text("Welcome back! Log in to\nmanage your classes.", textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Color(0xFF64748B), height: 1.4)),
                    const SizedBox(height: 40),

                    // 🚨 FIX: Applied email keyboard
                    _buildLabeledInput(label: "Email Address", hintText: "teacher@school.edu", controller: _emailController, obscureText: false, keyboardType: TextInputType.emailAddress),
                    const SizedBox(height: 20),
                    _buildLabeledInput(label: "Password", hintText: "••••••••", controller: _passwordController, obscureText: true),
                    const SizedBox(height: 10),

                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Password reset coming soon!"))); },
                        style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(50, 30), tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                        child: const Text("Forgot password?", style: TextStyle(color: Color(0xFF2EF889), fontWeight: FontWeight.w600, fontSize: 14)),
                      ),
                    ),
                    const SizedBox(height: 25),

                    SizedBox(
                      width: double.infinity, height: buttonHeight,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : handleTeacherLogin,
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2EF889), foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                        child: isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("Log In", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                    ),
                    const SizedBox(height: 30),
                    Divider(color: Colors.grey[200], thickness: 1),
                    const SizedBox(height: 20),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Don't have an account? ", style: TextStyle(color: Color(0xFF64748B), fontSize: 14)),
                        GestureDetector(
                          onTap: () { Navigator.push(context, MaterialPageRoute(builder: (context) => const TeacherSignUpScreen())); },
                          child: const Text("Sign Up", style: TextStyle(color: Color(0xFF2EF889), fontWeight: FontWeight.bold, fontSize: 14)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    TextButton.icon(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(foregroundColor: const Color(0xFF94A3B8)),
                      icon: const Icon(Icons.arrow_back, size: 18),
                      label: const Text("Back to Student Login", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 🚨 FIX: Added keyboardType parameter
  Widget _buildLabeledInput({required String label, required String hintText, required TextEditingController controller, required bool obscureText, TextInputType keyboardType = TextInputType.text}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF0D1C2E))),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(16)),
          child: TextField(
            controller: controller,
            obscureText: obscureText,
            keyboardType: keyboardType, // 🚨 Applies the specific keyboard
            decoration: InputDecoration(border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16), hintText: hintText, hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.w400)),
          ),
        ),
      ],
    );
  }
}