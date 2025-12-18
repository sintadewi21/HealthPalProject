import 'package:flutter/material.dart';

// Import file sesuai struktur folder kamu
import 'homepage.dart';             // Isinya class HomeScreen
import 'location_screen.dart';      // Isinya class LocationScreen
import 'palnews/palnews_page.dart'; // Isinya class PalNewsPage
import 'book_history.dart';         // Isinya class MyBookingsScreen
import 'profile.dart';              // Isinya class ProfilePage


class MainLayout extends StatefulWidget {
  final int initialIndex; // <--- 1. Tambahkan variabel ini

  // 2. Update constructor biar bisa terima input (defaultnya 0/Home)
  const MainLayout({Key? key, this.initialIndex = 0}) : super(key: key);

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  late int _selectedIndex; // <--- 3. Ubah jadi 'late' (jangan langsung = 0)

  @override
  void initState() {
    super.initState();
    // 4. Set index awal sesuai permintaan
    _selectedIndex = widget.initialIndex; 
  }


  // Daftar Halaman
  final List<Widget> _screens = [
    const HomeScreen(),        // Index 0
    const LocationScreen(),    // Index 1
    const PalNewsPage(),       // Index 2
    const MyBookingsScreen(),  // Index 3
    const ProfilePage(),       // Index 4
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // --- FUNGSI CUSTOM ICON BUILDER ---
  // Fungsi ini mengatur:
  // 1. Ganti icon outline -> filled saat aktif
  // 2. Munculkan lingkaran background saat aktif
  Widget _buildNavIcon(IconData inactiveIcon, IconData activeIcon, int index) {
    final bool isActive = _selectedIndex == index;
    
    return Container(
      padding: const EdgeInsets.all(8), // Jarak icon ke lingkaran
      decoration: isActive
          ? BoxDecoration(
              color: const Color(0xFFF3F4F6), // Warna lingkaran abu muda
              shape: BoxShape.circle,
            )
          : null, // Kalau tidak aktif, tidak ada background
      child: Icon(
        isActive ? activeIcon : inactiveIcon, // Ganti icon sesuai status
        color: isActive ? const Color(0xFF1E2A3B) : Colors.grey, // Biru tua vs Abu
        size: 24,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      
      bottomNavigationBar: Container(
        // Tambahkan border tipis di atas navbar biar makin mirip desain
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Colors.black12, width: 0.5)),
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          elevation: 0, // Hilangkan shadow bawaan biar flat
          
          showSelectedLabels: false,
          showUnselectedLabels: false,

          items: [
            // 1. Home (Outline -> Filled)
            BottomNavigationBarItem(
              icon: _buildNavIcon(Icons.home_outlined, Icons.home_filled, 0),
              label: '',
            ),
            // 2. Location (Outline -> Filled)
            BottomNavigationBarItem(
              icon: _buildNavIcon(Icons.location_on_outlined, Icons.location_on, 1),
              label: '',
            ),
            // 3. PalNews (Outline -> Filled)
            BottomNavigationBarItem(
              icon: _buildNavIcon(Icons.article_outlined, Icons.article, 2),
              label: '',
            ),
            // 4. Booking (Outline -> Filled)
            BottomNavigationBarItem(
              icon: _buildNavIcon(Icons.calendar_today_outlined, Icons.calendar_month, 3),
              label: '',
            ),
            // 5. Profile (Outline -> Filled)
            BottomNavigationBarItem(
              icon: _buildNavIcon(Icons.person_outline, Icons.person, 4),
              label: '',
            ),
          ],
        ),
      ),
    );
  }
}