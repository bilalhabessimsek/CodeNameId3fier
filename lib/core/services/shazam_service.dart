import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

class ShazamService {
  final Dio _dio = Dio();
  final String _baseUrl = 'https://shazam.p.rapidapi.com';
  final String _apiKey = '5536353540msh3ce4198a9fe57dfp1afb84jsn1500fb0f91ba';
  final String _apiHost = 'shazam.p.rapidapi.com';

  Future<List<dynamic>> search(String query) async {
    try {
      final response = await _dio.get(
        '$_baseUrl/search',
        queryParameters: {
          'term': query,
          'locale': 'en-US',
          'offset': '0',
          'limit': '5',
        },
        options: Options(
          headers: {'x-rapidapi-key': _apiKey, 'x-rapidapi-host': _apiHost},
        ),
      );

      if (response.statusCode == 200) {
        // The structure usually has 'tracks' -> 'hits'
        final data = response.data;
        if (data != null &&
            data['tracks'] != null &&
            data['tracks']['hits'] != null) {
          return data['tracks']['hits'];
        }
      }
      return [];
    } catch (e) {
      debugPrint("Shazam Search Error: $e");
      return [];
    }
  }

  // Use 'auto-complete' if 'search' is deprecated or complex
  Future<List<dynamic>> autoComplete(String query) async {
    try {
      final response = await _dio.get(
        '$_baseUrl/auto-complete',
        queryParameters: {'term': query, 'locale': 'en-US'},
        options: Options(
          headers: {'x-rapidapi-key': _apiKey, 'x-rapidapi-host': _apiHost},
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data != null && data['hints'] != null) {
          return data['hints'];
        }
      }
      return [];
    } catch (e) {
      debugPrint("Shazam AutoComplete Error: $e");
      return [];
    }
  }
}
