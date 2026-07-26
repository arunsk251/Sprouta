import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class GrowthTrackingScreen extends StatefulWidget {
  final String teacherName;
  final String? initialGroupId;

  const GrowthTrackingScreen({super.key, required this.teacherName, this.initialGroupId});

  @override
  State<GrowthTrackingScreen> createState() => _GrowthTrackingScreenState();
}

class _GrowthTrackingScreenState extends State<GrowthTrackingScreen> {
  String? selectedGroupId;

  final List<String> stages = [
    'Seed Planted',
    'Germination',
    'Seedling',
    'Young Plant',
    'Flowering',
    'Fruiting'
  ];

  @override
  void initState() {
    super.initState();
    selectedGroupId = widget.initialGroupId;
  }

  void _showUpdateStageBottomSheet(String currentStage, String groupId) {
    showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
        backgroundColor: Colors.white,
        builder: (context) {
          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(height: 5, width: 40, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
                const SizedBox(height: 20),
                const Text("Select Current Stage", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0D1C2E))),
                const SizedBox(height: 20),
                Expanded(
                  child: ListView.builder(
                      itemCount: stages.length,
                      itemBuilder: (context, index) {
                        bool isSelected = stages[index] == currentStage;
                        return GestureDetector(
                          onTap: () async {
                            double newProgress = (index + 1) / stages.length;

                            await FirebaseFirestore.instance.collection('groups').doc(groupId).update({
                              'stage': stages[index],
                              'progress': newProgress,
                            });
                            if (mounted) Navigator.pop(context);
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFF2EF889) : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                    stages[index],
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: isSelected ? Colors.white : const Color(0xFF334155)
                                    )
                                ),
                                if (isSelected) const Icon(Icons.check_circle_outline, color: Colors.white),
                              ],
                            ),
                          ),
                        );
                      }
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(backgroundColor: const Color(0xFFF8FAFC), padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                    child: const Text("Close", style: TextStyle(color: Color(0xFF475569), fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                )
              ],
            ),
          );
        }
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
      ),
      body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('groups').where('teacherName', isEqualTo: widget.teacherName).snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: Color(0xFF2EF889)));
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(child: Text("No groups found. Create a group first!", style: TextStyle(color: Colors.grey)));
            }

            var docs = snapshot.data!.docs;
            String currentGroupId = selectedGroupId ?? docs.first.id;
            int groupIndex = docs.indexWhere((doc) => doc.id == currentGroupId);
            var currentGroupDoc = groupIndex != -1 ? docs[groupIndex] : docs.first;

            var data = currentGroupDoc.data() as Map<String, dynamic>;

            String groupName = data['groupName'] ?? "Group";
            String plantName = data['plantName'] ?? "Plant";
            String currentStage = data['stage'] ?? "Seed Planted";
            int currentIndex = stages.indexOf(currentStage);
            if (currentIndex == -1) currentIndex = 0;

            String todayDate = DateFormat('M/d/yyyy').format(DateTime.now());

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Header with Dropdown
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(groupName, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF0D1C2E))),
                              Text(plantName.toUpperCase(), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8), letterSpacing: 1.5)),
                            ],
                          ),
                        ),

                        // 🚨 REDESIGNED: Modern Pill-shaped Dropdown Menu
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE2F6F0), // Soft modern background
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: currentGroupDoc.id,
                              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF0F766E), size: 22),
                              dropdownColor: Colors.white, // Pure white pop-up
                              elevation: 8, // Soft shadow
                              borderRadius: BorderRadius.circular(24), // Heavy rounding for the popup menu!
                              style: const TextStyle(color: Color(0xFF0F766E), fontWeight: FontWeight.bold, fontSize: 14),
                              onChanged: (String? newValue) {
                                if (newValue != null) {
                                  setState(() {
                                    selectedGroupId = newValue;
                                  });
                                }
                              },
                              items: docs.map((doc) {
                                var docData = doc.data() as Map<String, dynamic>;
                                bool isSelected = doc.id == currentGroupDoc.id;

                                return DropdownMenuItem<String>(
                                  value: doc.id,
                                  child: Text(
                                    docData['groupName'] ?? "Group",
                                    style: TextStyle(
                                      // Highlights the currently selected group
                                      color: isSelected ? const Color(0xFF0F766E) : const Color(0xFF64748B),
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        )
                      ],
                    ),
                    const SizedBox(height: 30),

                    // Sub-header Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Growth Timeline", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0D1C2E))),
                        TextButton.icon(
                          onPressed: () => _showUpdateStageBottomSheet(currentStage, currentGroupDoc.id),
                          icon: const Icon(Icons.edit, size: 16, color: Color(0xFF2EF889)),
                          label: const Text("Update Stage", style: TextStyle(color: Color(0xFF2EF889), fontWeight: FontWeight.bold, fontSize: 14)),
                        )
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Timeline List
                    Expanded(
                      child: ListView.builder(
                          itemCount: stages.length,
                          itemBuilder: (context, index) {
                            bool isCompleted = index < currentIndex;
                            bool isActive = index == currentIndex;
                            bool isLast = index == stages.length - 1;

                            return IntrinsicHeight(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Column(
                                    children: [
                                      Container(
                                        height: 45, width: 45,
                                        decoration: BoxDecoration(
                                          color: isCompleted ? const Color(0xFF2EF889) : Colors.transparent,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                              color: isActive || isCompleted ? const Color(0xFF2EF889) : Colors.transparent,
                                              width: 3
                                          ),
                                        ),
                                        child: Center(
                                          child: isCompleted
                                              ? const Icon(Icons.check, color: Colors.white, size: 24)
                                              : Text("${index + 1}", style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                              color: isActive ? const Color(0xFF2EF889) : const Color(0xFFCBD5E1)
                                          )),
                                        ),
                                      ),
                                      if (!isLast)
                                        Expanded(
                                          child: Container(
                                            width: 2,
                                            color: isCompleted ? const Color(0xFFE2E8F0) : const Color(0xFFF1F5F9),
                                          ),
                                        )
                                    ],
                                  ),
                                  const SizedBox(width: 20),

                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.only(top: 10.0, bottom: 40.0),
                                      child: isActive
                                          ? Container(
                                        padding: const EdgeInsets.all(20),
                                        decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(20),
                                            border: Border.all(color: const Color(0xFF2EF889), width: 1),
                                            boxShadow: [BoxShadow(color: const Color(0xFF2EF889).withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))]
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(stages[index], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF16A34A))),
                                            const SizedBox(height: 4),
                                            Text("Reached on $todayDate", style: const TextStyle(fontSize: 14, color: Color(0xFF94A3B8), fontStyle: FontStyle.italic)),
                                          ],
                                        ),
                                      )
                                          : Text(
                                          stages[index],
                                          style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: isCompleted ? const Color(0xFF0D1C2E) : const Color(0xFF94A3B8)
                                          )
                                      ),
                                    ),
                                  )
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