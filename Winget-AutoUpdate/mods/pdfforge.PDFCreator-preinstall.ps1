$Proc = @("PDFCreatorSetup")


function Stop-ModsProc ($Proc) {
    foreach ($process in $Proc)
    {
        Stop-Process -Name $process -Force -ErrorAction SilentlyContinue | Out-Null
    }
    Return
	}


if ($Proc) {
    Stop-ModsProc $Proc
    }
	