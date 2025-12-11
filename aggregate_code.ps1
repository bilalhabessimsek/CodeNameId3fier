param (
    [string]$outFile = "c:\Users\bilal\OneDrive\Desktop\modern_music_player\fullcode1.0.txt"
)
$root = "c:\Users\bilal\OneDrive\Desktop\modern_music_player"

# Initialize file
Set-Content -Path $outFile -Value "CODEBASE DUMP - $(Get-Date)" -Encoding UTF8

function Append-File($relativePath) {
    $fullPath = Join-Path $root $relativePath
    Add-Content -Path $outFile -Value "`n================================================================================"
    Add-Content -Path $outFile -Value "FILE: $relativePath"
    Add-Content -Path $outFile -Value "================================================================================`n"
    
    if (Test-Path $fullPath) {
        try {
            # Use -Raw to read entire file at once, preserving newlines
            $content = Get-Content -Path $fullPath -Raw -ErrorAction Stop
            Add-Content -Path $outFile -Value $content
        }
        catch {
            Add-Content -Path $outFile -Value "ERROR READING FILE: $_"
        }
    }
    else {
        Add-Content -Path $outFile -Value "ERROR: File not found."
    }
}

Write-Host "Processing configuration files..."
Append-File "pubspec.yaml"
Append-File "android\app\src\main\AndroidManifest.xml"
Append-File "lib\main.dart"

Write-Host "Processing core services..."
Append-File "lib\core\services\audio_provider.dart"
Append-File "lib\core\services\permission_service.dart"
Append-File "lib\core\services\tag_editor_service.dart"
Append-File "lib\core\services\lyrics_service.dart"
Append-File "lib\core\services\midi_player_service.dart"
Append-File "lib\core\services\shazam_service.dart"
Append-File "lib\core\services\cloud_recognition_service.dart"

Write-Host "Processing core widgets/utils..."
Append-File "lib\core\mixins\auto_scroll_mixin.dart"
Append-File "lib\core\widgets\song_list_tile.dart"
Append-File "lib\core\widgets\maintenance_selection_dialog.dart"

Write-Host "Processing home features..."
Append-File "lib\features\home\home_screen.dart"
Append-File "lib\features\home\search_screen.dart"
Append-File "lib\features\home\lost_songs_screen.dart"
Append-File "lib\features\home\cloud_identify_screen.dart"
Append-File "lib\features\home\online_metadata_screen.dart"
Append-File "lib\features\home\edit_tags_dialog.dart"
Append-File "lib\features\home\tabs\album_tab.dart"
Append-File "lib\features\home\tabs\artist_tab.dart"
Append-File "lib\features\home\tabs\favorites_tab.dart"
Append-File "lib\features\home\tabs\folder_tab.dart"
Append-File "lib\features\home\tabs\genre_tab.dart"
Append-File "lib\features\playlist\playlist_tab.dart"

Write-Host "Processing player features..."
Append-File "lib\features\player\player_screen.dart"
Append-File "lib\features\player\mini_player.dart"

Write-Host "Processing settings/eq..."
Append-File "lib\features\settings\settings_screen.dart"
Append-File "lib\features\equalizer\equalizer_screen.dart"

# ZIP Logic
$centralZip = "c:\Users\bilal\OneDrive\Desktop\fullcode.zip"
Write-Host "Adding $outFile to $centralZip..."

if (Test-Path $centralZip) {
    Compress-Archive -Update -Path $outFile -DestinationPath $centralZip
}
else {
    Compress-Archive -Path $outFile -DestinationPath $centralZip
}

Remove-Item $outFile
Write-Host "Done. Snapshot added to archive."
