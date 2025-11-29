import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'homepage.dart'; // Import halaman tujuan akhir

// Asumsi global instance 'supabase' sudah tersedia (dari main.dart)
final supabase = Supabase.instance.client;

class FillProfileScreen extends StatefulWidget {
  // Menerima nama yang diinput user saat Sign Up
  final String initialFullName; 

  const FillProfileScreen({
    super.key,
    required this.initialFullName, 
  });

  @override
  State<FillProfileScreen> createState() => _FillProfileScreenState();
}

class _FillProfileScreenState extends State<FillProfileScreen> {
  // Controller
  late final TextEditingController _fullNameController;
  final _nicknameController = TextEditingController();
  final _emailController = TextEditingController(); // Email akan diisi otomatis dari Supabase
  final _dobController = TextEditingController();
  
  // State
  String _selectedGender = 'Male';
  bool _isLoading = false;
  
  // Data untuk Dropdown Gender
  final List<String> _genders = ['Male', 'Female', 'Other'];

  // Data user dari Supabase (diinisialisasi saat initState)
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    // 1. Inisialisasi controller nama dengan nama dari Sign Up
    _fullNameController = TextEditingController(text: widget.initialFullName);

    
    // 2. Ambil data user yang baru login (Auth)
    _currentUser = supabase.auth.currentUser;

    // 3. Set email di controller (ReadOnly)
    _emailController.text = _currentUser?.email ?? '';
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _nicknameController.dispose();
    _emailController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  // Fungsi untuk menampilkan Date Picker
  Future<void> _selectDateOfBirth() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000), // Default tahun
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF003D5C), // Warna utama picker
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        // Format tanggal sederhana YYYY-MM-DD
        _dobController.text = picked.toIso8601String().split('T')[0];
      });
    }
  }

  // --- LOGIC SIMPAN DATA PROFIL KE SUPABASE ---
  void _saveProfile() async {
    if (_currentUser == null) {
      // Jika user tidak terautentikasi (seharusnya tidak terjadi setelah Sign Up)
      _showSnackBar('Error: User not authenticated.', isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final nickname = _nicknameController.text.trim();
    final dob = _dobController.text.trim();
    final fullName = _fullNameController.text.trim();

    try {
      // Data yang akan di-update di tabel 'profiles'
      final updates = {
        'full_name': fullName, // Update nama jika diubah
        'nickname': nickname.isNotEmpty ? nickname : null,
        'date_of_birth': dob.isNotEmpty ? dob : null,
        'gender': _selectedGender,
        // Kolom 'id' dan 'email' tidak perlu di-update (sudah ada)
      };

      // Panggil Supabase untuk update data di tabel 'profiles'
      // Diasumsikan data 'id' (UUID user) sudah ada di tabel profiles saat Sign Up
      await supabase
          .from('profiles')
          .update(updates)
          .eq('id', _currentUser!.id);

      _showSnackBar('Profile saved successfully!');

      // Navigasi ke HomePage setelah berhasil
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const SuccessScreen()),
        );
      }

    } on PostgrestException catch (e) {
      // Tangani error spesifik dari Supabase (Postgres)
      _showSnackBar('Database Error: ${e.message}', isError: true);
    } catch (e) {
      // Tangani error umum
      _showSnackBar('An unexpected error occurred: $e', isError: true);
    }

    setState(() {
      _isLoading = false;
    });
  }

  // Helper untuk SnackBar
  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
      ),
    );
  }


  // --- UI HELPER FUNCTIONS ---

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    IconData? icon,
    bool readOnly = false,
    VoidCallback? onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
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
        readOnly: readOnly,
        onTap: onTap,
        // EDIT 1: Mengubah warna teks input menjadi abu-abu gelap
        style: TextStyle(color: Colors.grey[700]),
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: icon != null ? Icon(icon, color: const Color(0xFF003D5C)) : null,
          contentPadding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 20.0),
          border: InputBorder.none, // Hilangkan border default
          // EDIT 2: Mengubah warna hint text menjadi abu-abu (untuk field readonly/email)
          hintStyle: TextStyle(color: const Color.fromARGB(255, 0, 0, 0)),
        ),
      ),
    );
  }

  // --- BUILD METHOD ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Fill Profile',
          style: TextStyle(
            color: Color(0xFF003D5C),
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF003D5C)),
          onPressed: () {
            // Bisa kembali ke Sign Up atau ke halaman sebelumnya
            Navigator.of(context).pop();
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            // FOTO PROFIL (Placeholder)
            Stack(
              children: [
                CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.grey.shade200,
                  child: Icon(
                    Icons.person,
                    size: 80,
                    color: Colors.grey.shade500,
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF003D5C),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.all(6.0),
                      child: Icon(
                        Icons.edit,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),

            // INPUT: Full Name (Sudah terisi otomatis)
            _buildTextField(
              controller: _fullNameController,
              hint: 'Full Name (Michael Jordan)',
              icon: Icons.person_outline,
            ),
            const SizedBox(height: 15),

            // INPUT: Nickname
            _buildTextField(
              controller: _nicknameController,
              hint: 'Nickname',
              icon: Icons.badge_outlined,
            ),
            const SizedBox(height: 15),

            // INPUT: Email (Read Only)
            _buildTextField(
              controller: _emailController,
              hint: 'name@example.com',
              icon: Icons.email_outlined,
              readOnly: true,
            ),
            const SizedBox(height: 15),

            // INPUT: Date of Birth
            _buildTextField(
              controller: _dobController,
              hint: 'Date of Birth (YYYY-MM-DD)',
              icon: Icons.calendar_today_outlined,
              readOnly: true, // Tidak bisa diketik, harus lewat Date Picker
              onTap: _selectDateOfBirth,
            ),
            const SizedBox(height: 15),

            // INPUT: Gender (Dropdown)
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
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
              child: DropdownButtonFormField<String>(
                value: _selectedGender,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.people_outline, color: Color(0xFF003D5C)),
                  // Hapus contentPadding di sini agar DropdownButton di bawah yang mengatur padding
                  border: InputBorder.none,
                ),
                // EDIT 3: Mengubah warna teks yang terpilih (e.g., Male/Female) menjadi abu-abu
                style: TextStyle(color: Colors.grey[700], fontSize: 16),
                icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF003D5C)),
                isExpanded: true, // Pastikan dropdown memenuhi lebar
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedGender = newValue!;
                  });
                },
                items: _genders.map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                // EDIT 4: Mengatur padding agar DropdownButton rata dengan TextField
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 0.0),
              ),
            ),
            const SizedBox(height: 40),

            // Tombol Save
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF003D5C),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 5,
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Save',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}