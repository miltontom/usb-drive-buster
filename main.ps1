$ansiRed = "`e[31m"
$ansiGreen = "`e[32m"
$ansiReset = "`e[0m"

$botToken = "6158360786:AAHeCbQu0CwF0uynudTMB0dWhGtvwWu992s"
$telegramChatId = "-1002137906945"

function MonitorUSBDevices {
    $logPath = "C:\Users\Milton\Desktop\PowerShell\usb-buster\log"
    $connectedDevices = @()

    while ($true) {
        $currentDevices = Get-PnpDevice | Where-Object {$_.Class -eq "USB" -and $_.Present -eq $true}
        
        # Check for connected devices
        foreach ($device in $currentDevices) {
            if ($connectedDevices -notcontains $device.InstanceId) {
                $connectedDevices += $device.InstanceId
                $dateTime = Get-Date -Format "dd-MM-yy HH:mm:ss"
                $logMessage = "[$dateTime] Connected: $($device.FriendlyName) (Instance ID: $($device.InstanceId))"
                Write-Host $ansiGreen"Connected$($ansiReset): $($device.FriendlyName)"
                Add-Content -Path $logPath -Value $logMessage
                $message = @"
A USB device was plugged into <b>$(($env:USERNAME+"@"+$env:COMPUTERNAME).ToLower())</b>`n
<b>Name</b>: $($device.FriendlyName)
<b>Date</b>: $(Get-Date -Format "dd-MMM-yy")
<b>Time</b>: $(Get-Date -Format "hh:mm:ss tt")
<b>Id</b>: $($device.InstanceId)
<b>OS</b>: $($env:OS)
"@
                Send-TelegramTextMessage -BotToken $botToken -ChatID $telegramChatId -Message $message | Out-Null
            }
        }

        # Check for disconnected devices
        foreach ($deviceId in $connectedDevices) {
            if ($currentDevices.InstanceId -notcontains $deviceId) {
                $connectedDevices = $connectedDevices -ne $deviceId
                $dateTime = Get-Date
                $logMessage = "[$dateTime] Disconnected: $($deviceId)"
                Write-Host $ansiRed"Disconnected$($ansiReset): $($deviceId)"
                Add-Content -Path $logPath -Value $logMessage
            }
        }

        Start-Sleep -Seconds 1
    }
}

MonitorUSBDevices
