# VARS definition

$modelPath = ".\model.json"
$usersCSVPath = ".\1000names.csv"


# [1] Check local files presence and import in context
if (!(Test-Path $modelPath) -or !(Test-Path $usersCSVPath)){
    Write-Host "$modelPath or $usersCSVPath not present!" -ForegroundColor Red
    Exit
}
else {
    $model = Get-Content $modelPath | ConvertFrom-Json
    $CSVNames = [System.Collections.ArrayList](Get-Content $usersCSVPath | ConvertFrom-Csv -Delimiter ";")
}

# [2] Check/Install ADDS role
if ((Get-WindowsFeature AD-Domain-Services).Installed){
    Write-Host '[v] ADDS already installed' -ForegroundColor Green
    # Get domain.tld + domain DN
    try { 
        $domain = (Get-ADDomain).Forest
        $domainDN = (Get-ADRootDSE).rootDomainNamingContext
    }
    catch{
        write-host $_ -ForegroundColor Red
        write-host 'ADDS installed but no domain detected - is the server in a "WAITING TO PROMOTE" state ?'
    }
}
else {
    Write-Host '[!] ADDS not installed' -ForegroundColor Yellow
    $rep = Read-Host "    [?] Do you want to install Active Directory Domain and Services ? (y/n)"
    if ($rep -like 'y*'){
        $DSRMpsw = ConvertTo-SecureString $model.PSW -AsPlainText -Force
        $domain = Read-Host "    [?] Please enter domain name (domain.tld)"
        try{
            Write-Host '[+] Trying to install ADDS role' -ForegroundColor Yellow
            Install-WindowsFeature AD-Domain-Services -IncludeAllSubFeature -IncludeManagementTools
            Write-Host '[+] Trying to promote server as Domain Controller (expect a reboot warning)' -ForegroundColor Yellow 
            Install-ADDSForest -DomainName $domain -InstallDns -SafeModeAdministratorPassword $DSRMpsw -Force
            Write-Host '[!] You will be disconnected to login again with the domain Administrator (same password as local Adminstrator)' -ForegroundColor Yellow
        }
        catch{write-host $_ -ForegroundColor Red}
        

    }
    else {
        Write-Host "[?] You don't want to install ADDS - Exiting" -ForegroundColor Yellow
        Exit
    }
}

# [3] ZHU-LI, do the thing (Populate AD)

## Create OUs

### Root OU

### Custom OUs in model.json

### foreach Depts in model.json -> create an OU in Users

### Set GGS groups

### Set DLGS groups

### Create SharedFolder - SMB share Everyone

### Set ACLs to SharedFolder: DLGS (RO & RW)

## Get

