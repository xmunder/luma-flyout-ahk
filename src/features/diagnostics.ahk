; Quick keyboard diagnostics while testing OEM keys.
if (DIAGNOSTICS_HOTKEY_KEY_HISTORY != "") {
    Hotkey(DIAGNOSTICS_HOTKEY_KEY_HISTORY, HandleDiagnosticsKeyHistoryHotkey)
}

HandleDiagnosticsKeyHistoryHotkey(*) {
    KeyHistory
}
