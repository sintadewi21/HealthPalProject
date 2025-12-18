// lib/palnews/palnews_detail_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'palnews_model.dart';

class PalNewsDetailPage extends StatelessWidget {
  final PalNewsItem news;

  const PalNewsDetailPage({super.key, required this.news});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      // =============== BODY DETAIL PALNEWS ===============
      body: SafeArea(
        child: Column(
          children: [
            // ===== HEADER DETAIL =====
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, size: 22),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  Expanded(
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset(
                            'assets/images/iconpalnews.png',
                            width: 24,
                            height: 24,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) {
                              // fallback kalau asset belum ada
                              return Icon(
                                Icons.description_outlined,
                                size: 20,
                                color: theme.primaryColor,
                              );
                            },
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'PalNews',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Colors.black.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 48), // penyeimbang space kanan
                ],
              ),
            ),

            // ===== HEADER IMAGE + TITLE =====
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20.0, vertical: 4),
              child: Container(
                height: 170,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: Colors.black,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: news.image.isNotEmpty
                            ? Image.network(
                                news.image,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) {
                                  return Container(
                                    color: Colors.grey[300],
                                    child: const Icon(
                                      Icons.broken_image,
                                      color: Colors.black45,
                                      size: 50,
                                    ),
                                  );
                                },
                              )
                            : Container(
                                color: Colors.grey[300],
                                child: const Icon(
                                  Icons.image,
                                  color: Colors.black45,
                                  size: 50,
                                ),
                              ),
                      ),
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withOpacity(0.25),
                                Colors.black.withOpacity(0.85),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Align(
                          alignment: Alignment.bottomLeft,
                          child: Text(
                            news.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              height: 1.2,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 8),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              height: 3,
              decoration: BoxDecoration(
                color: theme.primaryColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 8),

            // ===== KONTEN MARKDOWN =====
            Expanded(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Markdown(
                  data: news.content,
                  styleSheet: MarkdownStyleSheet(
                    p: const TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: Color(0xFF2C2C2E),
                    ),
                    h2: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1C2A3A),
                    ),
                    listBullet: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF2C2C2E),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
