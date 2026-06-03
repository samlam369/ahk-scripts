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
; Hold Tab and drive the mouse:
;   Tab + i / j / k / l  -> move cursor up / left / down / right (accelerates)
;   Tab + p / ;          -> scroll up / down (accelerates)
;   Tab + u  or  f       -> left   button: tap = click, hold = press-and-drag
;   Tab + o  or  d       -> right  button: tap = click, hold = press-and-drag
;   Tab + s              -> middle button: tap = click, hold = press-and-drag
; (u/o/p/; are the right-hand keys; f/d/s let the left hand click while the
;  right hand moves, which makes click-and-drag much more comfortable.)
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
lbtnDown       := false   ; is the left   button currently held down by us?
rbtnDown       := false   ; is the right  button currently held down by us?
mbtnDown       := false   ; is the middle button currently held down by us?
mouseToggleMode := false  ; m-toggle entry (CapsLock or RAlt): in mouse mode now?
mKeyDown        := false  ; guards the m toggle against auto-repeat

; The mouse-mode ToolTip follows the cursor, so work in screen coordinates.
CoordMode("Mouse", "Screen")
CoordMode("ToolTip", "Screen")

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

; Second entry point: while holding CapsLock OR RAlt, tap m to toggle mouse mode
; on/off. Mode lasts only for the current modifier hold (MouseTick clears it the
; moment both CapsLock and RAlt are released). Turning off just lets MouseTick
; self-stop on the next tick.
ToggleMouseMode() {
    global mouseToggleMode, mouseCurSpd, scrollCurSpd, scrollAccum, scrolling
    mouseToggleMode := !mouseToggleMode
    if mouseToggleMode {
        mouseCurSpd := MOUSE_MIN_SPD
        scrollCurSpd := SCROLL_MIN_SPD
        scrollAccum := 0.0
        scrolling := false
        SetTimer(MouseTick, MOUSE_TICK_MS)
    }
}

; Guarded m-tap toggle, shared by the CapsLock and RAlt entry hotkeys; mKeyDown
; stops auto-repeat from flickering the mode while m is held.
GuardedToggle() {
    global mKeyDown
    if mKeyDown
        return
    mKeyDown := true
    ToggleMouseMode()
}
ReleaseMKey() {
    global mKeyDown
    mKeyDown := false
}

; True while either toggle-modifier is physically held, i.e. the mouse mode is
; still being "held open" after an m-tap entry.
ToggleModHeld() => GetKeyState("CapsLock", "P") || GetKeyState("RAlt", "P")

; Send a mouse action (click / wheel) with RAlt momentarily neutralised, so apps
; never see Alt+Click / Alt+Wheel while in RAlt mouse mode. Done as one atomic
; SendInput so the {RAlt up}..{RAlt down} window can't let the >*! overrides drop
; out. {Blind} leaves any other held modifiers (Shift/Ctrl/Win) untouched. When
; RAlt isn't physically held (Tab / CapsLock modes) it just sends directly.
SendUnmodified(action) {
    if GetKeyState("RAlt", "P")
        SendInput("{Blind}{RAlt up}" action "{RAlt down}")
    else
        SendInput(action)
}

ReleaseMouseButtons() {
    global lbtnDown, rbtnDown, mbtnDown
    if lbtnDown {
        SendUnmodified("{LButton Up}")
        lbtnDown := false
    }
    if rbtnDown {
        SendUnmodified("{RButton Up}")
        rbtnDown := false
    }
    if mbtnDown {
        SendUnmodified("{MButton Up}")
        mbtnDown := false
    }
}

; Press (and keep holding) a mouse button. Guarded so key auto-repeat does not
; emit a stream of Down events.
PressMouseBtn(which) {
    global lbtnDown, rbtnDown, mbtnDown, tabUsed
    tabUsed := true
    if (which = "Left" && !lbtnDown) {
        SendUnmodified("{LButton Down}")
        lbtnDown := true
    } else if (which = "Right" && !rbtnDown) {
        SendUnmodified("{RButton Down}")
        rbtnDown := true
    } else if (which = "Middle" && !mbtnDown) {
        SendUnmodified("{MButton Down}")
        mbtnDown := true
    }
}

ReleaseMouseBtn(which) {
    global lbtnDown, rbtnDown, mbtnDown
    if (which = "Left" && lbtnDown) {
        SendUnmodified("{LButton Up}")
        lbtnDown := false
    } else if (which = "Middle" && mbtnDown) {
        SendUnmodified("{MButton Up}")
        mbtnDown := false
    } else if (which = "Right" && rbtnDown) {
        SendUnmodified("{RButton Up}")
        rbtnDown := false
    }
}

