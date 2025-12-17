import 'package:flutter/material.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _currentPage = 0;
  bool _isAnimating = false;

  final List<_OnboardingData> pages = [
    _OnboardingData(
      image: 'assets/images/onboardingpage.png',
      title: '',
      subtitle: '',
      isPureImage: true,
    ),
    _OnboardingData(
      image: 'assets/images/carousel1.png',
      title: 'Meet Doctors Online',
      subtitle:
          'Connect with Specialized Doctors Online for Convenient and Comprehensive Medical Consultations.',
    ),
    _OnboardingData(
      image: 'assets/images/carousel2.png',
      title: 'Connect with Specialists',
      subtitle:
          'Connect with Specialized Doctors Online for Convenient and Comprehensive Medical Consultations.',
    ),
    _OnboardingData(
      image: 'assets/images/carousel3.png',
      title: 'Thousands of Online Specialists',
      subtitle:
          'Explore a Vast Array of Online Medical Specialists, Offering an Extensive Range of Expertise Tailored to Your Healthcare Needs.',
    ),
  ];

  Future<void> _goToPage(int page) async {
    if (_isAnimating) return;
    _isAnimating = true;

    await _controller.animateToPage(
      page,
      duration: const Duration(milliseconds: 520),
      curve: Curves.easeOutCubic,
    );

    _isAnimating = false;
  }

  void _next() {
    if (_currentPage < pages.length - 1) {
      _goToPage(_currentPage + 1);
    } else {
      _goToHome();
    }
  }

  void _skip() => _goToHome();

  void _goToHome() {
    Navigator.of(context).pushReplacementNamed('/signin');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final showControls = _currentPage != 0;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            // ================= PAGE CONTENT (yang geser) =================
            PageView.builder(
              controller: _controller,
              itemCount: pages.length,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (i) => setState(() => _currentPage = i),
              itemBuilder: (context, index) {
                final data = pages[index];

                // Page 0: gambar full + shadow overlay
                if (data.isPureImage) {
                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _goToPage(1),
                    onVerticalDragEnd: (details) {
                      final v = details.primaryVelocity ?? 0;
                      if (v < -400) _goToPage(1);
                    },
                    child: Stack(
                      children: [
                        // IMAGE
                        Positioned.fill(
                          child: Image.asset(
                            data.image,
                            fit: BoxFit.cover,
                          ),
                        ),

                        // BOTTOM SHADOW ONLY
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [
                                  Colors.black.withOpacity(0.6), // shadow bawah
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // Page 1-3
                return Column(
                  children: [
                    Expanded(
                      flex: 6,
                      child: Image.asset(
                        data.image,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Expanded(
                      flex: 4,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 24, 24, 140),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Text(
                              data.title,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              data.subtitle,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),

            // ================= CONTROLS (tetap) =================
            if (showControls)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        blurRadius: 16,
                        offset: Offset(0, -6),
                        color: Color(0x14000000),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 260,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _next,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1C2A3A),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Next', 
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(3, (dotIndex) {
                          final pageIndex = dotIndex + 1;
                          final isActive = _currentPage == pageIndex;

                          return GestureDetector(
                            onTap: () => _goToPage(pageIndex),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              curve: Curves.easeOut,
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              width: isActive ? 16 : 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: isActive
                                    ? const Color(0xFF1C2A3A)
                                    : const Color(0xFFD1D5DB),
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 8),

                      TextButton(
                        onPressed: _skip,
                        child: const Text(
                          'Skip',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingData {
  final String image;
  final String title;
  final String subtitle;
  final bool isPureImage;

  _OnboardingData({
    required this.image,
    required this.title,
    required this.subtitle,
    this.isPureImage = false,
  });
}