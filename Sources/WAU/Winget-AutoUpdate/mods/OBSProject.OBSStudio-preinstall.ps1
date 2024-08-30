﻿# =============================
# Skript zur Verwaltung von OBS
# =============================
# Parameter zum Anpassen:
# $Proc: Name der Prozesse, die gestoppt werden sollen (wildcard `*` verwenden)
# $Wait: Prozesse, auf deren Beendigung gewartet werden soll (wildcard `*` verwenden)
# $timeoutSeconds: Zeit in Sekunden, nach der das Warten auf das Beenden der Prozesse abbricht

$Proc = @("obs64", "obs32")
$Wait = @("obs64", "obs32")
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

# Funktion zum Stoppen von Prozessen
function Stop-ModsProc ($Proc) {
    foreach ($process in $Proc) {
        Stop-Process -Name $process -Force -ErrorAction SilentlyContinue | Out-Null
    }
    return
}

# Hauptlogik
if ($Proc) {
    Stop-ModsProc $Proc
    if ($Wait) {
        Wait-ModsProc $Wait $timeoutSeconds
    }
}
