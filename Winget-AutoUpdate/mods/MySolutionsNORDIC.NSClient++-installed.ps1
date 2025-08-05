# Globale Steuervariable
$global:nsclientFound = $false

# Name des Dienstes
$dienstName = "nscp"

# Logverzeichnis und Logdatei
$logVerzeichnis = "C:\ProgramData\Winget-AutoUpdate\logs"
$logDatei = Join-Path $logVerzeichnis "nagiosconfig.log"

# Standardpfade für NSClient++
$suchPfade = @(
    "C:\Program Files\NSClient++",
    "C:\Program Files (x86)\NSClient++"
)

# Zielkonfiguration
$neueKonfiguration = @"
# If you want to fill this file with all available options run the following command:
#   nscp settings --generate --add-defaults --load-all
# If you want to activate a module and bring in all its options use:
#   nscp settings --activate-module <MODULE NAME> --add-defaults
# For details run: nscp settings --help

; in flight - TODO
[/settings/default]
allowed hosts = 10.254.1.8, 10.254.1.7
password = 

[/settings/NSClient/server]
use ssl = false
performance data = true
port = 5248
timeout = 30
verify mode = none
thread pool = 10

[/settings/NRPE/server]
port = 5666

[/settings/web/server]
port = 5249

[/modules]
CheckExternalScripts = 1
CheckHelpers = 1
CheckEventLog = 1
CheckNSCP = 1
CheckDisk = 1
CheckSystem = 1
NSClientServer = enabled
WEBServer = disabled
NRPEServer = disabled

[/settings/NRPE/server]
tls version = tlsv1.2+
insecure = false
verify mode = peer-cert
"@

# Logging-Funktion
function Log {
    param([string]$text)

    if (Test-Path $logVerzeichnis) {
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        Add-Content -Path $logDatei -Value "$timestamp - $text"
    } else {
        Write-Output $text
    }
}

# Funktion zur Prüfung, ob nsclient.ini existiert
function Check-NSClientIniExists {
    foreach ($pfad in $suchPfade) {
        $iniPfad = Join-Path $pfad "nsclient.ini"
        if (Test-Path $iniPfad) {
            Log "INI-Datei gefunden: $iniPfad"
            $global:nsclientFound = $true
            return
        }
            else {
            Log "Keine Datei vorhanden in: $iniPfad"
        }
        
    }

    if (-not $global:nsclientFound) {
        Log "INI-Datei wurde in keinem Pfad gefunden. Skript wird beendet."
    }
}

# Funktion zur Konfigurationsverarbeitung
function Set-NSClientConfig {
    foreach ($pfad in $suchPfade) {
        $iniPfad = Join-Path $pfad "nsclient.ini"
        if (Test-Path $iniPfad) {
            Log "Schreibe Konfiguration nach: $iniPfad"
            try {
                Set-Content -Path $iniPfad -Value $neueKonfiguration -Encoding UTF8 -Force
                Log "Konfiguration erfolgreich geschrieben."
                return $true
            } catch {
                Log "Fehler beim Schreiben der Konfiguration: $_"
                return $false
            }
        }
    }

    Log "Pfad zur INI-Datei konnte nicht ermittelt werden."
    return $false
}

# === Hauptlogik ===
Check-NSClientIniExists

if ($global:nsclientFound) {
    Log "NSClient++ erkannt. Starte Konfigurationsaktualisierung..."
    $konfigErfolgreich = Set-NSClientConfig

    if ($konfigErfolgreich) {
        Log "Konfiguration wurde erfolgreich gesetzt."
        $dienst = Get-Service -Name $dienstName -ErrorAction SilentlyContinue
        if ($dienst) {
            Log "Dienst '$dienstName' gefunden. Versuche Neustart..."
            try {
                Restart-Service -Name $dienstName -Force -ErrorAction Stop
                Log "Dienst '$dienstName' erfolgreich neu gestartet."
            } catch {
                Log "Fehler beim Neustart des Dienstes: $_"
            }
        } else {
            Log "Dienst '$dienstName' wurde nicht gefunden. Kein Neustart möglich."
        }
    } else {
        Log "Konfigurationsschreiben fehlgeschlagen."
    }
} else {
    exit 0
}
