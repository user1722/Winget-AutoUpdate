function Install-WinGet
{
   Write-Host -Object "`nChecking if Winget is installed" -ForegroundColor Yellow

   #Check Package Install
   $TestWinGet = Get-AppxProvisionedPackage -Online | Where-Object -FilterScript {
      $_.DisplayName -eq 'Microsoft.DesktopAppInstaller'
   }

   #Current: v1.5.2201 = 1.20.2201.0 = 2023.808.2243.0
   if ([Version]$TestWinGet.Version -ge '2023.808.2243.0')
   {
      Write-Host -Object 'Winget is Installed' -ForegroundColor Green
   }
   else
   {
      Write-Host -Object '-> Winget is not installed:'

      #Check if $WingetUpdatePath exist
      if (!(Test-Path $WingetUpdatePath))
      {
         $null = New-Item -ItemType Directory -Force -Path $WingetUpdatePath
      }

      #Downloading and Installing Dependencies in SYSTEM context
      if (!(Get-AppxPackage -Name 'Microsoft.UI.Xaml.2.7'))
      {
         Write-Host -Object '-> Downloading Microsoft.UI.Xaml.2.7...'
         $UiXamlUrl = 'https://www.nuget.org/api/v2/package/Microsoft.UI.Xaml/2.7.0'
         $UiXamlZip = "$WingetUpdatePath\Microsoft.UI.XAML.2.7.zip"
         Invoke-RestMethod -Uri $UiXamlUrl -OutFile $UiXamlZip
         Expand-Archive -Path $UiXamlZip -DestinationPath "$WingetUpdatePath\extracted" -Force
         try
         {
            Write-Host -Object '-> Installing Microsoft.UI.Xaml.2.7...'
            $null = Add-AppxProvisionedPackage -Online -PackagePath "$WingetUpdatePath\extracted\tools\AppX\x64\Release\Microsoft.UI.Xaml.2.7.appx" -SkipLicense
            Write-Host -Object 'Microsoft.UI.Xaml.2.7 installed successfully' -ForegroundColor Green
         }
         catch
         {
            Write-Host -Object 'Failed to intall Wicrosoft.UI.Xaml.2.7...' -ForegroundColor Red
         }
         Remove-Item -Path $UiXamlZip -Force
         Remove-Item -Path "$WingetUpdatePath\extracted" -Force -Recurse
      }

      if (!(Get-AppxPackage -Name 'Microsoft.VCLibs.140.00.UWPDesktop'))
      {
         Write-Host -Object '-> Downloading Microsoft.VCLibs.140.00.UWPDesktop...'
         $VCLibsUrl = 'https://aka.ms/Microsoft.VCLibs.x64.14.00.Desktop.appx'
         $VCLibsFile = "$WingetUpdatePath\Microsoft.VCLibs.x64.14.00.Desktop.appx"
         Invoke-RestMethod -Uri $VCLibsUrl -OutFile $VCLibsFile
         try
         {
            Write-Host -Object '-> Installing Microsoft.VCLibs.140.00.UWPDesktop...'
            $null = Add-AppxProvisionedPackage -Online -PackagePath $VCLibsFile -SkipLicense
            Write-Host -Object 'Microsoft.VCLibs.140.00.UWPDesktop installed successfully' -ForegroundColor Green
         }
         catch
         {
            Write-Host -Object 'Failed to intall Microsoft.VCLibs.140.00.UWPDesktop...' -ForegroundColor Red
         }
         Remove-Item -Path $VCLibsFile -Force
      }

      #Download WinGet MSIXBundle
      Write-Host -Object '-> Downloading Winget MSIXBundle for App Installer...'
      $WinGetURL = 'https://github.com/microsoft/winget-cli/releases/download/v1.5.2201/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle'
      $WebClient = New-Object -TypeName System.Net.WebClient
      $WebClient.DownloadFile($WinGetURL, "$WingetUpdatePath\Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle")

      #Install WinGet MSIXBundle in SYSTEM context
      try
      {
         Write-Host -Object '-> Installing Winget MSIXBundle for App Installer...'
         $null = Add-AppxProvisionedPackage -Online -PackagePath "$WingetUpdatePath\Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle" -SkipLicense
         Write-Host -Object 'Winget MSIXBundle for App Installer installed successfully' -ForegroundColor Green
      }
      catch
      {
         Write-Host -Object 'Failed to intall Winget MSIXBundle for App Installer...' -ForegroundColor Red
      }

      #Remove WinGet MSIXBundle
      Remove-Item -Path "$WingetUpdatePath\Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle" -Force -ErrorAction Continue
   }
}
