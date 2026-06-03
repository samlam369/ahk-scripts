#Requires AutoHotkey v2.0

; ============================================
; Key Mappings Configuration
; ============================================
; Define key mappings for both CapsLock and RAlt
keyMappings := Map(
    "i", "Up",
    "k", "Down",
    "j", "Left",
    "l", "Right",
    "u", "Home",
    "o", "End",
    "p", "Backspace",
    ";", "Delete"
)

; ============================================
; Helper Function for RAlt Hotkeys
; ============================================
; This function is needed because we need to prevent RAlt from being included in the output
SendKeyWithMods(key) {
    ; Get the state of other modifiers
    mods := ""
    if GetKeyState("Control", "P")
        mods .= "^"
    if GetKeyState("Shift", "P")
        mods .= "+"
    if GetKeyState("LAlt", "P")  ; Only check for left Alt, not right Alt
        mods .= "!"
    
    ; Send the key with modifiers, but without the RAlt that triggered this hotkey
    SendInput(mods "{" key "}")
}

; Function to register hotkeys
RegisterHotkeys(prefix) {
    for key, action in keyMappings {
        try {
            switch prefix {
                case "CapsLock":
                    Hotkey(prefix " & " key, ((targetKey, *) => SendInput("{Blind}{" targetKey "}")).Bind(action))
                case "RAlt":
                    Hotkey(">*!" key, ((targetKey, *) => SendKeyWithMods(targetKey)).Bind(action))
            }
        } catch Error as e {
            MsgBox "Failed to create hotkey: " e.Message
        }
    }
}

; ============================================
; Initialize Hotkeys
; ============================================

; Register CapsLock hotkeys
RegisterHotkeys("CapsLock")

; Register RAlt hotkeys
RegisterHotkeys("RAlt")

; ============================================
; New Features: Code Block Creation
; ============================================

; Helper function to paste text safely without losing clipboard content
SafePaste(txt) {
    SavedClip := ClipboardAll() ; Backup current clipboard
    A_Clipboard := txt
    if ClipWait(2) {
        SendInput("^v")
        Sleep(150) ; Brief pause to ensure OS finishes pasting
    }
    A_Clipboard := SavedClip ; Restore original clipboard
}

