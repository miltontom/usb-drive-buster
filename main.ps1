$red = "`e[31m"
$green = "`e[32m"
$reset = "`e[0m"

# Function to continuously monitor USB devices
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

        Start-Sleep -Seconds 1  # Adjust the interval as needed
    }
}

# Start monitoring USB devices
MonitorUSBDevices
