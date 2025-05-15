#Requires AutoHotkey v2.0

; Remap CapsLock to act as a modifier key
#HotIf true
CapsLock::return
#HotIf

SendArrowWithHeldModifiers(arrowKey) {
    local tempMods := ""
    if GetKeyState("Control", "P")  ; Check physical state of Ctrl
        tempMods .= "^"
    if GetKeyState("Shift", "P")    ; Check physical state of Shift
        tempMods .= "+"
    if GetKeyState("Alt", "P")     ; Check physical state of Alt
        tempMods .= "!"
    
    ; SendInput is generally more reliable for sending keystrokes.
    SendInput(tempMods . "{" . arrowKey . "}")
}

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
CapsLock & SC027::SendArrowWithHeldModifiers("Delete")  ; SC027 is the semicolon key