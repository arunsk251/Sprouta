import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';
import 'GroupManagementScreen.dart';

class ClassManagementScreen extends StatefulWidget {
  final String teacherName;
  const ClassManagementScreen({super.key, required this.teacherName});

  @override
  State<ClassManagementScreen> createState() => _ClassManagementScreenState();
}

class _ClassManagementScreenState extends State<ClassManagementScreen> {

  // Generates a random class code like "SP3421"
  String _generateClassCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    Random rnd = Random();
    return String.fromCharCodes(Iterable.generate(6, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))));
  }

  // 🚨 REDESIGNED: Modern Create Class Dialog
  void _showCreateClassDialog() {
    TextEditingController classController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          backgroundColor: Colors.white,
          elevation: 10,
          child: Padding(
            padding: const EdgeInsets.all(28.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: const Color(0xFFE2F6F0), borderRadius: BorderRadius.circular(16)),
                      child: const Icon(Icons.school_rounded, color: Color(0xFF0F766E), size: 24),
                    ),
                    const SizedBox(width: 16),
                    const Text("New Class", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: Color(0xFF0D1C2E))),
                  ],
                ),
                const SizedBox(height: 30),

                const Text("CLASS NAME", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8), letterSpacing: 1)),
                const SizedBox(height: 8),
                TextField(
                  controller: classController,
                  decoration: _modernInputDecoration(hint: "e.g. Grade 4B"),
                ),
                const SizedBox(height: 36),

                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                            backgroundColor: const Color(0xFFF8FAFC),
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))
                        ),
                        child: const Text("Cancel", style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          if (classController.text.isNotEmpty) {
                            await FirebaseFirestore.instance.collection('classes').add({
                              'className': classController.text.trim(),
                              'teacherName': widget.teacherName,
                              'code': _generateClassCode(),
                              'status': 'Active',
                              'createdAt': FieldValue.serverTimestamp(),
                            });
                            if (mounted) Navigator.pop(context);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2EF889),
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))
                        ),
                        child: const Text("Create", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        );
      },
    );
  }

  // 🚨 REDESIGNED: Modern Edit Class Dialog
  void _showEditClassDialog(String docId, String currentName) {
    TextEditingController editController = TextEditingController(text: currentName);

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          backgroundColor: Colors.white,
          elevation: 10,
          child: Padding(
            padding: const EdgeInsets.all(28.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: const Color(0xFFE0F2FE), borderRadius: BorderRadius.circular(16)),
                      child: const Icon(Icons.edit_rounded, color: Color(0xFF0284C7), size: 24),
                    ),
                    const SizedBox(width: 16),
                    const Text("Edit Class", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: Color(0xFF0D1C2E))),
                  ],
                ),
                const SizedBox(height: 30),

                const Text("CLASS NAME", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8), letterSpacing: 1)),
                const SizedBox(height: 8),
                TextField(
                  controller: editController,
                  decoration: _modernInputDecoration(hint: "e.g. Grade 4B"),
                ),
                const SizedBox(height: 36),

                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                            backgroundColor: const Color(0xFFF8FAFC),
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))
                        ),
                        child: const Text("Cancel", style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          if (editController.text.isNotEmpty && editController.text != currentName) {
                            await FirebaseFirestore.instance.collection('classes').doc(docId).update({
                              'className': editController.text.trim(),
                            });
                            if (mounted) Navigator.pop(context);
                          } else {
                            Navigator.pop(context);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0284C7),
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))
                        ),
                        child: const Text("Save", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        );
      },
    );
  }

  InputDecoration _modernInputDecoration({String hint = ""}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey[400]),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey[200]!, width: 1.5)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF2EF889), width: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F9),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
          child: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.black), onPressed: () => Navigator.pop(context)),
        ),
        title: const Text("Class Management", style: TextStyle(color: Color(0xFF0D1C2E), fontWeight: FontWeight.bold, fontSize: 22)),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              const SizedBox(height: 20),

              StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('classes').where('teacherName', isEqualTo: widget.teacherName).snapshots(),
                  builder: (context, snapshot) {
                    int totalClasses = snapshot.hasData ? snapshot.data!.docs.length : 0;
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("$totalClasses Classes Total", style: const TextStyle(fontSize: 16, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
                        ElevatedButton.icon(
                          onPressed: _showCreateClassDialog,
                          icon: const Icon(Icons.add, size: 20),
                          label: const Text("New Class", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2EF889),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        )
                      ],
                    );
                  }
              ),
              const SizedBox(height: 24),

              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('classes')
                      .where('teacherName', isEqualTo: widget.teacherName)
                      .orderBy('createdAt', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: Color(0xFF2EF889)));
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text("No classes yet. Click 'New Class' to start!", style: TextStyle(color: Colors.grey)));

                    return ListView.builder(
                      itemCount: snapshot.data!.docs.length,
                      itemBuilder: (context, index) {
                        return _buildClassCard(snapshot.data!.docs[index]);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildClassCard(DocumentSnapshot doc) {
    var data = doc.data() as Map<String, dynamic>;
    String docId = doc.id;
    String currentClassName = data['className'] ?? "Unknown";

    // 🚨 DYNAMIC LIVE COUNTING: Sub-querying the groups collection for this specific class
    return StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('groups')
            .where('teacherName', isEqualTo: widget.teacherName)
            .where('className', isEqualTo: currentClassName)
            .snapshots(),
        builder: (context, groupSnapshot) {

          int totalGroups = 0;
          int totalStudents = 0;

          if (groupSnapshot.hasData) {
            totalGroups = groupSnapshot.data!.docs.length;
            // Loop through every group in this class to sum up the students
            for (var groupDoc in groupSnapshot.data!.docs) {
              totalStudents += (groupDoc.data() as Map<String, dynamic>)['students'] as int? ?? 0;
            }
          }

          return Container(
            margin: const EdgeInsets.only(bottom: 20),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(currentClassName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0D1C2E))),
                    _buildIconButton(Icons.edit_outlined, () {
                      _showEditClassDialog(docId, currentClassName);
                    }),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(20)),
                      child: Text(data['status'] ?? "Active", style: const TextStyle(color: Color(0xFF16A34A), fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                    const SizedBox(width: 12),
                    Text("CODE: ${data['code']}", style: const TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.w600, fontSize: 13, letterSpacing: 1)),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    // 🚨 LIVE NUMBERS
                    Expanded(child: _buildInfoBox("STUDENTS", totalStudents.toString())),
                    const SizedBox(width: 16),
                    Expanded(child: _buildInfoBox("GROUPS", totalGroups.toString())),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => GroupManagementScreen(
                        teacherName: widget.teacherName,
                        className: currentClassName,
                      )));
                    },
                    style: TextButton.styleFrom(
                      backgroundColor: const Color(0xFFF8FAFC),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text("Manage Groups", style: TextStyle(color: Color(0xFF334155), fontWeight: FontWeight.bold, fontSize: 15)),
                  ),
                )
              ],
            ),
          );
        }
    );
  }

  Widget _buildInfoBox(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(color: Color(0xFF0D1C2E), fontSize: 24, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildIconButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: const Color(0xFF64748B), size: 20),
      ),
    );
  }
}