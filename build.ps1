param(
    [string]$SourcePath = "main.ahk",
    [string]$OutputName = "",
    [string]$CompilerPath = "",
    [string]$BaseFilePath = "",
    [string]$IconPath = "",
    [switch]$Clean
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$ProjectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$ResolvedSource = Join-Path $ProjectRoot $SourcePath
$DistDir = Join-Path $ProjectRoot "dist"
$ProjectName = Split-Path $ProjectRoot -Leaf

if ([string]::IsNullOrWhiteSpace($OutputName)) {
    $OutputName = $ProjectName
}

if (-not $OutputName.EndsWith(".exe", [System.StringComparison]::OrdinalIgnoreCase)) {
    $OutputName = "$OutputName.exe"
}

$ResolvedOutput = Join-Path $DistDir $OutputName

if (-not (Test-Path -LiteralPath $ResolvedSource)) {
    throw "No se encontro el script de entrada: $ResolvedSource"
}

if ($Clean -and (Test-Path -LiteralPath $ResolvedOutput)) {
    Remove-Item -LiteralPath $ResolvedOutput -Force
}

if (-not (Test-Path -LiteralPath $DistDir)) {
    New-Item -ItemType Directory -Path $DistDir | Out-Null
}

function Resolve-AhkCompiler {
    param([string]$PreferredPath)

    if (-not [string]::IsNullOrWhiteSpace($PreferredPath)) {
        if (Test-Path -LiteralPath $PreferredPath) {
            return (Resolve-Path -LiteralPath $PreferredPath).Path
        }

        throw "No se encontro Ahk2Exe en la ruta indicada: $PreferredPath"
    }

    $candidates = @(
        (Join-Path $env:ProgramFiles "AutoHotkey\Compiler\Ahk2Exe.exe"),
        (Join-Path ${env:ProgramFiles(x86)} "AutoHotkey\Compiler\Ahk2Exe.exe")
    ) | Where-Object { $_ -and $_.Trim() -ne "" }

    foreach ($candidate in $candidates) {
        if (Test-Path -LiteralPath $candidate) {
            return $candidate
        }
    }

    $fromPath = Get-Command "Ahk2Exe.exe" -ErrorAction SilentlyContinue
    if ($fromPath) {
        return $fromPath.Source
    }

    throw "No se encontro Ahk2Exe.exe. Instala AutoHotkey v2 con el compilador o pasa -CompilerPath."
}

function Resolve-AhkBaseFile {
    param(
        [string]$PreferredPath,
        [string]$ResolvedCompilerPath
    )

    if (-not [string]::IsNullOrWhiteSpace($PreferredPath)) {
        if (Test-Path -LiteralPath $PreferredPath) {
            return (Resolve-Path -LiteralPath $PreferredPath).Path
        }

        throw "No se encontro el Base file indicado: $PreferredPath"
    }

    $compilerDirectory = Split-Path -Parent $ResolvedCompilerPath
    $installRoot = Split-Path -Parent $compilerDirectory
    $candidates = @(
        (Join-Path $compilerDirectory "Unicode 64-bit.bin"),
        (Join-Path $compilerDirectory "Unicode 32-bit.bin"),
        (Join-Path $compilerDirectory "AutoHotkey64.exe"),
        (Join-Path $compilerDirectory "AutoHotkey32.exe"),
        (Join-Path $compilerDirectory "AutoHotkey.exe"),
        (Join-Path $installRoot "v2\AutoHotkey64.exe"),
        (Join-Path $installRoot "v2\AutoHotkey32.exe"),
        (Join-Path $installRoot "v2\AutoHotkey.exe"),
        (Join-Path $installRoot "AutoHotkey64.exe"),
        (Join-Path $installRoot "AutoHotkey32.exe"),
        (Join-Path $installRoot "AutoHotkey.exe")
    ) | Where-Object { $_ -and $_.Trim() -ne "" }

    foreach ($candidate in $candidates) {
        if (Test-Path -LiteralPath $candidate) {
            return (Resolve-Path -LiteralPath $candidate).Path
        }
    }

    throw "No se pudo resolver un Base file para Ahk2Exe. Usa -BaseFilePath o configura el Base file por defecto en Ahk2Exe."
}

function Convert-PngToIco {
    param(
        [string]$PngPath,
        [string]$IcoPath
    )

    Add-Type -AssemblyName System.Drawing
    if (-not ("NativeIcon" -as [type])) {
        Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;

public static class NativeIcon {
    [DllImport("user32.dll", CharSet = CharSet.Auto)]
    public static extern bool DestroyIcon(IntPtr handle);
}
"@
    }

    $sourceBitmap = $null
    $iconBitmap = $null
    $graphics = $null
    $icon = $null
    $stream = $null
    $iconHandle = [System.IntPtr]::Zero

    try {
        $sourceBitmap = New-Object System.Drawing.Bitmap($PngPath)
        $iconSize = [Math]::Min([Math]::Max($sourceBitmap.Width, $sourceBitmap.Height), 256)
        $iconBitmap = New-Object System.Drawing.Bitmap($iconSize, $iconSize)
        $graphics = [System.Drawing.Graphics]::FromImage($iconBitmap)
        $graphics.Clear([System.Drawing.Color]::Transparent)
        $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
        $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
        $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality

        $scale = [Math]::Min($iconSize / $sourceBitmap.Width, $iconSize / $sourceBitmap.Height)
        $drawWidth = [int][Math]::Round($sourceBitmap.Width * $scale)
        $drawHeight = [int][Math]::Round($sourceBitmap.Height * $scale)
        $offsetX = [int][Math]::Floor(($iconSize - $drawWidth) / 2)
        $offsetY = [int][Math]::Floor(($iconSize - $drawHeight) / 2)

        $graphics.DrawImage($sourceBitmap, $offsetX, $offsetY, $drawWidth, $drawHeight)

        $iconHandle = $iconBitmap.GetHicon()
        $icon = [System.Drawing.Icon]::FromHandle($iconHandle)
        $stream = [System.IO.File]::Open($IcoPath, [System.IO.FileMode]::Create)
        $icon.Save($stream)
    }
    finally {
        if ($stream) {
            $stream.Dispose()
        }

        if ($icon) {
            $icon.Dispose()
        }

        if ($iconHandle -ne [System.IntPtr]::Zero) {
            [NativeIcon]::DestroyIcon($iconHandle) | Out-Null
        }

        if ($graphics) {
            $graphics.Dispose()
        }

        if ($iconBitmap) {
            $iconBitmap.Dispose()
        }

        if ($sourceBitmap) {
            $sourceBitmap.Dispose()
        }
    }
}

function Resolve-BuildIcon {
    param(
        [string]$PreferredPath,
        [string]$RootPath,
        [string]$OutputDir
    )

    $candidatePath = $PreferredPath
    if ([string]::IsNullOrWhiteSpace($candidatePath)) {
        $defaultIco = Join-Path $RootPath "assets\logo_icon.ico"
        $defaultPng = Join-Path $RootPath "assets\logo_icon.png"

        if (Test-Path -LiteralPath $defaultIco) {
            $candidatePath = $defaultIco
        }
        elseif (Test-Path -LiteralPath $defaultPng) {
            $candidatePath = $defaultPng
        }
    }

    if ([string]::IsNullOrWhiteSpace($candidatePath)) {
        return $null
    }

    $resolvedCandidate = $candidatePath
    if (-not [System.IO.Path]::IsPathRooted($resolvedCandidate)) {
        $resolvedCandidate = Join-Path $RootPath $resolvedCandidate
    }

    if (-not (Test-Path -LiteralPath $resolvedCandidate)) {
        throw "No se encontro el icono indicado: $resolvedCandidate"
    }

    $extension = [System.IO.Path]::GetExtension($resolvedCandidate)
    if ($extension -ieq ".ico") {
        return (Resolve-Path -LiteralPath $resolvedCandidate).Path
    }

    if ($extension -ieq ".png") {
        $generatedIcon = Join-Path $OutputDir "_build_icon.ico"
        Convert-PngToIco -PngPath $resolvedCandidate -IcoPath $generatedIcon
        return $generatedIcon
    }

    throw "El icono debe estar en formato .ico o .png: $resolvedCandidate"
}

$ResolvedCompiler = Resolve-AhkCompiler -PreferredPath $CompilerPath
$ResolvedBaseFile = Resolve-AhkBaseFile -PreferredPath $BaseFilePath -ResolvedCompilerPath $ResolvedCompiler
$ResolvedIcon = Resolve-BuildIcon -PreferredPath $IconPath -RootPath $ProjectRoot -OutputDir $DistDir

Write-Host "Compilando $ResolvedSource"
Write-Host "Compilador: $ResolvedCompiler"
Write-Host "Base file: $ResolvedBaseFile"
Write-Host "Salida: $ResolvedOutput"
if ($ResolvedIcon) {
    Write-Host "Icono: $ResolvedIcon"
}

$compilerArgs = @("/in", $ResolvedSource, "/out", $ResolvedOutput, "/base", $ResolvedBaseFile)
if ($ResolvedIcon) {
    $compilerArgs += @("/icon", $ResolvedIcon)
}

$process = Start-Process -FilePath $ResolvedCompiler -ArgumentList $compilerArgs -Wait -PassThru
if ($process.ExitCode -ne 0) {
    throw "Ahk2Exe devolvio un codigo de salida $($process.ExitCode)."
}

if (-not (Test-Path -LiteralPath $ResolvedOutput)) {
    throw "Ahk2Exe no genero el ejecutable esperado: $ResolvedOutput"
}

Write-Host "Compilacion completada."
