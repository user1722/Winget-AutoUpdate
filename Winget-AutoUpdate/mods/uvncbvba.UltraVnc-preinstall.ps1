#Beginning of App Name string to Silently Uninstall (MSI/NSIS/INNO/EXE with defined silent uninstall in registry)
#Multiple: "app1*","app2*", required wildcard (*) after; search is done with "-like"!
$App = @("uvncbvba.UltraVnc")


$Proc = @("VNC*","ultra*","uvn*","msiexec*")

#Install App from Winget Repo, multiple: "appID1","appID2". Example:
#$AppID = @("Microsoft.PowerToys")
$AppID = @("uvncbvba.UltraVnc")

#Beginning of Process Name to Wait for to End - optional wildcard (*) after, without .exe, multiple: "proc1","proc2"
#$Wait = @("VNC*","ultra*","uvn*","msiexec*","winvn*")
$Wait = @("winvnc.exe","vncviewer.exe")

function Wait-ModsProc ($Wait) {
    foreach ($process in $Wait)
    {
        Get-Process $process -ErrorAction SilentlyContinue | Foreach-Object { $_.WaitForExit() }
    }
    Return
}




# resolve winget_exe
$winget_exe = Resolve-Path "C:\Program Files\WindowsApps\Microsoft.DesktopAppInstaller_*_x64__8wekyb3d8bbwe\winget.exe"
if ($winget_exe.count -gt 1){
        $winget_exe = $winget_exe[-1].Path
}
function Uninstall-ModsApp ($App) {
    foreach ($app in $AppID)
    {
        & $winget_exe uninstall --id $app --accept-package-agreements --accept-source-agreements -h
    }
    Return
}

function Install-ModsApp ($AppID) {
    foreach ($app in $AppID)
    {
        & $winget_exe install --id $app --accept-package-agreements --accept-source-agreements -h
    }
    Return
}



function Stop-ModsProc ($Proc) {
    foreach ($process in $Proc)
    {
        Stop-Process -Name $process -Force -ErrorAction SilentlyContinue | Out-Null
    }
    Return
	}


function Copy-ModsFile ($CopyFile, $CopyTo) {
    if (Test-Path "$CopyFile") {
        Copy-Item -Path $CopyFile -Destination $CopyTo -Recurse -Force -ErrorAction SilentlyContinue | Out-Null
    }
    Return
}

Stop-Service -Name "uvnc_service" -Force -ErrorAction SilentlyContinue | Out-Null



$CopyFile = ""
$CopyTo = ""
$APP32konloc = Join-Path -Path ${env:ProgramFiles(x86)} -ChildPath "uvnc bvba\UltraVnc\ultravnc.ini"
$APP64konloc = Join-Path -Path ${env:ProgramFiles} -ChildPath "uvnc bvba\UltraVnc\ultravnc.ini"
$APPuninstall = "false"	
$APP32location = Join-Path -Path ${env:ProgramFiles(x86)} -ChildPath "uvnc bvba\UltraVnc\"
$APP64location = Join-Path -Path ${env:ProgramFiles} -ChildPath "uvnc bvba\UltraVnc\"

if ($Proc) {
    Stop-ModsProc $Proc
    }


if (Test-Path -Path $APP32konloc)
{
$CopyFile = "$APP32konloc"
$CopyTo = "C:\_install"

if ($CopyFile -and $CopyTo) {
    Copy-ModsFile $CopyFile $CopyTo
}

}

if (Test-Path -Path $APP64konloc)
{
$CopyFile = "$APP64konloc"
$CopyTo = "C:\_install"
if ($CopyFile -and $CopyTo) {
    Copy-ModsFile $CopyFile $CopyTo
}


}

if (Test-Path -Path $APP32location)
{
    $APPuninstall32 = "True"
    Uninstall-ModsApp $App
	if ($Wait) {
    Wait-ModsProc $Wait
    }

}

if (Test-Path -Path $APP64location)
{
    $APPuninstall64 = "True"
    	if ($Wait) {
    Wait-ModsProc $Wait
    }
}

if($Appuninstall32 -eq "True")
{
	Install-ModsApp $AppID
		if ($Wait) {
    Wait-ModsProc $Wait
    }	
}


if($Appuninstall64 -eq "True")
{
	Install-ModsApp $AppID
	if ($Wait) {
    Wait-ModsProc $Wait
    }

}
	

else
{ 
}









