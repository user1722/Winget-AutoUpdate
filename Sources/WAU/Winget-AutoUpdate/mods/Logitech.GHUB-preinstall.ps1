# ==============================
# Skript zur Verwaltung von Logitech G HUB
# ==============================
# Parameter zum Anpassen:
# $App: Name der Anwendung für die Deinstallation (wildcard `*` verwenden)
# $Proc: Name der Prozesse, die gestoppt werden sollen (wildcard `*` verwenden)
# $AppID: Winget-ID der Anwendung zur Neuinstallation
# $Wait: Prozesse, auf deren Beendigung gewartet werden soll (wildcard `*` verwenden)
# $timeoutSeconds: Zeit in Sekunden, nach der das Warten auf das Beenden der Prozesse abbricht

$App = @("Logitech G HUB")
$Proc = @("lghub_updater", "lghub_system_tray")
$AppID = @("Logitech.GHUB")
$Wait = @("lghub_updater", "lghub_system_tray")
$timeoutSeconds = 600  # Timeout in Sekunden (Standard: 600 Sekunden = 10 Minuten)

# Funktion zum Warten auf das Beenden von Prozessen mit Timeout
function Wait-ModsProc ($Wait, $timeoutSeconds) {
    $startTime = Get-Date
    foreach ($process in $Wait) {
        while (Get-Process -Name $process -ErrorAction SilentlyContinue) {
            Start-Sleep -Seconds 1
            if ((Get-Date) -gt $startTime.AddSeconds($timeoutSeconds)) {
                Write-Host "Timeout reached while waiting for process $process to exit."
                return $false
            }
        }
    }
    return $true
}

