$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot

Push-Location -LiteralPath $projectRoot
try {
    & flutter build apk --release --no-pub --build-name=1.0.2-preview --dart-define=SENIORS_PREVIEW=true
    if ($LASTEXITCODE -ne 0) { throw 'Preview build failed.' }

    $apk = Join-Path $projectRoot 'build\app\outputs\flutter-apk\app-release.apk'
    $localProperties = Join-Path $projectRoot 'android\local.properties'
    $sdkLine = Get-Content -LiteralPath $localProperties | Where-Object { $_ -match '^sdk\.dir=' } | Select-Object -First 1
    if (-not $sdkLine) { throw 'Android SDK location was not found.' }
    $sdk = ($sdkLine -replace '^sdk\.dir=', '').Replace('\\', '\').Replace('\:', ':')
    $buildTools = Get-ChildItem -LiteralPath (Join-Path $sdk 'build-tools') -Directory |
        Where-Object { $_.Name -match '^\d+\.\d+\.\d+$' } |
        Sort-Object { [version]$_.Name } -Descending |
        Select-Object -First 1
    if (-not $buildTools) { throw 'Android build tools were not found.' }
    $badging = & (Join-Path $buildTools.FullName 'aapt.exe') dump badging $apk
    if ($LASTEXITCODE -ne 0 -or -not ($badging -match "^package: name='com\.seniors2027\.app\.preview' ")) {
        throw 'Build is not the isolated preview package. Do not install it over the main app.'
    }

    $outputDirectory = Join-Path $projectRoot 'build\preview'
    New-Item -ItemType Directory -Path $outputDirectory -Force | Out-Null
    $output = Join-Path $outputDirectory 'seniors2027-memoryboard-preview.apk'
    Copy-Item -LiteralPath $apk -Destination $output -Force
    Write-Output "Preview APK: $output"
    Write-Output 'Package: com.seniors2027.app.preview'
    Write-Output 'Installs alongside Seniors 2027; sign in separately in the preview app.'
} finally {
    Pop-Location
}
