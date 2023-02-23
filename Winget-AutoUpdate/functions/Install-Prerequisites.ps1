function Install-Prerequisites {

    Write-Host "`nChecking prerequisites..." -ForegroundColor Yellow

    #Check if Visual C++ 2019 or 2022 installed
    $Visual2019 = "Microsoft Visual C++ 2015-2019 Redistributable*"
    $Visual2022 = "Microsoft Visual C++ 2015-2022 Redistributable*"
    $path = Get-Item HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*, HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* | Where-Object { $_.GetValue("DisplayName") -like $Visual2019 -or $_.GetValue("DisplayName") -like $Visual2022 }

    #If not installed, ask for installation
    if (!($path)) {
        #If -silent option, force installation
        if ($Silent) {
            $InstallApp = 1
        }
        else {
            #Ask for installation
            $MsgBoxTitle = "Winget Prerequisites"
            $MsgBoxContent = "Microsoft Visual C++ 2015-2022 is required. Would you like to install it?"
            $MsgBoxTimeOut = 60
            $MsgBoxReturn = (New-Object -ComObject "Wscript.Shell").Popup($MsgBoxContent, $MsgBoxTimeOut, $MsgBoxTitle, 4 + 32)
            if ($MsgBoxReturn -ne 7) {
                $InstallApp = 1
            }
            else {
                $InstallApp = 0
            }
        }
        #Install if approved
        if ($InstallApp -eq 1) {
            try {
                if ((Get-CimInStance Win32_OperatingSystem).OSArchitecture -like "*64*") {
                    $OSArch = "x64"
                }
                else {
                    $OSArch = "x86"
                }
                Write-host "-> Downloading VC_redist.$OSArch.exe..."
                $SourceURL = "https://aka.ms/vs/17/release/VC_redist.$OSArch.exe"
                $Installer = $WingetUpdatePath + "\VC_redist.$OSArch.exe"
                $ProgressPreference = 'SilentlyContinue'
                Invoke-WebRequest $SourceURL -OutFile (New-Item -Path $Installer -Force)
                Write-host "-> Installing VC_redist.$OSArch.exe..."
                Start-Process -FilePath $Installer -Args "/quiet /norestart" -Wait
                Remove-Item $Installer -ErrorAction Ignore
                Write-host "-> MS Visual C++ 2015-2022 installed successfully" -ForegroundColor Green
            }
            catch {
                Write-host "-> MS Visual C++ 2015-2022 installation failed." -ForegroundColor Red
                Start-Sleep 3
            }
        }
        else {
            Write-host "-> MS Visual C++ 2015-2022 will not be installed." -ForegroundColor Magenta
        }
    }
    else {
        Write-Host "Prerequisites checked. OK" -ForegroundColor Green
    }
}