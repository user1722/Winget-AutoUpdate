#Sturcz Anpassung an Ausnahmen fuer Install Mods
<#
.SYNOPSIS
Install apps with Winget through Intune or SCCM.
Can be used standalone.

.DESCRIPTION
Allow to run Winget in System Context to install your apps.
https://github.com/user1722/Winget-Install

.PARAMETER AppIDs
Forward Winget App ID to install. For multiple apps, separate with ",". Case sensitive.

.PARAMETER Uninstall
To uninstall app. Works with AppIDs

.PARAMETER AllowUpgrade
To allow upgrade app if present. Works with AppIDs

.PARAMETER LogPath
Used to specify logpath. Default is same folder as Winget-Autoupdate project

.PARAMETER WAUWhiteList
Adds the app to the Winget-AutoUpdate White List. More info: https://github.com/user1722/Winget-AutoUpdate
If '-Uninstall' is used, it removes the app from WAU White List.

.EXAMPLE
.\winget-install.ps1 -AppIDs 7zip.7zip

.EXAMPLE
.\winget-install.ps1 -AppIDs 7zip.7zip -Uninstall

.EXAMPLE
.\winget-install.ps1 -AppIDs 7zip.7zip -WAUWhiteList

.EXAMPLE
.\winget-install.ps1 -AppIDs 7zip.7zip,Notepad++.Notepad++ -LogPath "C:\temp\logs"

.EXAMPLE
.\winget-install.ps1 -AppIDs "7zip.7zip -v 22.00", "Notepad++.Notepad++"

.EXAMPLE
.\winget-install.ps1 -AppIDs "Notepad++.Notepad++" -AllowUpgrade
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $True, ParameterSetName = "AppIDs")] [String[]] $AppIDs,
    [Parameter(Mandatory = $False)] [Switch] $Uninstall,
    [Parameter(Mandatory = $False)] [String] $LogPath,
    [Parameter(Mandatory = $False)] [Switch] $WAUWhiteList,
    [Parameter(Mandatory = $False)] [Switch] $AllowUpgrade
)


<# FUNCTIONS #>

#Include external Functions (check first if this script is a symlink or a real file)
$scriptItem = Get-Item -LiteralPath $MyInvocation.MyCommand.Definition
$realPath = if ($scriptItem.LinkType) {
    $targetPath = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($scriptItem.Directory.FullName, $scriptItem.Target))
    Split-Path -Parent $targetPath
}
else {
    $scriptItem.DirectoryName
}

. "$realPath\functions\Install-Prerequisites.ps1"
. "$realPath\functions\Update-StoreApps.ps1"
. "$realPath\functions\Add-ScopeMachine.ps1"
. "$realPath\functions\Get-WingetCmd.ps1"
. "$realPath\functions\Write-ToLog.ps1"
. "$realPath\functions\Confirm-Installation.ps1"
. "$realPath\functions\Compare-SemVer.ps1"

#Check if App exists in Winget Repository
function Confirm-Exist ($AppID) {
    #Check is app exists in the winget repository
    $WingetApp = & $winget show --Id $AppID -e --accept-source-agreements -s winget | Out-String

    #Return if AppID exists
    if ($WingetApp -match [regex]::Escape($AppID)) {
        Write-ToLog "-> $AppID exists on Winget Repository." "Cyan"
        return $true
    }
    else {
        Write-ToLog "-> $AppID does not exist on Winget Repository! Check spelling." "Red"
        return $false
    }
}

#Check if install modifications exist in "mods" directory
function Test-ModsInstall ($AppID) {
    #Check current location
    if (Test-Path ".\mods\$AppID-preinstall.ps1") {
        $ModsPreInstall = ".\mods\$AppID-preinstall.ps1"
    }
    #Else, check in WAU mods
    elseif (Test-Path "$WAUModsLocation\$AppID-preinstall.ps1") {
        $ModsPreInstall = "$WAUModsLocation\$AppID-preinstall.ps1"
    }

    if (Test-Path ".\mods\$AppID-install.ps1") {
        $ModsInstall = ".\mods\$AppID-install.ps1"
    }
    elseif (Test-Path "$WAUModsLocation\$AppID-install.ps1") {
        $ModsInstall = "$WAUModsLocation\$AppID-install.ps1"
    }

    if (Test-Path ".\mods\$AppID-installed-once.ps1") {
        $ModsInstalledOnce = ".\mods\$AppID-installed-once.ps1"
    }

    if (Test-Path ".\mods\$AppID-installed.ps1") {
        $ModsInstalled = ".\mods\$AppID-installed.ps1"
    }
    elseif (Test-Path "$WAUModsLocation\$AppID-installed.ps1") {
        $ModsInstalled = "$WAUModsLocation\$AppID-installed.ps1"
    }

    return $ModsPreInstall, $ModsInstall, $ModsInstalledOnce, $ModsInstalled
}

