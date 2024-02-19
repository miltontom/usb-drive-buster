$ansiRed = "`e[31m"
$ansiGreen = "`e[32m"
$ansiReset = "`e[0m"

$telegramBotToken = "6798888655:AAG6mQYSBniTxiAsqJ_e3pq6kRPoKLJMr7Q"
$telegramGroupChatId = "-1002137906945"

function getDeviceIdDetails($instanceId) {
    if ($instanceId -match "VID_([0-9A-F]+)&PID_([0-9A-F]+)\\(.+)") {
        $vendorId = $matches[1]
        $productId = $matches[2]
        $serialNumber = $matches[3]
    
        return @{
            "Vendor" = $vendorId
            "Product" = $productId
            "Serial Id" = $serialNumber
        }
    } else {
        Write-Host "Unable to extract VID and PID from the provided string."
    }
}

function getVendorAndProductDetails($vendId, $prodId) {
    $fileContent = Get-Content $PSScriptRoot\usb.ids
    $details = New-Object System.Collections.ArrayList

    foreach ($line in $fileContent) {
        if (-not ($line -match "^\t")) {
            $vendorDetails = $line -split '  '
            $vendorId = $vendorDetails[0]
            $vendorName = $vendorDetails[1]

            if ($vendorId.Equals($vendId)) {
                $details += $vendorName
            }
        } else {
            $productDetails = $line.TrimStart() -split '  '
            $productId = $productDetails[0]
            $productName = $productDetails[1]

            if ($productId.Equals($prodId)) {
                $details += $productName
            }
        }
    }

    return $details
}

function getDriveSize($serialNumber) {
    $disks = Get-Disk
    
    foreach ($disk in $disks) {
        if ($disk.SerialNumber -like $serialNumber) {
            return [math]::Round(($disk.Size / 1GB)) + 1
        }
    }
}

function MonitorUSBDevices {
    $logPath = $PSScriptRoot+"\usbdrive.log"
    $connectedDevices = @()

    while ($true) {
        $currentDevices = Get-PnpDevice | Where-Object {$_.Class -eq "USB" -and $_.FriendlyName -like "*USB Mass Storage Device*" -and $_.Present -eq $true}
        
        # Check for connected devices
        foreach ($device in $currentDevices) {
            $deviceIdDetails = getDeviceIdDetails $device.InstanceId
            $vendorId = $deviceIdDetails["Vendor"]
            $productId = $deviceIdDetails["Product"]
            $deviceSerialId = $deviceIdDetails["Serial Id"]
            $deviceVendorAndProductDetails = getVendorAndProductDetails $vendorId $productId
            $vendorName = $deviceVendorAndProductDetails[0]
            $productName = $deviceVendorAndProductDetails[1]

            if ($connectedDevices -notcontains $device.InstanceId) {
                $connectedDevices += $device.InstanceId
                $dateTime = Get-Date -Format "dd-MM-yy HH:mm:ss"
                $logMessage = "[$dateTime] [CONNECTED] $($device.FriendlyName)`n`tVENDOR: $($vendorName)`n`tPRODUCT: $($productName)`n`tSERIAL ID: $($deviceSerialId)`n`tSIZE: $(getDriveSize($deviceSerialId)) GB"
                Write-Host $ansiGreen"Connected$($ansiReset): $($device.FriendlyName)"
                Add-Content -Path $logPath -Value $logMessage

                $message = @"
A USB drive was plugged into <b>$(($env:USERNAME+"@"+$env:COMPUTERNAME).ToLower())</b>`n
<b>Name</b>: $($device.FriendlyName)
<b>Date</b>: $(Get-Date -Format "dd-MMM-yy")
<b>Time</b>: $(Get-Date -Format "hh:mm:ss tt")
<b>Vendor</b>: $($vendorName)
<b>Product</b>: $($productName)
<b>Serial Id</b>: $($deviceSerialId)
<b>Size</b>: $(getDriveSize($deviceSerialId)) GB
<b>OS</b>: $($env:OS)
"@
                Send-TelegramTextMessage -BotToken $telegramBotToken -ChatID $telegramGroupChatId -Message $message | Out-Null
            }
        }

        # Check for disconnected devices
        foreach ($deviceId in $connectedDevices) {
            if ($currentDevices.InstanceId -notcontains $deviceId) {
                $connectedDevices = $connectedDevices -ne $deviceId
                $dateTime = Get-Date -Format "dd-MM-yy HH:mm:ss"
                $logMessage = "[$dateTime] [DISCONNECTED] $($deviceId)`n`tVENDOR: $($vendorName)`n`tPRODUCT: $($productName)`n`tSERIAL ID: $($deviceSerialId)`n`tSIZE: $(getDriveSize($deviceSerialId)) GB"
                Write-Host $ansiRed"Disconnected$($ansiReset): $($deviceId)"
                Add-Content -Path $logPath -Value $logMessage
            }
        }

        Start-Sleep -Seconds 1
    }
}

MonitorUSBDevices
