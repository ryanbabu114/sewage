import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  final supabase = Supabase.instance.client;
  late Future<List<Map<String, dynamic>>> _alertsFuture;

  @override
  void initState() {
    super.initState();
    _alertsFuture = fetchAlerts(); // ✅ Cache Future
  }

  Future<List<Map<String, dynamic>>> fetchAlerts() async {
    try {
      final response = await supabase
          .from('alerts')
          .select()
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception("Failed to load alerts");
    }
  }

  Future<void> _refresh() async {
    setState(() {
      _alertsFuture = fetchAlerts();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _alertsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              "Error loading alerts",
              style: TextStyle(color: Colors.red.shade700),
            ),
          );
        }

        final alerts = snapshot.data ?? [];

        if (alerts.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.notifications_off, size: 50, color: Colors.grey),
                SizedBox(height: 12),
                Text("No alerts found"),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: alerts.length,
            itemBuilder: (context, index) {
              final alert = alerts[index];

              return _buildAlertCard(
                context,
                title: alert['status'] ?? "Unknown",
                unitId: alert['severity'] ?? "No severity",
                timestamp: _formatDate(alert['created_at']),
                icon: _selectIcon(alert['severity']),
                iconColor: _selectColor(alert['severity']),
                isCritical: alert['severity'] == "critical",
              );
            },
          ),
        );
      },
    );
  }

  // ✅ Clean readable timestamp
  String _formatDate(dynamic dateValue) {
    if (dateValue == null) return "Unknown time";
    try {
      final dt = DateTime.parse(dateValue);
      return DateFormat('MMM d, h:mm a').format(dt);
    } catch (_) {
      return dateValue.toString();
    }
  }

  IconData _selectIcon(String? severity) {
    switch (severity?.toLowerCase()) {
      case 'critical':
        return Icons.error;
      case 'warning':
        return Icons.warning_amber_rounded;
      default:
        return Icons.info_outline;
    }
  }

  Color _selectColor(String? severity) {
    switch (severity?.toLowerCase()) {
      case 'critical':
        return Colors.red.shade700;
      case 'warning':
        return Colors.orange.shade700;
      default:
        return Colors.blue.shade700;
    }
  }

  Widget _buildAlertCard(
      BuildContext context, {
        required String title,
        required String unitId,
        required String timestamp,
        required IconData icon,
        required Color iconColor,
        bool isCritical = false,
      }) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: isCritical ? Colors.red.shade700 : Colors.grey.shade300,
          width: isCritical ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: iconColor, size: 40),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isCritical ? Colors.red.shade900 : Colors.black87,
          ),
        ),
        subtitle: Text("$unitId\n$timestamp"),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        isThreeLine: true,
        onTap: () {},
      ),
    );
  }
}
