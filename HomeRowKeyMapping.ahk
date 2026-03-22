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
    content := A_Clipboard
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