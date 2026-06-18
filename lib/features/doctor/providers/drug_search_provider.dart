import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../../data/models/drug_model.dart';

// 1. Fetch all drugs once and cache them.
final allDrugsProvider = FutureProvider<List<DrugModel>>((ref) async {
  final url = Uri.parse('https://ready-api.vercel.app/api/drugs-eg?limit=30000');
  final response = await http.get(url);

  if (response.statusCode == 200) {
    final Map<String, dynamic> jsonResponse = json.decode(response.body);
    final List<dynamic> data = jsonResponse['data'] ?? [];
    return data.map((json) => DrugModel.fromJson(json)).toList();
  } else {
    throw Exception('Failed to load drugs from API');
  }
});

// 2. StateProvider to hold the current search query
final drugSearchQueryProvider = StateProvider<String>((ref) => '');

// 3. Provider that returns the filtered drugs based on the query.
// This executes synchronously based on the cached data and the current query.
final filteredDrugsProvider = Provider<List<DrugModel>>((ref) {
  final query = ref.watch(drugSearchQueryProvider).toLowerCase();
  final allDrugsAsync = ref.watch(allDrugsProvider);

  if (query.isEmpty) {
    return [];
  }

  return allDrugsAsync.maybeWhen(
    data: (drugs) {
      final filtered = drugs.where((drug) {
        return drug.commercialNameEn.toLowerCase().contains(query) ||
            drug.scientificName.toLowerCase().contains(query) ||
            drug.commercialNameAr.contains(query);
      }).toList();

      // Limit to top 15 results for UI performance
      return filtered.take(15).toList();
    },
    orElse: () => [],
  );
});
