// lib/palnews/palnews_page.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'palnews_model.dart';
import 'palnews_repository.dart';
import 'palnews_detail_page.dart';
import 'widgets/palnews_news_card.dart';
import 'widgets/palnews_category_chip.dart';

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

  @override
  void initState() {
    super.initState();
    repo = PalNewsRepository(Supabase.instance.client);
    futureNews = repo.fetchNews();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.black.withOpacity(0.08),
                      ),
                      color: Colors.white,
                    ),
                    child: Icon(
                      Icons.article_outlined,
                      size: 20,
                      color: theme.primaryColor,
                    ),
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
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.notifications_none),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
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
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 0,
                    horizontal: 16,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
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

                  final categorySet = <String>{};
                  for (final n in allNews) {
                    if (n.category.isNotEmpty) {
                      categorySet.add(n.category);
                    }
                  }

                  final categories = <String>['All', ...categorySet.toList()];
                  final chipIndex =
                      selectedCategoryIndex.clamp(0, categories.length - 1)
                          as int;

                  List<PalNewsItem> filtered = allNews;

                  if (chipIndex > 0 && chipIndex < categories.length) {
                    final selectedCategory = categories[chipIndex];
                    filtered = filtered
                        .where((n) => n.category == selectedCategory)
                        .toList();
                  }

                  if (searchQuery.isNotEmpty) {
                    filtered = filtered
                        .where((n) => n.title
                            .toLowerCase()
                            .contains(searchQuery.toLowerCase()))
                        .toList();
                  }

                  return Column(
                    children: [
                      Container(
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.only(
                          left: 20,
                          right: 20,
                          top: 12,
                          bottom: 4,
                        ),
                        child: Row(
                          children: [
                            for (int i = 0; i < categories.length; i++) ...[
                              PalNewsCategoryChip(
                                label: categories[i],
                                isSelected: chipIndex == i,
                                onTap: () {
                                  setState(() {
                                    selectedCategoryIndex = i;
                                  });
                                },
                              ),
                              const SizedBox(width: 8),
                            ],
                          ],
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 20.0,
                          vertical: 6.0,
                        ),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'On Trending',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 8,
                          ),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final item = filtered[index];
                            return Padding(
                              padding:
                                  const EdgeInsets.only(bottom: 16.0),
                              child: PalNewsNewsCard(
                                news: item,
                                showPager: index == 0,
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          PalNewsDetailPage(news: item),
                                    ),
                                  );
                                },
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
}
