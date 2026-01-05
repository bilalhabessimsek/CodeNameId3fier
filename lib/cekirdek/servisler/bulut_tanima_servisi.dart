import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'dart:io';

class CloudRecognitionService {
  Future<Map<String, dynamic>?> identifyMusicInCloud(String filePath) async {
    // 1. Try Audio Fingerprinting first
    String serverUrl = "https://mobilserver006.onrender.com/identify";

    try {
      debugPrint("DEBUG: Audio Scan START for $filePath");
      var uri = Uri.parse(serverUrl);
      var request = http.MultipartRequest('POST', uri);
      request.files.add(await http.MultipartFile.fromPath('file', filePath));

      debugPrint("DEBUG: Audio Scan: Uploading to $serverUrl...");
      final response = await request.send();
      debugPrint(
        "DEBUG: Audio Scan: Response Status Code: ${response.statusCode}",
      );

      if (response.statusCode == 200) {
        final responseData = await response.stream.bytesToString();
        debugPrint("DEBUG: Audio Scan: Response Body: $responseData");
        try {
          var json = jsonDecode(responseData) as Map<String, dynamic>;
          if (json['success'] == true || json['status'] == 'success') {
            debugPrint("DEBUG: Audio Scan: SUCCESS");

            // ENRICHMENT: If cover is missing, try to find it via iTunes
            if (json['cover_url'] == null && json['release_id'] == null) {
              final title = json['title'];
              final artist = json['artist'];
              if (title != null && artist != null) {
                debugPrint(
                  "DEBUG: Audio Scan found info but NO COVER. Searching iTunes for '$title $artist'...",
                );
                final coverResult = await _performiTunesSearch(
                  "$title $artist",
                );
                if (coverResult != null && coverResult['cover_url'] != null) {
                  json['cover_url'] = coverResult['cover_url'];
                  // Also grab album if missing
                  if (json['album'] == null ||
                      json['album'].toString().isEmpty) {
                    json['album'] = coverResult['album'];
                  }
                  debugPrint(
                    "DEBUG: Audio Scan: Enriched with cover from iTunes.",
                  );
                }
              }
            }

            return json; // Found by audio (maybe enriched)!
          } else {
            debugPrint(
              "DEBUG: Audio Scan: FAILED (Server returned success=false)",
            );
          }
        } catch (e) {
          debugPrint("DEBUG: Audio Scan: JSON Parse Error: $e");
        }
      } else {
        debugPrint("DEBUG: Audio Scan: HTTP Error ${response.statusCode}");
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
      String originalFilename = filename;

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

      debugPrint(
        "DEBUG: Text Search: Original '$originalFilename' -> Cleaned '$filename'",
      );

      if (filename.length < 3) {
        debugPrint("DEBUG: Text Search: Name too short, skipping.");
        return null;
      }

      return await _performiTunesSearch(filename);
    } catch (e) {
      debugPrint("DEBUG: Text Search Error: $e");
    }
    return null;
  }

  Future<Map<String, dynamic>?> _performiTunesSearch(String query) async {
    try {
      debugPrint("DEBUG: iTunes Search: Looking up '$query' (Country: TR)...");

      // Use iTunes Search API (Free, high quality metadata)
      // Added country=TR for better Turkish song support
      final uri = Uri.parse(
        "https://itunes.apple.com/search?term=${Uri.encodeComponent(query)}&media=music&limit=1&country=TR",
      );
      debugPrint("DEBUG: iTunes Search: Request URL: $uri");

      final response = await http.get(uri);
      debugPrint("DEBUG: iTunes Search: Response Code: ${response.statusCode}");

      if (response.statusCode == 200) {
        // debugPrint("DEBUG: iTunes Search: Response Body: ${response.body}");
        final json = jsonDecode(response.body);
        if (json['resultCount'] > 0) {
          final track = json['results'][0];
          debugPrint(
            "DEBUG: iTunes Search: FOUND: ${track['trackName']} - ${track['artistName']}",
          );

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
        } else {
          debugPrint("DEBUG: iTunes Search: NO RESULTS found.");
        }
      }
    } catch (e) {
      debugPrint("DEBUG: iTunes Search HTTP Error: $e");
    }
    return null;
  }
}
