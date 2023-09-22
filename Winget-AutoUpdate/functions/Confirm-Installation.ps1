function Confirm-Installation
{

   [CmdletBinding()]
   param
   (
      [string]
      $AppName,
      [string]
      $AppVer
   )

	$ConfigDir = Join-Path -Path $WorkingDir -ChildPath "Config"
	# Überprüfe, ob das Verzeichnis existiert
	if (-not (Test-Path -Path $ConfigDir -PathType Container)) {
    # Das Verzeichnis existiert nicht, also legen wir es an
    New-Item -Path $ConfigDir -ItemType Directory
    Write-Host "Das Verzeichnis $ConfigDir wurde erfolgreich erstellt."
	}
	else {
    Write-Host "Das Verzeichnis $ConfigDir existiert bereits."
	}

 
   # Set json export file
   
   $JsonFile = ('{0}\Config\InstalledApps.json' -f $WorkingDir)

   # Get installed apps and version in json file
   $null = (& $Winget export -s winget -o $JsonFile --include-versions)

   # Get json content
   $Json = (Get-Content -Path $JsonFile -Raw | ConvertFrom-Json)

   # Get apps and version in hashtable
   $Packages = $Json.Sources.Packages

   # Remove json file
   $null = (Remove-Item -Path $JsonFile -Force -Confirm:$false -ErrorAction SilentlyContinue)

   # Search for specific app and version
   $Apps = $Packages | Where-Object -FilterScript {
      ($_.PackageIdentifier -eq $AppName -and $_.Version -like ('{0}*' -f $AppVer))
   }

   if ($Apps)
   {
      return $true
   }
   else
   {
      return $false
   }
}
