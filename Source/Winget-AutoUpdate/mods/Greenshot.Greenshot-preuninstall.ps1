$Proc = @("Greenshot")

function Stop-ModsProc($Proc) {
    foreach ($name in $Proc) {
        # Prozesse beenden, die den Namen ähnlich enthalten
        Get-Process | Where-Object { $_.Name -like "*$name*" } | ForEach-Object {
            Stop-Process -Id $_.Id -Force -ErrorAction SilentlyContinue
        }

        # Dienste stoppen, deren Name oder DisplayName ähnlich ist
        Get-Service | Where-Object {
            $_.Name -like "*$name*" -or $_.DisplayName -like "*$name*"
        } | ForEach-Object {
            if ($_.Status -eq 'Running') {
                Stop-Service -Name $_.Name -Force -ErrorAction SilentlyContinue
            }
        }
    }
}

if ($Proc) {
    Stop-ModsProc $Proc
}
