#Function to configure the preferred scope option as Machine (with self-repair)
function Add-ScopeMachine {

    #Get Settings path for system or current user
    if ([System.Security.Principal.WindowsIdentity]::GetCurrent().IsSystem) {
        $SettingsPath = "$Env:windir\System32\config\systemprofile\AppData\Local\Microsoft\WinGet\Settings\defaultState\settings.json"
    }
    else {
        $SettingsPath = "$env:LOCALAPPDATA\Packages\Microsoft.DesktopAppInstaller_8wekyb3d8bbwe\LocalState\settings.json"
    }

    # Ensure directory exists
    $dir = Split-Path $SettingsPath -Parent
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }

    # Ensure file exists (and is not empty)
    if (-not (Test-Path $SettingsPath)) {
        '{}' | Out-File $SettingsPath -Encoding utf8 -Force
    }
    else {
        $rawCheck = Get-Content -Path $SettingsPath -Raw -ErrorAction SilentlyContinue
        if ([string]::IsNullOrWhiteSpace($rawCheck)) {
            $bak = "$SettingsPath.bak_empty_$(Get-Date -Format yyyyMMdd_HHmmss)"
            Copy-Item $SettingsPath $bak -Force -ErrorAction SilentlyContinue
            '{}' | Out-File $SettingsPath -Encoding utf8 -Force
        }
    }

    # Load JSON safely (strip // comment lines)
    $raw = Get-Content -Path $SettingsPath -Raw -ErrorAction SilentlyContinue
    $rawNoComments = ($raw -split "`r?`n" | Where-Object { $_ -notmatch '^\s*//' }) -join "`r`n"

    try {
        $ConfigFile = $rawNoComments | ConvertFrom-Json -ErrorAction Stop
    }
    catch {
        # Corrupt JSON -> backup and reset
        $bak = "$SettingsPath.bak_corrupt_$(Get-Date -Format yyyyMMdd_HHmmss)"
        Copy-Item $SettingsPath $bak -Force -ErrorAction SilentlyContinue
        $ConfigFile = [pscustomobject]@{}
    }

    # If ConvertFrom-Json returned $null for any reason, force an object
    if ($null -eq $ConfigFile) {
        $ConfigFile = [pscustomobject]@{}
    }

    # Ensure nested structure exists
    if (-not $ConfigFile.installBehavior) {
        $ConfigFile | Add-Member -MemberType NoteProperty -Name "installBehavior" -Value ([pscustomobject]@{}) -Force
    }
    if (-not $ConfigFile.installBehavior.preferences) {
        $ConfigFile.installBehavior | Add-Member -MemberType NoteProperty -Name "preferences" -Value ([pscustomobject]@{}) -Force
    }

    # Set scope to Machine
    $ConfigFile.installBehavior.preferences | Add-Member -MemberType NoteProperty -Name "scope" -Value "Machine" -Force

    # Write back
    $ConfigFile | ConvertTo-Json -Depth 100 | Out-File $SettingsPath -Encoding utf8 -Force
}