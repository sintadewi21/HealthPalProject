// lib/palnews/palnews_repository.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import 'palnews_model.dart';

class PalNewsRepository {
  final SupabaseClient client;

  PalNewsRepository(this.client);

  Future<List<PalNewsItem>> fetchNews() async {
    final response = await client
        .from('palnews')
        .select()
        .order('published_at', ascending: false);

    final data = response as List<dynamic>;
    return data
        .map((row) => PalNewsItem.fromJson(row as Map<String, dynamic>))
        .toList();
  }
}
