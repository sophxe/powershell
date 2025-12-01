<#
.SYNOPSIS
New-NWPLMeet.ps1 takes a csv file exported from OpenPowerlifting software, formats it using the openlifter-convert script, and then creates a new meet and pushes it to your local fork of the OpenPowerlifting project. You will then need to create a pull request for your changes to be committed to the upstream project. You may also need to edit the location of your local fork in the $MeetData variable.
.PARAMETER File
The name of the file. This assumes the file is already within your local Downloads folder.
.EXAMPLE 
New-NWPLMeet.ps1 -File 'Summer-Slam-2025.opl.csv' -Fed 'epa'
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory, HelpMessage = 'Add the file name of the OpenPL meet data')][string]$File,
    [Parameter(Mandatory, HelpMessage = 'Add the Federation name as per the repo')][string]$Fed
)

$ErrorActionPreference = "Stop"

# Check file parameter if it exists and is in the right format

$MeetData = "$Env:USERPROFILE\openpl\opl-data\meet-data\$Fed\"
$MeetFolder = Get-Item "$Env:USERPROFILE\Downloads\"
$MeetFile = "$MeetFolder\$File"

$CheckMeetFileExists = Test-Path $MeetFile
$CheckFedExists = Test-Path $MeetData

if ($CheckMeetFileExists -And $MeetFile -notlike "*.opl.csv") {
    Write-Host "[-] ERROR: Invalid file format for $File - ensure the file name ends in .opl.csv" -ForegroundColor Red
    exit
}

if (-not $CheckFedExists) {
    Write-Host "[-] ERROR: Federation $Fed doesn't exist - double check the federation name" -ForegroundColor Red
}

# get last created folder, then add 1 to it
$LastFolder = Get-ChildItem $MeetData -Directory | Where-Object {$_.Name -match '\d+$'} | Sort-Object Name | Select-Object -Last 1
$LastFolderNumber = [Int]$LastFolder.Name
$NewFolderName = $LastFolderNumber + 1

# check path doesn't already exist - this should be false if all is well
$CheckPath = Test-Path $MeetData\$NewFolderName

if ($CheckMeetFileExists -And !$CheckPath) {

    Set-Location $MeetData

    # make new folder location
    $NewFolderLocation = $MeetData + $NewFolderName

    # Create new branch and switch into it

    git.exe checkout -b adding-new-meet-$NewFolderName

    # Create the new directory
    New-Item -Type Directory -Name $NewFolderName | Out-Null
    Write-Host "[-] $NewFolderName created at $NewFolderLocation" -ForegroundColor Green

    # move meet data to newly created folder and then run the convert.py 
    Set-Location $NewFolderLocation

    Copy-Item $MeetFile .
    # rename the original meet file so it can be marked as done
    Rename-Item $MeetFile "$Meetfile.DONE"
    # reset the $MeetFile variable so it now has the new location and then rename it to original.csv for parsing
    $MeetFile = Get-ChildItem . -Filter *.opl.csv
    Rename-Item $MeetFile .\original.csv 
    Write-Host "[-] $MeetFile copied to $NewFolderLocation" -ForegroundColor Green

    # copy over openlifter scripts for conversion, then remove everything else once done
    Copy-Item "$Env:USERPROFILE\openpl\opl-data\scripts\openlifter-convert" .\openlifter-convert.py
    Copy-Item "$Env:USERPROFILE\openpl\opl-data\scripts\oplcsv.py" .\oplcsv.py
    powershell.exe "$Env:LOCALAPPDATA\Microsoft\WindowsApps\python3.exe" .\openlifter-convert.py

    # check files have been created
    $CheckFileCreate = Get-ChildItem . -Recurse -Filter *.csv -Exclude *.opl.csv, original.csv

    if ($CheckFileCreate) {
        Write-Host "[-] $MeetFile converted from original.csv to meet.csv and entries.csv" -ForegroundColor Green
        Get-ChildItem . -Recurse -Exclude *.csv | Remove-Item -Recurse -Force
        Write-Host "[-] $NewFolderName cleaned up and ready for pushing" -ForegroundColor Green
    }

    else {
        Write-Host "[-] ERROR - please check original file names and location then re-run script" -ForegroundColor Red
        exit
    }

    # push the new branch
    git.exe add .
    git.exe commit $BranchName -m "Adding new meet"
    git.exe push -u origin adding-new-meet-$NewFolderName

    Write-Host "Upload of $MeetFile to your Github repo successful - go and check the pipeline!" -ForegroundColor Green
    git.exe checkout main
}

else {
    Write-Host "[-] ERROR: $MeetFile does not exist or folder $NewFolderName already exists in the meet data - please check file name and folder name, you may need to perform manually if this error persists" -ForegroundColor Red
    exit
}


