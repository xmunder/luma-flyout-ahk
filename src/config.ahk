; Shared settings used across the script.
global BRIGHTNESS_STEP := 10
global BRIGHTNESS_POPUP_WIDTH := 169
global BRIGHTNESS_POPUP_HEIGHT := 42
global BRIGHTNESS_POPUP_RADIUS := 8
global BRIGHTNESS_POPUP_BAR_COLOR := "" ; Forces the same RGB hex color in all themes.
global BRIGHTNESS_POPUP_BAR_COLOR_LIGHT := "0067C0" ; RGB hex, `#` optional.
global BRIGHTNESS_POPUP_BAR_COLOR_DARK := "60CDFF" ; RGB hex, `#` optional.
global BRIGHTNESS_POPUP_BORDER_COLOR := "" ; Forces the same RGB hex border in all themes.
global BRIGHTNESS_POPUP_BORDER_COLOR_LIGHT := "D7D7D7" ; RGB hex, `#` optional.
global BRIGHTNESS_POPUP_BORDER_COLOR_DARK := "595959" ; RGB hex, `#` optional.
global BRIGHTNESS_POPUP_MARGIN_BOTTOM := 12
global BRIGHTNESS_POPUP_TIMEOUT_MS := 1400
global BRIGHTNESS_POPUP_RENDER_SCALE := 4
global OSD_TIMEOUT_MS := 1000
global BRIGHTNESS_WMI_PATH := "winmgmts:{impersonationLevel=impersonate}!\\.\root\WMI"