#Check if uninstall modifications exist in "mods" directory
function Test-ModsUninstall ($AppID) {
    #Check current location
    if (Test-Path ".\mods\$AppID-preuninstall.ps1") {
        $ModsPreUninstall = ".\mods\$AppID-preuninstall.ps1"
    }
    #Else, check in WAU mods
    elseif (Test-Path "$WAUModsLocation\$AppID-preuninstall.ps1") {
        $ModsPreUninstall = "$WAUModsLocation\$AppID-preuninstall.ps1"
    }

    if (Test-Path ".\mods\$AppID-uninstall.ps1") {
        $ModsUninstall = ".\mods\$AppID-uninstall.ps1"
    }
    elseif (Test-Path "$WAUModsLocation\$AppID-uninstall.ps1") {
        $ModsUninstall = "$WAUModsLocation\$AppID-uninstall.ps1"
    }

    if (Test-Path ".\mods\$AppID-uninstalled.ps1") {
        $ModsUninstalled = ".\mods\$AppID-uninstalled.ps1"
    }
    elseif (Test-Path "$WAUModsLocation\$AppID-uninstalled.ps1") {
        $ModsUninstalled = "$WAUModsLocation\$AppID-uninstalled.ps1"
    }

    return $ModsPreUninstall, $ModsUninstall, $ModsUninstalled
}

