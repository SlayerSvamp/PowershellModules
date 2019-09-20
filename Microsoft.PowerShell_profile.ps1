# the section below is written by Øyvind Kallstad
# the code was found in this article
# https://communary.net/2015/05/28/how-to-reload-the-powershell-console-session/

function Invoke-PowerShell {
    powershell -nologo
    Invoke-PowerShell
}

function Restart-PowerShell {
    if ($host.Name -eq 'ConsoleHost') {
        exit
    }
    Write-Warning 'Only usable while in the PowerShell console host'
}

Set-Alias -Name 'reload' -Value 'Restart-PowerShell'

$parentProcessId = (Get-WmiObject Win32_Process -Filter "ProcessId=$PID").ParentProcessId
$parentProcessName = (Get-WmiObject Win32_Process -Filter "ProcessId=$parentProcessId").ProcessName

if ($host.Name -eq 'ConsoleHost') {
    if (-not($parentProcessName -eq 'powershell.exe')) {
        Invoke-PowerShell
    }
}

# end of code by Øyvind Kallstad