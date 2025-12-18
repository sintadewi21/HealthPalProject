import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import 'homepage.dart';
import 'location_screen.dart';
import 'palnews/palnews_page.dart';
import 'book_history.dart';
import 'notification.dart';
import 'onboarding.dart'; // ✅ supaya bisa ke onboarding setelah logout
import 'edit_profile.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final supabase = Supabase.instance.client;
  late final StreamSubscription<AuthState> _authSub;
  String? _normalizeAvatarPath(String? value) {
    if (value == null) return null;
    var v = value.trim();
    if (v.isEmpty) return null;
    if (v.startsWith('http')) return v;
    v = v.replaceFirst(RegExp(r'^/+'), '');
    final idx = v.indexOf('profile-photos/');
    if (idx != -1) v = v.substring(idx + 'profile-photos/'.length);
    return v;
  }

  Future<Map<String, dynamic>?> _fetchProfile() async {
    final user = supabase.auth.currentUser;
    if (user == null) return null;

    final data = await supabase
        .from('profiles')
        .select('full_name, email, profile_photo_url')
        .eq('id', user.id)
        .maybeSingle();

    final raw = (data?['profile_photo_url'] as String?)?.trim();
    final normalized = _normalizeAvatarPath(raw);

    String? displayUrl;
    if (normalized != null && normalized.isNotEmpty) {
      if (normalized.startsWith('http')) {
        displayUrl = normalized;
      } else {
        displayUrl = await supabase.storage
            .from('profile-photos')
            .createSignedUrl(normalized, 60 * 60); // 1 jam
      }
    }

    return {
      ...?data,
     'profile_photo_url': displayUrl,
    };
  }
  int _currentIndex = 4;

  Future<Map<String, dynamic>?>? _profileFuture;

  @override
  void initState() {
    super.initState();

    _profileFuture = _fetchProfile();

    _authSub = supabase.auth.onAuthStateChange.listen((_) {
      if (!mounted) return;
      setState(() => _profileFuture = _fetchProfile());
    });
  }

  @override
  void dispose() {
    _authSub.cancel();
    super.dispose();
  }

  Future<void> _reloadProfile() async {
    if (supabase.auth.currentUser == null) return;
    setState(() => _profileFuture = _fetchProfile());
  }

  Future<void> _showLogoutDialog() async {
    final bool? yes = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.45), // ✅ background gelap
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white, // ✅ putih beneran
        surfaceTintColor: Colors.white, // ✅ hilangin “ungu tipis” Material 3
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Center(
          child: Text(
            'Logout',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
        content: const Text(
          'Are you sure you want to log out?',
          textAlign: TextAlign.center,
          style: TextStyle(color: Color(0xFF6B7280), fontWeight: FontWeight.w600),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: const Color(0xFFE5E7EB),
                      foregroundColor: const Color(0xFF1E2A3B),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(22),
                      ),
                    ),
                    child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: const Color(0xFF1C2833),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(22),
                      ),
                    ),
                    child: const Text('Yes, Logout', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (yes == true) {
      await supabase.auth.signOut();
      if (!mounted) return;

      // ✅ keluar ke onboarding.dart (tanpa ubah onboarding)
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const OnboardingScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = supabase.auth.currentUser;
    final String? userId = user?.id;

    // divider tidak sampai ujung layar (sejajar icon & chevron)
    Widget insetDivider() => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Divider(height: 1, thickness: 0.8, color: Colors.grey.shade300),
        );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false, // ✅ matiin tombol back
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Profile',
          style: TextStyle(
            color: Color(0xFF1E2A3B),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 12),

            // ✅ Nama & Email dari table profiles (fallback aman)
            FutureBuilder<Map<String, dynamic>?>(
              future: _profileFuture,
              builder: (context, snapshot) {
                final data = snapshot.data;

                final fullName = (data?['full_name'] as String?)?.trim();
                final email = (data?['email'] as String?)?.trim();
                final photoUrl = (data?['profile_photo_url'] as String?)?.trim();

                String initial = 'U';
                if (fullName != null && fullName.isNotEmpty) {
                  initial = fullName[0].toUpperCase();
                }

                return Column(
                  children: [
                    // ✅ FOTO PROFIL
                    Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFF1F3F6),
                        border: Border.all(color: Colors.grey.shade300, width: 1),
                      ),
                      child: ClipOval(
                        child: (photoUrl != null && photoUrl.isNotEmpty)
                            ? Image.network(
                                photoUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) {
                                  return Center(
                                    child: Text(
                                      initial,
                                      style: const TextStyle(
                                        fontSize: 36, // ✅ ikut dibesarin biar proporsional
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF1E2A3B),
                                      ),
                                    ),
                                  );
                                },
                              )
                            : Center(
                                child: Text(
                                  initial,
                                  style: const TextStyle(
                                    fontSize: 36, // ✅ ikut dibesarin
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF1E2A3B),
                                  ),
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // ✅ NAMA
                    Text(
                      (fullName != null && fullName.isNotEmpty) ? fullName : 'Your Name',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E2A3B),
                      ),
                    ),
                    const SizedBox(height: 4),

                    // ✅ EMAIL
                    Text(
                      email ?? '',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 20),

            _MenuItem(
              icon: Icons.person_outline,
              title: 'Edit Profile',
              onTap: () async {
                final changed = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const EditProfilePage(),
                  ),
                );

                if (changed == true) {
                  await _reloadProfile();
                }
              },
            ),
            insetDivider(),

            _MenuItem(
              customIcon: Stack(
                children: [
                  const Icon(
                    Icons.notifications_none,
                    color: Color(0xFF1E2A3B),
                  ),

                  if (userId != null)
                    StreamBuilder<List<Map<String, dynamic>>>(
                      stream: supabase
                          .from('notifications')
                          .stream(primaryKey: ['notification_id']),
                      builder: (context, snapshot) {
                        final data = snapshot.data ?? [];

                        final hasUnread = data.any((n) =>
                            n['user_id'] == userId &&
                            (n['status'] ?? 'unread') == 'unread');

                        if (!hasUnread) return const SizedBox.shrink();

                        return Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
              title: 'Notifications',
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const NotificationPage()),
                );
                setState(() {}); // refresh badge saat balik
              },
            ),
            insetDivider(),

            _MenuItem(
              icon: Icons.calendar_today_outlined,
              title: 'My Bookings',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MyBookingsScreen()),
                );
              },
            ),
            insetDivider(),

            _MenuItem(
              icon: Icons.logout,
              title: 'Log Out',
              onTap: _showLogoutDialog, // ✅ pakai popup konfirmasi
            ),
          ],
        ),
      ),
    );
  }

  Widget _navIcon(IconData icon, int index) {
    final bool isActive = _currentIndex == index;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFFF1F3F6) : Colors.transparent,
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        size: 24,
        color: isActive ? const Color(0xFF39434F) : Colors.grey,
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData? icon;
  final Widget? customIcon;
  final String title;
  final VoidCallback onTap;

  const _MenuItem({
    this.icon,
    this.customIcon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Row(
          children: [
            customIcon ??
                Icon(
                  icon,
                  color: const Color(0xFF1E2A3B),
                ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  color: Color(0xFF1E2A3B),
                ),
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}