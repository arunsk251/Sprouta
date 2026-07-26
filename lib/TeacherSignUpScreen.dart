import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TeacherSignUpScreen extends StatefulWidget {
  const TeacherSignUpScreen({super.key});

  @override
  State<TeacherSignUpScreen> createState() => _TeacherSignUpScreenState();
}

class _TeacherSignUpScreenState extends State<TeacherSignUpScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _schoolController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool isLoading = false;

  Future<void> handleTeacherSignUp() async {
    String name = _nameController.text.trim();
    String school = _schoolController.text.trim();
    // 🚨 FIX: Force email to lowercase so login matching never fails
    String email = _emailController.text.trim().toLowerCase();
    String password = _passwordController.text;

    if (name.isEmpty || school.isEmpty || email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in all fields.")),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final query = await FirebaseFirestore.instance
          .collection('teachers')
          .where('email', isEqualTo: email)
          .get();

      if (query.docs.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Email already in use! Try logging in.")),
        );
      } else {
        await FirebaseFirestore.instance.collection('teachers').add({
          'name': name,
          'school': school,
          'email': email,
          'password': password,
          'joinedAt': FieldValue.serverTimestamp(),
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Account created! Please Log In.", style: TextStyle(fontWeight: FontWeight.bold)), backgroundColor: Colors.green),
          );
          Navigator.pop(context);
        }
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
                    Container(
                      height: 64, width: 64,
                      decoration: BoxDecoration(color: const Color(0xFF2EF889), borderRadius: BorderRadius.circular(16)),
                      child: const Icon(Icons.school_outlined, color: Colors.white, size: 36),
                    ),
                    const SizedBox(height: 24),
                    const Text("Sprouta for\nTeachers", textAlign: TextAlign.center, style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: Color(0xFF0D1C2E), height: 1.1)),
                    const SizedBox(height: 12),
                    const Text("Join the growing community of\neducators.", textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Color(0xFF64748B), height: 1.4)),
                    const SizedBox(height: 40),

                    // 🚨 FIX: Added keyboardTypes for better UX
                    _buildLabeledInput(label: "Full Name", hintText: "Ms. Jennifer Adams", controller: _nameController, obscureText: false, keyboardType: TextInputType.name),
                    const SizedBox(height: 20),
                    _buildLabeledInput(label: "School Name", hintText: "Greenwood Elementary", controller: _schoolController, obscureText: false, keyboardType: TextInputType.text),
                    const SizedBox(height: 20),
                    _buildLabeledInput(label: "Email Address", hintText: "teacher@school.edu", controller: _emailController, obscureText: false, keyboardType: TextInputType.emailAddress),
                    const SizedBox(height: 20),
                    _buildLabeledInput(label: "Password", hintText: "••••••••", controller: _passwordController, obscureText: true),
                    const SizedBox(height: 35),

                    SizedBox(
                      width: double.infinity, height: buttonHeight,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : handleTeacherSignUp,
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2EF889), foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                        child: isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("Sign Up", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                    ),
                    const SizedBox(height: 30),
                    Divider(color: Colors.grey[200], thickness: 1),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Already have an account? ", style: TextStyle(color: Color(0xFF64748B), fontSize: 14)),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: const Text("Log In", style: TextStyle(color: Color(0xFF2EF889), fontWeight: FontWeight.bold, fontSize: 14)),
                        ),
                      ],
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