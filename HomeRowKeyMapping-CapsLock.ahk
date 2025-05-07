#Requires AutoHotkey v2.0+

SetCapsLockState("AlwaysOff")

; CapsLock:: {
;     static start := 0 ; Initialize start time
;     if (A_PriorKey = "CapsLock" && A_TimeSincePriorHotkey < 400 && A_TimeSinceThisHotkey > 50) { ; Double-tap
;         SetCapsLockState(!GetKeyState("CapsLock", "T"))
;         start := 0 ; Reset start time
;         return
;     }
;     start := A_TickCount
;     KeyWait("CapsLock")
;     ; If it wasn't a double-tap, it's a modifier press.
;     ; The *CapsLock::Return handles the modifier behavior.
; }

*CapsLock::Return ; Makes CapsLock act as a modifier and suppresses its native function when held

#HotIf GetKeyState("CapsLock", "P") ; True if CapsLock is being physically held down

    ; Standard navigation with CapsLock
    i::Send "{Up}"
    j::Send "{Left}"
    k::Send "{Down}"
    l::Send "{Right}"
    ; u::Send "{Home}"
    ; o::Send "{End}"

#HotIf ; Turns off context-sensitive hotkeys
