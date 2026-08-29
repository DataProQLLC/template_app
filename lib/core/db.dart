// lib/core/supabase.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config.dart';

Future<void> initSupabase() async {
  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    anonKey: AppConfig.supabasePublishableKey,
  );
}

SupabaseClient get sb => Supabase.instance.client;