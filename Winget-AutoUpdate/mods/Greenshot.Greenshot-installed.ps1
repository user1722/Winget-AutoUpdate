# Greenshot-Pfad ermitteln
$greenshotPath = "$env:ProgramFiles\Greenshot\Greenshot.exe"
if (-not (Test-Path $greenshotPath)) {
    $greenshotPath = "${env:ProgramFiles(x86)}\Greenshot\Greenshot.exe"
}

# Nur fortfahren, wenn Greenshot.exe gefunden wurde
if (Test-Path $greenshotPath) {

    # WScriptShell-Objekt für Shortcuts
    $WScriptShell = New-Object -ComObject WScript.Shell

    # Angemeldeten Benutzer ermitteln
    $loggedInUser = (Get-WmiObject -Class Win32_ComputerSystem).UserName
    if (-not $loggedInUser) {
        Write-Output "Kein Benutzer angemeldet. Abbruch."
        return
    }

    # Benutzername extrahieren (Domain\Benutzername → Benutzername)
    $username = ($loggedInUser -split '\\')[-1]
    $userProfile = Join-Path -Path "C:\Users" -ChildPath $username

    # Pfade manuell zusammensetzen
    $startupFolder = Join-Path -Path $userProfile -ChildPath "AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup"
    $programsFolder = Join-Path -Path $userProfile -ChildPath "AppData\Roaming\Microsoft\Windows\Start Menu\Programs"

    # Debug-Ausgaben
    Write-Output "Benutzer: $loggedInUser"
    Write-Output "Benutzerprofil: $userProfile"
    Write-Output "Startup-Verzeichnis: $startupFolder"
    Write-Output "Startmenü-Verzeichnis: $programsFolder"

    # 1. Autostart-Link (Benutzer)
    $autostartPath = Join-Path -Path $startupFolder -ChildPath "Greenshot.lnk"
    if (-not (Test-Path $autostartPath)) {
        try {
            $shortcut = $WScriptShell.CreateShortcut($autostartPath)
            $shortcut.TargetPath = $greenshotPath
            $shortcut.WorkingDirectory = Split-Path $greenshotPath
            $shortcut.IconLocation = $greenshotPath
            $shortcut.Save()
            Write-Output "Autostart-Verknüpfung erstellt: $autostartPath"
        } catch {
            Write-Output "Fehler beim Erstellen der Autostart-Verknüpfung: $_"
        }
    }
	
    # 2. Startmenü-Link (Benutzer)
    $startmenuPath = Join-Path -Path $programsFolder -ChildPath "Greenshot.lnk"
    if (-not (Test-Path $startmenuPath)) {
        try {
            $shortcut = $WScriptShell.CreateShortcut($startmenuPath)
            $shortcut.TargetPath = $greenshotPath
            $shortcut.WorkingDirectory = Split-Path $greenshotPath
            $shortcut.IconLocation = $greenshotPath
            $shortcut.Save()
            Write-Output "Startmenü-Verknüpfung erstellt: $startmenuPath"
        } catch {
            Write-Output "Fehler beim Erstellen der Startmenü-Verknüpfung: $_"
        }
    }


 # 3. Im User Context starten
		$serviceUIPath = "C:\ProgramData\Winget-AutoUpdate\ServiceUI.exe"

		if (Test-Path $serviceUIPath) {
			try {
				Start-Process -FilePath $serviceUIPath -ArgumentList "-process:explorer.exe `"$greenshotPath`"" -NoNewWindow
				Write-Output "Greenshot mit ServiceUI im Benutzerkontext gestartet."
			} catch {
				Write-Output "Fehler beim Start mit ServiceUI: $_"
			}
		} else {
			Write-Output "ServiceUI.exe nicht gefunden unter: $serviceUIPath"
		}
	
}
else {
    Write-Output "Greenshot wurde nicht gefunden."
}
