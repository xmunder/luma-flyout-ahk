; Navigation shortcuts.
if (NAVIGATION_HOTKEY_SELECT_END != "") {
    Hotkey(NAVIGATION_HOTKEY_SELECT_END, HandleNavigationSelectEndHotkey)
}

if (NAVIGATION_HOTKEY_SELECT_HOME != "") {
    Hotkey(NAVIGATION_HOTKEY_SELECT_HOME, HandleNavigationSelectHomeHotkey)
}

if (NAVIGATION_HOTKEY_END != "") {
    Hotkey(NAVIGATION_HOTKEY_END, HandleNavigationEndHotkey)
}

if (NAVIGATION_HOTKEY_HOME != "") {
    Hotkey(NAVIGATION_HOTKEY_HOME, HandleNavigationHomeHotkey)
}

if (NAVIGATION_HOTKEY_PRINT_SCREEN != "") {
    Hotkey(NAVIGATION_HOTKEY_PRINT_SCREEN, HandleNavigationPrintScreenHotkey)
}

HandleNavigationSelectEndHotkey(*) {
    Send("+{End}")
}

HandleNavigationSelectHomeHotkey(*) {
    Send("+{Home}")
}

HandleNavigationEndHotkey(*) {
    Send("{End}")
}

HandleNavigationHomeHotkey(*) {
    Send("{Home}")
}

HandleNavigationPrintScreenHotkey(*) {
    Send("{PrintScreen}")
}
