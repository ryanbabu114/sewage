import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final supabase = Supabase.instance.client;
  Timer? _autoRefreshTimer;

  List<Map<String, dynamic>> _alerts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    fetchAlerts();

    _autoRefreshTimer =
        Timer.periodic(const Duration(seconds: 5), (_) => fetchAlerts());
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  Future<void> fetchAlerts() async {
    final response = await supabase
        .from("alerts")
        .select('*, profile!alerts_assigned_worker_id_fkey(name, email)')
        .order("created_at", ascending: false);

    if (!mounted) return;

    setState(() {
      _alerts = List<Map<String, dynamic>>.from(response);
      _loading = false;
    });
  }

  // ================= HELPERS =================

  Color severityColor(String severity) {
    switch (severity.toLowerCase()) {
      case "high":
        return Colors.red;
      case "medium":
        return Colors.orange;
      default:
        return Colors.green;
    }
  }

  Widget statusBadge(bool processed) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: processed ? Colors.green : Colors.orange,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        processed ? "RESOLVED" : "PENDING",
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
    );
  }

  String formatTime(String? raw) {
    if (raw == null) return "Unknown";
    final dt = DateTime.tryParse(raw);
    if (dt == null) return raw;
    return DateFormat("MMM d, h:mm a").format(dt.toLocal());
  }

  Future<void> openInMaps(double lat, double lon) async {
    final url = Uri.parse("https://www.google.com/maps?q=$lat,$lon");
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  Widget dataRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text("$label: ${value ?? 'N/A'}"),
    );
  }

  // ================= UI =================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _alerts.length,
        itemBuilder: (context, index) {
          final alert = _alerts[index];

          final status = alert["status"] ?? "Unknown";
          final severity = alert["severity"] ?? "low";
          final processed = alert["processed"] == true;

          final worker = alert['profile'];
          final workerName =
              worker?['name'] ?? worker?['email'] ?? "Unassigned";

          final lat = alert["latitude"];
          final lon = alert["longitude"];

          final imagePath = alert["image_path"];
          final imageUrl = imagePath != null
              ? supabase.storage
              .from('sewer-images')
              .getPublicUrl(imagePath)
              : null;

          // 🔹 Merge distance + distance_2
          String combinedDistance() {
            final d1 = alert["distance"];
            final d2 = alert["distance_2"];

            if (d1 != null && d2 != null) {
              return "$d1 cm / $d2 cm";
            } else if (d1 != null) {
              return "$d1 cm";
            } else if (d2 != null) {
              return "$d2 cm";
            } else {
              return "N/A";
            }
          }

          return Card(
            elevation: 3,
            margin: const EdgeInsets.only(bottom: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ===== HEADER =====
                  Row(
                    mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "$status (${severity.toUpperCase()})",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: severityColor(severity),
                        ),
                      ),
                      statusBadge(processed),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // ===== BASIC INFO =====
                  dataRow("👷 Worker", workerName),
                  dataRow("📏 Distance", combinedDistance()),
                  dataRow("📍 Location", alert["location"]),
                  dataRow("🕒 Created",
                      formatTime(alert["created_at"])),

                  const SizedBox(height: 10),

                  // ===== DEVICE SECTION =====
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        dataRow("🔧 Device",
                            alert["device_name"]),
                        dataRow("🆔 Device ID",
                            alert["device_id"]),
                        dataRow("🌊 Flow Rate",
                            alert["flow_rate"]),
                        dataRow("📊 Level Difference",
                            alert["level_difference"]),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),

                  // ===== ASSIGNMENT =====
                  if (worker != null)
                    dataRow("👤 Assigned To", workerName),

                  dataRow("⏰ Assigned At",
                      formatTime(alert["assigned_at"])),

                  const SizedBox(height: 10),

                  // ===== MAP BUTTON =====
                  if (lat != null && lon != null)
                    InkWell(
                      onTap: () => openInMaps(
                          lat as double, lon as double),
                      child: const Text(
                        "🧭 View on Map",
                        style: TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                  const SizedBox(height: 10),

                  // ===== IMAGE =====
                  if (imageUrl != null)
                    ClipRRect(
                      borderRadius:
                      BorderRadius.circular(12),
                      child: Image.network(
                        imageUrl,
                        height: 170,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
