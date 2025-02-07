<#
.SYNOPSIS
Persistence-Finder aims to uncover malicious persistence in common Windows locations such as the registry, scheduled tasks, services, startup folders and wmi consumers
#>

# Scheduled Tasks

Write-Output "=============================`nSCHEDULED TASKS`n=============================`n"

cmd.exe /c schtasks /query /fo csv /v | ConvertFrom-Csv | Select-Object @{N='Name'; E={$_.TaskName}}, @{N='Task'; E={$_."Task To Run"}} | Where-Object {$_.Task -match '.*\.(exe|js|bat|py|cmd)' } | Format-List

# Services
Write-Output "=============================`nSERVICES`n=============================`n"

Get-CimInstance -class Win32_Service | Select-Object Name, PathName | Where-Object {$_.PathName -notmatch '.*system32.*'} | Format-List

# Startup folders

Write-Output "=============================`nSTARTUP FOLDERS`n=============================`n"

$StartupFolders = Get-ChildItem 'C:\users\*\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup\'

foreach ($folder in $StartupFolders) {
    Write-Host $folder
    Get-ChildItem $folder | Select-Object Name, CreationTime | Sort-Object CreationTime -Descending | Format-List
}

# Registry

Write-Output "=============================`nREGISTRY PERSISTENCE`n=============================`n"

$RegistryKeys = @("HKU\*\Software\Microsoft\Windows\CurrentVersion\Run",
 "HKU\*\Software\Microsoft\Windows\CurrentVersion\RunOnce",
 "HKU\*\Software\Microsoft\Windows\CurrentVersion\RunOnceEx",
 "HKLM\Software\Microsoft\Windows\CurrentVersion\Run",
 "HKLM\Software\Microsoft\Windows\CurrentVersion\RunOnce",
 "HKLM\Software\Microsoft\Windows\CurrentVersion\RunOnceEx",
 "HKU\*\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders",
 "HKU\*\Software\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders",
 "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders",
 "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders")

 foreach ($key in $RegistryKeys) {
    Get-ChildItem Registry::$key -ErrorAction SilentlyContinue
 }

 # WMI Persistence

Write-Output "=============================`nWMI PERSISTENCE`n=============================`n"


Get-WmiObject -Class __FilterToConsumerBinding -Namespace root\subscription
Get-WmiObject -Class __EventFilter -Namespace root\subscription
Get-WmiObject -Class __EventConsumer -Namespace root\subscription