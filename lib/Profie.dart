import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  // ------------------------------------------
  // Function to fetch ALL rows from "profile" table
  // ------------------------------------------
  Future<List<Map<String, dynamic>>> fetchAllProfiles() async {
    final response = await Supabase.instance.client
        .from('profile') // <-- your table name
        .select('*'); // <-- get everything

    return List<Map<String, dynamic>>.from(response);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Supabase User Profiles')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: fetchAllProfiles(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No profiles found.'));
          }

          final profiles = snapshot.data!;

          return ListView.builder(
            itemCount: profiles.length,
            itemBuilder: (context, index) {
              final profile = profiles[index];

              return ListTile(
                title: Text('ID: ${profile['id'] ?? 'N/A'}'),
                subtitle: Text('Role: ${profile['role'] ?? 'N/A'}'),
                trailing: Text('${profile['created_at'] ?? ''}'),
              );
            },
          );
        },
      ),
    );
  }
}
