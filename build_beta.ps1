$pubspec = "pubspec.yaml"
$content = Get-Content $pubspec -Raw

if ($content -match "version:\s*(\d+)\.(\d+)\.(\d+)\+(\d+)") {
    $major = [int]$matches[1]
    $minor = [int]$matches[2]
    $patch = [int]$matches[3]
    $build = [int]$matches[4] + 1

    $newVersion = "version: $major.$minor.$patch+$build"
    $content = $content -replace "version:\s*\d+\.\d+\.\d+\+\d+", $newVersion

    Set-Content $pubspec $content -Encoding UTF8

    Write-Host "Nueva versión: $major.$minor.$patch+$build"

    flutter clean
    flutter pub get
    dart run flutter_launcher_icons
    dart run flutter_native_splash:create
    flutter build apk --release

    $source = "build\app\outputs\flutter-apk\app-release.apk"
    $target = "build\app\outputs\flutter-apk\DriverAI-Beta-$major.$minor.$patch+$build.apk"

    Copy-Item $source $target -Force

    Write-Host "APK generado:"
    Write-Host $target
}
else {
    Write-Host "No se encontró version en pubspec.yaml"
}