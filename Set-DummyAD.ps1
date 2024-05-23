# Check local files presence

$modelPath = ".\model.json"
$usersCSVPath = ".\1000names.csv"

if (!Test-Path $modelPath){
    Write-Host "$modelPath not present!" -ForegroundColor Red
    Exit
}
if (!Test-Path $usersCSVPath){
    Write-Host "$usersCSVPath not present!" -ForegroundColor Red
    Exit
}

# Check ADDS role
if ((Get-WindowsFeature AD-Domain-Services).Installed){
    Write-Host "[OK] ADDS already installed" -ForegroundColor Green
    ## Get domain.tld + domain DN
}
else {
    Write-Host "[?] ADDS not installed" -ForegroundColor Yellow
    $rep = Read-Host " [?] Do you want to install Active Directory Domain and Services ?"
    if ($rep -like 'y*'){
        $DSRMpsw = ConvertTo-SecureString "Test1234=" -AsPlainText -Force
        $domain = Read-Host "Enter domain name (domain.tld)"
        Write-Host "[+] Installing ADDS role" -ForegroundColor Yellow
        try{
            Install-WindowsFeature AD-Domain-Services -IncludeAllSubFeature -IncludeManagementTools
        }
        catch{write-host $_}
        Write-Host "[+] Promote server as Domain Controller"
        try{
            Install-ADDSForest -DomainName $domain -InstallDns -SafeModeAdministratorPassword $DSRMpsw        
        }
        catch{write-host $_}
    }
    else {exit}
}


### Install-WindowsFeature AD-Domain-Services -IncludeAllSubFeature -IncludeManagementTools
### Install-ADDSForest -DomainName $domain -InstallDns -SafeModeAdministratorPassword $DSRM

# 2. import files present ?
## ERROR + STOP if not

# 3. 