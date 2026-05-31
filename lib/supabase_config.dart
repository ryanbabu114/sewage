import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: ',
      anonKey: '',
    );
  }

  static SupabaseClient get client => Supabase.instance.client;
}
