import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TeamMembersScreen extends StatefulWidget {
  final String groupId;
  final String groupName;

  const TeamMembersScreen({super.key, required this.groupId, required this.groupName});

  @override
  State<TeamMembersScreen> createState() => _TeamMembersScreenState();
}

class _TeamMembersScreenState extends State<TeamMembersScreen> {

  void _showMemberDialog(List<dynamic> currentMembers, {Map<String, dynamic>? existingMember, int? editIndex}) {
    if (existingMember == null && currentMembers.length >= 10) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Maximum of 10 students allowed per group!"), backgroundColor: Colors.red));
      return;
    }

    TextEditingController nameController = TextEditingController(text: existingMember?['name'] ?? '');
    TextEditingController rollController = TextEditingController(text: existingMember?['rollNo'] ?? '');

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
                // Modern Header with Icon
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: const Color(0xFFE0F2FE), borderRadius: BorderRadius.circular(16)),
                      child: Icon(
                          existingMember == null ? Icons.person_add_alt_1_rounded : Icons.manage_accounts_rounded,
                          color: const Color(0xFF0284C7),
                          size: 24
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(existingMember == null ? "Add Student" : "Edit Student", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: Color(0xFF0D1C2E))),
                  ],
                ),
                const SizedBox(height: 30),

                const Text("STUDENT NAME", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8), letterSpacing: 1)),
                const SizedBox(height: 8),
                TextField(
                    controller: nameController,
                    decoration: _modernInputDecoration(hint: "e.g. Leo Parker")
                ),
                const SizedBox(height: 24),

                const Text("ROLL NUMBER", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8), letterSpacing: 1)),
                const SizedBox(height: 8),
                TextField(
                    controller: rollController,
                    keyboardType: TextInputType.number,
                    decoration: _modernInputDecoration(hint: "e.g. 12")
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
                          if (nameController.text.isNotEmpty && rollController.text.isNotEmpty) {
                            List<dynamic> updatedMembers = List.from(currentMembers);
                            Map<String, dynamic> newStudent = {'name': nameController.text.trim(), 'rollNo': rollController.text.trim()};

                            if (editIndex != null) {
                              updatedMembers[editIndex] = newStudent; // Update existing
                            } else {
                              updatedMembers.add(newStudent); // Add new
                            }

                            // Update Firestore with the new list and the new total count!
                            await FirebaseFirestore.instance.collection('groups').doc(widget.groupId).update({
                              'members': updatedMembers,
                              'students': updatedMembers.length, // Keeps the group card sync'd
                            });

                            if (mounted) Navigator.pop(context);
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

  // 🚨 Replaces the old _inputDecoration method


  void _deleteMember(List<dynamic> currentMembers, int index) async {
    List<dynamic> updatedMembers = List.from(currentMembers);
    updatedMembers.removeAt(index);

    await FirebaseFirestore.instance.collection('groups').doc(widget.groupId).update({
      'members': updatedMembers,
      'students': updatedMembers.length,
    });
  }

  InputDecoration _modernInputDecoration({String hint = ""}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey[400]),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey[200]!, width: 1.5)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF0284C7), width: 2)),
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
        title: Text(widget.groupName, style: const TextStyle(color: Color(0xFF0D1C2E), fontWeight: FontWeight.bold, fontSize: 22)),
      ),
      body: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance.collection('groups').doc(widget.groupId).snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData || !snapshot.data!.exists) {
              return const Center(child: CircularProgressIndicator(color: Color(0xFF0284C7)));
            }

            var data = snapshot.data!.data() as Map<String, dynamic>;
            List<dynamic> members = data['members'] ?? [];

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Team Members (${members.length}/10)", style: const TextStyle(fontSize: 16, color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
                        if (members.length < 10)
                          ElevatedButton.icon(
                            onPressed: () => _showMemberDialog(members),
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text("Add", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0284C7), foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                          )
                      ],
                    ),
                    const SizedBox(height: 24),

                    if (members.isEmpty)
                      Expanded(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.group_off_rounded, size: 60, color: Colors.grey[300]),
                              const SizedBox(height: 16),
                              const Text("No students added yet.", style: TextStyle(color: Colors.grey, fontSize: 16)),
                            ],
                          ),
                        ),
                      )
                    else
                      Expanded(
                        child: ListView.builder(
                            itemCount: members.length,
                            itemBuilder: (context, index) {
                              var student = members[index];
                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2))]),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: const Color(0xFFE0F2FE),
                                      foregroundColor: const Color(0xFF0284C7),
                                      radius: 20,
                                      child: Text(student['rollNo'].toString(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(child: Text(student['name'], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0D1C2E)))),
                                    IconButton(icon: const Icon(Icons.edit_outlined, color: Color(0xFF94A3B8), size: 20), onPressed: () => _showMemberDialog(members, existingMember: student, editIndex: index)),
                                    IconButton(icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20), onPressed: () => _deleteMember(members, index)),
                                  ],
                                ),
                              );
                            }
                        ),
                      )
                  ],
                ),
              ),
            );
          }
      ),
    );
  }
}