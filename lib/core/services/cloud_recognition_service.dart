import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'dart:io';

class CloudRecognitionService {
  Future<Map<String, dynamic>?> identifyMusicInCloud(String filePath) async {
    // 1. Try Audio Fingerprinting first
    String serverUrl = "https://mobilserver006.onrender.com/identify";

    try {
      var uri = Uri.parse(serverUrl);
      var request = http.MultipartRequest('POST', uri);
      request.files.add(await http.MultipartFile.fromPath('file', filePath));

      debugPrint("DEBUG: Audio Scan: Uploading $filePath");
      final response = await request.send();

      if (response.statusCode == 200) {
        final responseData = await response.stream.bytesToString();
        try {
          final json = jsonDecode(responseData) as Map<String, dynamic>;
          if (json['success'] == true || json['status'] == 'success') {
            return json; // Found by audio!
          }
        } catch (_) {}
      }
    } catch (e) {
      debugPrint("DEBUG: Audio Scan Error: $e");
    }

    // 2. Fallback: Text Search using Filename
    debugPrint(
      "DEBUG: Audio Scan failed/no-match. Trying Filename Fallback...",
    );
    return await _searchByFilename(filePath);
  }

  Future<Map<String, dynamic>?> _searchByFilename(String filePath) async {
    try {
      // Extract and clean filename
      String filename = filePath.split(Platform.pathSeparator).last;

      // Remove extension
      filename = filename.replaceAll(RegExp(r'\.[a-zA-Z0-9]+$'), '');

      // Clean common garbage (track numbers, "official video", etc.)
      // 1. Remove starting numbers (e.g. "01. Song")
      filename = filename.replaceAll(RegExp(r'^\d+\s*[-\.]?\s*'), '');
      // 2. Remove common terms in brackets/parentheses
      filename = filename.replaceAll(RegExp(r'[\(\[\{].*?[\)\]\}]'), '');
      // 3. Remove "ft.", "feat." etc to simplify search
      filename = filename.replaceAll(
        RegExp(r'\s(ft\.|feat\.|featuring)\s.*', caseSensitive: false),
        '',
      );
      // 4. Replace underscores/hyphens with spaces
      filename = filename.replaceAll(RegExp(r'[_\-]'), ' ');
      // 5. Trim extra spaces
      filename = filename.trim().replaceAll(RegExp(r'\s+'), ' ');

      if (filename.length < 3) return null; // Too short to search

      debugPrint("DEBUG: Text Search: Looking up '$filename' on iTunes...");

      // Use iTunes Search API (Free, high quality metadata)
      final uri = Uri.parse(
        "https://itunes.apple.com/search?term=${Uri.encodeComponent(filename)}&media=music&limit=1",
      );
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['resultCount'] > 0) {
          final track = json['results'][0];

          // Map iTunes format to our internal format
          return {
            "success": true,
            "title": track['trackName'],
            "artist": track['artistName'],
            "album": track['collectionName'],
            "release_id": null, // iTunes doesn't give MBID
            "cover_url": track['artworkUrl100']?.replaceAll(
              '100x100',
              '600x600',
            ), // Upgrade quality
            "source": "text_fallback",
          };
        }
      }
    } catch (e) {
      debugPrint("DEBUG: Text Search Error: $e");
    }
    return null;
  }
}
