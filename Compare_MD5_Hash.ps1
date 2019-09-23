# PowerShell script that compares the MD5 hash of a file in the C:\Users\$env:USERNAME\Downloads folder with an expected hash value

# Prompt for the filename and don't continue unless input is detected and the file is valid
do {
    $File = Read-Host 'Enter the complete filename in the Downloads folder'
    $Path = "C:\Users\$env:USERNAME\Downloads\"
    $FullPath = ($Path + $File)
    $Validate = (Test-Path $FullPath)
    if ($File -eq "") {
        Write-Host "Please enter a file name in the Downloads folder to continue..." -ForegroundColor Red
    }
    elseif ($Validate -eq $FALSE) {
        Write-Host "The file $FullPath does not exist. `nPlease enter a valid filename in the Downloads folder to continue..." -ForegroundColor Red
    }
    else {
        Write-Host "Calculating the MD5 hash of $File" -ForegroundColor Green
    }
} until ($File -ne "" -and $Validate -eq $TRUE)

# Prompt for the optional, expected MD5 hash value
do {
    $ExpectedHash = Read-Host "Enter the expected MD5 hash value (optional).`nEnter 'none' if you don't want to provide an expected MD5 hash value."
    if ($ExpectedHash -eq "none") {
        Write-Host "You chose not to provide an MD5 hash value." -ForegroundColor Yellow
    }
    elseif ($ExpectedHash -ne "none") {
        Write-Host "Comparing the MD5 hash of $File" -ForegroundColor Green
    }
    else {
        Write-Host "Please enter an expected MD5 hash value  or 'none' to continue..." -ForegroundColor Red
    }
} until ($ExpectedHash -ne "")

# Compute the file hash using MD5
$ComputeHash = Get-FileHash "$($Path)$File" -Algorithm MD5

# Display the file hash info and prompt that the file hashes match or the hash is different and the file may be corrupt
$ComputeHash
if ($ComputeHash.hash -eq $ExpectedHash) {
    Write-Host "`nThe MD5 hash value matches the expected value." -ForegroundColor Green
}
elseif ($ExpectedHash -eq "none") {
    Write-Host "`nAn MD5 hash was not provided for comparison!" -ForegroundColor Yellow
}
elseif ($ComputeHash.hash -ne $ExpectedHash) {
    Write-Host "`nThe MD5 hash value does not match. This file may be corrupt!" -ForegroundColor Red
}
else {
    Write-Warning -Message "Oops...something must have gone wrong!"
}
