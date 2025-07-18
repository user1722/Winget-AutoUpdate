# Greenshot-Pfad ermitteln
$greenshotPath = "${env:ProgramFiles(x86)}\Greenshot\Greenshot.exe"
if (-not (Test-Path $greenshotPath)) {
    $greenshotPath = "$env:ProgramFiles\Greenshot\Greenshot.exe"
}

# Nur fortfahren, wenn Greenshot.exe gefunden wurde
if (Test-Path $greenshotPath) {

    # WScriptShell-Objekt für Shortcuts
    $WScriptShell = New-Object -ComObject WScript.Shell

    # 1. Autostart-Link (Benutzer)
    $autostartPath = Join-Path -Path ([Environment]::GetFolderPath("Startup")) -ChildPath "Greenshot.lnk"
    if (-not (Test-Path $autostartPath)) {
        try {
            $shortcut = $WScriptShell.CreateShortcut($autostartPath)
            $shortcut.TargetPath = $greenshotPath
            $shortcut.WorkingDirectory = Split-Path $greenshotPath
            $shortcut.IconLocation = $greenshotPath
            $shortcut.Save()
        } catch {}
    }

    # 2. Startmenü-Link (Benutzer)
    $startmenuPath = Join-Path -Path ([Environment]::GetFolderPath("Programs")) -ChildPath "Greenshot.lnk"
    if (-not (Test-Path $startmenuPath)) {
        try {
            $shortcut = $WScriptShell.CreateShortcut($startmenuPath)
            $shortcut.TargetPath = $greenshotPath
            $shortcut.WorkingDirectory = Split-Path $greenshotPath
            $shortcut.IconLocation = $greenshotPath
            $shortcut.Save()
        } catch {}
    }

    # 3. Greenshot starten
    Start-Process $greenshotPath
}
