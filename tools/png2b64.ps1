<#
.SYNOPSIS
  Convert image files (PNG/JPG/GIF) to the base64 ".b64" sidecars the AE3 desktop/browser reads.

.DESCRIPTION
  The AE3 web desktop (CEF) cannot reliably sample every image through the engine texture loader, so
  raster images are served as a base64-encoded sidecar file next to the image: "<image>.b64".
  js/bridge.js (AE3.loadImage) reads that file via RequestFile and wraps it as a data: URL for an
  <img>/CSS background. This script produces those sidecars.

  Output is RAW base64 text (no "data:" prefix, no line wrapping) - exactly what the bridge expects.

.PARAMETER Path
  One or more image files or folders. Folders are scanned (non-recursively) for *.png/*.jpg/*.jpeg/*.gif.

.PARAMETER Recurse
  Recurse into sub-folders when a folder is given.

.EXAMPLE
  # One file -> creates logo.png.b64 next to it
  ./png2b64.ps1 addons/desktop/images/wallpaper_1.png

.EXAMPLE
  # A whole mission images folder
  ./png2b64.ps1 -Recurse "C:\...\MyMission.Altis\media\images"
#>
param(
    [Parameter(Mandatory = $true, Position = 0)][string[]]$Path,
    [switch]$Recurse
)

$exts = @(".png", ".jpg", ".jpeg", ".gif")

function Convert-One([string]$file) {
    $bytes = [IO.File]::ReadAllBytes($file)
    $b64 = [Convert]::ToBase64String($bytes)
    $out = "$file.b64"
    [IO.File]::WriteAllText($out, $b64)
    Write-Host "Wrote $out ($($b64.Length) chars)"
}

foreach ($p in $Path) {
    if (Test-Path -LiteralPath $p -PathType Container) {
        Get-ChildItem -LiteralPath $p -File -Recurse:$Recurse |
            Where-Object { $exts -contains $_.Extension.ToLower() } |
            ForEach-Object { Convert-One $_.FullName }
    }
    elseif (Test-Path -LiteralPath $p -PathType Leaf) {
        Convert-One (Resolve-Path -LiteralPath $p).Path
    }
    else {
        Write-Warning "Not found: $p"
    }
}
