// lib/palnews/palnews_model.dart

class PalNewsItem {
  final String id;          // news_id uuid
  final String title;
  final String content;
  final String source;
  final String category;
  final DateTime publishedAt;
  final String image;       // sementara pakai placeholder lokal

  PalNewsItem({
    required this.id,
    required this.title,
    required this.content,
    required this.source,
    required this.category,
    required this.publishedAt,
    required this.image,
  });

  factory PalNewsItem.fromJson(Map<String, dynamic> json) {
    return PalNewsItem(
      id: json['news_id'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      source: (json['source'] as String?) ?? '',
      category: (json['category'] as String?) ?? '',
      publishedAt: DateTime.parse(json['published_at'] as String),
      image: (json['image_url'] as String?) ?? '',
    );
  }

  String get subtitle {
    // hapus heading markdown & bullet sederhana
    var plain = content
        .replaceAll('\r', ' ')
        .replaceAll('\n', ' ')
        .replaceAll(RegExp(r'#{1,6}\s*'), '') // #### heading
        .replaceAll(RegExp(r'-\s*'), ''); // bullet "-"
    plain = plain.replaceAll(RegExp(r'\s+'), ' ').trim();

    if (plain.length <= 100) return plain;
    return plain.substring(0, 100) + '...';
  }
}
