import 'package:audiotags/audiotags.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:media_scanner/media_scanner.dart';

class TagEditorService {
  final Dio _dio = Dio();

  Future<String?> updateTags({
    required String filePath,
    required String title,
    required String artist,
    String? album,
    String? genre,
    String? coverUrl,
  }) async {
    try {
      debugPrint("DEBUG: TagEditorService: Writing tags to $filePath");
      debugPrint(
        "DEBUG: TagEditorService: New Title: $title, Artist: $artist, Album: $album",
      );

      // 1. Dosya kapağını (cover) indir/hazırla
      List<int>? coverBytes;
      if (coverUrl != null && coverUrl.isNotEmpty) {
        try {
          final response = await _dio.get<List<int>>(
            coverUrl,
            options: Options(responseType: ResponseType.bytes),
          );
          if (response.statusCode == 200) {
            coverBytes = response.data;
          }
        } catch (e) {
          debugPrint("DEBUG: TagEditorService: Cover download failed: $e");
        }
      }

      // 2. Etiket nesnesini oluştur
      final tag = Tag(
        title: title,
        trackArtist: artist,
        album: album,
        genre: genre,
        pictures: coverBytes != null
            ? [
                Picture(
                  bytes: Uint8List.fromList(coverBytes),
                  mimeType: MimeType.png, // Set a default or detect
                  pictureType: PictureType.other,
                ),
              ]
            : [],
      );

      // 3. Dosyaya yaz
      await AudioTags.write(filePath, tag);
      debugPrint("DEBUG: TagEditorService: Successfully wrote tags.");

      // 4. Trigger Media Scan so the system/on_audio_query sees the change
      try {
        await MediaScanner.loadMedia(path: filePath);
        debugPrint(
          "DEBUG: TagEditorService: Media scan triggered for $filePath",
        );
      } catch (e) {
        debugPrint("DEBUG: TagEditorService: Media scan failed: $e");
      }

      return null; // Null means success
    } catch (e) {
      debugPrint("DEBUG: TagEditorService ERROR writing tags: $e");
      return e.toString();
    }
  }
}
