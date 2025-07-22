#Sturcz Anpassung der Pfade

Function Get-WAUConfig {

    # Liste m�glicher Pfade, priorisiert
    $PossiblePaths = @(
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Winget-AutoUpdate",
        "HKLM:\SOFTWARE\Romanitho\Winget-AutoUpdate",
        "HKLM:\SOFTWARE\WOW6432Node\Romanitho\Winget-AutoUpdate"
    )

    $WAUConfig = $null

    # Suche zuerst in den m�glichen Konfigpfaden
    foreach ($Path in $PossiblePaths) {
        if (Test-Path $Path) {
            try {
                $ConfigCandidate = Get-ItemProperty -Path $Path -ErrorAction Stop
                if ($ConfigCandidate) {
                    $WAUConfig = $ConfigCandidate
                    break
                }
            }
            catch {
                Write-Verbose "Fehler beim Laden der Konfiguration aus $Path : $_"
            }
        }
    }

    # Wenn keine Konfiguration gefunden wurde, abbrechen
    if (-not $WAUConfig) {
        Write-Warning "Keine g�ltige WAU-Konfiguration gefunden. Es werden Standardwerte verwendet."
        return $null
    }

    # Pr�fe, ob GPO aktiviert ist
    $GPOPath = "HKLM:\SOFTWARE\Policies\Romanitho\Winget-AutoUpdate"
    $ActivateGPOManagement = $null
    if (Test-Path $GPOPath) {
        $ActivateGPOManagement = Get-ItemPropertyValue -Path $GPOPath -Name "WAU_ActivateGPOManagement" -ErrorAction SilentlyContinue
    }

    # Wenn GPO aktiv ist, ersetze/erg�nze Properties aus der Policy
    if ($ActivateGPOManagement -eq 1) {
        try {
            $WAUPolicies = Get-ItemProperty -Path $GPOPath -ErrorAction Stop
            Write-Verbose "GPO-Konfiguration gefunden. �berschreibe lokale Konfiguration..."

            foreach ($property in $WAUPolicies.PSObject.Properties) {
                $name = $property.Name
                $value = $property.Value

                # Wenn die Property bereits existiert, ersetze sie
                if ($WAUConfig.PSObject.Properties.Match($name)) {
                    $WAUConfig.$name = $value
                }
                else {
                    # Sonst neu hinzuf�gen
                    $WAUConfig | Add-Member -NotePropertyName $name -NotePropertyValue $value
                }
            }

            # F�ge WAU_ActivateGPOManagement explizit hinzu, falls nicht vorhanden
            if (-not $WAUConfig.PSObject.Properties.Match("WAU_ActivateGPOManagement")) {
                $WAUConfig | Add-Member -NotePropertyName "WAU_ActivateGPOManagement" -NotePropertyValue 1
            }

        }
        catch {
            Write-Warning "Fehler beim Laden von WAU-GPO-Konfiguration: $_"
        }
    }

    return $WAUConfig
}
