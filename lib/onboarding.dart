import 'package:flutter/material.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  final List<_OnboardingData> pages = [
    _OnboardingData(
      image: 'assets/images/onboardingpage.png',
      title: '',
      subtitle: '',
      isPureImage: true, // halaman onboarding
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

  void _goToCarousel(int page) {
    _controller.animateToPage(
      page,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _goFromOnboardingToFirstCarousel() {
    _goToCarousel(1);
  }

  void _nextCarousel() {
    if (_currentPage < pages.length - 1) {
      _goToCarousel(_currentPage + 1);
    } else {
      _goToHome();
    }
  }

  void _skipToHome() {
    _goToHome();
  }

  void _goToHome() {
    Navigator.of(context).pushReplacementNamed('/signin');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: PageView.builder(
          controller: _controller,
          itemCount: pages.length,
          physics:
              const NeverScrollableScrollPhysics(), // disable swipe kiri-kanan
          onPageChanged: (index) {
            setState(() => _currentPage = index);
          },
          itemBuilder: (context, index) {
            final data = pages[index];

            // ========= PAGE 0: ONBOARDING (swipe bawah -> atas + tap) =========
            if (data.isPureImage) {
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                // tap di mana saja
                onTap: _goFromOnboardingToFirstCarousel,
                // swipe bawah -> atas
                onVerticalDragUpdate: (details) {
                  if (details.delta.dy < -8) {
                    // gerakan ke atas (nilai negatif)
                    _goFromOnboardingToFirstCarousel();
                  }
                },
                child: Image.asset(
                  data.image,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                ),
              );
            }

            // ========= PAGE 1–3: CAROUSEL =========
            return Column(
              children: [
                Expanded(
                  flex: 5,
                  child: Image.asset(
                    data.image,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                Expanded(
                  flex: 5,
                  child: Container(
                    width: double.infinity,
                    color: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 24,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
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
                        const SizedBox(height: 32),
                        SizedBox(
                          width: 260,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: _nextCarousel,
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
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            3, // 3 carousel
                            (dotIndex) {
                              final pageIndex = dotIndex + 1; // 1,2,3
                              final isActive = _currentPage == pageIndex;
                              return GestureDetector(
                                onTap: () => _goToCarousel(pageIndex),
                                child: AnimatedContainer(
                                  duration:
                                      const Duration(milliseconds: 200),
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 4),
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
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: _skipToHome,
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
            );
          },
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

