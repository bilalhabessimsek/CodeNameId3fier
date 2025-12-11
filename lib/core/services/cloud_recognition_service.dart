import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

class CloudRecognitionService {
  Future<Map<String, dynamic>?> identifyMusicInCloud(String filePath) async {
    // Render adresini güncelliyoruz
    String serverUrl = "https://mobilserver006.onrender.com/identify";

    try {
      var uri = Uri.parse(serverUrl);
      var request = http.MultipartRequest('POST', uri);

      // Dosyayı isteğe ekle
      request.files.add(await http.MultipartFile.fromPath('file', filePath));

      debugPrint("DEBUG: Sunucuya dosya gönderiliyor: $filePath");
      var response = await request.send();

      if (response.statusCode == 200) {
        var responseData = await response.stream.bytesToString();
        debugPrint("DEBUG: Sunucu yanıtı: $responseData");
        try {
          return jsonDecode(responseData) as Map<String, dynamic>;
        } catch (e) {
          return {"status": "success", "raw": responseData};
        }
      } else {
        var responseData = await response.stream.bytesToString();
        debugPrint(
          "HATA: Sunucu hata kodu: ${response.statusCode} - Yanıt: $responseData",
        );
        try {
          return jsonDecode(responseData) as Map<String, dynamic>;
        } catch (e) {
          return {
            "status": "error",
            "code": response.statusCode,
            "message": responseData,
          };
        }
      }
    } catch (e) {
      debugPrint("HATA: Müzik tanımlama sırasında bir sorun oluştu: $e");
      return {"status": "error", "message": e.toString()};
    }
  }
}
