#Function to check connectivity

function Test-Network {

    #Init
    $timeout = 0

    # Workaround for ARM64 (Access Denied / Win32 internal Server error)
    $ProgressPreference = 'SilentlyContinue'

    #Test connectivity during 5 min then timeout
    Write-Log "Checking internet connection..." "Yellow"
    While ($timeout -lt 300) {

        $URLtoTest = "https://raw.githubusercontent.com/user1722/Winget-AutoUpdate/main/LICENSE"
        $URLcontent = ((Invoke-WebRequest -URI $URLtoTest -UseBasicParsing).content)

        if ($URLcontent -like "*MIT License*") {

            Write-Log "Connected !" "Green"

            #Check for metered connection
            [void][Windows.Networking.Connectivity.NetworkInformation, Windows, ContentType = WindowsRuntime]
            $cost = [Windows.Networking.Connectivity.NetworkInformation]::GetInternetConnectionProfile().GetConnectionCost()

            if ($cost.ApproachingDataLimit -or $cost.OverDataLimit -or $cost.Roaming -or $cost.BackgroundDataUsageRestricted -or ($cost.NetworkCostType -ne "Unrestricted")) {

                Write-Log "Metered connection detected." "Yellow"

                if ($WAUConfig.WAU_DoNotRunOnMetered -eq 1) {

                    Write-Log "WAU is configured to bypass update checking on metered connection"
                    return $false

                }
                else {

                    Write-Log "WAU is configured to force update checking on metered connection"
                    return $true

                }

            }
            else {

                return $true

            }

        }
        else {

            Start-Sleep 10
            $timeout += 10

            #Send Warning Notif if no connection for 5 min
            if ($timeout -eq 300) {
                #Log
                Write-Log "Notify 'No connection' sent." "Yellow"

                #Notif
                $Title = $NotifLocale.local.outputs.output[0].title
                $Message = $NotifLocale.local.outputs.output[0].message
                $MessageType = "warning"
                $Balise = "Connection"
                Start-NotifTask -Title $Title -Message $Message -MessageType $MessageType -Balise $Balise
            }

        }

    }

    #Send Timeout Notif if no connection for 30 min
    Write-Log "Timeout. No internet connection !" "Red"

    #Notif
    $Title = $NotifLocale.local.outputs.output[1].title
    $Message = $NotifLocale.local.outputs.output[1].message
    $MessageType = "error"
    $Balise = "Connection"
    Start-NotifTask -Title $Title -Message $Message -MessageType $MessageType -Balise $Balise

    return $false

}
