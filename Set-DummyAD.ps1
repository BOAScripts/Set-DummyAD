# 1. DETECT ADDS / install ADDS

if (Get-WindowsFeature AD-Domain-Services).Installed){
    Write-Host "[OK] ADDS already installed" -ForegroundColor Green
}
else {
    Write-Host "[?] ADDS not installed" -ForegroundColor Yellow
    $rep = Read-Host " [?] Do you want to install Active Directory Domain and Services ?"
    if ($rep -like 'y*'){
        $installADDS = $true
    }
    else {exit}
}

## domain.tld
## OR
## install ADDS
### Get DSRM psw
### Get domain (dom.tld)
### Install-WindowsFeature AD-Domain-Services -IncludeAllSubFeature -IncludeManagementTools
### Install-ADDSForest -DomainName $domain -InstallDns -SafeModeAdministratorPassword $DSRM

# 2. import files present ?
## ERROR + STOP if not

# 3. 