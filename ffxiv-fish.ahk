#NoEnv
SetBatchLines, -1
SetWorkingDir, %A_AppData%\Advanced Combat Tracker\FFXIVLogs

; Requires ACT
;
; To use:
; Set coords according to your monitor
;	3rd person camera angle = 50
;	Adjust camera to look straight down, zoom in all the way (Not first person)
;	The "!" will appear roughly right on top your head, slightly in front (do a fish or two to get it)
;	Start -> AutoHotKey -> Window Spy
;	Make sure FFXIV is in focus and note X,Y coords for Top Left and Bottom Right search box.
;	Set the variables below accordingly: TopX, TopY, BotX, BotY
; Set bite color:
;	Using Window Spy hover the "!" when it appears to get the color. Aim for the pure white section.
;	Or use GSHade screenshot and get color from screenshot.
; Set keybinds: Hook, Cast

; Coords to search for Fishing "!"
global TopX := 1670
global TopY := 740
global BotX := 1700
global BotY := 760

; Keybinds
global cast_key := "c"
global hook_key := "1"

; ! Color (could be modded by GShade)
global bite_color := 0xF3F8FB

; Get current log file
Array := []
loop, Files, *.log
Array.Push(A_LoopFileName)
global log_file := Array[Array.Length()]

; Setup timers
global last_cast := A_Now
global caught := 1

; Main loop
Loop {
    land("You land a", cast_key)
    bite(hook_key)
}

; Look for catch and then cast
land(str, key)
{
    Loop {
        if (caught == 1)
        {
            loop, Parse, % Tail(3, log_file), `n
            {
                if InStr(A_LoopField, str) {
					line := StrSplit(A_LoopField, "|")
					line := StrSplit(line[2], ".")
					line := StrReplace(line[1], "T")
					line := StrReplace(line, "-")
					line := StrReplace(line, ":")
					;MsgBox, %last_cast% , %line%
                    if (last_cast < line)
                    {
                        last_cast := line
                        rndSleep(1750, 2500)
                        if WinActive("FINAL FANTASY XIV") {
                            SendInput % key
                        } else {
                            WinActivate, FINAL FANTASY XIV
                            SendInput % key
                        }
                        caught := 0
                        Sleep 3000
                        break
                    }
                }
            }
        } else {
            break
        }
        Sleep 500
    }
}

; Watch for "!" of the bite indicater and reel
bite(key)
{
	counter := 0
	Loop {
		; Break loop if caught
		if (caught == 1)
			break
		PixelSearch, Px, Py, %TopX%, %TopY%, %BotX%, %BotY%, %bite_color%, 3, Fast RGB
		if ErrorLevel
		{
			counter += 1
		} else {
			rndSleep(750, 1500)
			if WinActive("FINAL FANTASY XIV") {
				SendInput % key
			} else {
				WinActivate, FINAL FANTASY XIV
				SendInput % key
			}
			caught := 1
			Sleep 2000
			break
		}
        if(counter > 200) {
			caught := 1
			MsgBox, Search stopped
			break
		}
		Sleep 100
    }
}

; Random generator
rndSleep(min, max)
{
    Random, sleeptime, min, max
    Sleep, sleeptime
}

; Get last n lines of file
; Filter chat event 0843
Tail(k, file)   ; Return the last k lines of file
{
    Loop Read, %file%
    {
		i := Mod(A_Index, k)
		line := StrSplit(A_LoopReadLine, "|")
		if InStr(line[3], "0843")
			L%i% = %A_LoopReadLine%
	}
    L := L%i%
    Loop % k-1
    {
        IfLess i, 1, SetEnv i, %k%
        i--      ; Mod does not work here
        L := L%i% "`n" L
    }
    Return L
}
