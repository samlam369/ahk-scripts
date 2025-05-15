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
; Remap CapsLock to act as a modifier key
#HotIf true
CapsLock::return
#HotIf

; Use CapsLock as the main modifier for the hotkeys.
; Use wildcard (*) to allow other modifiers (Ctrl, Shift, Alt) to be physically held down
; at the same time. The SendArrowWithHeldModifiers function will then include them.
CapsLock & i::SendArrowWithHeldModifiers("Up")
CapsLock & k::SendArrowWithHeldModifiers("Down")
CapsLock & j::SendArrowWithHeldModifiers("Left")
CapsLock & l::SendArrowWithHeldModifiers("Right")
CapsLock & u::SendArrowWithHeldModifiers("Home")
CapsLock & o::SendArrowWithHeldModifiers("End")
CapsLock & p::SendArrowWithHeldModifiers("Backspace")
CapsLock & `;::SendArrowWithHeldModifiers("Delete")  ; Semicolon key

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

