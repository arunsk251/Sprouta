import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'mainscreen.dart';
import 'ClassManagementScreen.dart';
import 'GroupManagementScreen.dart';
import 'GrowthTrackingScreen.dart';
import 'ClassReportsScreen.dart';
import 'ContentLibraryScreen.dart';

class TeacherDashboardScreen extends StatefulWidget {
  const TeacherDashboardScreen({super.key});

  @override
  State<TeacherDashboardScreen> createState() => _TeacherDashboardScreenState();
}

class _TeacherDashboardScreenState extends State<TeacherDashboardScreen> {
  String teacherName = "";
  String schoolName = "";

  @override
  void initState() {
    super.initState();
    _loadTeacherData();
  }

  Future<void> _loadTeacherData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      teacherName = prefs.getString('userName') ?? "Educator";
      schoolName = prefs.getString('schoolName') ?? "School Name";
    });
  }

  Future<void> _handleLogout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const PlantBuddyLoginScreen()),
            (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F9),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 30),

              // 🚨 FULLY DYNAMIC STATS GRID
              // Uses nested StreamBuilders to accurately count both collections
              StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('classes').where('teacherName', isEqualTo: teacherName).snapshots(),
                  builder: (context, classSnapshot) {
                    int totalClasses = classSnapshot.hasData ? classSnapshot.data!.docs.length : 0;

                    return StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance.collection('groups').where('teacherName', isEqualTo: teacherName).snapshots(),
                        builder: (context, groupSnapshot) {
                          int totalGroups = groupSnapshot.hasData ? groupSnapshot.data!.docs.length : 0;

                          return Row(
                            children: [
                              Expanded(child: _buildStatCard(Icons.school_outlined, totalClasses.toString(), "TOTAL CLASSES", const Color(0xFFE0F2FE), const Color(0xFF0284C7))),
                              const SizedBox(width: 16),
                              Expanded(child: _buildStatCard(Icons.groups_outlined, totalGroups.toString(), "TOTAL GROUPS", const Color(0xFFF3E8FF), const Color(0xFF9333EA))),
                            ],
                          );
                        }
                    );
                  }
              ),

              const SizedBox(height: 30),

              // 🚨 MENU ITEMS
              _buildMenuItem(Icons.school_outlined, "Classes", "Manage your grade levels", onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => ClassManagementScreen(teacherName: teacherName)));
              }),
              const SizedBox(height: 16),
              _buildMenuItem(Icons.hub_outlined, "Student Groups", "Monitor group activities", onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => GroupManagementScreen(teacherName: teacherName)));
              }),
              const SizedBox(height: 16),
              _buildMenuItem(Icons.library_books_outlined, "Content Library", "Curriculum & media", onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const ContentLibraryScreen()));
              }),
              const SizedBox(height: 16),
              _buildMenuItem(Icons.show_chart_rounded, "Plant Progress", "Life cycle tracking", onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => GrowthTrackingScreen(teacherName: teacherName)));
              }),
              const SizedBox(height: 16),
              _buildMenuItem(Icons.bar_chart_rounded, "Reports", "Class growth analytics", onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => ClassReportsScreen(teacherName: teacherName)));
              }),

              const SizedBox(height: 30), // Padding at the bottom
            ],
          ),
        ),
      ),
    );
  }

  // --- UI HELPER COMPONENTS ---

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Hello, $teacherName!", style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF0D1C2E), height: 1.2)),
              const SizedBox(height: 8),
              Text("$schoolName • Lead\nEducator", style: const TextStyle(fontSize: 16, color: Color(0xFF64748B), height: 1.4)),
            ],
          ),
        ),
        GestureDetector(
          onTap: _handleLogout,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))]),
            child: const Icon(Icons.logout_rounded, color: Color(0xFF0D1C2E)),
          ),
        )
      ],
    );
  }

  Widget _buildStatCard(IconData icon, String value, String label, Color bgColor, Color iconColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: iconColor, size: 28)),
          const SizedBox(height: 20),
          Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF0D1C2E))),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B), letterSpacing: 0.5)),
        ],
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, String subtitle, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))]),
        child: Row(
          children: [
            Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: const Color(0xFFE2F6F0), borderRadius: BorderRadius.circular(16)), child: Icon(icon, color: const Color(0xFF0F766E), size: 28)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0D1C2E))),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(fontSize: 14, color: Color(0xFF64748B))),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFFCBD5E1), size: 30),
          ],
        ),
      ),
    );
  }
}