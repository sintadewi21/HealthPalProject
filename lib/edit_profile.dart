import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final supabase = Supabase.instance.client;

  final _nameCtrl = TextEditingController();
  final _nickCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _dobCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  bool _loading = true;
  bool _saving = false;

  DateTime? _dobValue; // simpan DateTime asli supaya gampang update ke DB

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _nickCtrl.dispose();
    _emailCtrl.dispose();
    _dobCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  InputDecoration _decor(String label) {
    return InputDecoration(
      labelText: label,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF1C2833), width: 1.2),
      ),
      suffixIcon: const Icon(Icons.edit, size: 18, color: Colors.black54),
    );
  }

  String _formatDob(DateTime d) {
    // format "YYYY / MM / DD" sesuai UI kamu
    final mm = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return '${d.year} / $mm / $dd';
  }

  DateTime? _parseDobFromDb(dynamic value) {
    // Supabase date biasanya balik String "YYYY-MM-DD"
    if (value == null) return null;
    try {
      if (value is String) return DateTime.parse(value);
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<void> _loadProfile() async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      if (!mounted) return;
      setState(() => _loading = false);
      return;
    }

    try {
      final data = await supabase
          .from('profiles')
          .select('full_name, nickname, email, date_of_birth')
          .eq('id', user.id)
          .maybeSingle();

      // fallback kalau email di profiles kosong: ambil dari auth user
      final authEmail = user.email ?? '';

      final fullName = (data?['full_name'] as String?) ?? '';
      final nickname = (data?['nickname'] as String?) ?? '';
      final email = ((data?['email'] as String?)?.trim().isNotEmpty ?? false)
          ? (data?['email'] as String)
          : authEmail;

      _dobValue = _parseDobFromDb(data?['date_of_birth']);

      _nameCtrl.text = fullName;
      _nickCtrl.text = nickname;
      _emailCtrl.text = email;
      _dobCtrl.text = _dobValue != null ? _formatDob(_dobValue!) : '';
      _passCtrl.text = ''; // jangan isi password dari mana pun (demi keamanan)
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load profile: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickDob() async {
    final initial = _dobValue ?? DateTime(2000, 1, 1);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1900, 1, 1),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _dobValue = DateTime(picked.year, picked.month, picked.day);
        _dobCtrl.text = _formatDob(_dobValue!);
      });
    }
  }

  Future<void> _save() async {
    if (_saving) return;

    final user = supabase.auth.currentUser;
    if (user == null) return;

    final fullName = _nameCtrl.text.trim();
    final nickname = _nickCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final newPassword = _passCtrl.text.trim(); // opsional

    setState(() => _saving = true);

    try {
      // 1) update table profiles
      await supabase.from('profiles').update({
        'full_name': fullName.isEmpty ? null : fullName,
        'nickname': nickname.isEmpty ? null : nickname,
        'email': email.isEmpty ? null : email,
        'date_of_birth':
            _dobValue == null ? null : _dobValue!.toIso8601String().substring(0, 10), // YYYY-MM-DD
      }).eq('id', user.id);

      // 2) optional: update auth email / password (kalau user mengisi)
      //    - email: Supabase biasanya kirim verifikasi email
      //    - password: langsung update auth
      final needsEmailUpdate = email.isNotEmpty && email != (user.email ?? '');
      if (needsEmailUpdate) {
        await supabase.auth.updateUser(UserAttributes(email: email));
      }

      if (newPassword.isNotEmpty) {
        await supabase.auth.updateUser(UserAttributes(password: newPassword));
        _passCtrl.clear();
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated')),
      );

      // penting: supaya ProfilePage kebaca update saat balik
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
        centerTitle: true,
        title: const Text(
          'Edit Profile',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
      ),

      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Padding(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 0),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 160),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(controller: _nameCtrl, decoration: _decor('Name')),
                      const SizedBox(height: 12),
                      TextField(controller: _nickCtrl, decoration: _decor('Nickname')),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _emailCtrl,
                        decoration: _decor('Email'),
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _dobCtrl,
                        decoration: _decor('Date of Birth'),
                        readOnly: true,
                        onTap: _pickDob, // ✅ pilih date
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _passCtrl,
                        decoration: _decor('Password'),
                        obscureText: true,
                      ),
                    ],
                  ),
                ),
              ),
      ),

      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 52,
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1C2833),
                    disabledBackgroundColor: const Color(0xFF1C2833).withOpacity(0.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(26),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    _saving ? 'Saving...' : 'Save Changes',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 52,
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // nanti kalau kamu mau: confirm modal + delete flow
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Delete (belum diaktifkan)')),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE53935),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(26),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Delete Account',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}