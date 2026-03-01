# Atajos Personalizados con AutoHotkey v2

Script modular en AutoHotkey v2 para controlar volumen, brillo, navegación y utilidades rápidas desde atajos de teclado configurables.

## Demo

![Demo principal del OSD de brillo](<./Grabación de pantalla 2026-02-28 230053.gif>)

![Demo adicional del OSD de brillo](<./Grabación de pantalla 2026-02-28 232138.gif>)

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

## Estructura

- `main.ahk`: punto de entrada principal.
- `shortcuts_v2.ahk`: wrapper de compatibilidad que carga `main.ahk`.
- `src/config.ahk`: hotkeys por defecto y configuración general.
- `src/features/`: lógica separada por funcionalidad.
- `src/shared/`: utilidades compartidas.

## Instalación

1. Instala AutoHotkey v2.
2. Clona o descarga este repositorio.
3. Abre `src/config.ahk` si quieres cambiar atajos o parámetros visuales.
4. Ejecuta `main.ahk`.

También puedes ejecutar `shortcuts_v2.ahk`, que carga el mismo script principal.

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
