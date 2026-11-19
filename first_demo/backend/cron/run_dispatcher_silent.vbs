' =========================================================================
' Hungrily Foods - Silent Background Dispatcher Runner for Windows Task Scheduler
' =========================================================================
' Executes run_dispatcher_windows.bat with window style 0 (completely hidden)
' so no console window flashes on developer / admin screen every minute.
' =========================================================================

Set WshShell = CreateObject("WScript.Shell")
Set FSO = CreateObject("Scripting.FileSystemObject")
ScriptDir = FSO.GetParentFolderName(WScript.ScriptFullName)
BatPath = ScriptDir & "\run_dispatcher_windows.bat"

WshShell.Run """" & BatPath & """", 0, False
Set WshShell = Nothing
Set FSO = Nothing
