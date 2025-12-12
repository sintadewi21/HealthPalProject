import 'package:flutter/material.dart';
import 'notification.dart';
import 'location_screen.dart'; // <-- IMPORT FILE BARU
import 'all_doctors_screen.dart';
import 'palnews/palnews_page.dart';
import 'book_history.dart'; // TAMBAHKAN IMPORT

/// =================== HOME SCREEN ===================

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PageController _bannerController = PageController();
  final TextEditingController _searchController = TextEditingController();

  int _currentBanner = 0;
  int _currentIndex = 0;

  @override
  void dispose() {
    _bannerController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // NAVBAR ICON BUILDER (BIAR MIRIP DESAIN)
  Widget _buildNavIcon(IconData icon, int index) {
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

  @override
  Widget build(BuildContext context) {
    // WARNA KATEGORI
    final categoryColors = <Color>[
      const Color(0xFFFFE3E3),
      const Color(0xFFE1F6EA),
      const Color(0xFFFFE4D2),
      const Color(0xFFEDE8FF),
      const Color(0xFFE0F3FF),
      const Color(0xFFEEE3FF),
      const Color(0xFFFFECF1),
      const Color(0xFFDFF7FF),
    ];

    // SEMUA KATEGORI (untuk halaman See All)
    final allCategories = [
      {'name': 'Dentistry', 'icon': Icons.medical_services_outlined},
      {'name': 'Cardiology', 'icon': Icons.favorite_border},
      {'name': 'Pulmonology', 'icon': Icons.air_outlined},
      {'name': 'General', 'icon': Icons.health_and_safety_outlined},
      {'name': 'Neurology', 'icon': Icons.psychology_outlined},
      {'name': 'Gastroenterology', 'icon': Icons.biotech_outlined},
      {'name': 'Laboratory', 'icon': Icons.science_outlined},
      {'name': 'Vaccination', 'icon': Icons.vaccines_outlined},
      // tambahan
      {'name': 'Gynecology', 'icon': Icons.pregnant_woman},
      {'name': 'Orthopedic', 'icon': Icons.accessibility_new},
      {'name': 'Pediatrics', 'icon': Icons.child_care},
      {'name': 'Dermatology', 'icon': Icons.spa},
      {'name': 'Ophthalmology', 'icon': Icons.remove_red_eye_outlined},
      {'name': 'Psychiatry', 'icon': Icons.psychology},
    ];

    // YANG DITAMPILKAN DI HOME CUMA 8 PERTAMA
    final homeCategories = allCategories.take(8).toList();

    // DATA BANNER CAROUSEL
    final banners = [
      {
        'title': 'Looking for\nSpecialist Doctors?',
        'subtitle': 'Schedule an appointment with our top doctors.',
        'image':
            'https://images.pexels.com/photos/3714743/pexels-photo-3714743.jpeg',
      },
      {
        'title': 'Book your\nnext checkup',
        'subtitle': 'Find trusted doctors near your location.',
        'image':
            'https://images.pexels.com/photos/6129682/pexels-photo-6129682.jpeg',
      },
      {
        'title': '24/7 Online\nConsultation',
        'subtitle': 'Chat with doctors anytime, anywhere.',
        'image':
            'https://images.pexels.com/photos/7578802/pexels-photo-7578802.jpeg',
      },
    ];

    final centers = [
      {
        'name': 'Sunrise Health Clinic',
        'location': 'Meruya Selatan',
        'image':
            'https://images.pexels.com/photos/263402/pexels-photo-263402.jpeg',
      },
      {
        'name': 'Golden Cardiology Center',
        'location': 'Jakarta Barat',
        'image':
            'https://images.pexels.com/photos/236380/pexels-photo-236380.jpeg',
      },
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),

      // ================== BOTTOM NAVBAR ==================
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        elevation: 0,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        onTap: (index) {
          setState(() => _currentIndex = index);

          if (index == 1) {
            // TAB LOCATION
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const LocationScreen()),
            );
          } else if (index == 2) {
            // TAB PALNEWS
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const PalNewsPage()),
            );
          } else if (index == 3) {
            // TAB CALENDAR → NAVIGATE KE BOOK_CANCEL
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const MyBookingsScreen()),
            );
          }
          // index 0 = Home (stay)
          // index 4 = Profile (nanti)
        },
        items: [
          BottomNavigationBarItem(
            icon: _buildNavIcon(Icons.home_rounded, 0),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: _buildNavIcon(Icons.location_on_outlined, 1),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: _buildNavIcon(Icons.article_outlined, 2),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: _buildNavIcon(Icons.calendar_today_outlined, 3),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: _buildNavIcon(Icons.person_outline, 4),
            label: '',
          ),
        ],
      ),

      // ================== BODY ==================
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// TOP LOCATION & NOTIFICATION
              Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Location',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.location_on_outlined, size: 18),
                          SizedBox(width: 4),
                          Text(
                            'Seattle, USA',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(width: 2),
                          Icon(Icons.keyboard_arrow_down_rounded, size: 18),
                        ],
                      ),
                    ],
                  ),
                  const Spacer(),
                  Stack(
                    children: [
                      InkWell(
                        borderRadius: BorderRadius.circular(50),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => NotificationPage(),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.notifications_none_rounded),
                        ),
                      ),
                      Positioned(
                        right: 6,
                        top: 6,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.red,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 16),

              /// SEARCH BAR
              TextField(
                controller: _searchController,
                onSubmitted: (value) {
                  if (value.trim().isEmpty) return;
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => AllDoctorsScreen(
                        initialQuery: value.trim(), // <<< kirim ke AllDoctorsScreen
                      ),
                    ),
                  );
                },
                decoration: InputDecoration(
                  hintText: 'Search doctor...',
                  prefixIcon: const Icon(
                    Icons.search,
                    color: Colors.grey,
                    size: 22,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 0,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              /// HERO BANNER - CAROUSEL
              SizedBox(
                height: 160,
                child: PageView.builder(
                  controller: _bannerController,
                  itemCount: banners.length,
                  onPageChanged: (index) {
                    setState(() {
                      _currentBanner = index;
                    });
                  },
                  itemBuilder: (context, index) {
                    final b = banners[index];
                    return Container(
                      margin: const EdgeInsets.only(right: 4),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        gradient: const LinearGradient(
                          colors: [Color(0xFF2E6FF3), Color(0xFF54C1F9)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    b['title'] as String,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    b['subtitle'] as String,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  _BannerDots(
                                    count: banners.length,
                                    currentIndex: _currentBanner,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Image.network(
                              b['image'] as String,
                              height: double.infinity,
                              width: 110,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 24),

              /// CATEGORIES TITLE
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Categories',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const AllDoctorsScreen(),
                        ),
                      );
                    },
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 0),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      'See All',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.blue,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              /// CATEGORIES GRID (4 kolom)
              LayoutBuilder(
                builder: (context, constraints) {
                  final itemWidth = (constraints.maxWidth - (3 * 12)) / 4;
                  return Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: List.generate(homeCategories.length, (index) {
                      final item = homeCategories[index];
                      final String categoryName = item['name'] as String;

                      return SizedBox(
                        width: itemWidth,
                        child: _CategoryCard(
                          name: categoryName,
                          icon: item['icon'] as IconData,
                          color: categoryColors[index % categoryColors.length],
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => AllDoctorsScreen(
                                  initialFilter: categoryName, // <<< kirim kategori
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    }),
                  );
                },
              ),

              const SizedBox(height: 24),

              /// NEARBY MEDICAL CENTERS TITLE
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text(
                    'Nearby Medical Centers',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  Text(
                    'See All',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.blue,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              /// HORIZONTAL LIST OF CENTERS
              SizedBox(
                height: 190,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: centers.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 16),
                  itemBuilder: (context, index) {
                    final c = centers[index];
                    return SizedBox(
                      width: 230,
                      child: _MedicalCenterCard(
                        name: c['name'] as String,
                        location: c['location'] as String,
                        imageUrl: c['image'] as String,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ======= SMALL WIDGETS UNTUK HOME =======

class _BannerDots extends StatelessWidget {
  final int count;
  final int currentIndex;

  const _BannerDots({
    super.key,
    required this.count,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(
        count,
        (index) => Padding(
          padding: const EdgeInsets.only(right: 6.0),
          child: _dot(index == currentIndex),
        ),
      ),
    );
  }

  Widget _dot(bool active) {
    return Container(
      height: active ? 8 : 6,
      width: active ? 16 : 6,
      decoration: BoxDecoration(
        color: active ? Colors.white : Colors.white38,
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final String name;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _CategoryCard({
    required this.name,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 20),
            ),
            const SizedBox(height: 6),
            Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}

class _MedicalCenterCard extends StatelessWidget {
  final String name;
  final String location;
  final String imageUrl;

  const _MedicalCenterCard({
    required this.name,
    required this.location,
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          SizedBox(
            height: 110,
            width: double.infinity,
            child: Image.network(imageUrl, fit: BoxFit.cover),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 14),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        location,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// =================== ALL CATEGORIES SCREEN ===================

class AllCategoriesScreen extends StatelessWidget {
  final List<Map<String, dynamic>> categories;
  final List<Color> categoryColors;

  const AllCategoriesScreen({
    super.key,
    required this.categories,
    required this.categoryColors,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Categories'),
        centerTitle: true,
        elevation: 0,
      ),
      backgroundColor: const Color(0xFFF7F8FA),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: LayoutBuilder(
          builder: (context, constraints) {
            // 3 kolom biar agak lega
            final itemWidth = (constraints.maxWidth - (2 * 12)) / 3;

            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: List.generate(categories.length, (index) {
                final item = categories[index];
                final String categoryName = item['name'] as String;

                return SizedBox(
                  width: itemWidth,
                  child: _CategoryCard(
                    name: categoryName,
                    icon: item['icon'] as IconData,
                    color: categoryColors[index % categoryColors.length],
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => AllDoctorsScreen(
                            initialFilter: categoryName, // filter dokter by kategori
                          ),
                        ),
                      );
                    },
                  ),
                );
              }),
            );
          },
        ),
      ),
    );
  }
}


/// =================== SUCCESS SCREEN (punyamu) ===================

class SuccessScreen extends StatefulWidget {
  const SuccessScreen({super.key});

  @override
  State<SuccessScreen> createState() => _SuccessScreenState();
}

class _SuccessScreenState extends State<SuccessScreen> {
  void _navigateToHome() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 121, 121, 121),
      body: Center(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.8,
          padding: const EdgeInsets.all(30.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(35),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Color.fromARGB(255, 135, 194, 184),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 40),
              ),
              const SizedBox(height: 30),
              const Text(
                'Congratulations!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF003D5C),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              const Text(
                'Your account is ready to use. You will be redirected to the Home Page in a few seconds...',
                style: TextStyle(fontSize: 16, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _navigateToHome,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 3, 33, 48),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(40),
                    ),
                  ),
                  child: const Text(
                    'Next',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
