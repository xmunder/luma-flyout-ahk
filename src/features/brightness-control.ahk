; Brightness hotkeys and WMI control.
^F4::{
    global BRIGHTNESS_STEP
    AdjustBrightness(BRIGHTNESS_STEP)
}

^F5::{
    global BRIGHTNESS_STEP
    AdjustBrightness(-BRIGHTNESS_STEP)
}

AdjustBrightness(step) {
    target := 0

    try {
        current := GetBrightness()
        if (current = "") {
            ShowMessage(
                "El brillo no esta disponible por WMI.`n"
                . "Si tu equipo lo maneja solo por BIOS/OEM, hay que mapear la tecla real del fabricante."
            )
            return
        }

        target := Round(Max(0, Min(100, current + step)))
        if (target != current) && !SetBrightness(target) {
            ShowMessage("No se encontro un monitor interno compatible para cambiar el brillo.")
            return
        }
    } catch Error as err {
        ShowDetailedError("No se pudo cambiar el brillo", err)
        return
    }

    try {
        ShowBrightnessGui(target)
    } catch Error as err {
        ShowOsd("Brillo", target)
        ShowDetailedError("El brillo cambio, pero fallo el OSD", err)
    }
}

GetBrightness() {
    global BRIGHTNESS_WMI_PATH

    try {
        for monitor in ComObjGet(BRIGHTNESS_WMI_PATH).ExecQuery("SELECT * FROM WmiMonitorBrightness") {
            return monitor.CurrentBrightness
        }
    } catch {
    }

    return ""
}

SetBrightness(level) {
    global BRIGHTNESS_WMI_PATH
    changed := false

    for monitor in ComObjGet(BRIGHTNESS_WMI_PATH).ExecQuery("SELECT * FROM WmiMonitorBrightnessMethods") {
        monitor.WmiSetBrightness(1, level)
        changed := true
    }

    return changed
}
