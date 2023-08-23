function Install-WinGet {

    Write-Host "`nChecking if Winget is installed" -ForegroundColor Yellow

    #Check Package Install
    $TestWinGet = Get-AppxProvisionedPackage -Online | Where-Object { $_.DisplayName -eq "Microsoft.DesktopAppInstaller" }

    #Current: v1.5.1881 = 1.20.1881.0 = 2023.707.2257.0
    If ([Version]$TestWinGet.Version -ge "2023.707.2257.0") {

        Write-Host "WinGet is Installed" -ForegroundColor Green

    }
    Else {

        #Download WinGet MSIXBundle
        Write-Host "-> Not installed. Downloading WinGet..."
        $WinGetURL = "https://github.com/microsoft/winget-cli/releases/download/v1.5.1881/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle"
        $WebClient = New-Object System.Net.WebClient
        $WebClient.DownloadFile($WinGetURL, "$PSScriptRoot\Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle")

        #Install WinGet MSIXBundle
        try {
            Write-Host "-> Installing Winget MSIXBundle for App Installer..."
            Add-AppxProvisionedPackage -Online -PackagePath "$PSScriptRoot\Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle" -SkipLicense | Out-Null
            Write-Host "Installed Winget MSIXBundle for App Installer" -ForegroundColor Green
        }
        catch {
            Write-Host "Failed to intall Winget MSIXBundle for App Installer..." -ForegroundColor Red
        }

        #Remove WinGet MSIXBundle
        Remove-Item -Path "$PSScriptRoot\Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle" -Force -ErrorAction Continue

    }

}
