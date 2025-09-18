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

; Helper function to create code block structure
CreateCodeBlock() {
    ; Send two newlines, three backticks, two newlines, three backticks, two newlines, then three up arrows
    ; Using Shift+Enter for newlines to avoid triggering send/submit actions
    SendInput("+{Enter}+{Enter}``````+{Enter}+{Enter}``````+{Enter}+{Enter}{Up}{Up}{Up}")
}

; Helper function to create code block and paste content
CreateCodeBlockWithPaste() {
    ; Two newlines, three backticks, newline, paste content, newline, three backticks, two newlines
    SendInput("+{Enter}+{Enter}``````+{Enter}^v+{Enter}``````+{Enter}+{Enter}")
}

; Feature 1: CapsLock + ` creates spaced code block
CapsLock & `::CreateCodeBlock()

; Feature 1: RAlt + ` creates spaced code block  
>*!`::CreateCodeBlock()

; Feature 2: CapsLock + v creates code block and pastes
CapsLock & v::CreateCodeBlockWithPaste()

; Feature 2: RAlt + v creates code block and pastes
>*!v::CreateCodeBlockWithPaste()