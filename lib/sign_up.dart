import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'fill_profile.dart'; // Import file Fill Profile
import 'sign_in.dart';

// Asumsi global instance 'supabase' sudah tersedia (dari main.dart)
final supabase = Supabase.instance.client; 

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  // Controller untuk menangani input
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController(); 

  // --- STATE UNTUK MENYIMPAN PESAN ERROR INLINE ---
  String? _emailError;
  String? _passwordError;
  // ---------------------------------------------

  // State untuk Loading
  bool _isLoading = false;
  
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Fungsi untuk membersihkan semua pesan error
  void _clearErrors() {
    _emailError = null;
    _passwordError = null;
  }

  // --- LOGIC SIGN UP DENGAN SUPABASE ---
  void _signUp() async {
    // 1. Ambil nilai dari Controller
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim(); 
    bool hasError = false;

    // Bersihkan semua error sebelum validasi baru
    _clearErrors(); 

    // --- 2. VALIDASI LOKAL (sebelum kirim ke Supabase) ---
    
    // Validasi Email: Kosong
    if (email.isEmpty) {
      _emailError = 'Email is required.';
      hasError = true;
    } 
    // Validasi Email: Format @gmail.com
    else if (!email.toLowerCase().endsWith('@gmail.com')) {
      _emailError = 'Only @gmail.com domain is allowed.';
      hasError = true;
    }

    // Validasi Password
    if (password.isEmpty) {
      _passwordError = 'Password is required.';
      hasError = true;
    } else if (password.length < 6) {
      _passwordError = 'Minimum 6 characters.';
      hasError = true;
    }

    // Jika ada error validasi lokal, update UI dan hentikan proses
    if (hasError) {
      setState(() {});
      return;
    }
    
    // Lanjutkan jika tidak ada error lokal
    setState(() {
      _isLoading = true;
    });

    try {
      // 3. Panggil Supabase Auth untuk Sign Up
      final AuthResponse authResponse = await supabase.auth.signUp(
        email: email,
        password: password, 
      );

      // 4. Cek respons dari Auth
      if (authResponse.user != null) {
        final userId = authResponse.user!.id;

        // 5. Simpan Data Profil (Nama) ke Tabel 'profiles'
        await supabase
          .from('profiles')
          .insert({'id': userId, 'email': email});

        // FIX: LANGSUNG NAVIGASI ke FillProfileScreen
        Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const FillProfileScreen(initialFullName: '',)),
        );

      } else {
        // Ini jarang terjadi
        _emailError = 'Registration failed. Please try again.';
        setState(() {});
      }

    } on AuthException catch (e) {
      // TANGANI ERROR SUPABASE (Contoh: Email sudah terdaftar)
      if (e.message.contains('already registered')) {
        _emailError = 'This email is already registered. Please Sign In.';
      } else {
        _emailError = 'Supabase Error: ${e.message}';
      }
      setState(() {});

    } catch (e) {
      // Tangani error umum
      _emailError = 'An unexpected error occurred.';
      setState(() {});
    }

    setState(() {
      _isLoading = false;
    });
  }

  // --- UI HELPER FUNCTIONS ---
  
  Widget _buildTextField({
  required TextEditingController controller,
  required String hint,
  required IconData icon,
  TextInputType keyboardType = TextInputType.text,
  bool isPassword = false, 
}) {
  return Container(
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 247, 246, 246),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
      ],
    ),
    child: TextField(
      controller: controller,
      obscureText: false,
      keyboardType: TextInputType.none,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[500]), // Warna hint text (abunya)
        prefixIcon: Icon(icon, color: const Color.fromARGB(255, 179, 179, 179)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: const Color.fromARGB(255, 250, 250, 250),
        contentPadding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 20.0),
      ),
      style: TextStyle(
        color: const Color.fromARGB(255, 50, 50, 50), // Warna teks input (abunya)
        fontSize: 16,
      ),
    ),
  );
}

  // --- BUILD METHOD ---

  @override
  Widget build(BuildContext context) {
    // KITA TAMBAHKAN BACKGROUND COLOR SPESIFIK DI SINI (mirip di screenshot)
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255), // Warna lavender/grey muda (background aplikasi)
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              // LOGO HEALTHPAL
              Image.asset(
                'assets/images/logo.png', // Ganti dengan nama file gambar kamu
                width: 100, // Sesuaikan ukuran lebar gambar
                height: 100, // Sesuaikan ukuran tinggi gambar
              ),
              const SizedBox(height: 30),
              const Text(
                'Sign Up',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'We are here to help you!',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 30),

              // INPUT: Your Email (TEKS ERROR DI TAMPILAN BACKGROUND APP)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTextField(
                    controller: _emailController,
                    hint: 'Your Email',
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  if (_emailError != null)
                    Padding(
                      padding: const EdgeInsets.only(left: 12.0, top: 4.0),
                      child: Text(
                        _emailError!,
                        style: const TextStyle(color: Colors.red, fontSize: 13),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 15),

              // INPUT: Password (TEKS ERROR DI TAMPILAN BACKGROUND APP)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTextField(
                    controller: _passwordController,
                    hint: 'Password',
                    icon: Icons.lock_outline,
                    isPassword: true,
                  ),
                  if (_passwordError != null)
                    Padding(
                      padding: const EdgeInsets.only(left: 12.0, top: 4.0),
                      child: Text(
                        _passwordError!,
                        style: const TextStyle(color: Colors.red, fontSize: 13),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 30),

              // Tombol Create Account
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _signUp, 
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 3, 33, 48),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(40),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Create Account',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
              const SizedBox(height: 20),

              // Link Sign In
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Do you have an account?'),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (context) => const SignInScreen()),
                      );
                    },
                    child: const Text(
                      'Sign In',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF003D5C),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}