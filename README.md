# LumaFlyout AHK

OSD de brillo personalizado para Windows en AutoHotkey v2, con control por WMI y hotkeys configurables para volumen, navegación y utilidades.

## Demo

<div style="display: flex; gap: 10px;">

![Demo de volumen](<./assets/demo_volume.gif>)

![Demo de brillo](<./assets/demo_brightness.gif>)

</div>

## Requisitos

- Windows 10 u 11.
- AutoHotkey v2.0 o superior.
- Un equipo compatible con control de brillo por WMI para usar el ajuste de brillo.

## Uso rápido

1. Instala AutoHotkey v2.
2. Clona o descarga este repositorio.
3. Ajusta las teclas o el estilo del OSD en `src/config.ahk`.
4. Ejecuta `main.ahk`.

## Compilación a EXE

El proyecto incluye `build.ps1` para compilar `main.ahk` con `Ahk2Exe`.

```powershell
.\build.ps1
```

Opciones comunes:

```powershell
.\build.ps1 -OutputName "LumaFlyout.exe"
.\build.ps1 -CompilerPath "C:\Program Files\AutoHotkey\Compiler\Ahk2Exe.exe"
.\build.ps1 -BaseFilePath "C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe"
.\build.ps1 -IconPath ".\assets\logo_icon.ico"
```

## Atajos por defecto

- `Ctrl + F1`: mute
- `Ctrl + F2`: bajar volumen
- `Ctrl + F3`: subir volumen
- `Ctrl + F4`: bajar brillo
- `Ctrl + F5`: subir brillo
- `Shift + Alt + Right`: `Shift + End`
- `Shift + Alt + Left`: `Shift + Home`
- `Alt + Right`: `End`
- `Alt + Left`: `Home`
- `F12`: `PrintScreen`
- `Ctrl + F11`: `KeyHistory`

## Configuración

Toda la configuración vive en `src/config.ahk`.

Símbolos útiles de AutoHotkey:

- `^`: `Ctrl`
- `+`: `Shift`
- `!`: `Alt`
- `#`: tecla `Windows`

Si una tecla queda en `""`, ese hotkey se desactiva.

## Notas

- El OSD de brillo es personalizado; no usa el flyout nativo de Windows.
- El ajuste de brillo depende de WMI y puede no estar disponible en algunos equipos.

## Licencia

MIT.
