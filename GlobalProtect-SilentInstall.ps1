# PS script to check Palo Alto Global Protect version and install the latest version if not up to date
# Author: Josh Jaggard

# !!!!!!!!!!!!!! IMPORTANT !!!!!!!!!!!!!!
# Set the target GP version variable for comparison (i.e. 5.2.9, 5.2.10, etc.)
$targetVer = "5.2.12"
# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!


# Define function for the install process.
# Function will be called later when version comparison requires an upgrade
function installGP {
    # Define GP install arguments
    $msiArguments = @(
        "/i"
        "GlobalProtect64.msi"
        "/quiet"
        "PORTAL=portal.myorg.com"
        "CERTIFICATESTORELOOKUP=machine"
        "CONNECTMETHOD=pre-logon"
    )
    # Run the installer w/arguments
    Start-Process "msiexec.exe" -ArgumentList $msiArguments -Wait -NoNewWindow 

    # If a specific GP registry value is present, ensure it's set to 1. Otherwise create the registry item and set the value.
    # This sets GlobalProtect as the default credential provider for Windows on login
    if (Get-ItemProperty -path "HKLM:\SOFTWARE\Palo Alto Networks\GlobalProtect" -name "SetGPCPDefault") {
        Set-ItemProperty -path "HKLM:\SOFTWARE\Palo Alto Networks\GlobalProtect" -name "SetGPCPDefault" -Value 1
    }
    else {
        New-ItemProperty -path "HKLM:\SOFTWARE\Palo Alto Networks\GlobalProtect" -name "SetGPCPDefault" -Value 1 -PropertyType dword
    }
    
    Write-Host "`nGlobalProtect upgrade complete." -ForegroundColor Green
    
    # Restart the PC (remove comment around section below to add restart)
    
    # Write-Host "`nRebooting PC." -ForegroundColor Yellow
    # restart-computer -Force
}

# Check GP version, compare to target GP version, and run install function if an upgrade is required
# If installed version is equal to or greater than target GP version, the install function will not be run

Write-Host "`nFetching Palo Alto GlobalProtect Info...`n"

# Fetch and store GP info and version as variables
$gpInfo = Get-WmiObject win32_product -Filter "Name LIKE '%GlobalProtect%'"
$gpVer = $gpInfo.Version

Write-Host "The installed GlobalProtect version is $gpVer"

# Split the installed version string into individual pieces and convert to integers for comparison with target version
$gpVerMajor = $gpVer.Split('.')[0]
$gpVerMinor = $gpVer.Split('.')[1]
$gpVerBuild = $gpVer.Split('.')[2]

$gpVerMajorInt = [int]$gpVerMajor
$gpVerMinorInt = [int]$gpVerMinor
$gpVerBuildInt = [int]$gpVerBuild

# Split the target version string into individual pieces and convert to integers for comparison with installed version
$targetVerMajor = $targetVer.Split('.')[0]
$targetVerMinor = $targetVer.Split('.')[1]
$targetVerBuild = $targetVer.Split('.')[2]

$targetVerMajorInt = [int]$targetVerMajor
$targetVerMinorInt = [int]$targetVerMinor
$targetVerBuildInt = [int]$targetVerBuild


Write-Host "The target GlobalProtect version is $targetVer`n"

# Compare the current and target versions and install update if version is less than target
if ($gpVerMajorInt -gt $targetVerMajorInt) {
    Write-Host "Installed GP version is higher than the target version..."
    Write-Host "Upgrade will not be performed" -ForegroundColor Red
}

elseif ($gpVerMajorInt -lt $targetVerMajorInt) {
    Write-Host "Installed GP version is lower than the target version..."
    Write-Host "Upgrading GP to target version..." -ForegroundColor Green
    installGP
}
elseif ($gpVerMajorInt -eq $targetVerMajorInt) {
    if ($gpVerMinorInt -gt $targetVerMinorInt) {
        Write-Host "Installed GP version is higher than the target version..."
        Write-Host "Upgrade will not be performed" -ForegroundColor Red
    }
    elseif ($gpVerMinorInt -lt $targetVerMinorInt) {
        Write-Host "Installed GP version is lower than the target version..."
        Write-Host "Upgrading GP to target version..." -ForegroundColor Green
        installGP
    }
    elseif ($gpVerMinorInt -eq $targetVerMinorInt) {
        if ($gpVerBuildInt -gt $targetVerBuildInt) {
            Write-Host "Installed GP version is higher than the target version..."
            Write-Host "Upgrade will not be performed" -ForegroundColor Red
        }
        elseif ($gpVerBuildInt -lt $targetVerBuildInt) {
            Write-Host "Installed GP version is lower than the target version..."
            Write-Host "Upgrading GP to target version..." -ForegroundColor Green
            installGP
        }
        elseif ($gpVerBuildInt -eq $targetVerBuildInt) {
            Write-Host "Installed GP version is equal to the target version..."
            Write-Host "Upgrade will not be performed" -ForegroundColor Red
        }
        else {
            Write-Host "Unable to compare current and target versions. No upgrade will take place."
        }
    }
    else {
        Write-Host "Unable to compare current and target versions. No upgrade will take place."
    }
}
else {
    Write-Host "Unable to compare current and target versions. No upgrade will take place."
}
