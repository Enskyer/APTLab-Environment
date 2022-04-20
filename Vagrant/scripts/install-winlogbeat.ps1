# Purpose: Configure winlogbeat
# Source: https://github.com/cyberdefenders/DetectionLabELK/blob/master/Vagrant/scripts/install-winlogbeat.ps1

$service = Get-WmiObject -Class Win32_Service -Filter "Name='winlogbeat'"
If (-not ($service)) {
  choco install winlogbeat -y

  $confFile = @"
#-------------------------- Windows Logs To Collect -----------------------------
winlogbeat.event_logs:
  - name: Application
    ignore_older: 30m
  - name: Security
    ignore_older: 30m
  - name: System
    ignore_older: 30m
  - name: Microsoft-windows-sysmon/operational
    ignore_older: 30m
  - name: Microsoft-windows-PowerShell/Operational
    ignore_older: 30m
    event_id: 4103, 4104
  - name: Windows PowerShell
    event_id: 400,600
    ignore_older: 30m
  - name: Microsoft-Windows-WMI-Activity/Operational
    event_id: 5857,5858,5859,5860,5861

#----------------------------- Kafka output --------------------------------
output.kafka:
  # initial brokers for reading cluster metadata
  # Place your HELK IP(s) here (keep the port).
  # If you only have one Kafka instance (default for HELK) then remove the 2nd IP that has port 9093
  hosts: ["192.168.57.105:9092"]
  topic: "winlogbeat"
  ############################# HELK Optimizing Latency ######################
  max_retries: 2
  max_message_bytes: 1000000
"@
  $confFile | Out-File -FilePath C:\ProgramData\chocolatey\lib\winlogbeat\tools\winlogbeat.yml -Encoding ascii

  # Exiting: Index management requested but the Elasticsearch output is not configured/enabled 
  # winlogbeat --path.config C:\ProgramData\chocolatey\lib\winlogbeat\tools setup

  sc.exe failure winlogbeat reset= 30 actions= restart/5000
  Start-Service winlogbeat
}
else {
  Write-Host "winlogbeat is already configured. Moving On."
}
If ((Get-Service -name winlogbeat).Status -ne "Running") {
  throw "winlogbeat service was not running"
}
