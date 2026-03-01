param(
    [string]$SourcePath = "main.ahk",
    [string]$OutputName = "",
    [string]$CompilerPath = "",
    [string]$BaseFilePath = "",
    [string]$IconPath = "",
    [switch]$Clean,
    [switch]$SkipStartupPrompt,
    [switch]$StartWithWindows
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$ProjectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$ResolvedSource = Join-Path $ProjectRoot $SourcePath
$DistDir = Join-Path $ProjectRoot "dist"

if (-not (Test-Path -LiteralPath $ResolvedSource)) {
    throw "No se encontro el script de entrada: $ResolvedSource"
}

$SourceName = [System.IO.Path]::GetFileNameWithoutExtension($ResolvedSource)

if ([string]::IsNullOrWhiteSpace($OutputName)) {
    $OutputName = $SourceName
}

if (-not $OutputName.EndsWith(".exe", [System.StringComparison]::OrdinalIgnoreCase)) {
    $OutputName = "$OutputName.exe"
}

$ResolvedOutput = Join-Path $DistDir $OutputName

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

function Wait-ForFile {
    param(
        [string]$Path,
        [int]$TimeoutMs = 2000
    )

    $elapsedMs = 0
    while ($elapsedMs -le $TimeoutMs) {
        if (Test-Path -LiteralPath $Path) {
            return $true
        }

        Start-Sleep -Milliseconds 200
        $elapsedMs += 200
    }

    return $false
}

function Test-CanPromptForInput {
    if (-not [System.Environment]::UserInteractive) {
        return $false
    }

    try {
        return (-not [System.Console]::IsInputRedirected)
    }
    catch {
        return $true
    }
}

function Confirm-StartWithWindows {
    param([string]$ExecutablePath)

    if (-not (Test-CanPromptForInput)) {
        Write-Host "No se pudo pedir confirmacion interactiva. Usa -StartWithWindows para habilitar el inicio automatico."
        return $null
    }

    $appName = [System.IO.Path]::GetFileName($ExecutablePath)

    while ($true) {
        $answer = Read-Host "Quieres que $appName arranque con Windows? [S/N]"
        if ([string]::IsNullOrWhiteSpace($answer)) {
            continue
        }

        switch -Regex ($answer.Trim().ToLowerInvariant()) {
            "^(s|si|y|yes)$" {
                return $true
            }
            "^(n|no)$" {
                return $false
            }
        }

        Write-Host "Respuesta no valida. Escribe S o N."
    }
}

function Enable-StartupLaunch {
    param([string]$ExecutablePath)

    $startupDir = [System.Environment]::GetFolderPath([System.Environment+SpecialFolder]::Startup)
    if ([string]::IsNullOrWhiteSpace($startupDir)) {
        throw "No se pudo resolver la carpeta Startup de Windows."
    }

    if (-not (Test-Path -LiteralPath $startupDir)) {
        New-Item -ItemType Directory -Path $startupDir | Out-Null
    }

    $shortcutName = "{0}.lnk" -f [System.IO.Path]::GetFileNameWithoutExtension($ExecutablePath)
    $shortcutPath = Join-Path $startupDir $shortcutName
    $shell = $null
    $shortcut = $null

    try {
        $shell = New-Object -ComObject WScript.Shell
        $shortcut = $shell.CreateShortcut($shortcutPath)
        $shortcut.TargetPath = $ExecutablePath
        $shortcut.WorkingDirectory = Split-Path -Parent $ExecutablePath
        $shortcut.IconLocation = $ExecutablePath
        $shortcut.Save()
    }
    finally {
        if ($shortcut) {
            [void][System.Runtime.InteropServices.Marshal]::FinalReleaseComObject($shortcut)
        }

        if ($shell) {
            [void][System.Runtime.InteropServices.Marshal]::FinalReleaseComObject($shell)
        }
    }

    return $shortcutPath
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

$global:LASTEXITCODE = 0
& $ResolvedCompiler @compilerArgs
$exitCode = $LASTEXITCODE

if ($exitCode -ne 0) {
    throw "Ahk2Exe devolvio un codigo de salida $exitCode."
}

if (-not (Wait-ForFile -Path $ResolvedOutput)) {
    $fallbackOutput = Join-Path (Split-Path -Parent $ResolvedSource) "$SourceName.exe"

    if ((Test-Path -LiteralPath $fallbackOutput) -and ($fallbackOutput -ne $ResolvedOutput)) {
        Move-Item -LiteralPath $fallbackOutput -Destination $ResolvedOutput -Force
    }
}

if (-not (Test-Path -LiteralPath $ResolvedOutput)) {
    throw "Ahk2Exe no genero el ejecutable esperado: $ResolvedOutput. Revisa si creo '$SourceName.exe' junto al script o si mostro un error adicional."
}

$startupPreference = $null
if ($StartWithWindows) {
    $startupPreference = $true
}
elseif (-not $SkipStartupPrompt) {
    $startupPreference = Confirm-StartWithWindows -ExecutablePath $ResolvedOutput
}

if ($startupPreference -eq $true) {
    $startupShortcut = Enable-StartupLaunch -ExecutablePath $ResolvedOutput
    Write-Host "Inicio con Windows habilitado: $startupShortcut"
}
elseif ($startupPreference -eq $false) {
    Write-Host "Inicio con Windows omitido."
}

Write-Host "Compilacion completada."
