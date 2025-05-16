#Requires AutoHotkey v2.0

; ============================================
; Shared Function for Arrow Key with Modifiers
; ============================================
; Handles sending keys with any held modifier keys (Ctrl, Shift, Alt)
; Parameters:
;   key: The key to send (e.g., "Up", "Down", "Left", "Right", "Home", etc.)
;   isRAltTrigger: Boolean indicating if triggered by Right Alt key (special handling for Alt)
SendKeyWithModifiers(key, isRAltTrigger := false) {
    local tempMods := ""
    
    ; Check for held modifier keys
    if GetKeyState("Control", "P")  ; Check physical state of Ctrl
        tempMods .= "^"
    if GetKeyState("Shift", "P")    ; Check physical state of Shift
        tempMods .= "+"
    
    ; Special handling for Alt key based on the trigger type
    if (isRAltTrigger) {
        ; For RAlt triggers, only include LAlt in modifiers (to avoid RAlt conflict)
        if GetKeyState("LAlt", "P")
            tempMods .= "!"
    } else {
        ; For CapsLock triggers, include any Alt key
        if GetKeyState("Alt", "P")
            tempMods .= "!"
    }
    
    ; Send the key combination with any held modifiers
    ; Using SendInput for reliability and consistency
    SendInput(tempMods . "{" . key . "}")
}

; ============================================
; CapsLock Configuration
; ============================================
; CapsLock is used as a modifier key when combined with other keys
; When pressed alone, it functions as a normal Caps Lock toggle (handled by Windows)
; When used with other keys, it triggers the hotkeys below
CapsLock & i::SendKeyWithModifiers("Up")      ; Move cursor up
CapsLock & k::SendKeyWithModifiers("Down")    ; Move cursor down
CapsLock & j::SendKeyWithModifiers("Left")    ; Move cursor left
CapsLock & l::SendKeyWithModifiers("Right")   ; Move cursor right
CapsLock & u::SendKeyWithModifiers("Home")    ; Move to start of line
CapsLock & o::SendKeyWithModifiers("End")     ; Move to end of line
CapsLock & p::SendKeyWithModifiers("Backspace") ; Delete previous character
CapsLock & `;::SendKeyWithModifiers("Delete")   ; Delete next character (semicolon key)

; ============================================
; Right Alt (AltGr) Configuration
; ============================================
; Right Alt (AltGr) is used as an alternative modifier key
; The * prefix allows other modifiers (Ctrl, Shift, LAlt) to be held down simultaneously
; The > prefix specifies the right Alt key specifically
; The ! symbol represents the Alt key in AHK
*>!i::SendKeyWithModifiers("Up", true)       ; Move cursor up
*>!k::SendKeyWithModifiers("Down", true)     ; Move cursor down
*>!j::SendKeyWithModifiers("Left", true)     ; Move cursor left
*>!l::SendKeyWithModifiers("Right", true)    ; Move cursor right
*>!u::SendKeyWithModifiers("Home", true)     ; Move to start of line
*>!o::SendKeyWithModifiers("End", true)      ; Move to end of line
*>!p::SendKeyWithModifiers("Backspace", true) ; Delete previous character
*>!;::SendKeyWithModifiers("Delete", true)    ; Delete next character (semicolon key)

