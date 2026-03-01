; Use media keys so Windows can show its native volume flyout.
if (AUDIO_HOTKEY_MUTE != "") {
    Hotkey(AUDIO_HOTKEY_MUTE, HandleAudioMuteHotkey)
}

if (AUDIO_HOTKEY_VOLUME_UP != "") {
    Hotkey(AUDIO_HOTKEY_VOLUME_UP, HandleAudioVolumeUpHotkey)
}

if (AUDIO_HOTKEY_VOLUME_DOWN != "") {
    Hotkey(AUDIO_HOTKEY_VOLUME_DOWN, HandleAudioVolumeDownHotkey)
}

HandleAudioMuteHotkey(*) {
    Send("{Volume_Mute}")
}

HandleAudioVolumeUpHotkey(*) {
    Send("{Volume_Up}")
}

HandleAudioVolumeDownHotkey(*) {
    Send("{Volume_Down}")
}
