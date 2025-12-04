import 'package:flutter/material.dart';
import 'package:sewage/addaccount.dart';
import 'package:sewage/profile_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'Profie.dart';
import 'alerts_screen.dart';
import 'history_screen.dart';
import 'unit_info_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? email;
  bool loadingProfile = true;

  @override
  void initState() {
    super.initState();
    fetchMyEmail();
  }

  Future<void> fetchMyEmail() async {
    final user = Supabase.instance.client.auth.currentUser;

    if (user == null) {
      setState(() {
        loadingProfile = false;
      });
      return;
    }

    try {
      // Try to fetch email from profile table first
      final response = await Supabase.instance.client
          .from('profile')
          .select('email')
          .eq('auth_id', user.id)
          .maybeSingle(); // returns null if not found

      setState(() {
        // Use email from profile table if available, otherwise from Auth
        email = response?['email'] ?? user.email;
        loadingProfile = false;
      });

      debugPrint('Profile fetch result: $response');
    } catch (e) {
      // On error, fall back to Auth email
      setState(() {
        email = user.email;
        loadingProfile = false;
      });
      debugPrint('Error fetching profile: $e');
    }
  }

  void _navigateToPage(BuildContext context, Widget page, String title) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: Text(title),
            backgroundColor: Colors.grey[100],
            elevation: 0,
            foregroundColor: Colors.black87,
          ),
          body: page,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayEmail = email ?? 'User';

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: loadingProfile
            ? const Text('Loading...')
            : Text(
                'Hello, $displayEmail',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
        backgroundColor: Colors.white,
        elevation: 1,
        foregroundColor: Colors.black87,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                );
              },
              child: const CircleAvatar(
                radius: 18,
                backgroundColor: Colors.grey,
                child: Icon(Icons.person, color: Colors.white, size: 22),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const SizedBox(height: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    _buildNavButton(
                      icon: Icons.warning_amber_rounded,
                      label: 'Alerts',
                      onTap: () => _navigateToPage(
                        context,
                        const AlertsScreen(),
                        'Alerts',
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildNavButton(
                      icon: Icons.info_outline,
                      label: 'Unit Info',
                      onTap: () => _navigateToPage(
                        context,
                        const UnitInfoScreen(),
                        'Unit Info',
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildNavButton(
                      icon: Icons.history,
                      label: 'Action & History',
                      onTap: () => _navigateToPage(
                        context,
                        const HistoryScreen(),
                        'Action & History',
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildNavButton(
                      icon: Icons.person_add,
                      label: 'Add Account',
                      onTap: () => _navigateToPage(
                        context,
                        const addaccounnt(),
                        'Add Account',
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildNavButton(
                      icon: Icons.people,
                      label: 'View Users',
                      onTap: () => _navigateToPage(
                        context,
                        const ProfilePage(),
                        'Users',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildNavButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final color = Colors.grey.shade700;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 5,
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(width: 16),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
