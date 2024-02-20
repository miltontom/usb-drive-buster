# USB Drive Buster

Bust anyone who connects a USB drive to cheat in practical examinations.

## Why I created this?

As practical examinations in computer science involve writing code, students tend to bring in USB flash drives with source code stored in it and the invigilators may be unaware of this so I decided to implement this system for my college as it was needed. However, this can also be implemented in schools as well.

## Working

The script runs as a service in the background and monitors for USB flash drives connected to the computer and logs the details to a file *usbdrivebuster.log* which contains info about when the device was connected/disconnected, vendor & product name, serial id and the drive size. It also a sends a message via telegram so that the invigilators can know about it. 

## Setup

### Prerequisites
* PowerShell 6.1.0 (or higher)
* [PoshGram](https://www.powershellgallery.com/packages/PoshGram/2.0.0) module installed
* Telegram requirements
    * Telegram account
    * Telegram [bot](https://core.telegram.org/bots#how-do-i-create-a-bot)
    * Group chat ID (refer this [video](https://youtu.be/UPC5Ck1oU6k?feature=shared&t=17))
    * Bot must be a member of the group chat

### Set bot token and chat id
On the `main.ps1` script file paste the token and id
```
$telegramBotToken = "nnnnnnnnn:xxxxxxx-xxxxxxxxxxxxxxxxxxxxxxxxxxx"
$telegramGroupChatId = "-nnnnnnnnn"
```

### Create a service (Windows)

1. Install `nssm` from the scoop package manager
2. Create a service

    ```powershell
    nssm install USBDriveBusterService "C:\path\to\pwsh.exe" "-ExecutionPolicy Bypass -File C:\path\to\main.ps1"
    ```
    **NOTE**: *The absolute path to the* `pwsh.exe` *and* `main.ps1` *should be specified*.
3. Configure the service

    ```powershell
    nssm edit USBDriveBusterService
    ```
    Set "Log on as" to the user account for your system, just specify the username and password for the user account and click `Edit service`.

    ![nssm service editor](previews\nssm.png)

    You can also set the startup type, the default is `automatic`

### Service Operations
**NOTE**: *The following operations should be run with administrator privileges*.
1. Start the service

    ```powershell
    # cmd
    net start USBDriveBusterService

    # powershell
    Start-Service -Name USBDriveBusterService
    ```
2. Stop the service

    ```powershell
    # cmd
    net stop USBDriveBusterService

    # powershell
    Stop-Service -Name USBDriveBusterService
    ```
3. Restart the service

    ```powershell
    # cmd
    net restart USBDriveBusterService

    # powershell
    Restart-Service -Name USBDriveBusterService
    ```
4. Remove the service

    ```powershell
    nssm remove USBDriveBusterService
    ```