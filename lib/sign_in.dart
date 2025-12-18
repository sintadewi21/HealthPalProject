import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'sign_up.dart'; // Perbaikan import
import 'homepage.dart';
import 'main_layout.dart';

// Asumsi global instance 'supabase' sudah tersedia (dari main.dart)
final supabase = Supabase.instance.client;

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  String? _emailError;
  String? _passwordError;
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

  // --- LOGIC SIGN IN DENGAN SUPABASE ---
  void _signIn() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    bool hasError = false;

    _clearErrors(); 
    
    // Validasi lokal
    if (email.isEmpty) {
      _emailError = 'Email is required.';
      hasError = true;
    } 
    if (password.isEmpty) {
      _passwordError = 'Password is required.';
      hasError = true;
    }

    if (hasError) {
      setState(() {});
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Panggil Supabase Auth untuk Log In
      final AuthResponse authResponse = await supabase.auth.signInWithPassword(
        email: email,
        password: password, 
      );

      // Cek respons dari Auth
      if (authResponse.user != null) {
        // Log In Berhasil!
        
        // FIX: Navigasi langsung ke HomeScreen
        // Navigator.of(context).pushReplacement(
        //     MaterialPageRoute(builder: (context) => const HomeScreen()),
        // );

        // Di dalam fungsi login success:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainLayout()), // Arahkan ke MainLayout
        );

      } 

    } on AuthException catch (_) {
      // Tangani error Supabase (misalnya kredensial salah)
      _emailError = 'Login failed: Invalid credentials or account not verified.';
      setState(() {});

    } catch (e) {
      _emailError = 'An unexpected error occurred.';
      setState(() {});
    }

    setState(() {
      _isLoading = false;
    });
  }

  // Helper Widget untuk TextField (sama dengan di Sign Up)
  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool isPassword = false, 
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: const Color.fromARGB(255, 183, 183, 183),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: false,
        keyboardType: TextInputType.none,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey[500]),
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

  @override
  Widget build(BuildContext context) {
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
              Image.asset(
                'assets/images/logo.png', // Ganti dengan nama file gambar kamu
                width: 100, // Sesuaikan ukuran lebar gambar
                height: 100, // Sesuaikan ukuran tinggi gambar
              ),
              const SizedBox(height: 30),
              const Text(
                'Sign In',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                "Hi, Welcome Back! Hope you're doing fine.",
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 30),

              // INPUT: Your Email (TEKS ERROR INLINE)
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

              // INPUT: Password (TEKS ERROR INLINE)
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

              // Tombol Sign In
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _signIn, 
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
                          'Sign In',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
              const SizedBox(height: 20),

              // Link Sign Up
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Don't have an account yet?"),
                  TextButton(
                    onPressed: () {
                      // Navigasi ke halaman Sign Up
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (context) => const SignUpScreen()),
                      );
                    },
                    child: const Text(
                      'Sign up',
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