# Define known RMM tools, install paths, and executable names - WIP
$knownRMMs = @(
    @{ Name = "TeamViewer"; Paths = @("C:\Program Files\TeamViewer", "C:\Program Files (x86)\TeamViewer"); Executables = @("TeamViewer.exe"); LogPaths = @("C:\Program Files\TeamViewer\Connections_incoming.txt") },
    @{ Name = "AnyDesk"; Paths = @("C:\Program Files\AnyDesk", "C:\Program Files (x86)\AnyDesk"); Executables = @("AnyDesk.exe"); LogPaths = @("C:\ProgramData\AnyDesk\connection_trace.txt", "C:\ProgramData\AnyDesk\ad_svc.trace", "C:\Users\*\AppData\Roaming\AnyDesk\ad.trace") },
    @{ Name = "ConnectWise Control"; Paths = @("C:\Program Files (x86)\ScreenConnect Client*", "C:\Program Files\ScreenConnect Client*"); Executables = @("connectwisecontrol.exe", "ScreenConnect.Client.exe"); LogPaths = @("C:\Program Files*\ScreenConnect\App_Data\Session.db") },
    @{ Name = "Splashtop"; Paths = @("C:\Program Files\Splashtop", "C:\Program Files (x86)\Splashtop"); Executables = @("SplashtopStreamer.exe"); LogPaths = @("C:\Program Files (x86)\Splashtop\Splashtop Remote\Server\log\SPlog.txt", "C:\Program Data\Splashtop\Temp\log\FTCLog.txt") },
    @{ Name = "GoToAssist"; Paths = @("C:\Program Files (x86)\GoToAssist", "C:\Program Files\GoToAssist"); Executables = @("g2aviewer.exe"); LogPaths = @("UKNOWN") },
    @{ Name = "Kaseya"; Paths = @("C:\Program Files\Kaseya", "C:\Program Files (x86)\Kaseya"); Executables = @("AgentMon.exe"); LogPaths = @("C:\Program Files*\Kaseya\*\agentmon.log") },
    @{ Name = "Zoho Assist"; Paths = @("C:\Program Files\Zoho", "C:\Program Files (x86)\Zoho"); Executables = @("ZohoAssist.exe"); LogPaths = @("UKNOWN") },
    @{ Name = "DWAgent"; Paths = @("C:\DWAgent"); Executables = @("dwagent.exe"); LogPaths = @("C:\Program Files\DWAgent\dwagent.log") },
    @{ Name = "NinjaRMM"; Paths = @("C:\Program Files\NinjaRMM", "C:\Program Files (x86)\NinjaRMM"); Executables = @("NinjaRMMTray.exe"); LogPaths = @("UKNOWN") },
    @{ Name = "Pulseway"; Paths = @("C:\Program Files\Pulseway", "C:\Program Files (x86)\Pulseway"); Executables = @("PCMonitorManager.exe"); LogPaths = "C:\Program Files (x86)\Pulseway\remotecontrolclient.log", "C:\Users\*\AppData\Roaming\Pulseway Remote Control\remotecontrolclient.log"  }
    @{ Name = "NetSupport"; Paths = @("C:\Program Files\NetSupport", "C:\Program Files (x86)\NetSupport"); Executables = @("client32.exe"); LogPaths = @("UKNOWN") }
)

# Suspicious directories to search for RMM binaries
$suspiciousDirs = @(
    "C:\Users\*\Downloads",
    "C:\Users\*\Documents",
    "C:\Users\*\Pictures",
    "C:\Users\*\Videos",
    "C:\Users\*\Desktop",
    "C:\Users\Public"
)

# Date threshold for classifying as malicious - anything from within the last 7 days
$now = (Get-Date).ToUniversalTime()
$threshold = $now.AddDays(-7)
$utctimestamp = $now.ToString("yyyy-MM-dd HH:mm:ss")

Write-Host ""
Write-Host "--- Finding RMM Tools -  Started: $utctimestamp ---"
Write-Host ""

