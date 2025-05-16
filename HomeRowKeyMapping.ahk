#Requires AutoHotkey v2.0

; ============================================
; Shared Function for Arrow Key with Modifiers
; ============================================
SendArrowWithHeldModifiers(arrowKey, isRAltTrigger := false) {
    local tempMods := ""
    if GetKeyState("Control", "P")  ; Check physical state of Ctrl
        tempMods .= "^"
    if GetKeyState("Shift", "P")    ; Check physical state of Shift
        tempMods .= "+"
    
    ; Special handling for Alt key based on the trigger type
    if (isRAltTrigger) {
        ; For RAlt triggers, only include LAlt in modifiers
        if GetKeyState("LAlt", "P")
            tempMods .= "!"
    } else {
        ; For CapsLock triggers, include any Alt key
        if GetKeyState("Alt", "P")
            tempMods .= "!"
    }
    
    ; SendInput is generally more reliable for sending keystrokes.
    SendInput(tempMods . "{" . arrowKey . "}")
}

; ============================================
; CapsLock Configuration
; ============================================
global is_modifier_used := false
global caps_down_time := 0

; --- Logic for CapsLock tap-toggle and modifier behavior ---
*CapsLock:: {
    caps_down_time := A_TickCount
    is_modifier_used := false ; Reset flag at the beginning of a potential combo
}

CapsLock Up:: {
    Critical ; Ensures this routine completes without interruption
    If (!is_modifier_used)
    {
        ; Check if it was a short press (tap)
        If (A_TickCount - caps_down_time < 200) ; 200ms threshold for tap, adjust if needed
        {
            SetCapsLockState
        }
    }
    ; is_modifier_used is reset by the next *CapsLock (down) press.
}
; --- End of CapsLock tap-toggle logic ---

; Remap CapsLock to act as a modifier key
#HotIf true
CapsLock::return
#HotIf

; Use CapsLock as the main modifier for the hotkeys.
; Use wildcard (*) to allow other modifiers (Ctrl, Shift, Alt) to be physically held down
; at the same time. The SendArrowWithHeldModifiers function will then include them.
CapsLock & i:: {
    Critical
    is_modifier_used := true
    SendArrowWithHeldModifiers("Up")
}
CapsLock & k:: {
    Critical
    is_modifier_used := true
    SendArrowWithHeldModifiers("Down")
}
CapsLock & j:: {
    Critical
    is_modifier_used := true
    SendArrowWithHeldModifiers("Left")
}
CapsLock & l:: {
    Critical
    is_modifier_used := true
    SendArrowWithHeldModifiers("Right")
}
CapsLock & u:: {
    Critical
    is_modifier_used := true
    SendArrowWithHeldModifiers("Home")
}
CapsLock & o:: {
    Critical
    is_modifier_used := true
    SendArrowWithHeldModifiers("End")
}
CapsLock & p:: {
    Critical
    is_modifier_used := true
    SendArrowWithHeldModifiers("Backspace")
}
CapsLock & `;:: { ; Semicolon key
    Critical
    is_modifier_used := true
    SendArrowWithHeldModifiers("Delete")
}

; ============================================
; RAlt Configuration
; ============================================
; Use RAlt (>) as the main modifier for the hotkeys.
; Use wildcard (*) to allow other modifiers (Ctrl, Shift, LAlt) to be physically held down
; at the same time. The SendArrowWithHeldModifiers function will then include them.
*>!i::SendArrowWithHeldModifiers("Up", true)
*>!k::SendArrowWithHeldModifiers("Down", true)
*>!j::SendArrowWithHeldModifiers("Left", true)
*>!l::SendArrowWithHeldModifiers("Right", true)
*>!u::SendArrowWithHeldModifiers("Home", true)
*>!o::SendArrowWithHeldModifiers("End", true)
*>!p::SendArrowWithHeldModifiers("Backspace", true)
*>!;::SendArrowWithHeldModifiers("Delete", true)
