param(
    [switch]$Clean
)

$ErrorActionPreference = 'Stop'

$projectRoot = Split-Path -Parent $PSScriptRoot
Set-Location $projectRoot

Write-Host 'Building Home Bakery Assistant for Windows release...' -ForegroundColor Cyan

if ($Clean) {
    Write-Host 'Running flutter clean...' -ForegroundColor Yellow
    flutter clean
}

Write-Host 'Fetching dependencies...' -ForegroundColor Yellow
flutter pub get

Write-Host 'Creating Windows release build...' -ForegroundColor Yellow
flutter build windows --release

$outputPath = Join-Path $projectRoot 'build\windows\x64\runner\Release'

Write-Host ''
Write-Host 'Build complete.' -ForegroundColor Green
Write-Host "Release output: $outputPath"
Write-Host ''
Write-Host 'Notes:' -ForegroundColor Cyan
Write-Host '- The app database is created at runtime in the user AppData/Application Support location.'
Write-Host '- Local demo/reset script data is not bundled into the shipped Windows build.'
Write-Host '- A fresh user install will start with an empty database unless you explicitly seed it.'