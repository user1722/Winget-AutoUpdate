Function Confirm-Installation ($AppName, $AppVer){

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
    #Set json export file
    $JsonFile = "$WorkingDir\Config\InstalledApps.json"

    #Get installed apps and version in json file
    & $Winget export -s winget -o $JsonFile --include-versions | Out-Null

    #Get json content
    $Json = Get-Content $JsonFile -Raw | ConvertFrom-Json

    #Get apps and version in hashtable
    $Packages = $Json.Sources.Packages

    #Remove json file
    Remove-Item $JsonFile -Force

    # Search for specific app and version
    $Apps = $Packages | Where-Object { $_.PackageIdentifier -eq $AppName -and $_.Version -like "$AppVer*"}

    if ($Apps){
        return $true
    }
    else{
        return $false
    }
}
