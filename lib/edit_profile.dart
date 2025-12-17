import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';

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
  final _picker = ImagePicker();

  String? _avatarPath;       // path di Storage, mis: "<uid>/avatar"
  String? _avatarDisplayUrl; // signed url untuk preview
  Uint8List? _newAvatarBytes;
  String? _newAvatarMime;
  bool _avatarBusy = false;
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

  // ===== AVATAR HELPERS =====
  String? _extractStoragePath(String? value) {
    if (value == null || value.trim().isEmpty) return null;

    // kalau tersimpan URL public, ambil path setelah "/profile-photos/"
    if (value.startsWith('http')) {
      final marker = '/profile-photos/';
      final i = value.indexOf(marker);
      if (i != -1) return value.substring(i + marker.length);
    }
    return value; // kalau sudah path, pakai apa adanya
  }

  Future<String?> _getAvatarDisplayUrl(String? path) async {
    final p = _extractStoragePath(path);
    if (p == null) return null;

    // jika ternyata sudah URL, langsung pakai
    if (p.startsWith('http')) return p;

    // signed url agar aman untuk bucket private/public
    final url = await supabase.storage
        .from('profile-photos')
        .createSignedUrl(p, 60 * 60); // 1 jam
    return url;
  }

  Future<void> _pickAvatar() async {
    if (_avatarBusy) return;

    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1024,
    );
    if (file == null) return;

    final bytes = await file.readAsBytes();
    final mime = lookupMimeType(file.name, headerBytes: bytes) ?? 'image/jpeg';

    setState(() {
      _newAvatarBytes = bytes;
      _newAvatarMime = mime;
    });
  }

  Future<String> _uploadAvatar() async {
    final user = supabase.auth.currentUser!;
    final uid = user.id;

    final path = '$uid/avatar'; // policy kamu butuh foldername[1] = uid

    await supabase.storage.from('profile-photos').uploadBinary(
          path,
          _newAvatarBytes!,
          fileOptions: FileOptions(
            upsert: true,
            contentType: _newAvatarMime ?? 'image/jpeg',
          ),
        );

    return path;
  }

  Future<void> _deleteAvatar() async {
    // kalau user baru pilih foto tapi belum save -> batalkan pilihan saja
    if (_newAvatarBytes != null) {
      setState(() {
        _newAvatarBytes = null;
        _newAvatarMime = null;
      });
      return;
    }
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final p = _extractStoragePath(_avatarPath);
    if (p == null) return;

    setState(() => _avatarBusy = true);
    try {
      await supabase.storage.from('profile-photos').remove([p]);

      await supabase
          .from('profiles')
          .update({'profile_photo_url': null})
          .eq('id', user.id);

      if (!mounted) return;
      setState(() {
        _avatarPath = null;
        _avatarDisplayUrl = null;
        _newAvatarBytes = null;
        _newAvatarMime = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Photo removed')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to remove photo: $e')),
      );
    } finally {
      if (mounted) setState(() => _avatarBusy = false);
    }
  }
  // ===== END AVATAR HELPERS =====

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
          .select('full_name, nickname, email, date_of_birth, profile_photo_url')
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
      _avatarPath = _extractStoragePath(data?['profile_photo_url'] as String?);
      _avatarDisplayUrl = await _getAvatarDisplayUrl(_avatarPath);
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
      String? photoPath = _avatarPath;

      // kalau user baru pilih foto (preview), upload dulu
      if (_newAvatarBytes != null) {
        setState(() => _avatarBusy = true);

        photoPath = await _uploadAvatar(); // return path: "<uid>/avatar"
        _avatarPath = photoPath;

        // refresh signed url untuk preview setelah upload
        _avatarDisplayUrl = await _getAvatarDisplayUrl(photoPath);

        // reset buffer preview
        _newAvatarBytes = null;
        _newAvatarMime = null;

        setState(() => _avatarBusy = false);
      }

      // 1) update table profiles
      await supabase.from('profiles').update({
        'full_name': fullName.isEmpty ? null : fullName,
        'nickname': nickname.isEmpty ? null : nickname,
        'email': email.isEmpty ? null : email,
        'date_of_birth': _dobValue == null ? null : _dobValue!.toIso8601String().substring(0, 10), // YYYY-MM-DD
        'profile_photo_url': photoPath,
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
                      Center(
                        child: Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            CircleAvatar(
                              radius: 46,
                              backgroundColor: Colors.grey.shade200,
                              backgroundImage: _newAvatarBytes != null
                                  ? MemoryImage(_newAvatarBytes!)
                                  : (_avatarDisplayUrl != null ? NetworkImage(_avatarDisplayUrl!) : null)
                                      as ImageProvider?,
                              child: (_newAvatarBytes == null && _avatarDisplayUrl == null)
                                  ? Text(
                                      (_nameCtrl.text.trim().isNotEmpty
                                              ? _nameCtrl.text.trim()[0].toUpperCase()
                                              : 'U'),
                                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
                                    )
                                  : null,
                            ),
                            InkWell(
                              onTap: (_loading || _avatarBusy) ? null : _pickAvatar,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.grey.shade300),
                                ),
                                child: const Icon(Icons.camera_alt, size: 18, color: Color(0xFF6D28D9)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          TextButton.icon(
                            onPressed: (_loading || _avatarBusy || (_avatarPath == null && _newAvatarBytes == null))
                                ? null
                                : _deleteAvatar,
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                            label: const Text('Remove', style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
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
                  onPressed: (_saving || _avatarBusy) ? null : _save,
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