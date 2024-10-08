﻿$Wait = @("VNC*","ultra*","uvn*","msiexec*","winvn*")
#$Wait = @("winvnc.exe","vncviewer.exe")



function Wait-ModsProc ($Wait) {
    foreach ($process in $Wait)
    {
        Get-Process $process -ErrorAction SilentlyContinue | Foreach-Object { $_.WaitForExit() }
    }
    Return
}

function Copy-ModsFile ($CopyFile, $CopyTo) {
    if (Test-Path "$CopyFile") {
        Copy-Item -Path $CopyFile -Destination $CopyTo -Recurse -Force -ErrorAction SilentlyContinue | Out-Null
    }
    Return
}

$APP32location = Join-Path -Path ${env:ProgramFiles(x86)} -ChildPath "uvnc bvba\UltraVnc\"
$APP64location = Join-Path -Path ${env:ProgramFiles} -ChildPath "uvnc bvba\UltraVnc\"


if($APP32location -eq "True")
{
	
	$CopyFile = "C:\_install\ultravnc.ini"
	$CopyTo = "$APP32location"
	if ($CopyFile -and $CopyTo) {
    Copy-ModsFile $CopyFile $CopyTo
	New-Service -Name "uvnc_service" -BinaryPathName "$APP32location\WinVNC.exe -service" -DisplayName "uvnc_service" -DependsOn "Tcpip"
	Start-Service -Name "uvnc_service"
}
	if ($Wait) {
    Wait-ModsProc $Wait
}
}
if($APP64location -eq "True")
{
	
	$CopyFile = "C:\_install\ultravnc.ini"
	$CopyTo = "$APP64location"
	if ($CopyFile -and $CopyTo) {
    Copy-ModsFile $CopyFile $CopyTo
	New-Service -Name "uvnc_service" -BinaryPathName "$APP64location\WinVNC.exe -service" -DisplayName "uvnc_service" -DependsOn "Tcpip"
	Start-Service -Name "uvnc_service"
}
	if ($Wait) {
    Wait-ModsProc $Wait
}
}

else
{ 
}


