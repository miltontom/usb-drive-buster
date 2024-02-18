$red = "`e[31m"
$green = "`e[32m"
$reset = "`e[0m"

$bot_token = "6158360786:AAHeCbQu0CwF0uynudTMB0dWhGtvwWu992s"
$chat_id = "-1002137906945"
function MonitorUSBDevices {
    $connectedDevices = @()

    while ($true) {
        $currentDevices = Get-PnpDevice | Where-Object {$_.Class -eq "USB" -and $_.Present -eq $true}
        
        # Check for connected devices
        foreach ($device in $currentDevices) {
            if ($connectedDevices -notcontains $device.InstanceId) {
                $connectedDevices += $device.InstanceId
                $dateTime = Get-Date -Format "dd-MM-yy HH:mm:ss"
                $logMessage = "[$dateTime] Connected: $($device.FriendlyName) (Instance ID: $($device.InstanceId))"
                Write-Host $green"Connected$($reset): $($device.FriendlyName)"
                Add-Content -Path "log" -Value $logMessage
                $message = @"
A USB device was plugged into <b>$(($env:USERNAME+"@"+$env:COMPUTERNAME).ToLower())</b>`n
<b>Name</b>: $($device.FriendlyName)
<b>Date</b>: $(Get-Date -Format "dd-MMM-yy")
<b>Time</b>: $(Get-Date -Format "hh:mm:ss tt")
<b>Id</b>: $($device.InstanceId)
<b>OS</b>: $($env:OS)
"@
                Send-TelegramTextMessage -BotToken $bot_token -ChatID $chat_id -Message $message | Out-Null
            }
        }

        # Check for disconnected devices
        foreach ($deviceId in $connectedDevices) {
            if ($currentDevices.InstanceId -notcontains $deviceId) {
                $connectedDevices = $connectedDevices -ne $deviceId
                $dateTime = Get-Date
                $logMessage = "[$dateTime] Disconnected: $($deviceId)"
                Write-Host $red"Disconnected$($reset): $($deviceId)"
                Add-Content -Path "log" -Value $logMessage
            }
        }

        Start-Sleep -Seconds 1
    }
}

MonitorUSBDevices