; Helper function to create code block structure
CreateCodeBlock() {
    ; SendText sends raw characters (like `n for newline) which is more reliable than simulating Enter keys.
    ; This avoids triggering "Send" buttons in most chat apps.
    SendText("`n`n``````" . "`n`n" . "``````" . "`n`n")
    SendInput("{Up 3}")
}

; Helper function to create code block and paste content
CreateCodeBlockWithPaste() {
    ; Construct the entire block first, then paste it atomically.
    ; This is much faster and more reliable than sequential SendInput calls.
    content := Trim(A_Clipboard, "`r`n`t ")
    block := "`n`n``````" . "`n" . content . "`n" . "``````" . "`n`n"
    SafePaste(block)
}

; Feature 1: CapsLock + ` creates spaced code block
CapsLock & `::CreateCodeBlock()

; Feature 1: RAlt + ` creates spaced code block  
>*!`::CreateCodeBlock()

; Feature 2: CapsLock + v creates code block and pastes
CapsLock & v::CreateCodeBlockWithPaste()

; Feature 2: RAlt + v creates code block and pastes
>*!v::CreateCodeBlockWithPaste()

; ============================================
; New Feature: Remote-only Right Ctrl -> Windows key
; ============================================
; When connected via RDP (e.g. through Guacamole), the ChromeOS Launcher key
; never reaches Windows. Workaround: press Right Ctrl on the Chromebook (which
; ChromeOS does NOT intercept); it arrives here as Right Ctrl, and we remap it
; to LWin -- but ONLY while this is a remote session, so local use is untouched.
;
; IsRemote() is checked on every keypress, so the remap auto-disables the moment
; you disconnect. No process management or session-event tracking needed.
;
; NOTE: SM_REMOTESESSION (0x1000) returns nonzero inside an RDP session. If you
; ever find it reports 0 in your Guacamole setup, run this once while connected
; to verify before troubleshooting further:
;     MsgBox DllCall("GetSystemMetrics", "Int", 0x1000)

IsRemote() => DllCall("GetSystemMetrics", "Int", 0x1000)  ; SM_REMOTESESSION

#HotIf IsRemote()
RCtrl::LWin
#HotIf

; ============================================
; New Feature: Mouse Control Layer (Tab held = momentary modifier)
; ============================================
; Hold Tab and drive the mouse with your right hand:
;   Tab + i / j / k / l  -> move cursor up / left / down / right (accelerates)
;   Tab + u              -> left  button: tap = click, hold = press-and-drag
;   Tab + o              -> right button: tap = click, hold = press-and-drag
;
; Design notes:
;   - Tab is swallowed on press and re-sent on release ONLY if it was tapped
;     without driving the layer, so a solo Tab still types Tab everywhere.
;   - Momentary layer: release Tab and you are instantly back to normal. The
;     movement timer also self-stops the moment Tab is physically up, which
;     doubles as a safety net so a held mouse button can never get stuck down.
;   - The whole layer is gated behind NoModsHeld(), so Alt+Tab / Ctrl+Tab /
;     Shift+Tab / Win+Tab all keep their native behaviour.
;
; Trade-off: holding Tab to auto-repeat Tab no longer works (hold = mouse
; mode). Tap Tab several times instead.

; --- Tunables (tweak to taste) ---
MOUSE_TICK_MS := 10     ; cursor update interval in ms; lower = smoother
MOUSE_MIN_SPD := 1.5    ; starting speed in px per tick
MOUSE_MAX_SPD := 30     ; top speed in px per tick
MOUSE_ACCEL   := 1.07   ; speed multiplier applied each tick while moving

; Scrolling is discrete: one {WheelUp}/{WheelDown} is a single wheel notch
; (~3 lines in most apps). We accumulate fractional notches per tick and only
; emit a whole notch once the accumulator reaches 1, which gives smooth,
; accelerating scroll speed without flooding the app with notches.
; The first notch fires immediately on key-down (no accumulation delay); these
; only govern the repeat rate while you keep holding.
SCROLL_MIN_SPD := 0.10   ; starting notches per tick  (~10 notches/sec)
SCROLL_MAX_SPD := 0.40   ; top notches per tick       (~40 notches/sec)
SCROLL_ACCEL   := 1.05   ; speed multiplier applied each tick while scrolling

mouseCurSpd    := MOUSE_MIN_SPD
scrollCurSpd   := SCROLL_MIN_SPD
scrollAccum    := 0.0     ; fractional notches carried between ticks
scrolling      := false   ; were we already scrolling last tick?
tabLayerActive := false   ; guards StartMouseLayer against Tab key-repeat
tabUsed        := false   ; did this Tab press drive the mouse layer?
lbtnDown       := false   ; is the left  button currently held down by us?
rbtnDown       := false   ; is the right button currently held down by us?

; True only when none of Ctrl / Alt / Shift / Win are physically down, so that
; modifier+Tab combos pass straight through to Windows.
NoModsHeld() => !(GetKeyState("Ctrl", "P") || GetKeyState("Alt", "P")
    || GetKeyState("Shift", "P") || GetKeyState("LWin", "P") || GetKeyState("RWin", "P"))

StartMouseLayer() {
    global tabLayerActive, tabUsed, mouseCurSpd, scrollCurSpd, scrollAccum, scrolling
    if tabLayerActive          ; ignore auto-repeat while Tab is held down
        return
    tabLayerActive := true
    tabUsed := false
    mouseCurSpd := MOUSE_MIN_SPD
    scrollCurSpd := SCROLL_MIN_SPD
    scrollAccum := 0.0
    scrolling := false
    SetTimer(MouseTick, MOUSE_TICK_MS)
}

EndMouseLayer() {
    global tabLayerActive, tabUsed, mouseCurSpd
    SetTimer(MouseTick, 0)
    ReleaseMouseButtons()
    mouseCurSpd := MOUSE_MIN_SPD
    tabLayerActive := false
    if !tabUsed                ; Tab was tapped on its own -> emit a real Tab
        SendInput("{Tab}")
}

ReleaseMouseButtons() {
    global lbtnDown, rbtnDown
    if lbtnDown {
        SendInput("{LButton Up}")
        lbtnDown := false
    }
    if rbtnDown {
        SendInput("{RButton Up}")
        rbtnDown := false
    }
}

; Press (and keep holding) a mouse button. Guarded so Tab+key auto-repeat does
; not emit a stream of Down events.
PressMouseBtn(which) {
    global lbtnDown, rbtnDown, tabUsed
    tabUsed := true
    if (which = "Left" && !lbtnDown) {
        SendInput("{LButton Down}")
        lbtnDown := true
    } else if (which = "Right" && !rbtnDown) {
        SendInput("{RButton Down}")
        rbtnDown := true
    }
}

ReleaseMouseBtn(which) {
    global lbtnDown, rbtnDown
    if (which = "Left" && lbtnDown) {
        SendInput("{LButton Up}")
        lbtnDown := false
    } else if (which = "Right" && rbtnDown) {
        SendInput("{RButton Up}")
        rbtnDown := false
    }
}

; Polls physical keys each tick so movement (diagonals + acceleration) and
; scrolling stay smooth regardless of key-repeat timing. Movement and scroll
; are handled independently so you can do either, both, or neither per tick.
MouseTick(*) {
    global mouseCurSpd, scrollCurSpd, scrollAccum, scrolling, tabUsed
    if !GetKeyState("Tab", "P") {       ; safety net: Tab no longer held
        SetTimer(MouseTick, 0)
        ReleaseMouseButtons()
        mouseCurSpd := MOUSE_MIN_SPD
        scrollCurSpd := SCROLL_MIN_SPD
        scrollAccum := 0.0
        scrolling := false
        return
    }

    ; --- cursor movement (i/j/k/l) ---
    dx := 0, dy := 0
    if GetKeyState("i", "P")
        dy -= 1
    if GetKeyState("k", "P")
        dy += 1
    if GetKeyState("j", "P")
        dx -= 1
    if GetKeyState("l", "P")
        dx += 1
    if (dx != 0 || dy != 0) {
        tabUsed := true
        mouseCurSpd := Min(mouseCurSpd * MOUSE_ACCEL, MOUSE_MAX_SPD)
        if (dx != 0 && dy != 0) {       ; keep diagonals the same speed
            dx *= 0.7071
            dy *= 0.7071
        }
        moveX := Round(dx * mouseCurSpd)
        moveY := Round(dy * mouseCurSpd)
        if (moveX != 0 || moveY != 0)
            MouseMove(moveX, moveY, 0, "R")
    } else {
        mouseCurSpd := MOUSE_MIN_SPD    ; reset acceleration when idle
    }

    ; --- scroll wheel (p = up, ; = down) ---
    sdir := 0
    if GetKeyState("p", "P")
        sdir += 1
    if GetKeyState(";", "P")            ; semicolon key
        sdir -= 1
    if (sdir != 0) {
        tabUsed := true
        if !scrolling {                  ; just started -> notch immediately
            scrolling := true
            scrollAccum += 1
        }
        scrollCurSpd := Min(scrollCurSpd * SCROLL_ACCEL, SCROLL_MAX_SPD)
        scrollAccum += scrollCurSpd
        while (scrollAccum >= 1) {       ; emit whole notches only
            SendInput(sdir > 0 ? "{WheelUp}" : "{WheelDown}")
            scrollAccum -= 1
        }
    } else {
        scrolling := false
        scrollCurSpd := SCROLL_MIN_SPD
        scrollAccum := 0.0
    }
}

; Tab itself: arm the layer on press, disarm (and maybe emit Tab) on release.
#HotIf NoModsHeld()
Tab::StartMouseLayer()
Tab up::EndMouseLayer()
#HotIf

; While Tab is physically held (and no modifier), the right-hand keys drive the
; mouse instead of typing: i/j/k/l are swallowed (the timer reads them), while
; u/o press and release the buttons so both tap-to-click and hold-to-drag work.
#HotIf GetKeyState("Tab", "P") && NoModsHeld()
i::return
j::return
k::return
l::return
p::return    ; scroll up   (handled by the timer)
`;::return   ; scroll down (handled by the timer)
u::PressMouseBtn("Left")
u up::ReleaseMouseBtn("Left")
o::PressMouseBtn("Right")
o up::ReleaseMouseBtn("Right")
#HotIf
