import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class PdfReportService {

  static Future<void> generateAndPrintClassReport({
    required String className,
    required String teacherName,
    required List<Map<String, dynamic>> groupsData,
    required String date,
  }) async {
    final pdf = pw.Document();

    // Calculate totals
    int totalGroups = groupsData.length;
    int totalStudents = groupsData.fold(0, (sum, group) => sum + ((group['students'] as int?) ?? 0));

    // We use MultiPage so it automatically creates new pages if the list of students is long!
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          List<pw.Widget> content = [];

          // --- HEADER ---
          content.add(
              pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text("Sprouta Class Report", style: pw.TextStyle(fontSize: 28, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex("#0D1C2E"))),
                          pw.SizedBox(height: 4),
                          pw.Text("Detailed Student & Growth Breakdown", style: pw.TextStyle(fontSize: 14, color: PdfColor.fromHex("#64748B"))),
                        ]
                    ),
                    pw.Text(date, style: pw.TextStyle(fontSize: 14, color: PdfColor.fromHex("#94A3B8"))),
                  ]
              )
          );
          content.add(pw.SizedBox(height: 20));
          content.add(pw.Divider(color: PdfColor.fromHex("#E2E8F0")));
          content.add(pw.SizedBox(height: 20));

          // --- CLASS OVERVIEW ---
          content.add(pw.Text("Class Overview", style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)));
          content.add(pw.SizedBox(height: 16));
          content.add(
              pw.Container(
                  padding: const pw.EdgeInsets.all(16),
                  decoration: pw.BoxDecoration(
                    color: PdfColor.fromHex("#F8FAFC"),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
                  ),
                  child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        _buildSummaryItem("Class Name", className),
                        _buildSummaryItem("Lead Educator", teacherName),
                        _buildSummaryItem("Total Students", totalStudents.toString()),
                        _buildSummaryItem("Active Groups", totalGroups.toString()),
                      ]
                  )
              )
          );
          content.add(pw.SizedBox(height: 40));

          // --- GROUP DETAILS & GRADING ---
          content.add(pw.Text("Group Performance & Marks", style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)));
          content.add(pw.SizedBox(height: 16));

          if (groupsData.isEmpty) {
            content.add(pw.Text("No groups have been created for this class yet.", style: pw.TextStyle(color: PdfColor.fromHex("#94A3B8"))));
          }

          for (var group in groupsData) {
            String groupName = group['groupName'] ?? 'Unknown Group';
            String stage = group['stage'] ?? 'Seed Planted';
            List<dynamic> members = group['members'] ?? [];

            // Format the date (Fallback to today if not found)
            String dateReached = "Recently";
            if (group['createdAt'] != null) {
              DateTime dt = (group['createdAt'] as Timestamp).toDate();
              dateReached = DateFormat('MMM d, yyyy').format(dt);
            }

            // Calculate Marks based on stage
            String marks = _calculateMarks(stage);

            content.add(
                pw.Container(
                    margin: const pw.EdgeInsets.only(bottom: 24),
                    padding: const pw.EdgeInsets.all(16),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColor.fromHex("#E2E8F0")),
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
                    ),
                    child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          // Group Header
                          pw.Row(
                              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                              children: [
                                pw.Text(groupName, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex("#0F766E"))),
                                pw.Text("Marks: $marks", style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex("#16A34A"))),
                              ]
                          ),
                          pw.SizedBox(height: 8),

                          // Stage Info
                          pw.Text("Current Stage: $stage", style: pw.TextStyle(fontSize: 12, color: PdfColor.fromHex("#334155"))),
                          pw.Text("Timeline Logged: $dateReached", style: pw.TextStyle(fontSize: 12, color: PdfColor.fromHex("#94A3B8"))),
                          pw.SizedBox(height: 16),

                          // Students Table
                          if (members.isNotEmpty)
                            pw.TableHelper.fromTextArray(
                              context: context,
                              cellAlignment: pw.Alignment.centerLeft,
                              headerDecoration: pw.BoxDecoration(color: PdfColor.fromHex("#F1F5F9")),
                              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex("#475569")),
                              cellStyle: pw.TextStyle(color: PdfColor.fromHex("#0D1C2E")),
                              headers: ['Roll No', 'Student Name'],
                              data: members.map((m) => [m['rollNo'].toString(), m['name'].toString()]).toList(),
                            )
                          else
                            pw.Text("No students assigned to this group.", style: pw.TextStyle(fontStyle: pw.FontStyle.italic, color: PdfColor.fromHex("#94A3B8"))),
                        ]
                    )
                )
            );
          }

          return content;
        },
      ),
    );

    // Share the PDF
    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'Sprouta_Report_$className.pdf',
    );
  }

  // --- HELPER METHODS ---

  static pw.Widget _buildSummaryItem(String label, String value) {
    return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(label, style: pw.TextStyle(fontSize: 10, color: PdfColor.fromHex("#94A3B8"))),
          pw.SizedBox(height: 4),
          pw.Text(value, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex("#0D1C2E"))),
        ]
    );
  }

  // Automated Grading System based on plant stage
  static String _calculateMarks(String stage) {
    switch (stage) {
      case 'Seed Planted': return '20 / 100';
      case 'Germination': return '40 / 100';
      case 'Seedling': return '60 / 100';
      case 'Young Plant': return '80 / 100';
      case 'Flowering': return '90 / 100';
      case 'Fruiting': return '100 / 100';
      default: return '0 / 100';
    }
  }
}