$fontUrls = @{
    "Poppins-Thin.ttf" = "https://github.com/google/fonts/raw/main/ofl/poppins/Poppins-Thin.ttf"
    "Poppins-ExtraLight.ttf" = "https://github.com/google/fonts/raw/main/ofl/poppins/Poppins-ExtraLight.ttf"
    "Poppins-Light.ttf" = "https://github.com/google/fonts/raw/main/ofl/poppins/Poppins-Light.ttf"
    "Poppins-Regular.ttf" = "https://github.com/google/fonts/raw/main/ofl/poppins/Poppins-Regular.ttf"
    "Poppins-Medium.ttf" = "https://github.com/google/fonts/raw/main/ofl/poppins/Poppins-Medium.ttf"
    "Poppins-SemiBold.ttf" = "https://github.com/google/fonts/raw/main/ofl/poppins/Poppins-SemiBold.ttf"
    "Poppins-Bold.ttf" = "https://github.com/google/fonts/raw/main/ofl/poppins/Poppins-Bold.ttf"
    "Poppins-ExtraBold.ttf" = "https://github.com/google/fonts/raw/main/ofl/poppins/Poppins-ExtraBold.ttf"
    "Poppins-Black.ttf" = "https://github.com/google/fonts/raw/main/ofl/poppins/Poppins-Black.ttf"
}

# Create fonts directory if it doesn't exist
if (-not (Test-Path "assets\fonts")) {
    New-Item -ItemType Directory -Path "assets\fonts" -Force
}

foreach ($font in $fontUrls.GetEnumerator()) {
    $outputPath = "assets\fonts\$($font.Key)"
    Write-Host "Downloading $($font.Key)..."
    Invoke-WebRequest -Uri $font.Value -OutFile $outputPath
} 