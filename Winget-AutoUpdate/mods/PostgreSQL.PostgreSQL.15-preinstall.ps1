# Beende sofort bei Fehlern
$ErrorActionPreference = "Stop"

Write-Host "🔍 Prüfe laufende Zulu Java Prozesse ..."

# Suche nach Prozessen mit Zulu Java (Azul Zulu)
$zuluProzesse = Get-Process -IncludeUserName -ErrorAction SilentlyContinue | Where-Object {
    (($_.Name -like "REMIRA*" -or $_.Name -like "javaw" -or $_.MainWindowTitle -match "REMIRA") -and !($_.Name -like "REMIRAUpdater"))
}

if ($zuluProzesse) {
    Write-Warning "❌ Zulu Platform / REMIRA POS läuft. PostgreSQL Installation wird gestoppt!"
    foreach ($p in $zuluProzesse) {
        Write-Host "↪️ Prozess gefunden: $($p.Name) (PID $($p.Id)) von $($p.UserName)"
    }

    # Rückgabecode für WAU/Winget
    exit 1
}
else {
    Write-Host "✅ Keine blockierenden Zulu/REMIRA Prozesse gefunden. Fortsetzung möglich."
    exit 0
}
