$ansiRed = "`e[31m"
$ansiGreen = "`e[32m"
$ansiReset = "`e[0m"

$botToken = "6158360786:AAHeCbQu0CwF0uynudTMB0dWhGtvwWu992s"
$telegramChatId = "-1002137906945"

function getDeviceIdDetails($instanceId) {
    if ($instanceId -match "VID_([0-9A-F]+)&PID_([0-9A-F]+)\\(.+)") {
        $vendorId = $matches[1]
        $productId = $matches[2]
        $serialNumber = $matches[3]
    
        return @{
            "Vendor" = $vendorId
            "Product" = $productId
            "Serial No." = $serialNumber
        }
    } else {
        Write-Host "Unable to extract VID and PID from the provided string."
    }
}

function getVendorAndProductDetails($vendId, $prodId) {
    $fileContent = Get-Content .\usb.ids
    $details = New-Object System.Collections.ArrayList

    foreach ($line in $fileContent) {
        if (-not ($line -match "^\t")) {
            $vendorDetails = $line -split '  '
            $vendorId = $vendorDetails[0]
            $vendorName = $vendorDetails[1]
            # write-host $vendorId $vendorName

            if ($vendorId.Equals($vendId)) {
                $details += $vendorName
            }
        } else {
            $productDetails = $line.TrimStart() -split '  '
            $productId = $productDetails[0]
            $productName = $productDetails[1]
            # write-host $productId $productName

            if ($productId.Equals($prodId)) {
                $details += $productName
            }
        }
    }

    return $details
}

function MonitorUSBDevices {
    $logPath = "C:\Users\Milton\Desktop\PowerShell\usb-buster\log"
    $connectedDevices = @()

    while ($true) {
        $currentDevices = Get-PnpDevice | Where-Object {$_.Class -eq "USB" -and $_.FriendlyName -like "*USB Mass Storage Device*" -and $_.Present -eq $true}
        
        # Check for connected devices
        foreach ($device in $currentDevices) {
            if ($connectedDevices -notcontains $device.InstanceId) {
                $connectedDevices += $device.InstanceId
                $dateTime = Get-Date -Format "dd-MM-yy HH:mm:ss"
                $logMessage = "[$dateTime] Connected: $($device.FriendlyName) (Instance ID: $($device.InstanceId))"
                Write-Host $ansiGreen"Connected$($ansiReset): $($device.FriendlyName)`t$($device.InstanceId)"
                Add-Content -Path $logPath -Value $logMessage

                $deviceIdDetails = getDeviceIdDetails $device.InstanceId
                $vendorId = $deviceIdDetails["Vendor"]
                $productId = $deviceIdDetails["Product"]
                $deviceVendorAndProductDetails = getVendorAndProductDetails $vendorId $productId
                $message = @"
A USB device was plugged into <b>$(($env:USERNAME+"@"+$env:COMPUTERNAME).ToLower())</b>`n
<b>Name</b>: $($device.FriendlyName)
<b>Date</b>: $(Get-Date -Format "dd-MMM-yy")
<b>Time</b>: $(Get-Date -Format "hh:mm:ss tt")
<b>Vendor</b>: $($deviceVendorAndProductDetails[0])
<b>Product</b>: $($deviceVendorAndProductDetails[1])
<b>Serial</b>: $($deviceIdDetails["Serial No."])
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
