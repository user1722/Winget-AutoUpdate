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
        foreach ($obj in $InstalledSoftware) {
            if ($obj.GetValue('DisplayName') -like $App) {
                $UninstallString = $obj.GetValue('UninstallString')
                
                # Überprüfe, ob der UninstallString leer oder ungültig ist
                if (![string]::IsNullOrEmpty($UninstallString)) {
                    $CleanedUninstallString = $UninstallString.Trim('"')
                    
                    # Versuche, den UninstallString auszuführen, falls er gültig ist
                    if ($CleanedUninstallString -like "MsiExec.exe*") {
                        $ProductCode = Select-String "{.*}" -inputobject $UninstallString
                        $ProductCode = $ProductCode.matches.groups[0].value
                        # MSI x64 Installer
                        $Exec = Start-Process "C:\Windows\System32\msiexec.exe" -ArgumentList "/x$ProductCode REBOOT=R /qn" -PassThru -Wait
                        # Stop Hard Reboot (if bad MSI!)
                        if ($Exec.ExitCode -eq 1641) {
                            Start-Process "C:\Windows\System32\shutdown.exe" -ArgumentList "/a"
                        }
                    } else {
                        # Falls der UninstallString eine EXE oder ein anderes Skript ist
                        try {
                            Start-Process -FilePath $CleanedUninstallString -Wait
                        } catch {
                            Write-Host "Failed to execute uninstall string: $CleanedUninstallString"
                        }
                    }
                }
            }
        }
    }
    Return
}

# Funktion zur Installation der Anwendung
function Install-ModsApp ($AppID) {
    foreach ($app in $AppID) {
        & winget install --id $app --accept-package-agreements --accept-source-agreements -h
    }
    Return
}

# Funktion zum Stoppen von Prozessen
function Stop-ModsProc ($Proc) {
    foreach ($process in $Proc) {
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
