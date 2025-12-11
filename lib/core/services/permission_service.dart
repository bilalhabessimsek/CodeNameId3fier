import 'package:on_audio_query/on_audio_query.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

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

  Future<bool> checkAndRequestFullStoragePermission() async {
    if (kIsWeb || !Platform.isAndroid) return true;

    var status = await Permission.manageExternalStorage.status;
    debugPrint(
      "DEBUG: PermissionService: Full storage status current: $status",
    );

    if (status.isGranted) return true;

    debugPrint(
      "DEBUG: PermissionService: Requesting MANAGE_EXTERNAL_STORAGE...",
    );
    status = await Permission.manageExternalStorage.request();

    // If still not granted, it might need manual toggle in some Android versions
    if (!status.isGranted) {
      debugPrint(
        "DEBUG: PermissionService: Not granted via request, checking if we should open settings...",
      );
      await openAppSettings();
      // Re-check after returning from settings
      status = await Permission.manageExternalStorage.status;
    }

    return status.isGranted;
  }
}