# Funktion zur Deinstallation der Anwendung
function Uninstall-ModsApp ($App) {
    foreach ($app in $App)
    {
        $InstalledSoftware = Get-ChildItem "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall"
        foreach ($obj in $InstalledSoftware){
            if ($obj.GetValue('DisplayName') -like $App) {
                $UninstallString = $obj.GetValue('UninstallString')
                $CleanedUninstallString = $UninstallString.Trim([char]0x0022)
                if ($UninstallString -like "MsiExec.exe*") {
                    $ProductCode = Select-String "{.*}" -inputobject $UninstallString
                    $ProductCode = $ProductCode.matches.groups[0].value
                    #MSI x64 Installer
                    $Exec = Start-Process "C:\Windows\System32\msiexec.exe" -ArgumentList "/x$ProductCode REBOOT=R /qn" -PassThru -Wait
                    #Stop Hard Reboot (if bad MSI!)
                    if ($Exec.ExitCode -eq 1641) {
                        Start-Process "C:\Windows\System32\shutdown.exe" -ArgumentList "/a"
                    }
                }
                else {
                    $QuietUninstallString = $obj.GetValue('QuietUninstallString')
                    if ($QuietUninstallString) {
                        $QuietUninstallString = Select-String "(\x22.*\x22) +(.*)" -inputobject $QuietUninstallString
                        $Command = $QuietUninstallString.matches.groups[1].value
                        $Parameter = $QuietUninstallString.matches.groups[2].value
                        #All EXE x64 Installers (already defined silent uninstall)
                        Start-Process $Command -ArgumentList $Parameter -Wait
                    }
                    else {
                        if ((Test-Path $CleanedUninstallString)) {
                            $NullSoft = Select-String -Path $CleanedUninstallString -Pattern "Nullsoft"
                        }
                        if ($NullSoft) {
                            #NSIS x64 Installer
                            Start-Process $UninstallString -ArgumentList "/S" -Wait
                        }
                        else {
                            if ((Test-Path $CleanedUninstallString)) {
                                $Inno = Select-String -Path $CleanedUninstallString -Pattern "Inno Setup"
                            }
                            if ($Inno) {
                                #Inno x64 Installer
                                Start-Process $UninstallString -ArgumentList "/VERYSILENT /SUPPRESSMSGBOXES /NORESTART /SP-" -Wait
                            }
                            else {
                                Write-Host "x64 Uninstaller unknown, trying the UninstallString from registry..."
                                $NativeUninstallString = Select-String "(\x22.*\x22) +(.*)" -inputobject $UninstallString
                                $Command = $NativeUninstallString.matches.groups[1].value
                                $Parameter = $NativeUninstallString.matches.groups[2].value
                                #All EXE x64 Installers (native defined uninstall)
                                Start-Process $Command -ArgumentList $Parameter -Wait
                            }
                        }
                    }
                }
                $x64 = $true
                break
            }
        }
        if (!$x64) {
            $InstalledSoftware = Get-ChildItem "HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall"
            foreach ($obj in $InstalledSoftware){
                if ($obj.GetValue('DisplayName') -like $App) {
                    $UninstallString = $obj.GetValue('UninstallString')
                    $CleanedUninstallString = $UninstallString.Trim([char]0x0022)
                    if ($UninstallString -like "MsiExec.exe*") {
                        $ProductCode = Select-String "{.*}" -inputobject $UninstallString
                        $ProductCode = $ProductCode.matches.groups[0].value
                        #MSI x86 Installer
                        $Exec = Start-Process "C:\Windows\System32\msiexec.exe" -ArgumentList "/x$ProductCode REBOOT=R /qn" -PassThru -Wait
                        #Stop Hard Reboot (if bad MSI!)
                        if ($Exec.ExitCode -eq 1641) {
                            Start-Process "C:\Windows\System32\shutdown.exe" -ArgumentList "/a"
                        }
                    }
                    else {
                        $QuietUninstallString = $obj.GetValue('QuietUninstallString')
                        if ($QuietUninstallString) {
                            $QuietUninstallString = Select-String "(\x22.*\x22) +(.*)" -inputobject $QuietUninstallString
                            $Command = $QuietUninstallString.matches.groups[1].value
                            $Parameter = $QuietUninstallString.matches.groups[2].value
                            #All EXE x86 Installers (already defined silent uninstall)
                            Start-Process $Command -ArgumentList $Parameter -Wait
                        }
                        else {
                            if ((Test-Path $CleanedUninstallString)) {
                                $NullSoft = Select-String -Path $CleanedUninstallString -Pattern "Nullsoft"
                            }
                            if ($NullSoft) {
                                #NSIS x86 Installer
                                Start-Process $UninstallString -ArgumentList "/S" -Wait
                            }
                            else {
                                if ((Test-Path $CleanedUninstallString)) {
                                    $Inno = Select-String -Path $CleanedUninstallString -Pattern "Inno Setup"
                                }
                                if ($Inno) {
                                    #Inno x86 Installer
                                    Start-Process $UninstallString -ArgumentList "/VERYSILENT /SUPPRESSMSGBOXES /NORESTART /SP-" -Wait
                                }
                                else {
                                    Write-Host "x86 Uninstaller unknown, trying the UninstallString from registry..."
                                    $NativeUninstallString = Select-String "(\x22.*\x22) +(.*)" -inputobject $UninstallString
                                    $Command = $NativeUninstallString.matches.groups[1].value
                                    $Parameter = $NativeUninstallString.matches.groups[2].value
                                    #All EXE x86 Installers (native defined uninstall)
                                    Start-Process $Command -ArgumentList $Parameter -Wait
                                }
                            }
                        }
                    }
                    break
                }
            }
        }
    }
    Return
}


# resolve winget_exe
$winget_exe = Resolve-Path "C:\Program Files\WindowsApps\Microsoft.DesktopAppInstaller_*_x64__8wekyb3d8bbwe\winget.exe"
if ($winget_exe.count -gt 1){
        $winget_exe = $winget_exe[-1].Path
}

# Funktion zur Installation der Anwendung
function Install-ModsApp ($AppID) {
    foreach ($app in $AppID)
    {
        & winget install --id $app --accept-package-agreements --accept-source-agreements -h
    }
    Return
}

# Funktion zum Stoppen von Prozessen
function Stop-ModsProc ($Proc) {
    foreach ($process in $Proc)
    {
        Stop-Process -Name $process -Force -ErrorAction SilentlyContinue | Out-Null
    }
    Return
}

# Hauptlogik

if ($Proc) {
    Stop-ModsProc $Proc
}

$APPuninstall = "false"	
$APP32location = "C:\Program Files\LGHUB\system_tray\lghub_system_tray.exe"

if (Test-Path -Path $APP32location) {
    $APPuninstall = "True"
    Uninstall-ModsApp $App
    if ($Wait) {
        Wait-ModsProc $Wait $timeoutSeconds
    }
}

if ($APPuninstall -eq "True") {
    Install-ModsApp $AppID
    if ($Wait) {
        Wait-ModsProc $Wait $timeoutSeconds
    }
} else { 
    Write-Host "Keine Deinstallation erforderlich, da die Anwendung nicht gefunden wurde."
}