#Install function
function Install-App ($AppID, $AppArgs) {
	# Versionsnummer aus den AppArgs extrahieren (wenn vorhanden)
    $AppVersion = $null
    if ($AppArgs -match "(?<=-v\s*)[\d\.]+") {
        $AppVersion = $Matches[0]
		write-host "extrahierte AppVersion $AppVersion"
    }
    $IsInstalled = Confirm-Installation -AppName $AppID -AppVer $AppVersion
    if (!($IsInstalled) -or $AllowUpgrade ) {
        #Check if mods exist (or already exist) for preinstall/install/installedonce/installed
        $ModsPreInstall, $ModsInstall, $ModsInstalledOnce, $ModsInstalled = Test-ModsInstall $($AppID)

        #If PreInstall script exist
        if ($ModsPreInstall) {
            Write-ToLog "-> Modifications for $AppID before install are being applied..." "Yellow"
		try {
			& "$ModsPreInstall"
			if ($LASTEXITCODE -ne 0) {
				
				if ($LASTEXITCODE -eq 101) {
				throw "PreInstall script exited with code $LASTEXITCODE a important Program is still running"	
				}
				elseif ($LASTEXITCODE -eq 450) {
				throw "PreInstall script exited with code $LASTEXITCODE a reboot is still required"	
				}
				else {
				throw "PreInstall script exited with code $LASTEXITCODE"
				}							
			}
		}
		catch {
			Write-ToLog "PreInstall for $($app.Id) failed: $_" "Red"

			# Benachrichtigung über Fehler senden
			$Title = $NotifLocale.local.outputs.output[4].title -f $($app.Name)
			$Message = "Das Preinstall-Modul für $($app.Name) wurde mit abgebrochen: $_"
			$MessageType = "error"
			$Balise = $($app.Name)
			Start-NotifTask -Title $Title -Message $Message -MessageType $MessageType -Balise $Balise -Button1Action $ReleaseNoteURL -Button1Text $Button1Text

			return  # Bricht die Funktion vollständig ab
		}
	}

        #Install App
        Write-ToLog "-> Installing $AppID..." "Yellow"
        $WingetArgs = "install --id $AppID -e --accept-package-agreements --accept-source-agreements -s winget -h $AppArgs" -split " "
        Write-ToLog "-> Running: `"$Winget`" $WingetArgs"
        & "$Winget" $WingetArgs | Where-Object { $_ -notlike "   *" } | Tee-Object -file $LogFile -Append

        if ($ModsInstall) {
            Write-ToLog "-> Modifications for $AppID during install are being applied..." "Yellow"
            & "$ModsInstall"
        }

        #Check if install is ok
        $IsInstalled = Confirm-Installation $AppID
        if ($IsInstalled) {
            Write-ToLog "-> $AppID successfully installed." "Green"

            if ($ModsInstalledOnce) {
                Write-ToLog "-> Modifications for $AppID after install (one time) are being applied..." "Yellow"
                & "$ModsInstalledOnce"
            }
            elseif ($ModsInstalled) {
                Write-ToLog "-> Modifications for $AppID after install are being applied..." "Yellow"
                & "$ModsInstalled"
            }

            #Add mods if deployed from Winget-Install
            if (Test-Path ".\mods\$AppID-*") {
                #Check if WAU default install path exists
                $Mods = "$WAUModsLocation"
                if (Test-Path $Mods) {
                    #Add mods
                    Write-ToLog "-> Add modifications for $AppID to WAU 'mods'"
                    Copy-Item ".\mods\$AppID-*" -Destination "$Mods" -Exclude "*installed-once*", "*uninstall*" -Force
                }
            }

            #Add to WAU White List if set
            if ($WAUWhiteList) {
                Add-WAUWhiteList $AppID
            }
        }
        else {
            Write-ToLog "-> $AppID installation failed!" "Red"
        }
    }
    else {
        Write-ToLog "-> $AppID is already installed." "Cyan"
    }
}

#Uninstall function
function Uninstall-App ($AppID, $AppArgs) {
    $IsInstalled = Confirm-Installation $AppID
    if ($IsInstalled) {
        #Check if mods exist (or already exist) for preuninstall/uninstall/uninstalled
        $ModsPreUninstall, $ModsUninstall, $ModsUninstalled = Test-ModsUninstall $AppID

        #If PreUninstall script exist
        if ($ModsPreUninstall) {
            Write-ToLog "-> Modifications for $AppID before uninstall are being applied..." "Yellow"
		try {
			& "$ModsPreUninstall"
			if ($LASTEXITCODE -ne 0) {
				
				if ($LASTEXITCODE -eq 101) {
				throw "PreUninstall script exited with code $LASTEXITCODE a important Program is still running"	
				}
				elseif ($LASTEXITCODE -eq 450) {
				throw "PreUninstall script exited with code $LASTEXITCODE a reboot is still required"	
				}
				else {
				throw "PreUninstall script exited with code $LASTEXITCODE"
				}							
			}
		}
		catch {
			Write-ToLog "PreUninstall for $($app.Id) failed: $_" "Red"

			# Benachrichtigung über Fehler senden
			$Title = $NotifLocale.local.outputs.output[4].title -f $($app.Name)
			$Message = "Das PreUninstall-Modul für $($app.Name) wurde mit abgebrochen: $_"
			$MessageType = "error"
			$Balise = $($app.Name)
			Start-NotifTask -Title $Title -Message $Message -MessageType $MessageType -Balise $Balise -Button1Action $ReleaseNoteURL -Button1Text $Button1Text

			return  # Bricht die Funktion vollständig ab
		}
	}

        #Uninstall App
        Write-ToLog "-> Uninstalling $AppID..." "Yellow"
        $WingetArgs = "uninstall --id $AppID -e --accept-source-agreements -h $AppArgs" -split " "
        Write-ToLog "-> Running: `"$Winget`" $WingetArgs"
        & "$Winget" $WingetArgs | Where-Object { $_ -notlike "   *" } | Tee-Object -file $LogFile -Append

        if ($ModsUninstall) {
            Write-ToLog "-> Modifications for $AppID during uninstall are being applied..." "Yellow"
            & "$ModsUninstall"
        }

        #Check if uninstall is ok
        $IsInstalled = Confirm-Installation $AppID
        if (!($IsInstalled)) {
            Write-ToLog "-> $AppID successfully uninstalled." "Green"
            if ($ModsUninstalled) {
                Write-ToLog "-> Modifications for $AppID after uninstall are being applied..." "Yellow"
                & "$ModsUninstalled"
            }

            #Remove mods if deployed from Winget-Install
            if (Test-Path ".\mods\$AppID-*") {
                #Check if WAU default install path exists
                $Mods = "$WAUModsLocation"
                if (Test-Path "$Mods\$AppID*") {
                    Write-ToLog "-> Remove $AppID modifications from WAU 'mods'"
                    #Remove mods
                    Remove-Item -Path "$Mods\$AppID-*" -Exclude "*uninstall*" -Force
                }
            }

            #Remove from WAU White List if set
            if ($WAUWhiteList) {
                Remove-WAUWhiteList $AppID
            }
        }
        else {
            Write-ToLog "-> $AppID uninstall failed!" "Red"
        }
    }
    else {
        Write-ToLog "-> $AppID is not installed." "Cyan"
    }
}

