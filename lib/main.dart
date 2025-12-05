import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'sign_up.dart'; // Import halaman Sign Up

// Global instance untuk kemudahan akses
final supabase = Supabase.instance.client; 

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // GANTI DENGAN KUNCI PROYEK KAMU
  const String supabaseUrl = 'https://twvktwrplxoduzawsyin.supabase.co'; 
  const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InR3dmt0d3JwbHhvZHV6YXdzeWluIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQwNzYxOTIsImV4cCI6MjA3OTY1MjE5Mn0.Rqb2PxiaKOZCd8cy1-DqrMlZz2nXn9m7BP-aZEV9rFg';

  await Supabase.initialize(
    url: supabaseUrl, 
    anonKey: supabaseAnonKey,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'HealthPal App',
      debugShowCheckedModeBanner: false,
      home: const SignUpScreen(), // Mulai dari halaman Sign Up
    );
  }
}