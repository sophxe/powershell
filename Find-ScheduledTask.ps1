<#
.SYNOPSIS
Find-ScheduledTask aims to find a scheduled task on the host with a given task name with the -Triage switch, and when passed with the Remediation switch, can remediate it from the host. This can be particularly useful in cases where the same scheduled task is found across multiple hosts. 
.PARAMETER name
The name of the task to search for.
.EXAMPLE 
Find-ScheduledTask.ps1 -Name 'maltask' -Triage
Find-ScheduledTask.ps1 -Name 'maltask' -Remediate
#>

[CmdletBinding()]
param (
    [string[]]$Name,
    [switch]$Triage,
    [switch]$Remediate
)

    # TODO - make this better to perform string searches on task to run and not just name

function Find-ScheduledTask {
    # Get scheduled tasks
    $tasks = cmd.exe /c schtasks /query /fo csv /v | ConvertFrom-Csv | Select-Object TaskName, "Task To Run" | Where-Object {$_.TaskName -like "*$Name*"}

    # Print out scheduled tasks
    Write-Host "`n=============================`n Scheduled Tasks Found`n============================="
    Write-Output $tasks | Format-List

    if ($Triage) {
        $count = $tasks.length
        Write-Output "Triage Completed - $count Scheduled Tasks Found. To remediate, re-run script with -Remediate switch"
    }

    # To remove the tasks
    if ($Remediate) {
        foreach ($task in $tasks) {
            try {
                $taskName = $task.TaskName
                $taskToRun = $task."Task To Run"
                cmd.exe /c schtasks /tn $taskName /delete /f
                Write-Output "[-] Task $taskName with action $taskToRun deleted"
            }
            catch {
                # If it fails
                Write-Output "Cannot delete $taskName"
            }
        }
        
    }
}

Find-ScheduledTask


