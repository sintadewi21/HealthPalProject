// lib/palnews/palnews_page.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../homepage.dart';          // ⬅️ untuk navigasi ke Home
import '../location_screen.dart';   // ⬅️ untuk navigasi ke Location
import '../profile.dart';            // ⬅️ untuk navigasi ke Profile

import 'palnews_model.dart';
import 'palnews_repository.dart';
import 'palnews_detail_page.dart';
import 'widgets/palnews_news_card.dart';
import 'widgets/palnews_category_chip.dart';

const primaryColor = Color(0xFF1C2A3A);

class PalNewsPage extends StatefulWidget {
  const PalNewsPage({super.key});

  @override
  State<PalNewsPage> createState() => _PalNewsPageState();
}

class _PalNewsPageState extends State<PalNewsPage> {
  int selectedCategoryIndex = 0;
  String searchQuery = '';

  late Future<List<PalNewsItem>> futureNews;
  late PalNewsRepository repo;

  final PageController _trendingController = PageController();
  int _currentTrendingIndex = 0;

  // ⬇️ NAVBAR STATE (tab PalNews aktif)
  int _currentIndex = 2;

  @override
  void initState() {
    super.initState();
    repo = PalNewsRepository(Supabase.instance.client);
    futureNews = repo.fetchNews();
  }

  @override
  void dispose() {
    _trendingController.dispose();
    super.dispose();
  }

  void _openDetail(PalNewsItem item) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => PalNewsDetailPage(news: item)),
    );
  }

  // ⬇️ SAMA SEPERTI DI HOMESCREEN
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
    return Scaffold(
      backgroundColor: Colors.white,

      // =============== NAVBAR PALING BAWAH ===============
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        elevation: 0,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        onTap: (index) {
          setState(() => _currentIndex = index);

          if (index == 0) {
            // ke Home
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const HomeScreen()),
            );
          } else if (index == 1) {
            // ke Location
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const LocationScreen()),
            );
          } else if (index == 2) {
            // PalNews (lagi di sini) → nggak perlu apa-apa
          } else if (index == 4) {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ProfilePage()),
            );
          }
          // index 3 = Calendar (nanti)
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

      // ================== BODY PALNEWS ==================
      body: SafeArea(
        child: Column(
          children: [
            // ===== HEADER PALNEWS =====
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
              child: SizedBox(
                width: double.infinity,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/images/iconpalnews.png',
                      width: 26,
                      height: 26,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'PalNews',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ===== SEARCH BAR =====
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20.0, vertical: 4.0),
              child: TextField(
                onChanged: (value) {
                  setState(() {
                    searchQuery = value;
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Search news',
                  hintStyle: const TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: Colors.grey,
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF3F4F6),
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 0,
                    horizontal: 16,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: Colors.black.withOpacity(0.05),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                      color: primaryColor,
                      width: 1.2,
                    ),
                  ),
                ),
              ),
            ),

            // ===== BODY =====
            Expanded(
              child: FutureBuilder<List<PalNewsItem>>(
                future: futureNews,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text('Error: ${snapshot.error}'),
                    );
                  }

                  final allNews = snapshot.data ?? [];
                  if (allNews.isEmpty) {
                    return const Center(child: Text('Belum ada berita'));
                  }

                  // --- KATEGORI ---
                  final categorySet = <String>{};
                  for (final n in allNews) {
                    if (n.category.isNotEmpty) categorySet.add(n.category);
                  }
                  final categories = <String>['All', ...categorySet.toList()];
                  final chipIndex =
                      selectedCategoryIndex.clamp(0, categories.length - 1)
                          as int;

                  // --- FILTER BERDASARKAN KATEGORI & SEARCH ---
                  List<PalNewsItem> filtered = allNews;

                  if (chipIndex > 0 && chipIndex < categories.length) {
                    final selectedCategory = categories[chipIndex];
                    filtered = filtered
                        .where((n) => n.category == selectedCategory)
                        .toList();
                  }

                  if (searchQuery.isNotEmpty) {
                    final q = searchQuery.toLowerCase();
                    filtered = filtered
                        .where((n) => n.title.toLowerCase().contains(q))
                        .toList();
                  }

                  // --- TRENDING: 3 terbaru, HANYA DI KATEGORI ALL ---
                  final bool showTrending =
                      chipIndex == 0 && filtered.isNotEmpty;
                  List<PalNewsItem> trendingTop = [];
                  if (showTrending) {
                    final trending = [...filtered]
                      ..sort((a, b) => b.publishedAt.compareTo(a.publishedAt));
                    trendingTop = trending.take(3).toList();
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ===== CATEGORY CHIPS =====
                      Padding(
                        padding: const EdgeInsets.only(
                          left: 20,
                          right: 0,
                          top: 12,
                          bottom: 4,
                        ),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              for (int i = 0; i < categories.length; i++) ...[
                                PalNewsCategoryChip(
                                  label: categories[i],
                                  isSelected: chipIndex == i,
                                  onTap: () {
                                    setState(() {
                                      selectedCategoryIndex = i;
                                      _currentTrendingIndex = 0;
                                    });
                                    if (_trendingController.hasClients) {
                                      _trendingController.jumpToPage(0);
                                    }
                                  },
                                ),
                                const SizedBox(width: 8),
                              ],
                            ],
                          ),
                        ),
                      ),

                      // ===== LISTVIEW: Trending section + semua berita =====
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 8,
                          ),
                          itemCount: filtered.length + (showTrending ? 1 : 0),
                          itemBuilder: (context, index) {
                            // index 0 = On Trending section bila showTrending
                            if (showTrending && index == 0) {
                              return _buildTrendingSection(trendingTop);
                            }

                            final realIndex = showTrending ? index - 1 : index;
                            final item = filtered[realIndex];

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16.0),
                              child: PalNewsNewsCard(
                                news: item,
                                showPager: false,
                                onTap: () => _openDetail(item),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ====== SECTION: ON TRENDING + CAROUSEL ======
  Widget _buildTrendingSection(List<PalNewsItem> trendingTop) {
    if (trendingTop.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 6.0),
          child: Text(
            'On Trending',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        SizedBox(
          height: 190,
          child: Stack(
            children: [
              PageView.builder(
                controller: _trendingController,
                itemCount: trendingTop.length,
                onPageChanged: (index) {
                  setState(() => _currentTrendingIndex = index);
                },
                itemBuilder: (context, index) {
                  final item = trendingTop[index];
                  return PalNewsNewsCard(
                    news: item,
                    showPager: false,
                    onTap: () => _openDetail(item),
                  );
                },
              ),
              // dots indikator (tap = pindah slide, nggak buka berita)
              Positioned(
                bottom: 10,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    trendingTop.length,
                    (i) {
                      final isActive = i == _currentTrendingIndex;
                      return GestureDetector(
                        onTap: () {
                          if (_trendingController.hasClients) {
                            _trendingController.animateToPage(
                              i,
                              duration: const Duration(milliseconds: 250),
                              curve: Curves.easeInOut,
                            );
                          }
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: isActive ? 16 : 8,
                          height: 4,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            color: Colors.white
                                .withOpacity(isActive ? 1.0 : 0.4),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 5,
          decoration: BoxDecoration(
            color: const Color(0xFF1B266A),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}
