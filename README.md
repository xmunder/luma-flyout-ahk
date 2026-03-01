# Atajos Personalizados con AutoHotkey v2

Script modular en AutoHotkey v2 para controlar volumen, brillo, navegación y utilidades rápidas desde atajos de teclado configurables.

## Demo

<div style="display: flex; gap: 10px;">

![Demo de volumen](<./assets/demo_volume.gif>)

![Demo de brillo](<./assets/demo_brightness.gif>)
</div>

## Características

- Atajos de volumen usando teclas multimedia nativas de Windows.
- Control de brillo por WMI para monitores internos compatibles.
- OSD de brillo personalizado con animación, borde, sombra y soporte para tema claro/oscuro.
- Atajos de navegación para `Home`, `End`, `Shift + Home` y `Shift + End`.
- Atajo rápido para `PrintScreen`.
- Atajo de diagnóstico para abrir `KeyHistory`.
- Configuración centralizada de hotkeys y constantes visuales en `src/config.ahk`.
- Estructura modular separada por feature.

## Requisitos

- Windows 10 u 11.
- AutoHotkey v2.0 o superior.
- Permisos normales de usuario para ejecutar scripts `.ahk`.
- Para el brillo:
  - Un panel interno o dispositivo que exponga control de brillo por WMI.
  - Si el equipo controla el brillo solo por BIOS/OEM, el cambio de brillo puede no funcionar.


## Instalación

1. Instala AutoHotkey v2.
2. Clona o descarga este repositorio.
3. Abre `src/config.ahk` si quieres cambiar atajos o parámetros visuales.
4. Ejecuta `main.ahk`.

## Compilación a EXE

El proyecto incluye un script de compilación en PowerShell: `build.ps1`.

Uso básico:

```powershell
.\build.ps1
```

Eso compila `main.ahk` y genera el ejecutable en `dist\`.

Opciones útiles:

```powershell
.\build.ps1 -OutputName "AtajosMSI.exe"
.\build.ps1 -CompilerPath "C:\Program Files\AutoHotkey\Compiler\Ahk2Exe.exe"
.\build.ps1 -Clean
```

Notas:

- Usa `Ahk2Exe.exe`, el compilador incluido con AutoHotkey.
- Si `Ahk2Exe.exe` no se encuentra automáticamente, puedes indicar la ruta con `-CompilerPath`.
- El `.exe` generado sigue dependiendo de la lógica actual del script y de las capacidades de Windows/equipo.

## Atajos por Defecto

Los atajos actuales salen de `src/config.ahk`.

### Audio

- `Ctrl + F1`: mute
- `Ctrl + F2`: bajar volumen
- `Ctrl + F3`: subir volumen

### Brillo

- `Ctrl + F4`: bajar brillo
- `Ctrl + F5`: subir brillo

### Navegación

- `Shift + Alt + Right`: `Shift + End`
- `Shift + Alt + Left`: `Shift + Home`
- `Alt + Right`: `End`
- `Alt + Left`: `Home`
- `F12`: `PrintScreen`

### Diagnóstico

- `Ctrl + F11`: abre `KeyHistory`

## Referencia de Símbolos en AutoHotkey

Si editas los hotkeys en `src/config.ahk`, AutoHotkey usa símbolos para representar modificadores:

- `^`: `Ctrl`
- `+`: `Shift`
- `!`: `Alt`
- `#`: tecla `Windows`

Ejemplos rápidos:

- `^F1` significa `Ctrl + F1`
- `+!Right` significa `Shift + Alt + Right`
- `!Left` significa `Alt + Left`

Documentación oficial:

- https://www.autohotkey.com/docs/v2/Hotkeys.htm

## Configuración

Todas las teclas se pueden cambiar desde `src/config.ahk`.

Cada grupo está documentado con comentarios:

- `Audio feature hotkeys`
- `Brightness feature hotkeys`
- `Navigation feature hotkeys`
- `Diagnostics feature hotkeys`

Si dejas una tecla en cadena vacía (`""`), ese hotkey queda desactivado.

Además, desde ese mismo archivo puedes ajustar:

- Paso de brillo.
- Tamaño del popup.
- Colores del OSD.
- Borde y sombra.
- Tiempo de fade y animación.

## Limitaciones Conocidas

- El OSD de brillo es personalizado; no usa el flyout nativo de Windows.
- El control de brillo depende de WMI. En algunos portátiles puede no estar disponible.
- El comportamiento visual del popup fue ajustado para escritorio Windows, pero puede variar según escala, tema y shell del sistema.

## Uso Rápido

1. Ejecuta `main.ahk`.
2. Prueba los atajos por defecto.
3. Si necesitas cambiar teclas, edita `src/config.ahk`.
4. Recarga el script.
