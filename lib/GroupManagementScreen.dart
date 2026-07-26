import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'GrowthTrackingScreen.dart';
import 'TeamMembersScreen.dart'; // 🚨 NEW IMPORT

class GroupManagementScreen extends StatefulWidget {
  final String teacherName;
  final String? className;

  const GroupManagementScreen({super.key, required this.teacherName, this.className});

  @override
  State<GroupManagementScreen> createState() => _GroupManagementScreenState();
}

class _GroupManagementScreenState extends State<GroupManagementScreen> {

  void _showCreateGroupDialog() {
    TextEditingController groupController = TextEditingController();

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
                      decoration: BoxDecoration(color: const Color(0xFFE2F6F0), borderRadius: BorderRadius.circular(16)),
                      child: const Icon(Icons.group_add_rounded, color: Color(0xFF0F766E), size: 24),
                    ),
                    const SizedBox(width: 16),
                    const Text("New Group", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: Color(0xFF0D1C2E))),
                  ],
                ),
                const SizedBox(height: 30),

                const Text("GROUP NAME", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8), letterSpacing: 1)),
                const SizedBox(height: 8),
                TextField(
                  controller: groupController,
                  decoration: InputDecoration(
                    hintText: "e.g. Green Warriors",
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey[200]!, width: 1.5)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF2EF889), width: 2)),
                  ),
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
                          if (groupController.text.isNotEmpty) {
                            await FirebaseFirestore.instance.collection('groups').add({
                              'groupName': groupController.text.trim(),
                              'teacherName': widget.teacherName,
                              'className': widget.className ?? "Unassigned",
                              'plantName': 'Leafy',
                              'stage': 'Seed Planted',
                              'students': 0,
                              'members': [], // Initializes the empty team list
                              'kitId': 'Unassigned',
                              'progress': 0.16,
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

  // 🚨 COMPLETELY REDESIGNED: Modern Aesthetic Manage Team Dialog
  void _showManageTeamDialog(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    TextEditingController nameController = TextEditingController(text: data['groupName']);
    TextEditingController kitController = TextEditingController(text: data['kitId'] == 'Unassigned' ? '' : data['kitId']);

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
                      decoration: BoxDecoration(color: const Color(0xFFF3E8FF), borderRadius: BorderRadius.circular(16)),
                      child: const Icon(Icons.tune_rounded, color: Color(0xFF9333EA), size: 24),
                    ),
                    const SizedBox(width: 16),
                    const Text("Team Settings", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: Color(0xFF0D1C2E))),
                  ],
                ),
                const SizedBox(height: 30),

                const Text("GROUP NAME", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8), letterSpacing: 1)),
                const SizedBox(height: 8),
                TextField(controller: nameController, decoration: _modernInputDecoration()),
                const SizedBox(height: 24),

                const Text("KIT ID (OPTIONAL)", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8), letterSpacing: 1)),
                const SizedBox(height: 8),
                TextField(controller: kitController, decoration: _modernInputDecoration(hint: "e.g. SP-4092")),
                const SizedBox(height: 36),

                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(backgroundColor: const Color(0xFFF8FAFC), padding: const EdgeInsets.symmetric(vertical: 18), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                        child: const Text("Cancel", style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          if (nameController.text.isNotEmpty) {
                            String kitId = kitController.text.trim().isEmpty ? "Unassigned" : kitController.text.trim();
                            await FirebaseFirestore.instance.collection('groups').doc(doc.id).update({
                              'groupName': nameController.text.trim(),
                              'kitId': kitId,
                            });
                            if (mounted) Navigator.pop(context);
                          }
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF9333EA), elevation: 0, padding: const EdgeInsets.symmetric(vertical: 18), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                        child: const Text("Save Changes", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
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
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF9333EA), width: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    Query query = FirebaseFirestore.instance.collection('groups').where('teacherName', isEqualTo: widget.teacherName);
    if (widget.className != null) {
      query = query.where('className', isEqualTo: widget.className);
    }

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
        title: const Text("Groups & Teams", style: TextStyle(color: Color(0xFF0D1C2E), fontWeight: FontWeight.bold, fontSize: 22)),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              const SizedBox(height: 20),

              StreamBuilder<QuerySnapshot>(
                  stream: query.snapshots(),
                  builder: (context, snapshot) {
                    int totalGroups = snapshot.hasData ? snapshot.data!.docs.length : 0;
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("$totalGroups Groups Total", style: const TextStyle(fontSize: 16, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
                        ElevatedButton.icon(
                          onPressed: _showCreateGroupDialog,
                          icon: const Icon(Icons.add, size: 20),
                          label: const Text("New Group", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
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
                  stream: query.snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: Color(0xFF2EF889)));
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text("No groups yet. Click 'New Group' to start!", style: TextStyle(color: Colors.grey)));

                    return ListView.builder(
                      itemCount: snapshot.data!.docs.length,
                      itemBuilder: (context, index) => _buildGroupCard(snapshot.data!.docs[index]),
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

  Widget _buildGroupCard(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    double progress = data['progress']?.toDouble() ?? 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 50, width: 50,
                decoration: const BoxDecoration(color: Color(0xFFF1F5F9), shape: BoxShape.circle),
                child: const Icon(Icons.groups_rounded, color: Color(0xFF94A3B8), size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(data['groupName'] ?? "Unknown Group", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0D1C2E))),
                    const SizedBox(height: 4),
                    Text("${data['plantName']} • ${data['stage']}", style: const TextStyle(color: Color(0xFF16A34A), fontWeight: FontWeight.w600, fontSize: 13)),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => _showManageTeamDialog(doc),
                child: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.tune, color: Color(0xFF64748B), size: 20)),
              )
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: _buildInfoBox("STUDENTS", data['students'].toString(), isHighlighted: false)),
              const SizedBox(width: 16),
              Expanded(child: _buildInfoBox("KIT ID", data['kitId'].toString(), isHighlighted: true)),
            ],
          ),
          const SizedBox(height: 20),
          ClipRRect(borderRadius: BorderRadius.circular(10), child: LinearProgressIndicator(value: progress, backgroundColor: const Color(0xFFF1F5F9), color: const Color(0xFF2EF889), minHeight: 6)),
          const SizedBox(height: 24),

          // 🚨 REDESIGNED ACTION BUTTONS
          Row(
            children: [
              Expanded(
                child: TextButton.icon(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => GrowthTrackingScreen(teacherName: widget.teacherName, initialGroupId: doc.id)));
                  },
                  style: TextButton.styleFrom(backgroundColor: const Color(0xFFE2F6F0), padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  icon: const Icon(Icons.trending_up_rounded, color: Color(0xFF0F766E), size: 18),
                  label: const Text("Track Growth", style: TextStyle(color: Color(0xFF0F766E), fontWeight: FontWeight.bold, fontSize: 14)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: () {
                // 🚨 NAVIGATE TO NEW TEAM MEMBERS SCREEN
                Navigator.push(context, MaterialPageRoute(builder: (context) => TeamMembersScreen(groupId: doc.id, groupName: data['groupName'])));
              },
              style: TextButton.styleFrom(backgroundColor: const Color(0xFFE0F2FE), padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              icon: const Icon(Icons.people_alt_outlined, color: Color(0xFF0284C7), size: 18),
              label: const Text("View & Manage Students", style: TextStyle(color: Color(0xFF0284C7), fontWeight: FontWeight.bold, fontSize: 14)),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildInfoBox(String label, String value, {required bool isHighlighted}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(color: isHighlighted ? const Color(0xFF94A3B8) : const Color(0xFF0D1C2E), fontSize: 18, fontWeight: FontWeight.bold, fontStyle: isHighlighted && value == "Unassigned" ? FontStyle.italic : FontStyle.normal)),
        ],
      ),
    );
  }
}