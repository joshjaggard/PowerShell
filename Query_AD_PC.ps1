# Script to check a PC against AD and get the description to see what user it belongs to
# Author: Josh Jaggard

$textDivider = "#" * 85
Write-Host "`n$textDivider`n This script checks a PC hostname against AD and provides the user it's assigned to`n$textDivider`n"

# Prompt for a hostname and ensure input is provided
while($true) {
    do {
        $Hostname = Read-Host 'Enter a PC hostname or type "end" to exit'
        if ($Hostname -eq "") {
            Write-Host "No input detected. Please enter a PC hostname to continue...`n" -ForegroundColor Yellow
        }
        elseif ($Hostname -eq "end" -OR $Hostname -eq "exit" -OR $Hostname -eq "quit" -OR $Hostname -eq "close") {
            Write-Host "You chose the blue pill and will remain in ignorance`nQuitting the script`n" -ForegroundColor Cyan
            Exit
        }
        else {
            Write-Host "`nFetching info for $Hostname...`n"
        }
    } until ($Hostname -ne "")
    
    # Enter an AD server here
    $adServer = "myserver.example.com"

    # Run the Get-ADComputer command using the provided hostname and catch the error if the computer object isn't in AD
    try {
        $queryADforPC = Get-ADComputer $Hostname -Properties Description,ManagedBy,IPv4Address,DNSHostName -Server $adServer":3268"
        $queryADforPC | Format-List Name,Description,ManagedBy,IPv4Address
     }
    catch [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException] {
        Write-Host "The computer object $Hostname is not listed in AD`nCheck the hostname and try again`n" -ForegroundColor Red
    }
    catch {
        Write-Warning "This script just imploded`nTry running it again and maybe don't do whatever you just did"
    }

    # Run a simple ping connectivity test and output if the device is online or not
    Write-Host "Running connectivity test (may take up to 10s)..."

    # Determine PS console major version
    # The PS console version is used to insert the -TimeoutSeconds flag for newer versions that support it. This speeds up the connectivity check.
    $psVersion = $host.version.major

    try {
        if ($psVersion -gt 5) {
            $dnsName = Get-ADComputer $Hostname -Server $adServer":3268" | Select-Object -ExpandProperty DNSHostName
            $testPCnew = Test-Connection $dnsName -Count 2 -TimeoutSeconds 1 -Quiet -ea SilentlyContinue
            if ($testPCnew -eq $true) {
                Write-Host "$dnsName is online`n`n" -ForegroundColor Cyan
            }
            elseif ($testPCnew -eq $false){
                Write-Host "$dnsName is offline`n`n" -ForegroundColor Yellow
            }
            else {
                Write-Host "The connectivity status of $dnsName could not be determined`nMost likely DNS couldn't resolve the hostname`n`n" -ForegroundColor Red
            }
        }
        elseif ($psVersion -le 5) {
            $dnsName = Get-ADComputer $Hostname -Server $adServer":3268" | Select-Object -ExpandProperty DNSHostName
            $testPC = Test-Connection $dnsName -Count 2 -Quiet -ea SilentlyContinue
            if ($testPC -eq $true){
                Write-Host "$dnsName is online`n`n" -ForegroundColor Cyan
            }
            elseif ($testPC -eq $false){
                Write-Host "$dnsName is offline`n`n" -ForegroundColor Yellow
            }
            else {
                Write-Host "The connectivity status of $dnsName could not be determined`nMost likely DNS couldn't resolve the hostname`n`n" -ForegroundColor Red
            }
        }
        else {
            Write-Host "Couldn't determine PS console version"
        }
    }
    catch [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException] {
        Write-Host "The computer object $Hostname is not listed in AD`nA connectivity check could not be run`n" -ForegroundColor Red
    }
    catch {
        Write-Warning "This script just imploded`nTry running it again and maybe don't do whatever you just did"
    }
    #Loop the script
    Continue
}
