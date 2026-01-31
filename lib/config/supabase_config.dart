import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  // ✅ PASTIKAN URUTAN INI BENAR!
  static const url = 'https://ysauqoxzyfwebzlbcmay.supabase.co';
  static const anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InlzYXVxb3h6eWZ3ZWJ6bGJjbWF5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjgyNjE2ODMsImV4cCI6MjA4MzgzNzY4M30.-CEcEP28ccmJc9mpc438n9RhaR6RADqZuMTe5lbqdFo';

  static Future<void> init() async {
    await Supabase.initialize(
      url: url,
      anonKey: anonKey,
    );
  }

  static SupabaseClient get client => Supabase.instance.client;
}