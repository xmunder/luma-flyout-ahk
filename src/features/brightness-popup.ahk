; Brightness popup renderer and GDI+ lifecycle.
global BrightnessPopupCloseTimer := CloseBrightnessPopup.Bind()
global BrightnessPopupHwnd := 0
global BrightnessPopupGdipToken := 0
global BrightnessPopupReady := false

OnExit((*) => ShutdownBrightnessPopup())

ShowBrightnessGui(level) {
    global BRIGHTNESS_POPUP_MARGIN_BOTTOM
    global BRIGHTNESS_POPUP_TIMEOUT_MS
    global BrightnessPopupCloseTimer
    global BrightnessPopupHwnd

    metrics := GetBrightnessPopupMetrics()

    EnsureBrightnessPopupReady()
    DrawBrightnessPopup(level, metrics)

    x := Max(0, (A_ScreenWidth - metrics.windowWidth) // 2)
    y := Max(0, GetTaskbarTop() - metrics.contentHeight - BRIGHTNESS_POPUP_MARGIN_BOTTOM - metrics.contentY)

    DllCall(
        "SetWindowPos",
        "ptr", BrightnessPopupHwnd,
        "ptr", -1,
        "int", x,
        "int", y,
        "int", 0,
        "int", 0,
        "uint", 0x0041
    )

    SetTimer(BrightnessPopupCloseTimer, 0)
    SetTimer(BrightnessPopupCloseTimer, -BRIGHTNESS_POPUP_TIMEOUT_MS)
}

EnsureBrightnessPopupReady() {
    global BrightnessPopupReady
    global BrightnessPopupGdipToken
    global BrightnessPopupHwnd

    if !BrightnessPopupReady {
        DllCall("LoadLibrary", "str", "gdiplus")

        startupInput := Buffer(24, 0)
        NumPut("uint", 1, startupInput, 0)

        status := DllCall(
            "gdiplus\GdiplusStartup",
            "ptr*", &BrightnessPopupGdipToken,
            "ptr", startupInput,
            "ptr", 0
        )

        if (status != 0) {
            throw Error("No se pudo inicializar GDI+.",, status)
        }

        BrightnessPopupReady := true
    }

    if !BrightnessPopupHwnd {
        BrightnessPopupHwnd := CreateBrightnessLayeredPopup()
    }

    if !BrightnessPopupHwnd {
        throw Error("No se pudo crear la ventana del OSD.")
    }
}

CreateBrightnessLayeredPopup() {
    exStyle := 0x80000 | 0x8 | 0x80 | 0x20 | 0x8000000
    style := 0x80000000
    metrics := GetBrightnessPopupMetrics()

    return DllCall(
        "CreateWindowEx",
        "uint", exStyle,
        "str", "Static",
        "str", "",
        "uint", style,
        "int", 0,
        "int", 0,
        "int", metrics.windowWidth,
        "int", metrics.windowHeight,
        "ptr", 0,
        "ptr", 0,
        "ptr", 0,
        "ptr", 0,
        "ptr"
    )
}

GetBrightnessPopupMetrics() {
    global BRIGHTNESS_POPUP_WIDTH
    global BRIGHTNESS_POPUP_HEIGHT
    global BRIGHTNESS_POPUP_SHADOW_SIZE
    global BRIGHTNESS_POPUP_SHADOW_OFFSET_Y

    return {
        contentWidth: BRIGHTNESS_POPUP_WIDTH,
        contentHeight: BRIGHTNESS_POPUP_HEIGHT,
        contentX: BRIGHTNESS_POPUP_SHADOW_SIZE,
        contentY: BRIGHTNESS_POPUP_SHADOW_SIZE,
        shadowSize: BRIGHTNESS_POPUP_SHADOW_SIZE,
        shadowOffsetY: BRIGHTNESS_POPUP_SHADOW_OFFSET_Y,
        windowWidth: BRIGHTNESS_POPUP_WIDTH + (BRIGHTNESS_POPUP_SHADOW_SIZE * 2),
        windowHeight: BRIGHTNESS_POPUP_HEIGHT + (BRIGHTNESS_POPUP_SHADOW_SIZE * 2) + BRIGHTNESS_POPUP_SHADOW_OFFSET_Y
    }
}

DrawBrightnessPopup(level, metrics) {
    global BrightnessPopupHwnd
    global BRIGHTNESS_POPUP_RADIUS
    global BRIGHTNESS_POPUP_BAR_WIDTH
    global BRIGHTNESS_POPUP_RENDER_SCALE

    theme := GetBrightnessPopupTheme()
    level := Round(Max(0, Min(100, level)))

    popupWidth := metrics.contentWidth
    popupHeight := metrics.contentHeight
    windowWidth := metrics.windowWidth
    windowHeight := metrics.windowHeight
    renderScale := BRIGHTNESS_POPUP_RENDER_SCALE

    barWidth := BRIGHTNESS_POPUP_BAR_WIDTH
    barHeight := 4
    barRadius := 2
    barMarginTop := 19
    barMarginLeft := 42
    barFillRadius := 2

    iconMarginLeft := 11
    iconMarginTop := 13
    sunCenterRadius := 2
    sunRayLength := 2
    sunRayGap := 2
    sunRayThickness := 1.25
    sunRayCount := 8
    barFillColor := ResolveBrightnessPopupBarColor(theme)
    borderColor := ResolveBrightnessPopupBorderColor(theme)

    scaledWidth := popupWidth * renderScale
    scaledHeight := popupHeight * renderScale
    scaledWindowWidth := windowWidth * renderScale
    scaledWindowHeight := windowHeight * renderScale
    scaledRadius := BRIGHTNESS_POPUP_RADIUS * renderScale
    contentX := metrics.contentX * renderScale
    contentY := metrics.contentY * renderScale
    shadowSize := metrics.shadowSize * renderScale
    shadowOffsetY := metrics.shadowOffsetY * renderScale

    largeBitmap := 0
    DllCall(
        "gdiplus\GdipCreateBitmapFromScan0",
        "int", scaledWindowWidth,
        "int", scaledWindowHeight,
        "int", 0,
        "int", 0x26200A,
        "ptr", 0,
        "ptr*", &largeBitmap
    )

    graphics := 0
    DllCall("gdiplus\GdipGetImageGraphicsContext", "ptr", largeBitmap, "ptr*", &graphics)
    DllCall("gdiplus\GdipSetSmoothingMode", "ptr", graphics, "int", 4)
    DllCall("gdiplus\GdipSetPixelOffsetMode", "ptr", graphics, "int", 4)
    DllCall("gdiplus\GdipSetCompositingQuality", "ptr", graphics, "int", 4)
    DllCall("gdiplus\GdipGraphicsClear", "ptr", graphics, "uint", 0x00000000)

    DrawBrightnessPopupShadow(graphics, contentX, contentY, scaledWidth, scaledHeight, scaledRadius, shadowSize, shadowOffsetY, theme)

    backgroundArgb := (theme.popupAlpha << 24) | HexToInt(theme.popupBg)
    backgroundBrush := 0
    DllCall("gdiplus\GdipCreateSolidFill", "uint", backgroundArgb, "ptr*", &backgroundBrush)
    backgroundPath := 0
    DllCall("gdiplus\GdipCreatePath", "int", 0, "ptr*", &backgroundPath)
    AddRoundedRectPath(backgroundPath, contentX, contentY, scaledWidth, scaledHeight, scaledRadius)
    DllCall("gdiplus\GdipFillPath", "ptr", graphics, "ptr", backgroundBrush, "ptr", backgroundPath)

    borderWidth := 1.0 * renderScale
    borderInset := borderWidth / 2.0
    borderArgb := (theme.borderAlpha << 24) | HexToInt(borderColor)
    borderPen := 0
    DllCall("gdiplus\GdipCreatePen1", "uint", borderArgb, "float", borderWidth, "int", 2, "ptr*", &borderPen)
    borderPath := 0
    DllCall("gdiplus\GdipCreatePath", "int", 0, "ptr*", &borderPath)
    AddRoundedRectPath(
        borderPath,
        contentX + borderInset,
        contentY + borderInset,
        scaledWidth - borderWidth,
        scaledHeight - borderWidth,
        Max(0, scaledRadius - borderInset)
    )
    DllCall("gdiplus\GdipDrawPath", "ptr", graphics, "ptr", borderPen, "ptr", borderPath)
    DllCall("gdiplus\GdipDeletePen", "ptr", borderPen)
    DllCall("gdiplus\GdipDeletePath", "ptr", borderPath)

    DllCall("gdiplus\GdipDeleteBrush", "ptr", backgroundBrush)
    DllCall("gdiplus\GdipDeletePath", "ptr", backgroundPath)

    iconSize := (sunCenterRadius + sunRayGap + sunRayLength) * 2 * renderScale
    iconX := (metrics.contentX + iconMarginLeft) * renderScale
    iconY := (metrics.contentY + iconMarginTop) * renderScale
    centerRadius := sunCenterRadius * renderScale
    rayLength := sunRayLength * renderScale
    rayGap := sunRayGap * renderScale
    rayThickness := sunRayThickness * renderScale
    centerX := iconX + iconSize / 2
    centerY := iconY + iconSize / 2
    iconArgb := 0xFF000000 | HexToInt(theme.icon)

    iconBrush := 0
    DllCall("gdiplus\GdipCreateSolidFill", "uint", iconArgb, "ptr*", &iconBrush)
    DllCall(
        "gdiplus\GdipFillEllipse",
        "ptr", graphics,
        "ptr", iconBrush,
        "float", centerX - centerRadius,
        "float", centerY - centerRadius,
        "float", centerRadius * 2,
        "float", centerRadius * 2
    )
    DllCall("gdiplus\GdipDeleteBrush", "ptr", iconBrush)

    iconPen := 0
    DllCall("gdiplus\GdipCreatePen1", "uint", iconArgb, "float", rayThickness, "int", 2, "ptr*", &iconPen)
    DllCall("gdiplus\GdipSetPenStartCap", "ptr", iconPen, "int", 2)
    DllCall("gdiplus\GdipSetPenEndCap", "ptr", iconPen, "int", 2)

    normalizedLevel := level / 100.0
    globalRayLengthScale := 0.55 + (0.45 * normalizedLevel)
    pi := 3.14159265358979
    Loop sunRayCount {
        rayRank := GetBrightnessRayRank(A_Index)
        rayStrength := GetBrightnessRayStrength(level, rayRank, sunRayCount)
        if (rayStrength <= 0) {
            continue
        }

        angle := (A_Index - 1) * (2 * pi / sunRayCount)
        startDistance := centerRadius + rayGap
        currentRayLength := Max(1.0 * renderScale, rayLength * globalRayLengthScale * (0.35 + (0.65 * rayStrength)))
        endDistance := centerRadius + rayGap + currentRayLength
        x1 := centerX + Cos(angle) * startDistance
        y1 := centerY + Sin(angle) * startDistance
        x2 := centerX + Cos(angle) * endDistance
        y2 := centerY + Sin(angle) * endDistance

        DllCall(
            "gdiplus\GdipDrawLine",
            "ptr", graphics,
            "ptr", iconPen,
            "float", x1,
            "float", y1,
            "float", x2,
            "float", y2
        )
    }
    DllCall("gdiplus\GdipDeletePen", "ptr", iconPen)

    barX := (metrics.contentX + barMarginLeft) * renderScale
    barY := (metrics.contentY + barMarginTop) * renderScale
    scaledBarWidth := barWidth * renderScale
    scaledBarHeight := barHeight * renderScale
    scaledBarRadius := barRadius * renderScale
    scaledFillRadius := barFillRadius * renderScale

    barBackgroundArgb := 0xFF000000 | HexToInt(theme.barBg)
    barBackgroundBrush := 0
    DllCall("gdiplus\GdipCreateSolidFill", "uint", barBackgroundArgb, "ptr*", &barBackgroundBrush)
    barBackgroundPath := 0
    DllCall("gdiplus\GdipCreatePath", "int", 0, "ptr*", &barBackgroundPath)
    AddRoundedRectPath(barBackgroundPath, barX, barY, scaledBarWidth, scaledBarHeight, scaledBarRadius)
    DllCall("gdiplus\GdipFillPath", "ptr", graphics, "ptr", barBackgroundBrush, "ptr", barBackgroundPath)
    DllCall("gdiplus\GdipDeleteBrush", "ptr", barBackgroundBrush)
    DllCall("gdiplus\GdipDeletePath", "ptr", barBackgroundPath)

    fillWidth := Round((scaledBarWidth * level) / 100)
    if (fillWidth > 0) {
        if (fillWidth < (2 * renderScale) && level > 0) {
            fillWidth := 2 * renderScale
        }

        fillArgb := 0xFF000000 | HexToInt(barFillColor)
        fillBrush := 0
        DllCall("gdiplus\GdipCreateSolidFill", "uint", fillArgb, "ptr*", &fillBrush)
        fillPath := 0
        DllCall("gdiplus\GdipCreatePath", "int", 0, "ptr*", &fillPath)

        effectiveRadius := Min(scaledFillRadius, fillWidth // 2, scaledBarHeight // 2)
        AddRoundedRectPath(fillPath, barX, barY, fillWidth, scaledBarHeight, effectiveRadius)
        DllCall("gdiplus\GdipFillPath", "ptr", graphics, "ptr", fillBrush, "ptr", fillPath)
        DllCall("gdiplus\GdipDeleteBrush", "ptr", fillBrush)
        DllCall("gdiplus\GdipDeletePath", "ptr", fillPath)
    }

    DllCall("gdiplus\GdipDeleteGraphics", "ptr", graphics)

    finalBitmap := 0
    DllCall(
        "gdiplus\GdipCreateBitmapFromScan0",
        "int", windowWidth,
        "int", windowHeight,
        "int", 0,
        "int", 0x26200A,
        "ptr", 0,
        "ptr*", &finalBitmap
    )

    finalGraphics := 0
    DllCall("gdiplus\GdipGetImageGraphicsContext", "ptr", finalBitmap, "ptr*", &finalGraphics)
    DllCall("gdiplus\GdipSetInterpolationMode", "ptr", finalGraphics, "int", 7)
    DllCall("gdiplus\GdipSetPixelOffsetMode", "ptr", finalGraphics, "int", 4)
    DllCall("gdiplus\GdipSetCompositingQuality", "ptr", finalGraphics, "int", 4)
    DllCall("gdiplus\GdipSetSmoothingMode", "ptr", finalGraphics, "int", 4)
    DllCall(
        "gdiplus\GdipDrawImageRectI",
        "ptr", finalGraphics,
        "ptr", largeBitmap,
        "int", 0,
        "int", 0,
        "int", windowWidth,
        "int", windowHeight
    )
    DllCall("gdiplus\GdipDeleteGraphics", "ptr", finalGraphics)
    DllCall("gdiplus\GdipDisposeImage", "ptr", largeBitmap)

    hBitmap := 0
    DllCall("gdiplus\GdipCreateHBITMAPFromBitmap", "ptr", finalBitmap, "ptr*", &hBitmap, "uint", 0)
    DllCall("gdiplus\GdipDisposeImage", "ptr", finalBitmap)

    screenDc := DllCall("GetDC", "ptr", 0, "ptr")
    memDc := DllCall("CreateCompatibleDC", "ptr", screenDc, "ptr")
    oldBitmap := DllCall("SelectObject", "ptr", memDc, "ptr", hBitmap, "ptr")

    sizeBuffer := Buffer(8, 0)
    NumPut("int", windowWidth, sizeBuffer, 0)
    NumPut("int", windowHeight, sizeBuffer, 4)

    sourcePoint := Buffer(8, 0)

    blend := Buffer(4, 0)
    NumPut("uchar", 0, blend, 0)
    NumPut("uchar", 0, blend, 1)
    NumPut("uchar", 255, blend, 2)
    NumPut("uchar", 1, blend, 3)

    DllCall(
        "UpdateLayeredWindow",
        "ptr", BrightnessPopupHwnd,
        "ptr", screenDc,
        "ptr", 0,
        "ptr", sizeBuffer,
        "ptr", memDc,
        "ptr", sourcePoint,
        "uint", 0,
        "ptr", blend,
        "uint", 2
    )

    DllCall("SelectObject", "ptr", memDc, "ptr", oldBitmap)
    DllCall("DeleteDC", "ptr", memDc)
    DllCall("DeleteObject", "ptr", hBitmap)
    DllCall("ReleaseDC", "ptr", 0, "ptr", screenDc)
}

GetBrightnessPopupTheme() {
    isLight := false

    try {
        themeValue := RegRead(
            "HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize",
            "AppsUseLightTheme"
        )
        isLight := (themeValue = 1)
    } catch {
    }

    if (isLight) {
        return {
            isLight: true,
            popupBg: "F3F3F3",
            popupAlpha: 250,
            borderAlpha: 220,
            shadowColor: "000000",
            shadowInnerAlpha: 30,
            shadowOuterAlpha: 14,
            barBg: "D1D1D1",
            barFill: "0067C0",
            icon: "1A1A1A"
        }
    }

    return {
        isLight: false,
        popupBg: "2C2C2C",
        popupAlpha: 245,
        borderAlpha: 210,
        shadowColor: "000000",
        shadowInnerAlpha: 48,
        shadowOuterAlpha: 22,
        barBg: "4D4D4D",
        barFill: "60CDFF",
        icon: "FFFFFF"
    }
}

ResolveBrightnessPopupBarColor(theme) {
    global BRIGHTNESS_POPUP_BAR_COLOR
    global BRIGHTNESS_POPUP_BAR_COLOR_LIGHT
    global BRIGHTNESS_POPUP_BAR_COLOR_DARK

    if (BRIGHTNESS_POPUP_BAR_COLOR != "") {
        return BRIGHTNESS_POPUP_BAR_COLOR
    }

    if (theme.isLight && BRIGHTNESS_POPUP_BAR_COLOR_LIGHT != "") {
        return BRIGHTNESS_POPUP_BAR_COLOR_LIGHT
    }

    if (!theme.isLight && BRIGHTNESS_POPUP_BAR_COLOR_DARK != "") {
        return BRIGHTNESS_POPUP_BAR_COLOR_DARK
    }

    return theme.barFill
}

ResolveBrightnessPopupBorderColor(theme) {
    global BRIGHTNESS_POPUP_BORDER_COLOR
    global BRIGHTNESS_POPUP_BORDER_COLOR_LIGHT
    global BRIGHTNESS_POPUP_BORDER_COLOR_DARK

    if (BRIGHTNESS_POPUP_BORDER_COLOR != "") {
        return BRIGHTNESS_POPUP_BORDER_COLOR
    }

    if (theme.isLight && BRIGHTNESS_POPUP_BORDER_COLOR_LIGHT != "") {
        return BRIGHTNESS_POPUP_BORDER_COLOR_LIGHT
    }

    if (!theme.isLight && BRIGHTNESS_POPUP_BORDER_COLOR_DARK != "") {
        return BRIGHTNESS_POPUP_BORDER_COLOR_DARK
    }

    return theme.popupBg
}

GetBrightnessRayRank(rayIndex) {
    ; Keep the icon balanced by hiding rays in opposite pairs.
    static rayOrder := [1, 5, 3, 7, 2, 6, 4, 8]

    Loop rayOrder.Length {
        if (rayOrder[A_Index] = rayIndex) {
            return A_Index
        }
    }

    return rayOrder.Length + 1
}

GetBrightnessRayStrength(level, rayRank, totalRays) {
    fillUnits := (level / 100.0) * totalRays
    return Min(1.0, Max(0.0, fillUnits - (rayRank - 1)))
}

DrawBrightnessPopupShadow(graphics, x, y, width, height, radius, shadowSize, shadowOffsetY, theme) {
    if (shadowSize <= 0) {
        return
    }

    DrawBrightnessShadowLayer(
        graphics,
        x,
        y,
        width,
        height,
        radius,
        shadowSize,
        shadowOffsetY,
        theme.shadowOuterAlpha,
        theme.shadowColor
    )
    DrawBrightnessShadowLayer(
        graphics,
        x,
        y,
        width,
        height,
        radius,
        Max(1.0, shadowSize * 0.55),
        shadowOffsetY * 0.5,
        theme.shadowInnerAlpha,
        theme.shadowColor
    )
}

DrawBrightnessShadowLayer(graphics, x, y, width, height, radius, expand, offsetY, alpha, colorHex) {
    shadowArgb := (alpha << 24) | HexToInt(colorHex)
    shadowBrush := 0
    DllCall("gdiplus\GdipCreateSolidFill", "uint", shadowArgb, "ptr*", &shadowBrush)
    shadowPath := 0
    DllCall("gdiplus\GdipCreatePath", "int", 0, "ptr*", &shadowPath)
    AddRoundedRectPath(
        shadowPath,
        x - expand,
        y - expand + offsetY,
        width + (expand * 2),
        height + (expand * 2),
        radius + expand
    )
    DllCall("gdiplus\GdipFillPath", "ptr", graphics, "ptr", shadowBrush, "ptr", shadowPath)
    DllCall("gdiplus\GdipDeleteBrush", "ptr", shadowBrush)
    DllCall("gdiplus\GdipDeletePath", "ptr", shadowPath)
}

GetTaskbarTop() {
    hTaskbar := DllCall("FindWindow", "str", "Shell_TrayWnd", "ptr", 0, "ptr")
    if !hTaskbar {
        return A_ScreenHeight - 48
    }

    rect := Buffer(16, 0)
    DllCall("GetWindowRect", "ptr", hTaskbar, "ptr", rect)

    taskbarTop := NumGet(rect, 4, "int")
    taskbarBottom := NumGet(rect, 12, "int")

    if (taskbarTop > A_ScreenHeight // 2) {
        return taskbarTop
    }

    if (taskbarBottom < A_ScreenHeight // 2) {
        return taskbarBottom
    }

    return A_ScreenHeight - 48
}

CloseBrightnessPopup(*) {
    global BrightnessPopupHwnd

    if BrightnessPopupHwnd {
        DllCall("DestroyWindow", "ptr", BrightnessPopupHwnd)
        BrightnessPopupHwnd := 0
    }
}

ShutdownBrightnessPopup(*) {
    global BrightnessPopupReady
    global BrightnessPopupGdipToken

    CloseBrightnessPopup()

    if (BrightnessPopupReady && BrightnessPopupGdipToken) {
        DllCall("gdiplus\GdiplusShutdown", "ptr", BrightnessPopupGdipToken)
        BrightnessPopupGdipToken := 0
        BrightnessPopupReady := false
    }
}

AddRoundedRectPath(pathHandle, x, y, width, height, radius) {
    if (radius <= 0) {
        DllCall("gdiplus\GdipAddPathRectangle", "ptr", pathHandle, "float", x, "float", y, "float", width, "float", height)
        return
    }

    radius := Min(radius, width / 2.0, height / 2.0)
    diameter := radius * 2.0

    DllCall("gdiplus\GdipStartPathFigure", "ptr", pathHandle)
    DllCall("gdiplus\GdipAddPathArc", "ptr", pathHandle, "float", x, "float", y, "float", diameter, "float", diameter, "float", 180.0, "float", 90.0)
    DllCall("gdiplus\GdipAddPathArc", "ptr", pathHandle, "float", x + width - diameter, "float", y, "float", diameter, "float", diameter, "float", 270.0, "float", 90.0)
    DllCall("gdiplus\GdipAddPathArc", "ptr", pathHandle, "float", x + width - diameter, "float", y + height - diameter, "float", diameter, "float", diameter, "float", 0.0, "float", 90.0)
    DllCall("gdiplus\GdipAddPathArc", "ptr", pathHandle, "float", x, "float", y + height - diameter, "float", diameter, "float", diameter, "float", 90.0, "float", 90.0)
    DllCall("gdiplus\GdipClosePathFigure", "ptr", pathHandle)
}

HexToInt(hexColor) {
    hexColor := StrReplace(hexColor, "#", "")
    return Integer("0x" hexColor)
}
