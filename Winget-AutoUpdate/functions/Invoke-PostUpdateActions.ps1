#Function to make actions post WAU update

function Invoke-PostUpdateActions {

    #log
    Write-Log "Running Post Update actions..." "yellow"

    #Reset Winget Sources
    $ResolveWingetPath = Resolve-Path "$env:programfiles\WindowsApps\Microsoft.DesktopAppInstaller_*_*__8wekyb3d8bbwe\winget.exe" | Sort-Object { [version]($_.Path -replace '^[^\d]+_((\d+\.)*\d+)_.*', '$1') }
    if ($ResolveWingetPath) {
        #If multiple version, pick last one
        $WingetPath = $ResolveWingetPath[-1].Path
        & $WingetPath source reset --force

        #log
        Write-Log "-> Winget sources reseted." "green"
    }

    #Create WAU Regkey if not present
    $regPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Winget-AutoUpdate"
    if (!(test-path $regPath)) {
        New-Item $regPath -Force
        New-ItemProperty $regPath -Name DisplayName -Value "Winget-AutoUpdate (WAU)" -Force
        New-ItemProperty $regPath -Name DisplayIcon -Value "C:\Windows\System32\shell32.dll,-16739" -Force
        New-ItemProperty $regPath -Name NoModify -Value 1 -Force
        New-ItemProperty $regPath -Name NoRepair -Value 1 -Force
        New-ItemProperty $regPath -Name Publisher -Value "Romanitho" -Force
        New-ItemProperty $regPath -Name URLInfoAbout -Value "https://github.com/user1722/Winget-AutoUpdate" -Force
        New-ItemProperty $regPath -Name InstallLocation -Value $WorkingDir -Force
        New-ItemProperty $regPath -Name UninstallString -Value "powershell.exe -noprofile -executionpolicy bypass -file `"$WorkingDir\WAU-Uninstall.ps1`"" -Force
        New-ItemProperty $regPath -Name QuietUninstallString -Value "powershell.exe -noprofile -executionpolicy bypass -file `"$WorkingDir\WAU-Uninstall.ps1`"" -Force
        New-ItemProperty $regPath -Name WAU_UpdatePrerelease -Value 0 -PropertyType DWord -Force

        #log
        Write-Log "-> $regPath created." "green"
    }
    #Fix Notif where WAU_NotificationLevel is not set
    $regNotif = Get-ItemProperty $regPath -Name WAU_NotificationLevel -ErrorAction SilentlyContinue
    if (!$regNotif) {
        New-ItemProperty $regPath -Name WAU_NotificationLevel -Value Full -Force

        #log
        Write-Log "-> Notification level setting was missing. Fixed with 'Full' option."
    }

    #Set WAU_MaxLogFiles/WAU_MaxLogSize if not set
    $MaxLogFiles = Get-ItemProperty $regPath -Name WAU_MaxLogFiles -ErrorAction SilentlyContinue
    if (!$MaxLogFiles) {
        New-ItemProperty $regPath -Name WAU_MaxLogFiles -Value 3 -PropertyType DWord -Force | Out-Null
        New-ItemProperty $regPath -Name WAU_MaxLogSize -Value 1048576 -PropertyType DWord -Force | Out-Null

        #log
        Write-Log "-> MaxLogFiles/MaxLogSize setting was missing. Fixed with 3/1048576 (in bytes, default is 1048576 = 1 MB)."
    }
    
    #Set WAU_ListPath if not set
    $ListPath = Get-ItemProperty $regPath -Name WAU_ListPath -ErrorAction SilentlyContinue
    if (!$ListPath) {
        New-ItemProperty $regPath -Name WAU_ListPath -Force | Out-Null

        #log
        Write-Log "-> ListPath setting was missing. Fixed with empty string."
    }

    #Set WAU_ModsPath if not set
    $ModsPath = Get-ItemProperty $regPath -Name WAU_ModsPath -ErrorAction SilentlyContinue
    if (!$ModsPath) {
        New-ItemProperty $regPath -Name WAU_ModsPath -Force | Out-Null

        #log
        Write-Log "-> ModsPath setting was missing. Fixed with empty string."
    }

    #Security check
    Write-Log "-> Checking Mods Directory:" "yellow"
    $Protected = Invoke-ModsProtect "$($WAUConfig.InstallLocation)\mods"
    if ($Protected -eq $True) {
        Write-Log "-> The mods directory is now secured!" "green"
    }
    elseif ($Protected -eq $False) {
        Write-Log "-> The mods directory was already secured!" "green"
    }
    else {
        Write-Log "-> Error: The mods directory couldn't be verified as secured!" "red"
    }

    #Convert about.xml if exists (previous WAU versions) to reg
    $WAUAboutPath = "$WorkingDir\config\about.xml"
    if (test-path $WAUAboutPath) {
        [xml]$About = Get-Content $WAUAboutPath -Encoding UTF8 -ErrorAction SilentlyContinue
        New-ItemProperty $regPath -Name DisplayVersion -Value $About.app.version -Force
        New-ItemProperty $regPath -Name VersionMajor -Value ([version]$About.app.version).Major -Force
        New-ItemProperty $regPath -Name VersionMinor -Value ([version]$About.app.version).Minor -Force

        #Remove file once converted
        Remove-Item $WAUAboutPath -Force -Confirm:$false

        #log
        Write-Log "-> $WAUAboutPath converted." "green"
    }

    #Convert config.xml if exists (previous WAU versions) to reg
    $WAUConfigPath = "$WorkingDir\config\config.xml"
    if (test-path $WAUConfigPath) {
        [xml]$Config = Get-Content $WAUConfigPath -Encoding UTF8 -ErrorAction SilentlyContinue
        if ($Config.app.WAUautoupdate -eq "False") { New-ItemProperty $regPath -Name WAU_DisableAutoUpdate -Value 1 -Force }
        if ($Config.app.NotificationLevel) { New-ItemProperty $regPath -Name WAU_NotificationLevel -Value $Config.app.NotificationLevel -Force }
        if ($Config.app.UseWAUWhiteList -eq "True") { New-ItemProperty $regPath -Name WAU_UseWhiteList -Value 1 -PropertyType DWord -Force }
        if ($Config.app.WAUprerelease -eq "True") { New-ItemProperty $regPath -Name WAU_UpdatePrerelease -Value 1 -PropertyType DWord -Force }

        #Remove file once converted
        Remove-Item $WAUConfigPath -Force -Confirm:$false

        #log
        Write-Log "-> $WAUConfigPath converted." "green"
    }

    #Remove old functions
    $FileNames = @(
        "$WorkingDir\functions\Get-WAUConfig.ps1",
        "$WorkingDir\functions\Get-WAUCurrentVersion.ps1",
        "$WorkingDir\functions\Get-WAUUpdateStatus.ps1"
    )
    foreach ($FileName in $FileNames) {
        if (Test-Path $FileName) {
            Remove-Item $FileName -Force -Confirm:$false

            #log
            Write-Log "-> $FileName removed." "green"
        }
    }

    #Reset WAU_UpdatePostActions Value
    $WAUConfig | New-ItemProperty -Name WAU_PostUpdateActions -Value 0 -Force

    #Get updated WAU Config
    $Script:WAUConfig = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Winget-AutoUpdate"

    #log
    Write-Log "Post Update actions finished" "green"

}
