import 'package:on_audio_query/on_audio_query.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';

class PermissionService {
  Future<bool> requestStoragePermission() async {
    if (kIsWeb) return false;

    if (Platform.isAndroid) {
      debugPrint(
        "DEBUG: PermissionService: Starting permission request sequence...",
      );

      // On Android 13+ (API 33+), we need READ_MEDIA_AUDIO
      final audioStatus = await Permission.audio.status;
      debugPrint(
        "DEBUG: PermissionService: Current audio status: $audioStatus",
      );

      if (audioStatus.isPermanentlyDenied) {
        debugPrint(
          "DEBUG: PermissionService: Audio permission permanently denied. Opening settings...",
        );
        // openAppSettings(); // Optional: You might want to show a dialog first
      }

      final requestedAudioStatus = await Permission.audio.request();
      debugPrint(
        "DEBUG: PermissionService: Requested audio status: $requestedAudioStatus",
      );

      // For older versions or general storage access (Write/Read)
      final storageStatus = await Permission.storage.request();
      debugPrint(
        "DEBUG: PermissionService: Requested general storage status: $storageStatus",
      );

      // Notification permission for background playback
      await Permission.notification.request();

      // Check if we have at least one of the required permissions (READ)
      bool hasReadPermission =
          requestedAudioStatus.isGranted || storageStatus.isGranted;

      // For Full File Management (Deletion/Editing) on Android 11+ (API 30+)
      // Note: This opens a system settings page.
      if (await Permission.manageExternalStorage.status.isDenied) {
        debugPrint(
          "DEBUG: PermissionService: Requesting MANAGE_EXTERNAL_STORAGE for file modification support...",
        );
        // We only request it if READ permission is already granted or being granted
        if (hasReadPermission) {
          await Permission.manageExternalStorage.request();
        }
      }

      if (hasReadPermission) {
        debugPrint(
          "DEBUG: PermissionService: Basic Media/Storage permission granted.",
        );
        return true;
      }

      // Last resort: internal on_audio_query request
      final OnAudioQuery audioQuery = OnAudioQuery();
      final onAudioStatus = await audioQuery.permissionsRequest();
      debugPrint(
        "DEBUG: PermissionService: OnAudioQuery backup result: $onAudioStatus",
      );
      return onAudioStatus;
    }

    return true; // Non-Android is handled differently or assumed ok
  }

  Future<bool> checkAndRequestFullStoragePermission(
    BuildContext context,
  ) async {
    if (kIsWeb || !Platform.isAndroid) return true;

    // Check if we are on Android 11 (API 30) or higher
    // For lower versions, WRITE_EXTERNAL_STORAGE is usually enough
    var status = await Permission.manageExternalStorage.status;
    debugPrint("DEBUG: Full storage status current: $status");

    if (status.isGranted) return true;

    // Show an explanation dialog before taking the user to settings
    if (context.mounted) {
      bool proceed =
          await showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              backgroundColor: const Color(0xFF1E1E1E),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
                side: const BorderSide(color: Colors.blueAccent, width: 1),
              ),
              title: const Row(
                children: [
                  Icon(Icons.security, color: Colors.blueAccent),
                  SizedBox(width: 10),
                  Text(
                    "Dosya Erişim İzni",
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
              content: const Text(
                "Şarkıları kütüphaneden kalıcı olarak sileyebilmemiz için Android sisteminde 'Tüm dosyalara erişim' iznini vermeniz gerekmektedir.\n\nBir sonraki ekranda bu uygulamayı bulup izni aktif hale getirin.",
                style: TextStyle(color: Colors.white70),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text(
                    "VAZGEÇ",
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                  ),
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text("AYARLARA GİT"),
                ),
              ],
            ),
          ) ??
          false;

      if (!proceed) return false;
    }

    debugPrint("DEBUG: Requesting MANAGE_EXTERNAL_STORAGE...");
    status = await Permission.manageExternalStorage.request();

    // Re-check
    if (!status.isGranted) {
      // Fallback: If request() didn't open the settings, force it
      debugPrint("DEBUG: Still not granted, forcing app settings...");
      await openAppSettings();
      status = await Permission.manageExternalStorage.status;
    }

    return status.isGranted;
  }
}
