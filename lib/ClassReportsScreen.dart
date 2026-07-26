import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'PdfReportService.dart';

class ClassReportsScreen extends StatefulWidget {
  final String teacherName;
  const ClassReportsScreen({super.key, required this.teacherName});

  @override
  State<ClassReportsScreen> createState() => _ClassReportsScreenState();
}

class _ClassReportsScreenState extends State<ClassReportsScreen> {
  // Helper to map stages to specific colors as seen in your design
  final Map<String, Color> stageColors = {
    'Seed Planted': const Color(0xFF10B981),
    'Germination': const Color(0xFF34D399),
    'Seedling': const Color(0xFF2EF889), // Sprouta Green
    'Young Plant': const Color(0xFF3B82F6), // Blue
    'Flowering': const Color(0xFFA855F7), // Purple
    'Fruiting': const Color(0xFFF59E0B), // Orange
  };

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
        title: const Text("Class Reports", style: TextStyle(color: Color(0xFF0D1C2E), fontWeight: FontWeight.bold, fontSize: 22)),
      ),
      // Top Level Stream: Fetches ALL groups to calculate overall stats
      body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('groups').where('teacherName', isEqualTo: widget.teacherName).snapshots(),
          builder: (context, groupsSnapshot) {
            if (groupsSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: Color(0xFF2EF889)));
            }

            List<QueryDocumentSnapshot> allGroups = groupsSnapshot.hasData ? groupsSnapshot.data!.docs : [];

            // --- 1. CALCULATE ENGAGEMENT (Average Progress) ---
            double totalProgress = 0;
            for (var group in allGroups) {
              totalProgress += (group.data() as Map<String, dynamic>)['progress']?.toDouble() ?? 0.0;
            }
            int avgCompletion = allGroups.isEmpty ? 0 : ((totalProgress / allGroups.length) * 100).toInt();

            // --- 2. CALCULATE GROWTH PROGRESS (Count per stage) ---
            Map<String, int> stageCounts = {};
            for (var group in allGroups) {
              String stage = (group.data() as Map<String, dynamic>)['stage'] ?? 'Unknown';
              stageCounts[stage] = (stageCounts[stage] ?? 0) + 1;
            }
            // Sort stages by count (highest first)
            var sortedStages = stageCounts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
            int maxGroupsInAStage = sortedStages.isNotEmpty ? sortedStages.first.value : 1;

            return SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- ENGAGEMENT SUMMARY CARD ---
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))]),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("ENGAGEMENT SUMMARY", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8), letterSpacing: 1)),
                          const SizedBox(height: 16),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text("$avgCompletion%", style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Color(0xFF16A34A), height: 1)),
                              const SizedBox(width: 8),
                              const Padding(
                                padding: EdgeInsets.only(bottom: 8.0),
                                child: Text("Average Completion", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // --- GROWTH PROGRESS CARD ---
                    if (sortedStages.isNotEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))]),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("GROWTH PROGRESS", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8), letterSpacing: 1)),
                            const SizedBox(height: 24),

                            // Dynamically build bars for the top stages
                            ...sortedStages.take(3).map((entry) {
                              String stageName = entry.key;
                              int count = entry.value;
                              double barFill = count / maxGroupsInAStage;
                              Color barColor = stageColors[stageName] ?? const Color(0xFF2EF889);

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 20.0),
                                child: Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(stageName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0D1C2E))),
                                        Text("$count groups", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: barColor)),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: LinearProgressIndicator(
                                        value: barFill,
                                        backgroundColor: const Color(0xFFF1F5F9),
                                        color: barColor,
                                        minHeight: 8,
                                      ),
                                    )
                                  ],
                                ),
                              );
                            }).toList(),
                          ],
                        ),
                      ),
                    const SizedBox(height: 30),

                    // --- GENERATE CLASS REPORT SECTION ---
                    const Text("Generate Class Report", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0D1C2E))),
                    const SizedBox(height: 16),

                    // Nested Stream: Fetches classes to build the list
                    StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance.collection('classes').where('teacherName', isEqualTo: widget.teacherName).snapshots(),
                        builder: (context, classesSnapshot) {
                          if (!classesSnapshot.hasData) return const SizedBox.shrink();
                          var classDocs = classesSnapshot.data!.docs;

                          if (classDocs.isEmpty) {
                            return const Padding(padding: EdgeInsets.all(20), child: Text("No classes created yet.", style: TextStyle(color: Colors.grey)));
                          }

                          return ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: classDocs.length,
                            itemBuilder: (context, index) {
                              var classData = classDocs[index].data() as Map<String, dynamic>;
                              String className = classData['className'] ?? "Unknown";

                              // Calculate dynamic student & group counts from the allGroups list
                              var groupsInThisClass = allGroups.where((g) => (g.data() as Map<String, dynamic>)['className'] == className).toList();
                              int classGroupCount = groupsInThisClass.length;
                              int classStudentCount = groupsInThisClass.fold(0, (sum, g) => sum + ((g.data() as Map<String, dynamic>)['students'] as int? ?? 0));

                              return Container(
                                margin: const EdgeInsets.only(bottom: 16),
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))]),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: const BoxDecoration(color: Color(0xFFF1F5F9), shape: BoxShape.circle),
                                          child: const Icon(Icons.school_outlined, color: Color(0xFF64748B), size: 24),
                                        ),
                                        const SizedBox(width: 16),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(className, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF0D1C2E))),
                                            const SizedBox(height: 4),
                                            Text("$classStudentCount Students • $classGroupCount Groups", style: const TextStyle(fontSize: 14, color: Color(0xFF94A3B8))),
                                          ],
                                        )
                                      ],
                                    ),
                                    const SizedBox(height: 24),

                                    // 🚨 REDESIGNED BUTTON: Web View icon removed, PDF button fills the width
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton.icon(
                                        onPressed: () async {
                                          // 1. Get today's date
                                          String today = DateFormat('MMMM d, yyyy').format(DateTime.now());

                                          // 2. Extract the detailed group data for THIS specific class only
                                          var groupsInThisClass = allGroups.where((g) => (g.data() as Map<String, dynamic>)['className'] == className).toList();

                                          // Convert the raw Firestore documents into a clean List of Maps for the PDF service
                                          List<Map<String, dynamic>> detailedGroupsData = groupsInThisClass.map((g) {
                                            return g.data() as Map<String, dynamic>;
                                          }).toList();

                                          // 3. Generate the PDF!
                                          await PdfReportService.generateAndPrintClassReport(
                                            className: className,
                                            teacherName: widget.teacherName,
                                            groupsData: detailedGroupsData,
                                            date: today,
                                          );
                                        },
                                        icon: const Icon(Icons.picture_as_pdf_rounded, size: 18),
                                        label: const Text("Export PDF", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF2EF889),
                                          foregroundColor: Colors.white,
                                          elevation: 0,
                                          padding: const EdgeInsets.symmetric(vertical: 16),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        }
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