; Polls physical keys each tick so movement (diagonals + acceleration) and
; scrolling stay smooth regardless of key-repeat timing. Movement and scroll
; are handled independently so you can do either, both, or neither per tick.
MouseTick(*) {
    global mouseCurSpd, scrollCurSpd, scrollAccum, scrolling, tabUsed, mouseToggleMode, lbtnDown, rbtnDown, mbtnDown
    ; The layer is live while EITHER entry method holds it open: Tab physically
    ; down, OR mouse mode toggled on AND a toggle-modifier (CapsLock/RAlt) still
    ; physically held. Releasing the modifier therefore exits mouse mode.
    if !(GetKeyState("Tab", "P") || (mouseToggleMode && ToggleModHeld())) {
        SetTimer(MouseTick, 0)
        ReleaseMouseButtons()
        mouseToggleMode := false
        ToolTip()                       ; clear the mouse-mode indicator
        mouseCurSpd := MOUSE_MIN_SPD
        scrollCurSpd := SCROLL_MIN_SPD
        scrollAccum := 0.0
        scrolling := false
        return
    }

    ; Show a cursor-following indicator only for the (stateful) toggle mode.
    if mouseToggleMode {
        MouseGetPos(&tipX, &tipY)
        ToolTip("🖱 MOUSE", tipX + 32, tipY + 32)
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
        sdir -= 1
    if GetKeyState(";", "P")            ; semicolon key
        sdir += 1
    if (sdir != 0) {
        tabUsed := true
        if !scrolling {                  ; just started -> notch immediately
            scrolling := true
            scrollAccum += 1
        }
        scrollCurSpd := Min(scrollCurSpd * SCROLL_ACCEL, SCROLL_MAX_SPD)
        scrollAccum += scrollCurSpd
        notches := ""                    ; batch whole notches into one send
        while (scrollAccum >= 1) {
            notches .= (sdir > 0 ? "{WheelUp}" : "{WheelDown}")
            scrollAccum -= 1
        }
        if (notches != "")
            SendUnmodified(notches)
    } else {
        scrolling := false
        scrollCurSpd := SCROLL_MIN_SPD
        scrollAccum := 0.0
    }

    ; --- release held buttons once their key(s) are let go (ends a drag) ---
    ; The button DOWN is triggered instantly by the per-mode hotkeys; release is
    ; polled here from the physical key state because CapsLock custom-combination
    ; "up" events fire early while the suffix auto-repeats, which would otherwise
    ; drop the button mid-drag. Polling is reliable for every entry method.
    ; Each button has a right-hand key and a left-hand key; release only once
    ; neither is held (so you can even hand off a drag between hands).
    if (lbtnDown && !GetKeyState("u", "P") && !GetKeyState("f", "P"))
        ReleaseMouseBtn("Left")
    if (rbtnDown && !GetKeyState("o", "P") && !GetKeyState("d", "P"))
        ReleaseMouseBtn("Right")
    if (mbtnDown && !GetKeyState("s", "P"))
        ReleaseMouseBtn("Middle")
}

; Tab itself: arm the layer on press, disarm (and maybe emit Tab) on release.
#HotIf NoModsHeld()
Tab::StartMouseLayer()
Tab up::EndMouseLayer()
#HotIf

; While Tab is physically held (and no modifier), these keys drive the mouse
; instead of typing: i/j/k/l are swallowed (the timer reads them for movement).
; Buttons can be clicked with either hand -- right hand: u = left, o = right;
; left hand: f = left, d = right, s = middle. Each press fires on key-down; the
; timer releases on key-up, so tap-to-click and hold-to-drag both work, and the
; left/right-hand split makes dragging (hold button one hand, move the other)
; comfortable.
#HotIf GetKeyState("Tab", "P") && NoModsHeld()
i::return
j::return
k::return
l::return
p::return    ; scroll up   (handled by the timer)
`;::return   ; scroll down (handled by the timer)
u::PressMouseBtn("Left")
o::PressMouseBtn("Right")
f::PressMouseBtn("Left")
d::PressMouseBtn("Right")
s::PressMouseBtn("Middle")
#HotIf

; ============================================
; Alternative entry: CapsLock or RAlt + m toggles mouse mode (no reach for Tab)
; ============================================
; Tap m while holding CapsLock OR RAlt to enter/exit mouse mode. While in mouse
; mode, the usual CapsLock/RAlt + ijkluop; mappings are overridden to drive the
; mouse; tap m again (or release the modifier) to leave. This block is fully
; self-contained, so either entry method can be deleted later without touching
; the other.
;
; How the override works: the modifier+key mappings created in RegisterHotkeys
; have no #HotIf criterion, so AHK treats them as the lowest-priority fallback.
; The #HotIf mouseToggleMode variants below therefore win whenever mouse mode is
; on, and fall back to the normal arrow/Home/End behaviour when it is off.
;
; NOTE: RAlt is a real Alt key, so it stays physically down during mouse mode.
; To stop apps seeing Alt+Click / Alt+Wheel (e.g. a browser treating Alt+Click
; on a link as "download"), every click/scroll is sent via SendUnmodified(),
; which momentarily lifts RAlt for the action only. Movement needs no such care.

; The toggle must work in BOTH states, so these stay global (no #HotIf).
CapsLock & m::GuardedToggle()
CapsLock & m up::ReleaseMKey()
>*!m::GuardedToggle()
>*!m up::ReleaseMKey()

#HotIf mouseToggleMode
; --- CapsLock variants (override the arrow/Home/End/etc. mappings) ---
CapsLock & i::return
CapsLock & j::return
CapsLock & k::return
CapsLock & l::return
CapsLock & p::return    ; scroll up   (handled by the timer)
CapsLock & `;::return   ; scroll down (handled by the timer)
CapsLock & u::PressMouseBtn("Left")
CapsLock & o::PressMouseBtn("Right")
CapsLock & f::PressMouseBtn("Left")
CapsLock & d::PressMouseBtn("Right")
CapsLock & s::PressMouseBtn("Middle")
; --- RAlt variants (same overrides, RAlt hotkey syntax) ---
>*!i::return
>*!j::return
>*!k::return
>*!l::return
>*!p::return            ; scroll up   (handled by the timer)
>*!`;::return           ; scroll down (handled by the timer)
>*!u::PressMouseBtn("Left")
>*!o::PressMouseBtn("Right")
>*!f::PressMouseBtn("Left")
>*!d::PressMouseBtn("Right")
>*!s::PressMouseBtn("Middle")
#HotIf
