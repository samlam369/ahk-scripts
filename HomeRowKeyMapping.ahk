#Requires AutoHotkey v2.0

; ============================================
; CapsLock Configuration
; ============================================
; CapsLock is used as a modifier key when combined with other keys
; When pressed alone, it functions as a normal Caps Lock toggle (handled by Windows)
; When used with other keys, it triggers the hotkeys below
; {Blind} preserves the state of modifier keys (Ctrl, Shift, Alt)
CapsLock &  i::SendInput "{Blind}{Up}"
CapsLock &  k::SendInput "{Blind}{Down}"
CapsLock &  j::SendInput "{Blind}{Left}"
CapsLock &  l::SendInput "{Blind}{Right}"
CapsLock &  u::SendInput "{Blind}{Home}"
CapsLock &  o::SendInput "{Blind}{End}"
CapsLock &  p::SendInput "{Blind}{Backspace}"
CapsLock & `;::SendInput "{Blind}{Delete}"

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
    SendInput mods "{" key "}"
}

; ============================================
; Right Alt (AltGr) Configuration
; ============================================
; Right Alt (AltGr) is used as an alternative modifier key
; The * prefix allows other modifiers (Ctrl, Shift, LAlt) to be held down simultaneously
; The > prefix specifies the right Alt key specifically
*>!i::SendKeyWithMods("Up")
*>!k::SendKeyWithMods("Down")
*>!j::SendKeyWithMods("Left")
*>!l::SendKeyWithMods("Right")
*>!u::SendKeyWithMods("Home")
*>!o::SendKeyWithMods("End")
*>!p::SendKeyWithMods("Backspace")
*>!;::SendKeyWithMods("Delete")