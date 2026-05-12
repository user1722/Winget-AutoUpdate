#Anpassungen Sturcz
#Anpassungen von Return Werten für Install Skript
function Install-Prerequisites {

    try {

        Write-ToLog "Checking prerequisites..." "Yellow"

        #Check if Visual C++ 2022 is installed
        $Visual2022 = "Microsoft Visual C++ 20*"
        $VisualMinVer = "14.50.0.0"
        $path = Get-Item HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*, HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* | Where-Object {
            $displayName    = $_.GetValue("DisplayName")
            $displayVersion = $_.GetValue("DisplayVersion")
            if (-not ($displayName -like $Visual2022) -or -not $displayVersion) { return $false }
            try   { [version]$displayVersion -ge [version]$VisualMinVer }
            catch { $false }
        }
 
        if (!($path)) {
            try {
                Write-ToLog "MS Visual C++ 2015-2022 is not installed" "Red"
 
                #Get proc architecture
                if ($env:PROCESSOR_ARCHITECTURE -eq "ARM64") {
                    $OSArch = "arm64"
                }
                elseif ($env:PROCESSOR_ARCHITECTURE -like "*64*") {
                    $OSArch = "x64"
                }
                else {
                    $OSArch = "x86"
                }
 
                #Download and install
                $SourceURL = "https://aka.ms/vs/17/release/VC_redist.$OSArch.exe"
                $Installer = "$env:TEMP\VC_redist.$OSArch.exe"
                Write-ToLog "-> Downloading $SourceURL..."
                Invoke-WebRequest $SourceURL -OutFile $Installer -UseBasicParsing
                Write-ToLog "-> Installing VC_redist.$OSArch.exe..."
                Start-Process -FilePath $Installer -Args "/quiet /norestart" -Wait
                Write-ToLog "-> MS Visual C++ 2015-2022 installed successfully." "Green"
            }
            catch {
                Write-ToLog "-> MS Visual C++ 2015-2022 installation failed." "Red"
            }
            finally {
                Remove-Item $Installer -ErrorAction Ignore
            }
        }
        else {
            $foundName    = ($path | Select-Object -First 1).GetValue("DisplayName")
            $foundVersion = ($path | Select-Object -First 1).GetValue("DisplayVersion")
            Write-ToLog "-> MS Visual C++ already installed: $foundName ($foundVersion)" "Green"
        }
 
        #Check if Microsoft.VCLibs.140.00.UWPDesktop is installed
        if (!(Get-AppxPackage -Name 'Microsoft.VCLibs.140.00.UWPDesktop' -AllUsers)) {
            try {
                Write-ToLog "Microsoft.VCLibs.140.00.UWPDesktop is not installed" "Red"
                #Download
                $VCLibsUrl = "https://aka.ms/Microsoft.VCLibs.x64.14.00.Desktop.appx"
                $VCLibsFile = "$env:TEMP\Microsoft.VCLibs.x64.14.00.Desktop.appx"
                Write-ToLog "-> Downloading Microsoft.VCLibs.140.00.UWPDesktop..."
                Invoke-WebRequest -Uri $VCLibsUrl -OutFile $VCLibsFile -UseBasicParsing
                #Install
                Write-ToLog "-> Installing Microsoft.VCLibs.140.00.UWPDesktop..."
                Add-AppxProvisionedPackage -Online -PackagePath $VCLibsFile -SkipLicense | Out-Null
                Write-ToLog "-> Microsoft.VCLibs.140.00.UWPDesktop installed successfully." "Green"
            }
            catch {
                Write-ToLog "-> Failed to install Microsoft.VCLibs.140.00.UWPDesktop..." "Red"
            }
            finally {
                Remove-Item -Path $VCLibsFile -Force -ErrorAction Ignore
            }
        }
 
        #Check if Microsoft.UI.Xaml.2.8 is installed
        if (!(Get-AppxPackage -Name 'Microsoft.UI.Xaml.2.8' -AllUsers)) {
            try {
                Write-ToLog "Microsoft.UI.Xaml.2.8 is not installed" "Red"
                #Download
                $UIXamlUrl = "https://github.com/microsoft/microsoft-ui-xaml/releases/download/v2.8.6/Microsoft.UI.Xaml.2.8.x64.appx"
                $UIXamlFile = "$env:TEMP\Microsoft.UI.Xaml.2.8.x64.appx"
                Write-ToLog "-> Downloading Microsoft.UI.Xaml.2.8..."
                Invoke-WebRequest -Uri $UIXamlUrl -OutFile $UIXamlFile -UseBasicParsing
                #Install
                Write-ToLog "-> Installing Microsoft.UI.Xaml.2.8..."
                Add-AppxProvisionedPackage -Online -PackagePath $UIXamlFile -SkipLicense | Out-Null
                Write-ToLog "-> Microsoft.UI.Xaml.2.8 installed successfully." "Green"
            }
            catch {
                Write-ToLog "-> Failed to install Microsoft.UI.Xaml.2.8..." "Red"
            }
            finally {
                Remove-Item -Path $UIXamlFile -Force -ErrorAction Ignore
            }
        }
 
        #Check if Winget is installed (and up to date)
        try {
            #Get latest WinGet info
            $WinGeturl = 'https://api.github.com/repos/microsoft/winget-cli/releases/latest'
            $resp = Invoke-WebRequest $WinGeturl -UseBasicParsing -Headers @{ "User-Agent" = "WAU-Updater" }
            $WinGetAvailableVersion = ((ConvertFrom-Json $resp.Content).tag_name).TrimStart("v")
        }
        catch {
            #If fail set version to the latest known version as of 2026-02-26
            $WinGetAvailableVersion = "1.28.190"
        }
 
        try {
            #Get Admin Context Winget Location
            $WingetInfo = (Get-Item "$env:ProgramFiles\WindowsApps\Microsoft.DesktopAppInstaller_*_8wekyb3d8bbwe\winget.exe").VersionInfo | Sort-Object -Property FileVersionRaw
            #If multiple versions, pick most recent one
            $WingetCmd = $WingetInfo[-1].FileName
            #Get current Winget Version
            $raw = (& $WingetCmd -v 2>&1 | Out-String).Trim()
            # Extract first X.Y.Z(.W) from output (handles "Unexpected error..." prefix)
            if ($raw -match '(?<!\d)v?(\d+\.\d+\.\d+(?:\.\d+)?)\b') {
                $WinGetInstalledVersion = $Matches[1]
            }
            else {
                throw "Could not parse winget version from output: $raw"
            }
        }
        catch {
            Write-ToLog "WinGet is not installed" "Red"
            $WinGetInstalledVersion = "0.0.0"
        }
 
        Write-ToLog "WinGet installed version: $WinGetInstalledVersion | WinGet available version: $WinGetAvailableVersion"
 
        #Check if the currently installed version is less than the available version
        if ((Compare-SemVer -Version1 $WinGetInstalledVersion -Version2 $WinGetAvailableVersion) -lt 0) {
            #Install WinGet MSIXBundle in SYSTEM context
            try {
                #Download WinGet MSIXBundle
                Write-ToLog "-> Downloading WinGet MSIXBundle for App Installer..."
                $WinGetURL = "https://github.com/microsoft/winget-cli/releases/download/v$WinGetAvailableVersion/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle"
                $WingetInstaller = "$env:TEMP\Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle"
                Invoke-WebRequest -Uri $WinGetURL -OutFile $WingetInstaller -UseBasicParsing
 
                #Install
                Write-ToLog "-> Installing WinGet MSIXBundle for App Installer..."
                Add-AppxProvisionedPackage -Online -PackagePath $WingetInstaller -SkipLicense | Out-Null
                Write-ToLog "-> WinGet MSIXBundle (v$WinGetAvailableVersion) for App Installer installed successfully!" "Green"
            }
            catch {
                Write-ToLog "-> Failed to install WinGet MSIXBundle for App Installer..." "Red"
                #Force Store Apps to update
                Update-StoreApps
            }
            try {
                #Reset WinGet Sources
                $WingetInfo = (Get-Item "$env:ProgramFiles\WindowsApps\Microsoft.DesktopAppInstaller_*_8wekyb3d8bbwe\winget.exe").VersionInfo | Sort-Object -Property FileVersionRaw
                #If multiple versions, pick most recent one
                $WingetCmd = $WingetInfo[-1].FileName
                & $WingetCmd source reset --force
                Write-ToLog "-> WinGet sources reset." "Green"
            }
            catch {
                Write-ToLog "-> Failed to Reset Source" "Red"
                #Force Store Apps to update
                Update-StoreApps
            }
            #Remove WinGet MSIXBundle
            Remove-Item -Path $WingetInstaller -Force -ErrorAction SilentlyContinue
        }
        else {
            Write-ToLog "-> WinGet is up to date: v$WinGetInstalledVersion" "Green"
        }
 
        Write-ToLog "Prerequisites checked. OK return true" "Green"
        return $true
 
    }
    catch {
        Write-ToLog "Prerequisites check failed return false:" "Red"
        Write-ToLog $_.Exception.Message "Red"
        Write-ToLog $_.ScriptStackTrace "Red"
        return $false
    }
}