Write-Host "========================`n FOUND TOOLS`n========================`n"

# Search known install paths
foreach ($tool in $knownRMMs) {
    foreach ($pathPattern in $tool.Paths) {
        $foundPaths = Get-ChildItem -Path $pathPattern -Recurse -ErrorAction SilentlyContinue -Include *.exe | Where-Object { $_.PSIsContainer -eq $false }

        foreach ($file in $foundPaths) {
            $creationTime = $($file.CreationTime).ToUniversalTime()
            $lastWriteTime = $($file.LastWriteTime).ToUniversalTime()

            $isRecent = $false
            if ($creationTime -gt $threshold -or $lastWriteTime -gt $threshold) {
                $isRecent = $true
            }

            $classification = ""
            if ($isRecent -eq $true) {
                $classification = "SUSPICIOUS"
            }
            else {
                $classification = "BENIGN"
            }

            if ($classification -eq "SUSPICIOUS") {
                Write-Host "[$classification - RECENTLY MODIFIED] $($tool.Name)`n"
            }
            else {
                Write-Host "[$classification] $($tool.Name)" 
            }

            Write-Host "[-] Path: $($file.FullName)"
            $fileHash = (Get-FileHash -Algorithm SHA256 $($file.FullName)).Hash
            Write-Host "[-] Hash: $fileHash"

            # Format timestamps to UTC
            $creationTimeUTC = $creationTime.ToString("yyyy-MM-dd HH:mm:ss")
            $modifiedTimeUTC = $lastWriteTime.ToString("yyyy-MM-dd HH:mm:ss")
            Write-Host "[-] Created: $creationTimeUTC"
            Write-Host "[-] Modified: $modifiedTimeUTC"

            # Get log locations for current tool
            $matchingLogPaths = $tool.LogPaths

            foreach ($logPath in $matchingLogPaths)  {
                if ($logPath -ne "UNKNOWN") {
                    $logLocation = (Get-ChildItem -Path $logPath -Recurse -ErrorAction SilentlyContinue).FullName
                }
                if ($loglocation) {
                    Write-Host "[-] Log Path: $loglocation"
                }
                else {
                    Write-Host "[-] Log Path: UNKNOWN"
                }
            }
            Write-Host ""
        }
    }
}

# Search suspicious directories for known executables
foreach ($dirPattern in $suspiciousDirs) {
    $files = Get-ChildItem -Path $dirPattern -Recurse -Include *.exe -ErrorAction SilentlyContinue

    foreach ($file in $files) {
        foreach ($tool in $knownRMMs) {
            foreach ($exeName in $tool.Executables) {
                if ($file.Name -ieq $exeName) {
                    $creationTime = $file.CreationTime
                    $lastWriteTime = $file.LastWriteTime

                    $isRecent = $false
                    if ($creationTime -gt $threshold -or $lastWriteTime -gt $threshold) {
                        $isRecent = $true
                    }

                    $classification = ""
                    if ($isRecent -eq $true) {
                        $classification = "MALICIOUS"
                    }
                    else {
                        $classification = "BENIGN"
                    }

                    Write-Host "[SUSPICIOUS PATH - LIKELY $classification] $($tool.Name)`n"
                    Write-Host "[-] Path: $($file.FullName)"
                    $fileHash = (Get-FileHash -Algorithm SHA256 $($file.FullName)).Hash
                    Write-Host "[-] Hash: $fileHash"
                    $creationTimeUTC = $creationTime.ToString("yyyy-MM-dd HH:mm:ss")
                    $modifiedTimeUTC = $lastWriteTime.ToString("yyyy-MM-dd HH:mm:ss")
                    Write-Host "[-] Created: $creationTimeUTC"
                    Write-Host "[-] Modified: $modifiedTimeUTC"
                    Write-Host ""
                }
            }
        }
    }
}

Write-Host "--- Finding RMM Tools Complete ---"
Write-Host ""
