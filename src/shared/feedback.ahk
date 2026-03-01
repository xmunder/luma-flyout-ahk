; Reuse one callback object for tooltip cleanup.
global ClearOsdTimer := ClearOsd.Bind()

ShowOsd(label, level, state := "") {
    global OSD_TIMEOUT_MS
    global ClearOsdTimer
    static lastLabel := ""
    static shownLevel := 0

    if (lastLabel != label) {
        shownLevel := level
        RenderOsd(label, shownLevel, state)
    } else {
        delta := level - shownLevel
        frames := Min(8, Max(1, Abs(delta)))

        Loop frames {
            frameLevel := Round(shownLevel + (delta * A_Index / frames))
            RenderOsd(label, frameLevel, state)
            Sleep(12)
        }

        shownLevel := level
    }

    lastLabel := label
    SetTimer(ClearOsdTimer, 0)
    SetTimer(ClearOsdTimer, -OSD_TIMEOUT_MS)
}

RenderOsd(label, level, state := "") {
    filled := Round(level / 10)
    bar := "["

    Loop 10 {
        bar .= (A_Index <= filled) ? "#" : "-"
    }

    bar .= "]"

    text := label ": " level "%"
    if (state != "") {
        text .= " | " state
    }

    x := Max(0, (A_ScreenWidth // 2) - 100)
    ToolTip(text "`n" bar, x, 40)
}

ShowMessage(message) {
    global ClearOsdTimer
    x := Max(0, (A_ScreenWidth // 2) - 170)
    ToolTip(message, x, 40)
    SetTimer(ClearOsdTimer, 0)
    SetTimer(ClearOsdTimer, -1400)
}

ShowDetailedError(prefix, err) {
    details := prefix ".`n" err.Message

    if (err.What != "") {
        details .= "`nEn: " err.What
    }

    if (err.File != "") {
        details .= "`nArchivo: " err.File
    }

    if (err.Line != "") {
        details .= "`nLinea: " err.Line
    }

    if (err.Extra != "") {
        details .= "`nExtra: " err.Extra
    }

    if (err.Stack != "") {
        details .= "`n`nStack:`n" err.Stack
    }

    MsgBox(details, "Diagnostico AutoHotkey")
}

ClearOsd() {
    ToolTip()
}
