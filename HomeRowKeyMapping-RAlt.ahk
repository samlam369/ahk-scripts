#Requires AutoHotkey v2.0

SendArrowWithHeldModifiers(arrowKey) {
    local tempMods := ""
    if GetKeyState("Control", "P")  ; Check physical state of Ctrl
        tempMods .= "^"
    if GetKeyState("Shift", "P")    ; Check physical state of Shift
        tempMods .= "+"
    if GetKeyState("LAlt", "P")     ; Check physical state of LAlt (as RAlt is the trigger)
        tempMods .= "!"
    
    ; SendInput is generally more reliable for sending keystrokes.
    SendInput(tempMods . "{" . arrowKey . "}")
}

; Use RAlt (>) as the main modifier for the hotkeys.
; Use wildcard (*) to allow other modifiers (Ctrl, Shift, LAlt) to be physically held down
; at the same time. The SendArrowWithHeldModifiers function will then include them.

*>!i::SendArrowWithHeldModifiers("Up")
*>!k::SendArrowWithHeldModifiers("Down")
*>!j::SendArrowWithHeldModifiers("Left")
*>!l::SendArrowWithHeldModifiers("Right")
*>!u::SendArrowWithHeldModifiers("Home")
*>!o::SendArrowWithHeldModifiers("End")
*>!p::SendArrowWithHeldModifiers("Backspace")
*>!;::SendArrowWithHeldModifiers("Delete")