#Function to Add app to WAU white list
function Add-WAUWhiteList ($AppID) {
    #Check if WAU default install path is defined
    if ($WAUInstallLocation) {
        $WhiteList = "$WAUInstallLocation\included_apps.txt"
        #Create included_apps.txt if it doesn't exist
        if (!(Test-Path $WhiteList)) {
            New-Item -ItemType File -Path $WhiteList -Force -ErrorAction SilentlyContinue
        }
        Write-ToLog "-> Add $AppID to WAU included_apps.txt"
        #Add App to "included_apps.txt"
        Add-Content -Path $WhiteList -Value "`n$AppID" -Force
        #Remove duplicate and blank lines
        $file = Get-Content $WhiteList | Select-Object -Unique | Where-Object { $_.trim() -ne "" } | Sort-Object
        $file | Out-File $WhiteList
    }
}

#Function to Remove app from WAU white list
function Remove-WAUWhiteList ($AppID) {
    #Check if WAU default install path exists
    $WhiteList = "$WAUInstallLocation\included_apps.txt"
    if (Test-Path $WhiteList) {
        Write-ToLog "-> Remove $AppID from WAU included_apps.txt"
        #Remove app from list
        $file = Get-Content $WhiteList | Where-Object { $_ -ne "$AppID" }
        $file | Out-File $WhiteList
    }
}

<# MAIN #>

#If running as a 32-bit process on an x64 system, re-launch as a 64-bit process
if ("$env:PROCESSOR_ARCHITEW6432" -ne "ARM64") {
    if (Test-Path "$($env:WINDIR)\SysNative\WindowsPowerShell\v1.0\powershell.exe") {
        Start-Process "$($env:WINDIR)\SysNative\WindowsPowerShell\v1.0\powershell.exe" -Wait -ArgumentList "-NoProfile -ExecutionPolicy Bypass -Command $($MyInvocation.line)"
        Exit $lastexitcode
    }
}

#Config console output encoding
$null = cmd /c '' #Tip for ISE
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$Script:ProgressPreference = 'SilentlyContinue'

#Check if current process is elevated (System or admin user)
$CurrentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
$Script:IsElevated = $CurrentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

#Get WAU Installed location
$WAURegKey = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Winget-AutoUpdate"
$Script:WAUInstallLocation = Get-ItemProperty $WAURegKey -ErrorAction SilentlyContinue | Select-Object -ExpandProperty InstallLocation
$Script:WAUModsLocation = Join-Path -Path $WAUInstallLocation -ChildPath "mods"

#Log file & LogPath initialization
if ($IsElevated) {
    if (!($LogPath)) {
        #If LogPath is not set, get WAU log path
        if ($WAUInstallLocation) {
            $LogPath = "$WAUInstallLocation\Logs"
        }
        else {
            #Else, set a default one
            $LogPath = "$env:ProgramData\Winget-AutoUpdate\Logs"
        }
    }
    $Script:LogFile = "$LogPath\install.log"
}
else {
    if (!($LogPath)) {
        $LogPath = "C:\Users\$env:UserName\AppData\Roaming\Winget-AutoUpdate\Logs"
    }
    $Script:LogFile = "$LogPath\install_$env:UserName.log"
}

#Logs initialization
if (!(Test-Path $LogPath)) {
    New-Item -ItemType Directory -Force -Path $LogPath | Out-Null
}

#Log Header
if ($Uninstall) {
    Write-ToLog -LogMsg "NEW UNINSTALL REQUEST" -LogColor "Magenta" -IsHeader
}
else {
    Write-ToLog -LogMsg "NEW INSTALL REQUEST" -LogColor "Magenta" -IsHeader
}

if ($IsElevated -eq $True) {
    Write-ToLog "Running with admin rights.`n"

    #Check/install prerequisites
    Install-Prerequisites

    #Reload Winget command
    $Script:Winget = Get-WingetCmd

    #Run Scope Machine function
    Add-ScopeMachine
}
else {
    Write-ToLog "Running without admin rights.`n"

    #Get Winget command
    $Script:Winget = Get-WingetCmd
}

if ($Winget) {
    #Put apps in an array
    $AppIDsArray = $AppIDs -split ","
    Write-Host ""

    #Run install or uninstall for all apps
    foreach ($App_Full in $AppIDsArray) {
        #Split AppID and Custom arguments
        $AppID, $AppArgs = ($App_Full.Trim().Split(" ", 2))

        #Log current App
        Write-ToLog "Start $AppID processing..." "Blue"

        #Install or Uninstall command
        if ($Uninstall) {
            Uninstall-App $AppID $AppArgs
        }
        else {
            #Check if app exists on Winget Repo
            $Exists = Confirm-Exist $AppID
            if ($Exists) {
                #Install
                Install-App $AppID $AppArgs
            }
        }

        #Log current App
        Write-ToLog "$AppID processing finished!`n" "Blue"
        Start-Sleep 1
    }
}

Write-ToLog "###   END REQUEST   ###`n" "Magenta"
Start-Sleep 3
