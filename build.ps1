param(
    [string]$SourcePath = "main.ahk",
    [string]$OutputName = "",
    [string]$CompilerPath = "",
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

$ResolvedCompiler = Resolve-AhkCompiler -PreferredPath $CompilerPath

Write-Host "Compilando $ResolvedSource"
Write-Host "Compilador: $ResolvedCompiler"
Write-Host "Salida: $ResolvedOutput"

& $ResolvedCompiler /in $ResolvedSource /out $ResolvedOutput

if ($LASTEXITCODE -ne 0) {
    throw "Ahk2Exe devolvio un codigo de salida $LASTEXITCODE."
}

Write-Host "Compilacion completada."
