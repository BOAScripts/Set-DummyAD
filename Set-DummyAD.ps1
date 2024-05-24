# static VARIABLES definition
$modelPath = ".\model.json"
$usersCSVPath = ".\1000names.csv"


# [1] Check local files presence and import in context
if ((Test-Path $modelPath) -or (Test-Path $usersCSVPath)){
    $model = Get-Content $modelPath | ConvertFrom-Json
    $CSVNames = [System.Collections.ArrayList](Get-Content $usersCSVPath | ConvertFrom-Csv -Delimiter ";")
}
else {
    Write-Host "$modelPath or $usersCSVPath not present!" -ForegroundColor Red
    Exit
}

# [2] Check/Install ADDS role
if ((Get-WindowsFeature AD-Domain-Services).Installed){
    Write-Host '[v] ADDS already installed' -ForegroundColor Green
    # Get domain.tld + domain DN
    try { 
        $domain = (Get-ADDomain).Forest
        $domainDN = (Get-ADRootDSE).rootDomainNamingContext
        Write-Host "    [i] Domain is: $domain // Domain distinguished name is: $domainDN" -ForegroundColor Yellow
    }
    catch{
        write-host $_ -ForegroundColor Red
        write-host '[!] ADDS installed but no domain detected - is the server in a "WAITING TO PROMOTE" state ?' -ForegroundColor Red
    }
}
else {
    Write-Host '[!] ADDS not installed' -ForegroundColor Yellow
    $rep = Read-Host "    [?] Do you want to install Active Directory Domain and Services ? (y/n)"
    if ($rep -like 'y*'){
        Write-Host "    [!] DSRM password will be: $($model.PSW)" -ForegroundColor Yellow
        $DSRMpsw = ConvertTo-SecureString $model.PSW -AsPlainText -Force
        $domain = Read-Host "    [?] Please enter domain name (domain.tld)"
        try{
            Write-Host '[+] Trying to install ADDS role' -ForegroundColor Yellow
            Install-WindowsFeature AD-Domain-Services -IncludeAllSubFeature -IncludeManagementTools
            Write-Host '[+] Trying to promote server as Domain Controller (expect a reboot warning)' -ForegroundColor Yellow
            Write-Host '[i] EXCPECT A REBOOT WARNING ONCE DONE' -ForegroundColor Yellow
            Install-ADDSForest -DomainName $domain -InstallDns -SafeModeAdministratorPassword $DSRMpsw -Force
            Write-Host '[!] You will be disconnected to login again with the domain Administrator (same password as local Adminstrator)' -ForegroundColor Yellow
        }
        catch{write-host $_ -ForegroundColor Red}
    }
    else {
        Write-Host "[!] You don't want to install ADDS - Exiting" -ForegroundColor Red
        Exit
    }
}

# [3] ZHU-LI, do the thing (Populate AD)
Write-Host "[i] Populating AD following json & csv file" -ForegroundColor Yellow
## Create OUs
Write-Host "    [i] OUs generation" -ForegroundColor Yellow
try {
    ### Root OU
    New-ADOrganizationalUnit -Name $model.RootOUName -Path $domainDN -ProtectedFromAccidentalDeletion $model.PreventOUDeletion
    $RootOUdn = (Get-ADOrganizationalUnit -Filter * | Where-Object Name -eq $model.RootOUName).DistinguishedName
    Write-Host "    [+] $RootOUdn created" -ForegroundColor Yellow
    Write-Host "-------------------------"
    ### Custom OUs in model.json
    foreach ($ouName in $model.CustomOUs) {
        if ($ouName -notlike "*/*"){
            # This a TOP OU
            New-ADOrganizationalUnit -Name $ouName -Path $RootOUdn -ProtectedFromAccidentalDeletion $model.PreventOUDeletion
        }
        else {
            # This is a SUB OU
            $parentOU, $childOU = $ouName.Split('/')[0], $ouName.Split('/')[1]
            $parentOUdn = (Get-ADOrganizationalUnit -Filter * | Where-Object Name -eq $parentOU).DistinguishedName
            New-ADOrganizationalUnit -Name $childOU -Path $parentOUdn -ProtectedFromAccidentalDeletion $model.PreventOUDeletion   
        }
    }
    Write-Host "    [+] CustomOUs created" -ForegroundColor Yellow
    ### foreach Depts in model.json -> create an OU in Users
}
catch {Write-Host $_ -ForegroundColor Red}

### Set GGS groups

### Set DLGS groups

### Create SharedFolder - SMB share Everyone

### Set ACLs to SharedFolder: DLGS (RO & RW)

## Get

